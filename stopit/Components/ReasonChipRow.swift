import SwiftUI

struct ReasonChipRow: View {
    var selected: HabitEventReason?
    var onSelect: (HabitEventReason?) -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(HabitEventReason.allCases) { reason in
                Button {
                    onSelect(selected == reason ? nil : reason)
                } label: {
                    Text(reason.displayName)
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            selected == reason
                                ? StopitTheme.raisedSurface
                                : Color.clear
                        )
                        .foregroundStyle(
                            selected == reason
                                ? StopitTheme.primary
                                : StopitTheme.secondary
                        )
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(
                                    selected == reason
                                        ? StopitTheme.border
                                        : StopitTheme.border.opacity(0.7),
                                    lineWidth: 0.5
                                )
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(reason.displayName)
                .accessibilityAddTraits(selected == reason ? .isSelected : [])
                .accessibilityIdentifier("reason \(reason.rawValue)")
            }
        }
    }
}
