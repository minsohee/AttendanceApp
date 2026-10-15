import SwiftUI

struct AddClassView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss

    @State private var className = ""
    @State private var schedule = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("수업 정보") {
                    TextField("수업명 (예: 영어회화 월요반)", text: $className)
                    TextField("시간/메모 (예: 매주 월요일 10시)", text: $schedule)
                }

                Section {
                    Text("수업을 만든 후 학생을 추가할 수 있어요.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("새 수업 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("추가") {
                        let newClass = ClassRoom(name: className, schedule: schedule, students: [])
                        store.addClass(newClass)
                        dismiss()
                    }
                    .disabled(className.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
