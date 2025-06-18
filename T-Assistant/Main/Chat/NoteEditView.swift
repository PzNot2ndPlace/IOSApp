import SwiftUI

struct NoteEditView: View {
    let noteData: NoteData
    var onSave: (() -> Void)? = nil

    @State private var selectedCategory: String
    @State private var editedText: String
    @State private var selectedTriggerId: UUID?
    @State private var triggerValue: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let categories = [
        "EVENT", "SHOPPING", "CALL", "MEETING", "DEADLINE", "HEALTH", "ROUTINE", "OTHER"
    ]
    private let categoryIcons: [String: String] = [
        "EVENT": "sparkles",
        "SHOPPING": "cart",
        "CALL": "phone",
        "MEETING": "person.2",
        "DEADLINE": "clock",
        "HEALTH": "heart",
        "ROUTINE": "repeat",
        "OTHER": "ellipsis"
    ]
    private let triggerIcons: [String: String] = [
        "TIME": "calendar",
        "LOCATION": "location.fill"
    ]

    init(noteData: NoteData, onSave: (() -> Void)? = nil) {
        self.noteData = noteData
        self.onSave = onSave
        _selectedCategory = State(initialValue: noteData.categoryType)
        _editedText = State(initialValue: noteData.text)
        _selectedTriggerId = State(initialValue: noteData.triggers.first?.id)
        if let firstTrigger = noteData.triggers.first {
            _triggerValue = State(initialValue: firstTrigger.time != nil ? Self.formatDate(firstTrigger.time!) : (firstTrigger.location ?? ""))
        }
    }

    var body: some View {
        ZStack {
            Color(red: 230/255, green: 235/255, blue: 241/255)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text("Редактировать заметку")
                        .font(.largeTitle).bold()
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Заголовок: Редактировать заметку")

                ScrollView {
                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Категория")
                                .font(.caption)
                                .foregroundColor(.gray)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(categories, id: \.self) { cat in
                                        Button(action: { selectedCategory = cat }) {
                                            HStack(spacing: 6) {
                                                if let icon = categoryIcons[cat] {
                                                    Image(systemName: icon)
                                                        .font(.system(size: 16, weight: .medium))
                                                }
                                                Text(localizedType(cat))
                                                    .font(.system(size: 16, weight: .medium))
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 14)
                                            .background(selectedCategory == cat ? Color("action") : Color(red: 245/255, green: 245/255, blue: 245/255))
                                            .foregroundColor(.black)
                                            .cornerRadius(8)
                                            .shadow(color: selectedCategory == cat ? Color("action").opacity(0.15) : .clear, radius: 4, x: 0, y: 2)
                                        }
                                        .accessibilityLabel("Категория: " + localizedType(cat) + (selectedCategory == cat ? ", выбрано" : ""))
                                        .accessibilityAddTraits(selectedCategory == cat ? [.isButton, .isSelected] : .isButton)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Выбор категории напоминания")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Текст напоминания")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Текст", text: $editedText)
                                .padding(10)
                                .background(Color(red: 245/255, green: 245/255, blue: 245/255))
                                .cornerRadius(8)
                                .accessibilityLabel("Текст напоминания")
                                .accessibilityHint("Введите или измените текст напоминания")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Поле ввода текста напоминания")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Триггер")
                                .font(.caption)
                                .foregroundColor(.gray)
                            if noteData.triggers.count <= 3 {
                                HStack(spacing: 10) {
                                    ForEach(noteData.triggers) { trigger in
                                        Button(action: { selectedTriggerId = trigger.id }) {
                                            HStack(spacing: 6) {
                                                if let icon = triggerIcons[trigger.triggerType.uppercased()] {
                                                    Image(systemName: icon)
                                                        .font(.system(size: 16, weight: .medium))
                                                }
                                                Text(localizedType(trigger.triggerType))
                                                    .font(.system(size: 16, weight: .medium))
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 14)
                                            .background(selectedTriggerId == trigger.id ? Color("action") : Color(red: 245/255, green: 245/255, blue: 245/255))
                                            .foregroundColor(.black)
                                            .cornerRadius(8)
                                            .shadow(color: selectedTriggerId == trigger.id ? Color("action").opacity(0.15) : .clear, radius: 4, x: 0, y: 2)
                                        }
                                        .accessibilityLabel("Триггер: " + localizedType(trigger.triggerType) + (selectedTriggerId == trigger.id ? ", выбран" : ""))
                                        .accessibilityAddTraits(selectedTriggerId == trigger.id ? [.isButton, .isSelected] : .isButton)
                                    }
                                }
                                .padding(.vertical, 2)
                            } else {
                                Picker("Триггер", selection: $selectedTriggerId) {
                                    ForEach(noteData.triggers) { trigger in
                                        HStack {
                                            if let icon = triggerIcons[trigger.triggerType.uppercased()] {
                                                Image(systemName: icon)
                                            }
                                            Text(localizedType(trigger.triggerType))
                                        }.tag(trigger.id as UUID?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .font(.system(size: 16, weight: .medium))
                                .accessibilityLabel("Выбор триггера напоминания")
                            }
                            if let trigger = noteData.triggers.first(where: { $0.id == selectedTriggerId }) {
                                if trigger.triggerType.uppercased() == "TIME" {
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar")
                                            .foregroundColor(Color("action"))
                                        DatePicker("", selection: Binding(
                                            get: {
                                                trigger.time ?? Date()
                                            },
                                            set: { newDate in
                                                triggerValue = Self.formatDate(newDate)
                                            }
                                        ), displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .accessibilityLabel("Время напоминания")
                                        .accessibilityHint("Выберите или измените дату и время")
                                    }
                                    .padding(10)
                                    .background(Color(red: 245/255, green: 245/255, blue: 245/255))
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                } else if trigger.triggerType.uppercased() == "LOCATION" {
                                    TextField("Локация", text: $triggerValue)
                                        .padding(10)
                                        .background(Color(red: 245/255, green: 245/255, blue: 245/255))
                                        .cornerRadius(8)
                                        .accessibilityLabel("Локация для напоминания")
                                        .accessibilityHint("Введите или измените локацию")
                                } else {
                                    TextField("Значение триггера", text: $triggerValue)
                                        .padding(10)
                                        .background(Color(red: 245/255, green: 245/255, blue: 245/255))
                                        .cornerRadius(8)
                                        .accessibilityLabel("Значение триггера для напоминания")
                                        .accessibilityHint("Введите или измените значение триггера")
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Выбор триггера для напоминания")

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .accessibilityLabel("Ошибка: " + errorMessage)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)
                }

                Spacer()

                HStack(spacing: 16) {
                    Button(action: { onSave?() }) {
                        Text("Отмена")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                    }
                    .accessibilityLabel("Отмена редактирования")
                    .accessibilityHint("Двойной тап — закрыть экран без сохранения изменений")
                    Button(action: { saveNote() }) {
                        Text(isSaving ? "Сохраняю..." : "Сохранить")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isSaving ? Color.gray.opacity(0.3) : Color("action"))
                            .foregroundColor(isSaving ? .gray : .black)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                    }
                    .disabled(isSaving)
                    .accessibilityLabel("Сохранить изменения")
                    .accessibilityHint("Двойной тап — сохранить изменения в напоминании")
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }

    private func saveNote() {
        guard let triggerId = selectedTriggerId else {
            errorMessage = "Выберите триггер"
            return
        }
        isSaving = true
        NoteService.shared.updateNote(noteId: noteData.id, categoryType: selectedCategory, text: editedText, triggerId: triggerId, triggerValue: triggerValue) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success:
                    onSave?()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.string(from: date)
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
