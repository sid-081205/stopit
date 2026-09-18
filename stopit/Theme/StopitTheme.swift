import SwiftUI

enum StopitTheme {
    static let background = Color.black
    static let surface = Color(white: 0.08)
    static let raisedSurface = Color(white: 0.12)
    static let border = Color(white: 0.22)
    static let primary = Color.white
    static let secondary = Color(white: 0.64)
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
