import SwiftUI
import Contacts
import ContactsUI
import MessageUI

struct ClassDetailView: View {
    @EnvironmentObject var store: DataStore
    @State private var classRoom: ClassRoom
    @State private var showingAddStudent = false
    @State private var showingEditStudent = false
    @State private var selectedStudent: Student? = nil
    @State private var editingName = ""
    @State private var editingPhone = ""
    @State private var editingMemo = ""

    @State private var attendedStudents: Set<UUID> = []
    @State private var sentStudents: Set<UUID> = []
    @State private var currentStudentForSMS: Student? = nil
    @State private var messageBody = ""
    @State private var smsMode: SMSMode = .attendance
    @State private var showingCodiSMS = false
    @State private var showingEndClassAlert = false
    @State private var showingDoneAlert = false
    @State private var endClassQueue: [Student] = []
    @State private var endClassIndex = 0
    @State private var endClassSentCount = 0

    enum SMSMode { case attendance, endClass }

    init(classRoom: ClassRoom) {
        _classRoom = State(initialValue: classRoom)
    }

    var normalStudents: [Student] {
        classRoom.students.filter { $0.name != "__codi__" }
    }

    var codiTeacher: Student? {
        classRoom.students.first(where: { $0.name == "__codi__" })
    }

    var attendedStudentList: [Student] {
        classRoom.students.filter { attendedStudents.contains($0.id) }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("오늘 출석")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(attendedStudents.count) / \(normalStudents.count)명")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.indigo)
                    }
                    Spacer()
                    if !classRoom.schedule.isEmpty {
                        Text(classRoom.schedule)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if codiTeacher != nil && !attendedStudents.isEmpty {
                Section {
                    Button(action: {
                        prepareCodiMessage()
                        showingCodiSMS = true
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "message.fill")
                                .font(.title3)
                            Text("코디 선생님께 출석 현황 전송")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.purple)
                }
            }

            Section {
                if normalStudents.isEmpty {
                    Text("등록된 학생이 없어요. 학생을 추가해주세요.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(normalStudents) { student in
                        HStack(spacing: 14) {
                            Button(action: { markAttendance(student: student) }) {
                                ZStack {
                                    Circle()
                                        .fill(attendedStudents.contains(student.id) ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: attendedStudents.contains(student.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundColor(attendedStudents.contains(student.id) ? .green : .gray)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(attendedStudents.contains(student.id))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(student.name)
                                    .font(.headline)
                                if !student.memo.isEmpty {
                                    Text(student.memo)
                                        .font(.caption)
                                        .foregroundColor(.indigo)
                                }
                                Text(student.phone)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            HStack(spacing: 8) {
                                if sentStudents.contains(student.id) {
                                    Label("발송", systemImage: "message.fill")
                                        .font(.caption)
                                        .foregroundColor(.indigo)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.indigo.opacity(0.1))
                                        .cornerRadius(8)
                                } else if attendedStudents.contains(student.id) {
                                    Text("출석")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                }

                                Button(action: {
                                    selectedStudent = student
                                    editingName = student.name
                                    editingPhone = student.phone
                                    editingMemo = student.memo
                                    showingEditStudent = true
                                }) {
                                    Image(systemName: "pencil.circle")
                                        .foregroundColor(.secondary)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteStudent)
                }
            } header: {
                HStack {
                    Text("학생 목록")
                    Spacer()
                    Button(action: { showingAddStudent = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.indigo)
                    }
                }
            } footer: {
                Text("왼쪽으로 밀면 삭제, 연필 아이콘을 누르면 수정")
                    .font(.caption)
            }

            if !attendedStudents.isEmpty {
                Section {
                    Button(action: { showingEndClassAlert = true }) {
                        HStack {
                            Spacer()
                            Image(systemName: "door.right.hand.open")
                                .font(.title3)
                            Text("수업 종료 문자 발송")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.orange)
                } footer: {
                    Text("출석한 \(attendedStudents.count)명에게 수업 종료 문자를 보냅니다.")
                        .font(.caption)
                }
            }

            Section {
                if let codi = classRoom.students.first(where: { $0.name == "__codi__" }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("코디 선생님")
                                    .font(.headline)
                            }
                            Text(codi.phone)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            selectedStudent = codi
                            editingName = "__codi__"
                            editingPhone = codi.phone
                            editingMemo = ""
                            showingEditStudent = true
                        }) {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.orange)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button(action: {
                        selectedStudent = nil
                        editingName = "__codi__"
                        editingPhone = ""
                        editingMemo = ""
                        showingEditStudent = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.orange)
                            Text("코디 선생님 번호 등록")
                                .foregroundColor(.orange)
                        }
                    }
                }
            } header: {
                Text("출석 요약 수신자")
            } footer: {
                Text("출석 현황을 코디 선생님께 문자로 보낼 수 있습니다.")
                    .font(.caption)
            }

            if !attendedStudents.isEmpty {
                Section {
                    Button(action: { showingDoneAlert = true }) {
                        HStack {
                            Spacer()
                            Text("오늘 출석 완료 (초기화)")
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                } footer: {
                    Text("완료하면 오늘 출석 기록이 초기화됩니다.")
                        .font(.caption)
                }
            }
        }
        .navigationTitle(classRoom.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddStudent) {
            AddStudentView(classRoom: $classRoom, onSave: {
                store.updateClass(classRoom)
            })
        }
        .sheet(isPresented: $showingEditStudent) {
            EditStudentView(
                isCodi: editingName == "__codi__" || selectedStudent?.name == "__codi__",
                name: $editingName,
                phone: $editingPhone,
                memo: $editingMemo,
                onSave: {
                    if let student = selectedStudent,
                       let index = classRoom.students.firstIndex(where: { $0.id == student.id }) {
                        if student.name == "__codi__" {
                            classRoom.students[index].name = "__codi__"
                        } else {
                            classRoom.students[index].name = editingName
                            classRoom.students[index].memo = editingMemo
                        }
                        classRoom.students[index].phone = editingPhone
                    } else {
                        let codi = Student(name: "__codi__", phone: editingPhone)
                        classRoom.students.append(codi)
                    }
                    store.updateClass(classRoom)
                },
                onDelete: {
                    if let student = selectedStudent {
                        classRoom.students.removeAll { $0.id == student.id }
                        store.updateClass(classRoom)
                    }
                }
            )
        }
        .sheet(item: $currentStudentForSMS) { student in
            MessageComposeView(
                recipients: [student.phone],
                body: messageBody
            ) { result in
                if result == .sent {
                    if smsMode == .attendance {
                        sentStudents.insert(student.id)
                        let record = AttendanceRecord(
                            studentId: student.id,
                            studentName: student.name,
                            className: classRoom.name,
                            timestamp: Date(),
                            messageSent: true
                        )
                        store.addRecord(record)
                        currentStudentForSMS = nil
                    } else {
                        endClassSentCount += 1
                        currentStudentForSMS = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            processNextEndClass()
                        }
                    }
                } else {
                    currentStudentForSMS = nil
                    if smsMode == .endClass {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            processNextEndClass()
                        }
                    }
                }
            }
            .id(student.id)
        }
        .sheet(isPresented: $showingCodiSMS) {
            if let codi = codiTeacher {
                MessageComposeView(
                    recipients: [codi.phone],
                    body: messageBody
                ) { _ in }
            }
        }
        .alert("수업 종료 문자 발송", isPresented: $showingEndClassAlert) {
            Button("발송 시작") { startEndClassSMS() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("출석한 \(attendedStudents.count)명에게\n수업 종료 문자를 순서대로 발송합니다.")
        }
        .alert("출석 완료", isPresented: $showingDoneAlert) {
            Button("초기화", role: .destructive) {
                store.clearSession(classRoomId: classRoom.id)
                attendedStudents = []
                sentStudents = []
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("총 \(normalStudents.count)명 중 \(attendedStudents.count)명 출석\n초기화하면 오늘 출석이 리셋됩니다.")
        }
        .onAppear {
            if let updated = store.classes.first(where: { $0.id == classRoom.id }) {
                classRoom = updated
            }
            attendedStudents = store.loadSession(classRoomId: classRoom.id)
        }
        .onChange(of: attendedStudents) {
            store.updateSession(classRoomId: classRoom.id, attendedIds: attendedStudents)
        }
    }

    func markAttendance(student: Student) {
        guard !attendedStudents.contains(student.id) else { return }
        attendedStudents.insert(student.id)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH시 mm분"
        let timeStr = formatter.string(from: Date())

        messageBody = "[\(classRoom.name)]\n\(student.name) 학생 \(timeStr)에 출석하였습니다."
        smsMode = .attendance
        currentStudentForSMS = student
    }

    func prepareCodiMessage() {
        let total = normalStudents.count
        let attended = attendedStudents.count
        messageBody = "[\(classRoom.name)]\n전체 \(total)명 중 \(attended)명 출석하였습니다."
    }

    func startEndClassSMS() {
        endClassQueue = attendedStudentList.filter { $0.name != "__codi__" }
        endClassIndex = 0
        endClassSentCount = 0
        guard !endClassQueue.isEmpty else { return }
        sendEndClassToStudent(endClassQueue[0])
        endClassIndex = 1
    }

    func sendEndClassToStudent(_ student: Student) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH시 mm분"
        let timeStr = formatter.string(from: Date())
        messageBody = "[\(classRoom.name)]\n\(timeStr)에 수업이 종료되었습니다."
        smsMode = .endClass
        currentStudentForSMS = student
    }

    func processNextEndClass() {
        guard endClassIndex < endClassQueue.count else {
            currentStudentForSMS = nil
            return
        }
        let student = endClassQueue[endClassIndex]
        endClassIndex += 1
        sendEndClassToStudent(student)
    }

    func deleteStudent(at offsets: IndexSet) {
        let normal = normalStudents
        var updated = normal
        updated.remove(atOffsets: offsets)
        let codi = classRoom.students.filter { $0.name == "__codi__" }
        classRoom.students = updated + codi
        store.updateClass(classRoom)
    }
}

// MARK: - 학생 수정 뷰
struct EditStudentView: View {
    let isCodi: Bool
    @Binding var name: String
    @Binding var phone: String
    @Binding var memo: String
    var onSave: () -> Void
    var onDelete: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingContactPicker = false
    @State private var contacts: [CNContact] = []
    @State private var searchText = ""

    var filteredContacts: [CNContact] {
        if searchText.isEmpty { return contacts }
        return contacts.filter {
            "\($0.familyName)\($0.givenName)".localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if !isCodi {
                    Section("학생 이름") {
                        TextField("이름", text: $name)
                    }
                }

                Section(isCodi ? "코디 선생님 전화번호" : "전화번호") {
                    Button(action: {
                        loadContacts()
                        showingContactPicker = true
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundColor(.indigo)
                            Text("연락처에서 선택")
                                .foregroundColor(.indigo)
                        }
                    }
                    TextField("전화번호 (예: 01012345678)", text: $phone)
                        .keyboardType(.phonePad)
                }

                if !isCodi {
                    Section("메모") {
                        TextField("예: 3학년, 목요반", text: $memo)
                    }
                }

                Section {
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        HStack {
                            Spacer()
                            Text(isCodi ? "코디 선생님 삭제" : "학생 삭제")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(isCodi ? "코디 선생님 수정" : "학생 정보 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(phone.trimmingCharacters(in: .whitespaces).isEmpty ||
                              (!isCodi && name.trimmingCharacters(in: .whitespaces).isEmpty))
                }
            }
            .alert("삭제하시겠어요?", isPresented: $showingDeleteAlert) {
                Button("삭제", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("취소", role: .cancel) {}
            }
            .sheet(isPresented: $showingContactPicker) {
                NavigationStack {
                    List(filteredContacts, id: \.identifier) { contact in
                        let fullName = "\(contact.familyName)\(contact.givenName)"
                        let contactPhone = contact.phoneNumbers.first?.value.stringValue ?? ""
                        Button(action: {
                            let digits = contactPhone.filter { $0.isNumber }
                            phone = digits.hasPrefix("82") && digits.count >= 11 ? "0" + digits.dropFirst(2) : digits
                            showingContactPicker = false
                        }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fullName.isEmpty ? "(이름 없음)" : fullName)
                                    .foregroundColor(.primary)
                                Text(contactPhone)
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
                if !contact.phoneNumbers.isEmpty { result.append(contact) }
            }
            DispatchQueue.main.async {
                self.contacts = result.sorted {
                    "\($0.familyName)\($0.givenName)" < "\($1.familyName)\($1.givenName)"
                }
            }
        }
    }
}

// MARK: - Message Compose
struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    let completion: (MessageComposeResult) -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = recipients
        vc.body = body
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let completion: (MessageComposeResult) -> Void
        init(completion: @escaping (MessageComposeResult) -> Void) { self.completion = completion }
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
            completion(result)
        }
    }
}
