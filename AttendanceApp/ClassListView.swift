import SwiftUI

struct ClassListView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingAddClass = false

    var body: some View {
        NavigationStack {
            Group {
                if store.classes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("등록된 수업이 없어요")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("+ 버튼을 눌러 수업을 추가해보세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(store.classes) { classRoom in
                            NavigationLink(destination: ClassDetailView(classRoom: classRoom)) {
                                ClassRowView(classRoom: classRoom)
                            }
                        }
                        .onDelete(perform: store.deleteClass)
                    }
                }
            }
            .navigationTitle("내 수업")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddClass = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClass) {
                AddClassView()
            }
        }
    }
}

struct ClassRowView: View {
    let classRoom: ClassRoom

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(classRoom.name)
                .font(.headline)
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("학생 \(classRoom.students.count)명")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !classRoom.schedule.isEmpty {
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(classRoom.schedule)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
