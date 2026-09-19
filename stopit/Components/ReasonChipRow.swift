import SwiftUI

struct ReasonChipRow: View {
    var selected: HabitEventReason?
    var onSelect: (HabitEventReason?) -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 8
        ) {
            ForEach(HabitEventReason.allCases) { reason in
                Button {
                    onSelect(selected == reason ? nil : reason)
                } label: {
                    Text(reason.displayName)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            selected == reason
                                ? StopitTheme.raisedSurface
                                : StopitTheme.surface
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
                                        ? StopitTheme.primary.opacity(0.35)
                                        : StopitTheme.border,
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
