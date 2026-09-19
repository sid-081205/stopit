import SwiftUI

enum StopitTheme {
    static let background = Color.black
    static let surface = Color(white: 0.08)
    static let raisedSurface = Color(white: 0.12)
    static let border = Color(white: 0.22)
    static let primary = Color.white
    static let secondary = Color(white: 0.64)
}

struct SoftPressButtonStyle: ButtonStyle {
    var reduceMotion = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(reduceMotion || !configuration.isPressed ? 1 : 0.985)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.14),
                value: configuration.isPressed
            )
    }
}

struct StopitCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(StopitTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(StopitTheme.border, lineWidth: 0.5)
            }
    }
}
