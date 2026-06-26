import SwiftUI
import MacSeshCore

enum SearchMode {
    case switchSession
    case replaceSession
}

struct SearchView: View {
    let mode: SearchMode
    let onDismiss: () -> Void

    @State private var query = ""
    @State private var projects: [Project] = []
    @State private var activeSessions: Set<String> = []
    @State private var errorMessage: String?
    @State private var isLoading = true
    @FocusState private var searchFocused: Bool

    private var filtered: [Project] {
        guard !query.isEmpty else { return projects }
        let q = query.lowercased()
        return projects.filter {
            $0.name.lowercased().contains(q) || $0.path.lowercased().contains(q)
        }
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
        .shadow(radius: 20)
        .onAppear {
            searchFocused = true
            loadData()
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(mode == .switchSession ? "Switch to project..." : "Replace with project...", text: $query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .font(.title3)
                .onKeyPress(.escape) {
                    onDismiss()
                    return .handled
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var resultArea: some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = errorMessage {
            Text(error)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filtered.isEmpty {
            Text(query.isEmpty ? "No projects found in configured directories." : "No matches for \"\(query)\"")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(filtered) { project in
                ProjectRow(
                    project: project,
                    hasActiveSession: activeSessions.contains(sanitizeSessionName(project.name))
                )
                .contentShape(Rectangle())
                .onTapGesture { selectProject(project) }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Data loading

    private func loadData() {
        // Shell operations are synchronous but fast (<100ms); running on main
        // is acceptable here. A future improvement could detach to a background task.
        Task { @MainActor in
            defer { isLoading = false }
            do {
                let dirs = Settings.projectDirectories
                let all = findGitProjects(in: dirs)
                let visits = loadVisits()
                projects = scored(all, visits: visits)
                let clients = (try? listClients()) ?? []
                activeSessions = Set(clients.map(\.session))
            }
        }
    }

    // MARK: - Selection

    private func selectProject(_ project: Project) {
        Task { @MainActor in
            do {
                recordVisit(to: project.path)
                let sessionName = sanitizeSessionName(project.name)

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
                        errorMessage = "No active tmux client found. Open a tmux session in Ghostty first."
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

// MARK: - Row

struct ProjectRow: View {
    let project: Project
    let hasActiveSession: Bool

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
        .padding(.vertical, 4)
    }
}
