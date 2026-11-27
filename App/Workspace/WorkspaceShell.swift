import FeatureChat
import PurlayContract
import PurlayKit
import PurlayModuleAPI
import SwiftUI

/// The signed-in shell borrows the Kit's authority and owns the presentation of destinations this build ships.
@MainActor
enum WorkspaceDestinations {
    static func features(for model: AppModel) -> [any FeatureModule] {
        guard let workspace = model.workspace, let origin = model.webFrontDoor else { return [] }
        let workspaceURL = origin.appending(component: "w").appending(component: workspace.slug)
        let registry = ModuleRegistry([
            ChatFeature(title: Words.chat, browserAction: Words.openChatInBrowser, workspaceURL: workspaceURL)
        ])
        let allowed: Set<ModuleID> = model.chatAvailable ? [.chat] : []
        return registry.enabled(allowed: allowed)
    }
}

struct WorkspaceShell: View {
    @Environment(\.horizontalSizeClass) private var width
    @State private var selected: ModuleID?
    @State private var columns = NavigationSplitViewVisibility.all
    let sessions: WorkspaceSessions

    var body: some View {
        let model = sessions.active
        let features = WorkspaceDestinations.features(for: model)
        Group {
            if features.isEmpty {
                empty(model)
            } else if width == .regular {
                sidebar(features)
            } else {
                tabs(features)
            }
        }
        .onChange(of: features.map(\.id), initial: true) { _, ids in
            if selected.map(ids.contains) != true { selected = ids.first }
        }
    }

    private func tabs(_ features: [any FeatureModule]) -> some View {
        TabView(selection: $selected) {
            ForEach(features, id: \.id) { feature in
                Tab(value: Optional(feature.id)) {
                    NavigationStack {
                        feature.makeRoot()
                            .navigationTitle(Text(feature.title))
                            .toolbar { toolbar }
                    }
                } label: {
                    featureLabel(feature)
                }
            }
        }
    }

    private func sidebar(_ features: [any FeatureModule]) -> some View {
        NavigationSplitView(columnVisibility: $columns) {
            List(selection: $selected) {
                ForEach(features, id: \.id) { feature in
                    NavigationLink(value: feature.id) { featureLabel(feature) }
                        .accessibilityIdentifier("workspace.sidebar.\(feature.id.rawValue)")
                }
            }
            .listStyle(.sidebar)
            .toolbar { toolbar }
        } detail: {
            if let feature = features.first(where: { $0.id == selected }) ?? features.first {
                feature.makeRoot()
                    .navigationTitle(Text(feature.title))
            }
        }
    }

    private func empty(_ model: AppModel) -> some View {
        NavigationStack {
            if model.me?.mustEnrolTwoFactor == true {
                ContentUnavailableView {
                    Label {
                        Text(Words.twoFactorRequired)
                    } icon: {
                        Image(systemName: "lock.shield")
                    }
                } actions: {
                    if let destination = model.twoFactorSetupURL {
                        Link(destination: destination) { Text(Words.setUpTwoFactor) }
                    }
                }
            } else if model.workspace != nil {
                ContentUnavailableView {
                    Label {
                        Text(Words.noWorkspaceModules)
                    } icon: {
                        Image(systemName: "square.grid.2x2")
                    }
                }
                .accessibilityIdentifier("workspace.emptyModules")
                .navigationTitle(Text(Words.workspace))
                .toolbar { toolbar }
            } else {
                ContentUnavailableView {
                    Label {
                        Text(Words.noWorkspaces)
                    } icon: {
                        Image(systemName: "person.2")
                    }
                }
                .accessibilityIdentifier("workspace.emptyMemberships")
                .navigationTitle(Text(Words.workspace))
            }
        }
    }

    private func featureLabel(_ feature: any FeatureModule) -> some View {
        Label {
            Text(feature.title)
        } icon: {
            Image(systemName: feature.systemImage)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if let workspace = sessions.active.workspace {
                WorkspaceSwitcher(sessions: sessions, workspace: workspace)
            }
        }
    }
}

private struct WorkspaceSwitcher: View {
    let sessions: WorkspaceSessions
    let workspace: Workspace

    var body: some View {
        let choices = sessions.choices
        if choices.count > 1 {
            Menu {
                ForEach(choices, id: \.id) { candidate in
                    Button {
                        Task { await sessions.select(candidate.id) }
                    } label: {
                        if candidate.id == workspace.id {
                            Label {
                                Text(verbatim: choiceLabel(candidate, in: choices))
                            } icon: {
                                Image(systemName: "checkmark")
                            }
                        } else {
                            Text(verbatim: choiceLabel(candidate, in: choices))
                        }
                    }
                    .accessibilityAddTraits(candidate.id == workspace.id ? .isSelected : [])
                }
            } label: {
                HStack {
                    Text(verbatim: workspace.name).lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                }
            }
            .accessibilityLabel(Text(Words.switchWorkspace(choiceLabel(workspace, in: choices))))
            .accessibilityIdentifier("workspace.switcher")
            .disabled(sessions.isSelecting)
        } else {
            Text(verbatim: workspace.name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .accessibilityIdentifier("workspace.name")
        }
    }

    private func choiceLabel(_ candidate: Workspace, in choices: [Workspace]) -> String {
        choices.contains { $0.id != candidate.id && $0.name == candidate.name }
            ? "\(candidate.name) (\(candidate.slug))" : candidate.name
    }
}
