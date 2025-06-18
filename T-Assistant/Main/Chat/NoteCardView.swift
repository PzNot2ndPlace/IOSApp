import SwiftUI
import EventKit

struct NoteCardView: View {
    let noteData: NoteData
    var onEdit: (() -> Void)? = nil
    @State private var showEditSheet = false
    @State private var showExportAlert = false
    @State private var exportResult: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Напоминание")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                if !noteData.categoryType.isEmpty {
                    Text(localizedType(noteData.categoryType).uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(5)
                }
            }

            Text(noteData.text)
                .font(.body)
                .padding(8)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(8)
            
            if !noteData.triggers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Триггеры:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    ForEach(noteData.triggers) { trigger in
                        HStack {
                            Image(systemName: icon(for: trigger.triggerType))
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(displayString(for: trigger))
                                .font(.caption)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            HStack {
                Spacer()
                Button(action: {
                    showEditSheet = true
                }) {
                    Text("Редактировать")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Редактировать напоминание")
                .accessibilityHint("Двойной тап — открыть экран редактирования")
                Button(action: {
                    exportToCalendar()
                }) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title3)
                        .foregroundColor(.green)
                        .padding(.leading, 8)
                }
                .accessibilityLabel("Экспортировать в календарь")
                .accessibilityHint("Двойной тап — добавить напоминание в календарь")
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
        .sheet(isPresented: $showEditSheet) {
            NoteEditView(noteData: noteData) {
                showEditSheet = false
                onEdit?()
            }
        }
        .alert(isPresented: $showExportAlert) {
            Alert(title: Text("Экспорт в календарь"), message: Text(exportResult), dismissButton: .default(Text("OK")))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(noteAccessibilityLabel(noteData))
        .accessibilityHint("Двойной тап — открыть меню действий для напоминания")
    }
    
    private func icon(for triggerType: String) -> String {
        switch triggerType {
        case "TIME": return "calendar"
        case "LOCATION": return "location.fill"
        default: return "questionmark.circle.fill"
        }
    }

    private func localizedType(_ type: String) -> String {
        switch type.uppercased() {
        case "LOCATION": return "Локация"
        case "TIME": return "Время"
        case "EVENT": return "Мероприятие"
        case "SHOPPING": return "Шоппинг"
        case "CALL": return "Звонок"
        case "MEETING": return "Встреча"
        case "DEADLINE": return "Дедлайн"
        case "HEALTH": return "Здоровье"
        case "ROUTINE": return "Рутина"
        case "OTHER": return "Другое"
        default: return type
        }
    }

    private func displayString(for trigger: NoteData.Trigger) -> String {
        var parts: [String] = []
        parts.append(localizedType(trigger.triggerType))

        if let time = trigger.time {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
            parts.append("– \(dateFormatter.string(from: time))")
        }

        if let location = trigger.location, !location.isEmpty {
            parts.append("– \(location)")
        }
        return parts.joined(separator: " ")
    }

    private func exportToCalendar() {
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event) { granted, error in
            if let error = error {
                exportResult = "Ошибка доступа к календарю: \(error.localizedDescription)"
                showExportAlert = true
                return
            }
            if !granted {
                exportResult = "Нет разрешения на доступ к календарю."
                showExportAlert = true
                return
            }
            let event = EKEvent(eventStore: eventStore)
            event.title = noteData.text
            if let timeTrigger = noteData.triggers.first(where: { $0.triggerType.uppercased() == "TIME" }), let date = timeTrigger.time {
                event.startDate = date
                event.endDate = date.addingTimeInterval(60*60)
            } else {
                event.startDate = Date()
                event.endDate = Date().addingTimeInterval(60*60)
            }
            if let locationTrigger = noteData.triggers.first(where: { $0.triggerType.uppercased() == "LOCATION" }), let loc = locationTrigger.location, !loc.isEmpty {
                let ekLocation = EKStructuredLocation(title: loc)
                event.structuredLocation = ekLocation
            }
            event.calendar = eventStore.defaultCalendarForNewEvents
            do {
                try eventStore.save(event, span: .thisEvent)
                exportResult = "Событие успешно добавлено в календарь!"
            } catch {
                exportResult = "Ошибка при сохранении события: \(error.localizedDescription)"
            }
            showExportAlert = true
        }
    }

    private func noteAccessibilityLabel(_ note: NoteData) -> String {
        var result = "Напоминание: " + note.text
        if !note.triggers.isEmpty {
            let triggersText = note.triggers.map { trigger in
                var triggerStr = localizedType(trigger.triggerType)
                if let time = trigger.time {
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "ru_RU")
                    dateFormatter.dateFormat = "d MMMM yyyy HH:mm"
                    triggerStr += ", " + dateFormatter.string(from: time)
                }
                if let location = trigger.location, !location.isEmpty {
                    triggerStr += ", " + location
                }
                return triggerStr
            }.joined(separator: ". ")
            result += ". " + triggersText
        }
        return result
    }
}
