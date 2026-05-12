import WidgetKit
import SwiftUI

// MARK: - Widget entry point
@main
struct PrimeCutWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrimeCutWidget()
        PrimeCutChecklistWidget()
    }
}

// MARK: - Step ring widget
struct PrimeCutWidget: Widget {
    let kind = "PrimeCutStepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrimeCutProvider()) { entry in
            PrimeCutWidgetEntryView(entry: entry)
                .containerBackground(Color(hex: "#0B0B0B"), for: .widget)
        }
        .configurationDisplayName("Prime Cut")
        .description("Steps, streak, and daily progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Checklist-only widget
struct PrimeCutChecklistWidget: Widget {
    let kind = "PrimeCutChecklistWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrimeCutProvider()) { entry in
            ChecklistWidgetView(entry: entry)
                .containerBackground(Color(hex: "#0B0B0B"), for: .widget)
        }
        .configurationDisplayName("Prime Cut Checklist")
        .description("Quick view of today's checklist.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry view router
struct PrimeCutWidgetEntryView: View {
    let entry: PrimeCutEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallStepRingWidget(entry: entry)
        case .systemMedium: MediumWidget(entry: entry)
        case .systemLarge:  LargeWidget(entry: entry)
        default:            SmallStepRingWidget(entry: entry)
        }
    }
}

// MARK: - Checklist widget view
struct ChecklistWidgetView: View {
    let entry: PrimeCutEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        let items = family == .systemSmall
            ? Array(entry.snapshot.checklistItems.prefix(3))
            : entry.snapshot.checklistItems

        VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 7) {
            Text("TODAY")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(Color(hex: "#4CAF72"))
                .kerning(1.5)

            ForEach(items, id: \.label) { item in
                HStack(spacing: 6) {
                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: family == .systemSmall ? 12 : 14))
                        .foregroundStyle(item.isChecked ? Color(hex: "#4CAF72") : Color(hex: "#48484A"))
                    Text(item.label)
                        .font(.system(size: family == .systemSmall ? 12 : 13,
                                      weight: item.isChecked ? .regular : .semibold))
                        .foregroundStyle(item.isChecked ? Color(hex: "#48484A") : Color(hex: "#F5F5F5"))
                        .strikethrough(item.isChecked, color: Color(hex: "#48484A"))
                }
            }
        }
        .padding(family == .systemSmall ? 12 : 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
