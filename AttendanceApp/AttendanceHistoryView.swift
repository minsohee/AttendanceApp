import SwiftUI

struct AttendanceHistoryView: View {
    @EnvironmentObject var store: DataStore

    var groupedRecords: [(String, [AttendanceRecord])] {
        let sorted = store.records.sorted { $0.timestamp > $1.timestamp }
        var groups: [(String, [AttendanceRecord])] = []
        var dict: [String: [AttendanceRecord]] = [:]

        for record in sorted {
            let dateStr = dayString(record.timestamp)
            dict[dateStr, default: []].append(record)
        }

        // 날짜 순 정렬
        let sortedKeys = dict.keys.sorted(by: >)
        for key in sortedKeys {
            groups.append((key, dict[key]!))
        }
        return groups
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("출석 기록이 없어요")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("출석 체크를 하면 여기에 기록이 남아요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedRecords, id: \.0) { (date, records) in
                            Section(date) {
                                ForEach(records) { record in
                                    RecordRowView(record: record)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("출석 기록")
        }
    }

    func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일 (E)"
        return formatter.string(from: date)
    }
}

struct RecordRowView: View {
    let record: AttendanceRecord

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: record.timestamp)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.studentName)
                    .font(.headline)
                Text(record.className)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if record.messageSent {
                    Label("문자발송", systemImage: "message.fill")
                        .font(.caption2)
                        .foregroundColor(.indigo)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
