import SwiftUI

/// Anthropic-inspired warm palette: ivory paper, ink text, clay/coral accent.
enum Theme {
    static let cream     = Color(red: 0.941, green: 0.933, blue: 0.902) // #F0EEE6
    static let ink       = Color(red: 0.122, green: 0.118, blue: 0.114) // #1F1E1D
    static let inkMuted  = Color(red: 0.463, green: 0.455, blue: 0.424) // #76746C
    static let accent    = Color(red: 0.851, green: 0.467, blue: 0.341) // #D97757  Claude coral
    static let warning   = Color(red: 0.749, green: 0.302, blue: 0.263) // #BF4D43  clay rust
    static let track     = Color(red: 0.882, green: 0.871, blue: 0.831) // #E1DED4
    static let divider   = Color(red: 0.871, green: 0.859, blue: 0.812) // #DEDBCF

    /// Bar / accent colour by how much is spent. Warns when running low.
    static func barColor(used: Int) -> Color {
        used < 80 ? accent : warning
    }
}
