import SwiftUI

struct ContentView: View {
    @StateObject private var store = DataStore()

    var body: some View {
        TabView {
            ClassListView()
                .tabItem {
                    Label("수업", systemImage: "book.fill")
                }

            AttendanceHistoryView()
                .tabItem {
                    Label("출석 기록", systemImage: "list.bullet.clipboard.fill")
                }
        }
        .environmentObject(store)
        .tint(.indigo)
    }
}

