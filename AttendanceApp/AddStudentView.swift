import SwiftUI
import Contacts

struct AddStudentView: View {
    @Binding var classRoom: ClassRoom
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var studentName = ""
    @State private var studentPhone = ""
    @State private var studentMemo = ""
    @State private var showingContactPicker = false
    @State private var contactSelected = false
    @State private var contacts: [CNContact] = []
    @State private var searchText = ""

    var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter {
            let fullName = "\($0.familyName)\($0.givenName)"
            return fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("학생 이름") {
                    TextField("이름 입력 (예: 홍길동)", text: $studentName)
                }

                Section("전화번호") {
                    Button(action: {
                        loadContacts()
                        showingContactPicker = true
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundColor(.indigo)
                            Text(contactSelected ? "연락처 다시 선택" : "연락처에서 전화번호 가져오기")
                                .foregroundColor(.indigo)
                        }
                    }

                    TextField("또는 직접 입력 (예: 01012345678)", text: $studentPhone)
                        .keyboardType(.phonePad)

                    if contactSelected {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("전화번호 불러옴: \(studentPhone)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("메모") {
                    TextField("예: 3학년, 목요반", text: $studentMemo)
                }

                Section {
                    Text("메모는 동명이인 구분이나 특이사항을 적어두는 공간이에요.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("학생 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("추가") {
                        let student = Student(
                            name: studentName.trimmingCharacters(in: .whitespaces),
                            phone: cleanPhone(studentPhone),
                            memo: studentMemo.trimmingCharacters(in: .whitespaces)
                        )
                        classRoom.students.append(student)
                        onSave()
                        dismiss()
                    }
                    .disabled(studentName.trimmingCharacters(in: .whitespaces).isEmpty ||
                              studentPhone.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                NavigationStack {
                    List(filteredContacts, id: \.identifier) { contact in
                        let fullName = "\(contact.familyName)\(contact.givenName)"
                        let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
                        Button(action: {
                            studentPhone = cleanPhone(phone)
                            contactSelected = true
                            showingContactPicker = false
                        }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fullName.isEmpty ? "(이름 없음)" : fullName)
                                    .foregroundColor(.primary)
                                Text(phone)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "연락처 검색")
                    .navigationTitle("연락처 선택")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("취소") { showingContactPicker = false }
                        }
                    }
                }
            }
        }
    }

    func loadContacts() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, _ in
            guard granted else { return }
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keys)
            var result: [CNContact] = []
            try? store.enumerateContacts(with: request) { contact, _ in
                if !contact.phoneNumbers.isEmpty {
                    result.append(contact)
                }
            }
            DispatchQueue.main.async {
                self.contacts = result.sorted {
                    "\($0.familyName)\($0.givenName)" < "\($1.familyName)\($1.givenName)"
                }
            }
        }
    }

    func cleanPhone(_ phone: String) -> String {
        let digits = phone.filter { $0.isNumber }
        if digits.hasPrefix("82") && digits.count >= 11 {
            return "0" + digits.dropFirst(2)
        }
        return digits
    }
}
