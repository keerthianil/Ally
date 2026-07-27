import CoreGraphics

/// Corner-radius scale. Ally leans on generous, friendly radii to match the
/// playful personality — cards use `lg`/`xl`, pills use `full`.
enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 22
    static let xxl: CGFloat = 28
    /// Fully rounded (pills, chips, circular buttons). Use with a large value.
    static let full: CGFloat = 999
}
