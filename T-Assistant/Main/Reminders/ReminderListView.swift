import SwiftUI

struct ReminderListView: View {
    @StateObject private var viewModel = ReminderListViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 230/255, green: 235/255, blue: 241/255)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        if viewModel.filteredReminders.isEmpty && !viewModel.isLoading {
                            Text("У вас пока нет напоминаний, соответствующих поиску.")
                                .foregroundColor(.gray)
                                .padding()
                                .accessibilityLabel("Нет напоминаний, соответствующих поиску")
                        } else {
                            ForEach(viewModel.filteredReminders) { reminder in
                                NoteCardView(noteData: reminder, onEdit: {
                                    viewModel.fetchReminders()
                                })
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel(noteAccessibilityLabel(reminder))
                                .accessibilityHint("Двойной тап — открыть меню действий для напоминания")
                            }
                        }

                        if viewModel.isLoading {
                            ProgressView("Загрузка напоминаний...")
                                .padding()
                                .accessibilityLabel("Загрузка напоминаний")
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Поиск напоминаний")
            .accessibilityLabel("Поиск напоминаний")
            .accessibilityHint("Введите текст для поиска по напоминаниям")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
        }
        .onAppear {
            viewModel.fetchReminders()
        }
        .alert(item: $viewModel.errorMessage) { error in
            Alert(title: Text("Ошибка"), message: Text(error.message), dismissButton: .default(Text("OK")))
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
}

// ViewModel для ReminderListView
class ReminderListViewModel: ObservableObject {
    @Published var allReminders: [NoteData] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: ErrorMessage? = nil
    @Published var searchText: String = ""

    var filteredReminders: [NoteData] {
        if searchText.isEmpty {
            return allReminders
        } else {
            return allReminders.filter { reminder in
                reminder.text.lowercased().contains(searchText.lowercased()) ||
                reminder.categoryType.lowercased().contains(searchText.lowercased()) ||
                reminder.triggers.contains(where: { trigger in
                    trigger.triggerType.lowercased().contains(searchText.lowercased()) ||
                    (trigger.location?.lowercased().contains(searchText.lowercased()) ?? false)
                })
            }
        }
    }

    func fetchReminders() {
        isLoading = true
        ReminderService.shared.fetchMyNotes { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let notes):
                    self.allReminders = notes
                case .failure(let error):
                    self.errorMessage = ErrorMessage(message: error.localizedDescription)
                    print("Error fetching reminders: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    ReminderListView()
} 
