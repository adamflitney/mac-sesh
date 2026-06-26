import SwiftUI
import MacSeshCore

enum SearchMode {
    case switchSession
    case replaceSession
}

// MARK: - View Model

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var allProjects: [Project] = []
    @Published var activeSessions: Set<String> = []
    @Published var selectedIndex: Int = 0
    @Published var errorMessage: String?
    @Published var isLoading = true

    let mode: SearchMode
    let onDismiss: () -> Void

    init(mode: SearchMode, onDismiss: @escaping () -> Void) {
        self.mode = mode
        self.onDismiss = onDismiss
    }

    var filtered: [Project] {
        guard !query.isEmpty else { return allProjects }
        return allProjects.compactMap { project -> Project? in
            // Score against the project name; also try the last path component
            let nameScore = fuzzyScore(query, in: project.name)
            let lastComponent = project.path.components(separatedBy: "/").last ?? ""
            let pathScore = lastComponent != project.name ? fuzzyScore(query, in: lastComponent) : nil
            guard let fuzzy = [nameScore, pathScore].compactMap({ $0 }).max() else { return nil }
            var p = project
            // Combine fuzzy score with frecency; frecency is preserved from allProjects ordering
            p.score = fuzzy + project.score
            return p
        }.sorted { $0.score > $1.score }
    }

    var selectedProject: Project? {
        let list = filtered
        guard !list.isEmpty, selectedIndex < list.count else { return nil }
        return list[selectedIndex]
    }

    func clampSelection() {
        let count = filtered.count
        guard count > 0 else { selectedIndex = 0; return }
        selectedIndex = max(0, min(count - 1, selectedIndex))
    }

    func moveSelection(by delta: Int) {
        let count = filtered.count
        guard count > 0 else { return }
        selectedIndex = max(0, min(count - 1, selectedIndex + delta))
    }

    func loadData() {
        isLoading = true
        errorMessage = nil
        let dirs = Settings.projectDirectories
        let all = findGitProjects(in: dirs)
        let visits = loadVisits()
        allProjects = scored(all, visits: visits)
        activeSessions = Set(((try? listClients()) ?? []).map(\.session))
        isLoading = false
        selectedIndex = 0
    }

    func selectProject(_ project: Project) {
        let sessionName = sanitizeSessionName(project.name)
        Task { @MainActor in
            do {
                recordVisit(to: project.path)
                switch mode {
                case .switchSession:
                    let found = try Ghostty.focusTab(session: sessionName)
                    if !found {
                        let existing = (try? listSessions()) ?? []
                        if !existing.contains(sessionName) {
                            try createSession(name: sessionName, path: project.path)
                        }
                        try Ghostty.openTab(session: sessionName)
                    }

                case .replaceSession:
                    let clients = try listClients()
                    guard let client = mostRecentClient(from: clients) else {
                        errorMessage = "No active tmux client. Open a tmux session in Ghostty first."
                        return
                    }
                    let existing = (try? listSessions()) ?? []
                    if !existing.contains(sessionName) {
                        try createSession(name: sessionName, path: project.path)
                    }
                    try switchClient(session: sessionName, tty: client.tty)
                    try Ghostty.focusApp()
                }
                onDismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - View

struct SearchView: View {
    @StateObject private var model: SearchViewModel
    @FocusState private var searchFocused: Bool
    @State private var keyMonitor: Any?

    init(mode: SearchMode, onDismiss: @escaping () -> Void) {
        _model = StateObject(wrappedValue: SearchViewModel(mode: mode, onDismiss: onDismiss))
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            resultArea
        }
        .frame(width: 620, height: 420)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: model.query) {
            model.selectedIndex = 0
        }
        .onAppear {
            model.loadData()
            installKeyMonitor()
            // Delay is required: @FocusState set before the NSPanel becomes key is silently ignored
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                searchFocused = true
            }
        }
        .onDisappear {
            removeKeyMonitor()
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(
                model.mode == .switchSession ? "Switch to project..." : "Replace with project...",
                text: $model.query
            )
            .textFieldStyle(.plain)
            .focused($searchFocused)
            .font(.title3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var resultArea: some View {
        if model.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = model.errorMessage {
            Text(error)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.filtered.isEmpty {
            Text(model.query.isEmpty
                 ? "No projects found in configured directories."
                 : "No matches for \"\(model.query)\"")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            projectList
        }
    }

    private var projectList: some View {
        let list = model.filtered
        return ScrollViewReader { proxy in
            ScrollView {
                // VStack (not Lazy) ensures rows are fully replaced when the
                // filtered list changes — LazyVStack can serve stale cached rows.
                VStack(spacing: 0) {
                    ForEach(Array(list.enumerated()), id: \.element.id) { index, project in
                        ProjectRow(
                            project: project,
                            hasActiveSession: model.activeSessions.contains(sanitizeSessionName(project.name)),
                            isSelected: index == model.selectedIndex
                        )
                        .id(index)
                        .contentShape(Rectangle())
                        .onTapGesture { model.selectProject(project) }
                    }
                }
            }
            // .id forces the ScrollView to rebuild from scratch when the query changes,
            // preventing stale scroll position or row identity issues.
            .id(model.query)
            .onChange(of: model.selectedIndex) { _, idx in
                withAnimation(.easeInOut(duration: 0.1)) {
                    proxy.scrollTo(idx, anchor: .center)
                }
            }
        }
    }

    // MARK: - Keyboard navigation

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak model] event in
            guard let model else { return event }
            switch Int(event.keyCode) {
            case 125: // down arrow
                model.moveSelection(by: 1)
                return nil
            case 126: // up arrow
                model.moveSelection(by: -1)
                return nil
            case 36, 76: // return / numpad enter
                if let p = model.selectedProject { model.selectProject(p) }
                return nil
            case 53: // escape
                model.onDismiss()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }
}

// MARK: - Row

struct ProjectRow: View {
    let project: Project
    let hasActiveSession: Bool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.body.weight(.medium))
                Text(project.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if hasActiveSession {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 7, height: 7)
                    Text("active")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
    }
}
