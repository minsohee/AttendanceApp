import SwiftUI
import MessageUI

struct AttendanceCheckView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss

    let classRoom: ClassRoom

    @State private var attendedStudents: Set<UUID> = []
    @State private var currentStudentForSMS: Student? = nil
    @State private var smsMode: SMSMode = .attendance
    @State private var showingMessageCompose = false
    @State private var showingCodiSMS = false
    @State private var messageBody = ""
    @State private var sentStudents: Set<UUID> = []
    @State private var showingEndClassAlert = false
    @State private var showingDoneAlert = false
    @State private var endClassSentCount = 0
    @State private var endClassIndex = 0
    @State private var endClassQueue: [Student] = []

    enum SMSMode {
        case attendance, endClass
    }

    var attendedStudentList: [Student] {
        classRoom.students.filter { attendedStudents.contains($0.id) }
    }

    var normalStudents: [Student] {
        classRoom.students.filter { $0.name != "__codi__" }
    }

    var codiTeacher: Student? {
        classRoom.students.first(where: { $0.name == "__codi__" })
    }

    var body: some View {
        NavigationStack {
            List {
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
                    } footer: {
                        Text("출석 \(attendedStudents.count)명 / 전체 \(normalStudents.count)명")
                            .font(.caption)
                    }
                }

                Section("학생 목록 (\(attendedStudents.count)/\(normalStudents.count)명 출석)") {
                    ForEach(normalStudents) { student in
                        StudentAttendanceRow(
                            student: student,
                            isAttended: attendedStudents.contains(student.id),
                            isSent: sentStudents.contains(student.id)
                        ) {
                            markAttendance(student: student)
                        }
                    }
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
            }
            .navigationTitle("\(classRoom.name) 출석체크")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") { showingDoneAlert = true }
                        .fontWeight(.semibold)
                        .foregroundColor(.indigo)
                }
            }
            // 출석 문자 / 수업종료 문자
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
                        } else {
                            endClassSentCount += 1
                        }
                    }
                    currentStudentForSMS = nil
                    if smsMode == .endClass {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            processNextEndClass()
                        }
                    }
                }
            }
            // 코디 문자
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
            .alert("출석 체크 완료", isPresented: $showingDoneAlert) {
                Button("완료") {
                    store.clearSession(classRoomId: classRoom.id)
                    dismiss()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("총 \(normalStudents.count)명 중 \(attendedStudents.count)명 출석\n완료하면 오늘 출석 기록이 초기화됩니다.")
            }
        }
        .onAppear {
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
        endClassQueue = attendedStudentList
        endClassIndex = 0
        endClassSentCount = 0
        processNextEndClass()
    }

    func processNextEndClass() {
        guard endClassIndex < endClassQueue.count else {
            currentStudentForSMS = nil
            return
        }
        let student = endClassQueue[endClassIndex]
        endClassIndex += 1

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH시 mm분"
        let timeStr = formatter.string(from: Date())

        messageBody = "[\(classRoom.name)]\n\(timeStr)에 수업이 종료되었습니다."
        smsMode = .endClass
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            currentStudentForSMS = student
        }
    }
}

// MARK: - Student Row
struct StudentAttendanceRow: View {
    let student: Student
    let isAttended: Bool
    let isSent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isAttended ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: isAttended ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isAttended ? .green : .gray)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(student.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(student.phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isSent {
                    Label("문자발송", systemImage: "message.fill")
                        .font(.caption)
                        .foregroundColor(.indigo)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.indigo.opacity(0.1))
                        .cornerRadius(8)
                } else if isAttended {
                    Text("출석")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 4)
        }
        .disabled(isAttended)
    }
}


