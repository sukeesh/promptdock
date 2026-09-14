import SwiftUI

enum DockColor {
    static let ink = Color(red: 0.08, green: 0.12, blue: 0.10)
    static let muted = Color(red: 0.35, green: 0.41, blue: 0.37)
    static let paper = Color(red: 0.96, green: 0.97, blue: 0.94)
    static let panel = Color.white
    static let line = Color(red: 0.83, green: 0.86, blue: 0.80)
    static let lineStrong = Color(red: 0.61, green: 0.68, blue: 0.61)
    static let spruce = Color(red: 0.13, green: 0.28, blue: 0.22)
    static let moss = Color(red: 0.41, green: 0.53, blue: 0.35)
    static let copper = Color(red: 0.71, green: 0.40, blue: 0.25)
    static let steel = Color(red: 0.23, green: 0.37, blue: 0.45)
    static let mist = Color(red: 0.90, green: 0.93, blue: 0.89)
    static let warm = Color(red: 0.95, green: 0.88, blue: 0.75)
}

struct PlainPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DockColor.panel)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(DockColor.line)
            )
    }
}

extension View {
    func plainPanel() -> some View {
        modifier(PlainPanel())
    }
}
