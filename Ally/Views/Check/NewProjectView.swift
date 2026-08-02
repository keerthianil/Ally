import SwiftUI

/// Create-a-project sheet: name + platform. Kept intentionally tiny so starting a
/// check feels effortless (empty-state friction is where assessments die).
struct NewProjectView: View {
    var onCreate: (String, Project.Platform) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var platform: Project.Platform = .iOS
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("What are you checking?")
                            .font(Typography.title2)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text("A project name and platform, that's it.")
                            .font(Typography.subheadline)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("PROJECT NAME").font(Typography.eyebrow).foregroundStyle(ColorTokens.textSecondary)
                        TextField("e.g. Checkout redesign", text: $name)
                            .font(Typography.body)
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .accessibilityLabel("Project name")
                            .padding(Spacing.lg)
                            .background(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                                .fill(ColorTokens.surfaceElevated))
                            .overlay(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                                .stroke(ColorTokens.border, lineWidth: 0.5))
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("PLATFORM").font(Typography.eyebrow).foregroundStyle(ColorTokens.textSecondary)
                        HStack(spacing: Spacing.sm) {
                            ForEach(Project.Platform.allCases) { p in
                                platformChip(p)
                            }
                        }
                    }
                }
                .padding(Spacing.xl)
            }
            .background(AllyBackground())
            .navigationTitle("New Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        onCreate(name.trimmingCharacters(in: .whitespaces), platform)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { nameFocused = true }
        }
    }

    private func platformChip(_ p: Project.Platform) -> some View {
        let selected = platform == p
        return Button {
            platform = p
            Haptics.selection()
        } label: {
            Text(p.rawValue)
                .font(Typography.subheadline.weight(.semibold))
                .foregroundStyle(selected ? ColorTokens.onBrand : ColorTokens.textSecondary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .frame(minHeight: 44)
                .background(Capsule().fill(selected ? ColorTokens.brandPrimary : ColorTokens.surfaceElevated))
                .overlay(Capsule().stroke(ColorTokens.border, lineWidth: selected ? 0 : 0.5))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}
