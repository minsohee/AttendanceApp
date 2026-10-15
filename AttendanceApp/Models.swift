import SwiftUI
import Combine

// MARK: - Student Model
struct Student: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var phone: String
    var memo: String = ""
}

// MARK: - Class Model
struct ClassRoom: Identifiable, Codable {
    var id = UUID()
    var name: String
    var schedule: String
    var students: [Student]
}

// MARK: - Attendance Record
struct AttendanceRecord: Identifiable, Codable {
    var id = UUID()
    var studentId: UUID
    var studentName: String
    var className: String
    var timestamp: Date
    var messageSent: Bool

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일 HH시 mm분"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Session (진행중인 출석 세션)
struct AttendanceSession: Codable {
    var classRoomId: UUID
    var attendedStudentIds: [UUID]
    var date: Date
}

// MARK: - Data Store
class DataStore: ObservableObject {
    @Published var classes: [ClassRoom] = []
    @Published var records: [AttendanceRecord] = []
    @Published var sessions: [UUID: AttendanceSession] = [:] // 수업별 진행중인 세션

    private let classesKey = "saved_classes"
    private let recordsKey = "saved_records"
    private let sessionsKey = "saved_sessions"

    init() {
        load()
    }

    func save() {
        if let encodedClasses = try? JSONEncoder().encode(classes) {
            UserDefaults.standard.set(encodedClasses, forKey: classesKey)
            UserDefaults.standard.synchronize()
        }
        if let encodedRecords = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encodedRecords, forKey: recordsKey)
            UserDefaults.standard.synchronize()
        }
        if let encodedSessions = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encodedSessions, forKey: sessionsKey)
            UserDefaults.standard.synchronize()
        }
    }

    func load() {
        if let savedClasses = UserDefaults.standard.data(forKey: classesKey),
           let decodedClasses = try? JSONDecoder().decode([ClassRoom].self, from: savedClasses) {
            classes = decodedClasses
        }
        if let savedRecords = UserDefaults.standard.data(forKey: recordsKey),
           let decodedRecords = try? JSONDecoder().decode([AttendanceRecord].self, from: savedRecords) {
            records = decodedRecords
        }
        if let savedSessions = UserDefaults.standard.data(forKey: sessionsKey),
           let decodedSessions = try? JSONDecoder().decode([UUID: AttendanceSession].self, from: savedSessions) {
            sessions = decodedSessions
        }
    }

    func addClass(_ classRoom: ClassRoom) {
        classes.append(classRoom)
        save()
    }

    func updateClass(_ classRoom: ClassRoom) {
        if let index = classes.firstIndex(where: { $0.id == classRoom.id }) {
            classes[index] = classRoom
            save()
        }
    }

    func deleteClass(at offsets: IndexSet) {
        classes.remove(atOffsets: offsets)
        save()
    }

    func addRecord(_ record: AttendanceRecord) {
        DispatchQueue.main.async {
            self.records.append(record)
            self.save()
        }
    }

    // 출석 세션 저장
    func updateSession(classRoomId: UUID, attendedIds: Set<UUID>) {
        sessions[classRoomId] = AttendanceSession(
            classRoomId: classRoomId,
            attendedStudentIds: Array(attendedIds),
            date: Date()
        )
        save()
    }

    // 출석 세션 불러오기 (오늘 날짜 것만)
    func loadSession(classRoomId: UUID) -> Set<UUID> {
        guard let session = sessions[classRoomId] else { return [] }
        let calendar = Calendar.current
        if calendar.isDateInToday(session.date) {
            return Set(session.attendedStudentIds)
        }
        return []
    }

    // 출석 세션 종료
    func clearSession(classRoomId: UUID) {
        sessions.removeValue(forKey: classRoomId)
        save()
    }

    func recordsForClass(_ className: String) -> [AttendanceRecord] {
        records.filter { $0.className == className }
               .sorted { $0.timestamp > $1.timestamp }
    }
}
