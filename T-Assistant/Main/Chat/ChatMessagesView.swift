import SwiftUI
import AVFoundation

struct ChatMessagesView: View {
    let messages: [Message]
    
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    
    private var groupedMessages: [(date: Date, messages: [Message])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: messages) { calendar.startOfDay(for: $0.timestamp) }
        return grouped
            .sorted { $0.key < $1.key }
            .map { (date: $0.key, messages: $0.value) }
    }
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(groupedMessages, id: \ .date) { (date, messages) in
                        VStack(alignment: .center, spacing: 8) {
                            Text(dateFormatted(date))
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            ForEach(messages) { message in
                                messageBubble(message)
                                    .id(message.id)
                            }
                        }
                    }
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        DispatchQueue.main.async {
                            withAnimation {
                                scrollProxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func messageBubble(_ message: Message) -> some View {
        HStack {
            if message.isUser {
                Spacer()
                Button(action: {
                    if let noteData = message.noteData {
                        speak(noteSpeechText(noteData))
                    } else if let text = message.text {
                        speak(text)
                    }
                }) {
                    Image("speechIcon")
                        .font(.system(size: 28))
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .background(Circle().fill(Color("buttonSec")))
                }
                .accessibilityLabel(message.noteData != nil ? "Озвучить напоминание" : "Озвучить сообщение")
                .accessibilityHint("Двойной тап — воспроизвести голосом")
                .accessibilityAddTraits(.isButton)
            }
            
            if let noteData = message.noteData {
                NoteCardView(noteData: noteData)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(noteAccessibilityLabel(noteData))
                    .accessibilityHint("Двойной тап — открыть меню действий для напоминания")
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    if !message.isUser, let sender = message.senderName {
                        Text(sender)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Text(message.text ?? "")
                        .font(.body)
                    
                    HStack {
                        Spacer()
                        Text(timeFormatted(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.65, alignment: .leading)
                .padding(12)
                .background(bubbleColor(for: message.isUser))
                .cornerRadius(12)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(message.text ?? "")
                .accessibilityHint(message.isUser ? "Ваше сообщение" : "Сообщение от ассистента")
            }
            
            if !message.isUser {
                Button(action: {
                    if let noteData = message.noteData {
                        speak(noteSpeechText(noteData))
                    } else if let text = message.text {
                        speak(text)
                    }
                }) {
                    Image("speechIcon")
                        .font(.system(size: 28))
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .background(Circle().fill(Color("buttonSec")))
                }
                .accessibilityLabel(message.noteData != nil ? "Озвучить напоминание" : "Озвучить сообщение")
                .accessibilityHint("Двойной тап — воспроизвести голосом")
                .accessibilityAddTraits(.isButton)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    private func bubbleColor(for isUser: Bool) -> Color {
        isUser ? Color("priorityMessage") : Color.white
    }
    
    private func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func timeFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")
        speechSynthesizer.speak(utterance)
    }
    
    private func noteSpeechText(_ note: NoteData) -> String {
        var result = note.text
        if !note.triggers.isEmpty {
            let triggersText = note.triggers.map { trigger in
                var triggerStr = localizedType(trigger.triggerType)
                if let time = trigger.time {
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "ru_RU")
                    dateFormatter.dateFormat = "d MMMM yyyy HH:mm"
                    triggerStr += " – " + dateFormatter.string(from: time)
                }
                if let location = trigger.location, !location.isEmpty {
                    triggerStr += " – " + location
                }
                return triggerStr
            }.joined(separator: ". ")
            result += ". " + triggersText
        }
        return result
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
