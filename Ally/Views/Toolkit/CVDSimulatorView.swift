import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Color-blindness simulator. Applies a Core Image color-matrix for each of eight
/// CVD types to a photo the user picks (or a built-in sample), so designers can
/// see what a color-dependent UI looks like to others.
///
/// Picking a photo shows it immediately (Apple's photo picker is already the
/// selection/confirmation step); ✕ on the image clears it back to the sample.
struct CVDSimulatorView: View {
    /// The chosen photo (nil → we're showing the built-in sample).
    @State private var chosenImage: UIImage?

    @State private var display: UIImage?
    @State private var type: CVDType = .normal
    @State private var pickerItem: PhotosPickerItem?
    @State private var sample: UIImage?

    private static let ciContext = CIContext()

    private var isConfirmed: Bool { chosenImage != nil }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                intro
                imageArea
                chipsSection
                photoPickerButton
                Text(type.explanation)
                    .font(Typography.footnote).foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .background(AllyBackground(accent: ColorTokens.vision))
        .scrollIndicators(.hidden)
        .navigationTitle("Color Blindness")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if sample == nil { sample = Self.sampleImage() }; render() }
        .onChange(of: type) { _, _ in render() }
        .onChange(of: pickerItem) { _, new in loadPicked(new) }
    }

    // MARK: Intro

    private var intro: some View {
        Text("See how a screenshot looks to people with different types of color blindness. Tap a type below to simulate it — or choose your own photo.")
            .font(Typography.callout)
            .foregroundStyle(ColorTokens.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Image area

    private var imageArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(ColorTokens.surfaceElevated)
            if let display {
                Image(uiImage: display)
                    .resizable().scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
            } else {
                ProgressView()
            }
        }
        .frame(height: 300)
        .overlay(alignment: .topLeading) {
            Text("\(isConfirmed ? "YOUR PHOTO" : "SAMPLE") · \(type.title.uppercased())")
                .font(Typography.eyebrow).foregroundStyle(.white)
                .padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xxs)
                .background(Capsule().fill(.black.opacity(0.55)))
                .padding(Spacing.md)
        }
        .overlay(alignment: .topTrailing) {
            if isConfirmed { removeButton }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isConfirmed ? "Your photo" : "Built-in sample"), simulated as \(type.title)")
    }

    private var removeButton: some View {
        Button { removePhoto() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(.black.opacity(0.6)))
        }
        .buttonStyle(.plain)
        .padding(Spacing.md)
        .accessibilityLabel("Remove photo")
        .accessibilityHint("Clears your photo and returns to the sample")
    }

    // MARK: Chips

    private var chipsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("TAP A TYPE TO SIMULATE")
                .font(Typography.eyebrow)
                .foregroundStyle(ColorTokens.textTertiary)
            typePicker
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var typePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(CVDType.allCases) { t in
                    Button {
                        type = t; Haptics.selection()
                    } label: {
                        Text(t.title)
                            .font(Typography.subheadline.weight(.semibold))
                            .foregroundStyle(type == t ? ColorTokens.onBrand : ColorTokens.textSecondary)
                            .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm)
                            .frame(minHeight: 44)
                            .background(Capsule().fill(type == t ? ColorTokens.brandPrimary : ColorTokens.surfaceElevated))
                            .overlay(Capsule().stroke(type == t ? Color.clear : ColorTokens.border, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Simulate \(t.title)")
                    .accessibilityAddTraits(type == t ? [.isButton, .isSelected] : .isButton)
                }
            }
            .padding(.horizontal, 2)
        }
        .horizontalScrollFade()
    }

    // MARK: Photo picker button (styled per state)

    @ViewBuilder private var photoPickerButton: some View {
        if isConfirmed {
            // Locked while a photo is confirmed — remove it (✕) to swap.
            Label("Tap ✕ on the photo to choose another", systemImage: "lock.fill")
                .font(Typography.subheadline.weight(.semibold))
                .foregroundStyle(ColorTokens.textTertiary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Capsule().fill(ColorTokens.surfaceElevated.opacity(0.6)))
                .opacity(0.6)
                .accessibilityHidden(true)
        } else {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Choose a screenshot", systemImage: "photo.on.rectangle")
                    .font(Typography.headline)
                    .foregroundStyle(ColorTokens.onBrand)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Capsule().fill(ColorTokens.brandPrimary))
            }
            .accessibilityLabel("Choose a screenshot from your photo library")
        }
    }

    // MARK: Flow actions

    private func removePhoto() {
        chosenImage = nil
        pickerItem = nil
        type = .normal
        Haptics.light()
        render()
    }

    // MARK: Processing

    /// The image the shown/filtered result is derived from.
    private var baseImage: UIImage? { chosenImage ?? sample }

    private func render() {
        guard let base = baseImage else { return }
        display = Self.apply(type, to: base) ?? base
    }

    private func loadPicked(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                await MainActor.run {
                    chosenImage = img       // picker itself is the selection step
                    type = .normal
                    Haptics.success()
                    render()
                }
            }
        }
    }

    static func apply(_ type: CVDType, to image: UIImage) -> UIImage? {
        guard type != .normal, let cg = image.cgImage else { return image }
        let ci = CIImage(cgImage: cg)
        let f = CIFilter.colorMatrix()
        f.inputImage = ci
        let m = type.matrix
        f.rVector = CIVector(x: m[0], y: m[1], z: m[2], w: 0)
        f.gVector = CIVector(x: m[3], y: m[4], z: m[5], w: 0)
        f.bVector = CIVector(x: m[6], y: m[7], z: m[8], w: 0)
        f.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        guard let out = f.outputImage,
              let cgOut = ciContext.createCGImage(out, from: ci.extent) else { return image }
        return UIImage(cgImage: cgOut, scale: image.scale, orientation: image.imageOrientation)
    }

    /// A colorful built-in sample (swatches + a red/green status pair) so the tool
    /// is useful before the user imports anything.
    @MainActor static func sampleImage() -> UIImage? {
        let renderer = ImageRenderer(content: CVDSample())
        renderer.scale = 3
        return renderer.uiImage
    }
}

private struct CVDSample: View {
    private let swatches: [Color] = [
        Color(hex: 0xEF4444), Color(hex: 0xF59E0B), Color(hex: 0x22C55E),
        Color(hex: 0x12C2E9), Color(hex: 0x8B5CF6), Color(hex: 0xD6249F)
    ]
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(swatches.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 8).fill(swatches[i]).frame(width: 44, height: 44)
                }
            }
            HStack(spacing: 16) {
                HStack(spacing: 6) { Circle().fill(Color(hex: 0x22C55E)).frame(width: 18, height: 18); Text("Success").bold() }
                HStack(spacing: 6) { Circle().fill(Color(hex: 0xEF4444)).frame(width: 18, height: 18); Text("Error").bold() }
            }
            .font(.system(size: 15))
        }
        .padding(24)
        .frame(width: 360, height: 180)
        .background(Color.white)
    }
}

enum CVDType: String, CaseIterable, Identifiable {
    case normal, protanopia, protanomaly, deuteranopia, deuteranomaly,
         tritanopia, tritanomaly, achromatopsia
    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal:        return "Normal"
        case .protanopia:    return "Protanopia"
        case .protanomaly:   return "Protanomaly"
        case .deuteranopia:  return "Deuteranopia"
        case .deuteranomaly: return "Deuteranomaly"
        case .tritanopia:    return "Tritanopia"
        case .tritanomaly:   return "Tritanomaly"
        case .achromatopsia: return "Achromatopsia"
        }
    }

    var explanation: String {
        switch self {
        case .normal:        return "Typical color vision — for comparison."
        case .protanopia:    return "No red cones — reds look dark, red/green confusable."
        case .protanomaly:   return "Reduced red sensitivity."
        case .deuteranopia:  return "No green cones — the most common red/green type."
        case .deuteranomaly: return "Reduced green sensitivity — the single most common CVD."
        case .tritanopia:    return "No blue cones — blue/yellow confusable (rare)."
        case .tritanomaly:   return "Reduced blue sensitivity."
        case .achromatopsia: return "No color at all — total color blindness (very rare)."
        }
    }

    /// Row-major 3×3 simulation matrix (widely-used sRGB approximations).
    var matrix: [CGFloat] {
        switch self {
        case .normal:        return [1,0,0, 0,1,0, 0,0,1]
        case .protanopia:    return [0.567,0.433,0, 0.558,0.442,0, 0,0.242,0.758]
        case .protanomaly:   return [0.817,0.183,0, 0.333,0.667,0, 0,0.125,0.875]
        case .deuteranopia:  return [0.625,0.375,0, 0.70,0.30,0, 0,0.30,0.70]
        case .deuteranomaly: return [0.80,0.20,0, 0.258,0.742,0, 0,0.142,0.858]
        case .tritanopia:    return [0.95,0.05,0, 0,0.433,0.567, 0,0.475,0.525]
        case .tritanomaly:   return [0.967,0.033,0, 0,0.733,0.267, 0,0.183,0.817]
        case .achromatopsia: return [0.299,0.587,0.114, 0.299,0.587,0.114, 0.299,0.587,0.114]
        }
    }
}
