import AppKit
import Foundation

@MainActor
final class PromptStore: ObservableObject {
    @Published private(set) var prompts: [Prompt] = []
    @Published private(set) var userCollections: [String] = []
    @Published var selectedPromptID: Prompt.ID?
    @Published var selectedCollection = "All"
    @Published var query = ""

    private let storeURL: URL
    private let collectionsURL: URL
    private var saveTask: Task<Void, Never>?
    private var saveCollectionsTask: Task<Void, Never>?

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("PromptDock", isDirectory: true)
        self.storeURL = directory.appendingPathComponent("prompts.json")
        self.collectionsURL = directory.appendingPathComponent("folders.json")
        load(from: directory)
    }

    var collections: [String] {
        ["All", "Favorites"] + userCollections
    }

    var filteredPrompts: [Prompt] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return prompts
            .filter { prompt in
                switch selectedCollection {
                case "Favorites": prompt.isFavorite
                case "All": true
                default: prompt.collection == selectedCollection
                }
            }
            .filter { prompt in
                guard !trimmed.isEmpty else { return true }
                let haystack = ([prompt.title, prompt.body, prompt.collection] + prompt.tags)
                    .joined(separator: " ")
                    .lowercased()
                return haystack.contains(trimmed)
            }
            .sorted { lhs, rhs in
                if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }
                return (lhs.lastUsedAt ?? lhs.updatedAt) > (rhs.lastUsedAt ?? rhs.updatedAt)
            }
    }

    var selectedPrompt: Prompt? {
        guard let selectedPromptID else { return filteredPrompts.first }
        return prompts.first { $0.id == selectedPromptID } ?? filteredPrompts.first
    }

    func addPrompt() {
        let collection = userCollections.contains(selectedCollection) ? selectedCollection : ""
        let prompt = Prompt(
            title: "Untitled prompt",
            body: "Write your reusable prompt here. Add variables like {{topic}} when you need fill-in fields.",
            collection: collection,
            tags: []
        )
        prompts.insert(prompt, at: 0)
        selectedPromptID = prompt.id
        scheduleSave()
    }

    func addCollection(named rawName: String) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !["All", "Favorites"].contains(name), !userCollections.contains(name) else { return }
        userCollections.append(name)
        userCollections.sort()
        selectedCollection = name
        selectedPromptID = filteredPrompts.first?.id
        scheduleCollectionsSave()
    }

    func importPrompts(from urls: [URL]) {
        let imported = urls.compactMap(importPrompt)
        guard !imported.isEmpty else { return }
        prompts.insert(contentsOf: imported, at: 0)
        selectedPromptID = imported.first?.id
        scheduleSave()
    }

    func delete(_ prompt: Prompt) {
        prompts.removeAll { $0.id == prompt.id }
        selectedPromptID = filteredPrompts.first?.id
        scheduleSave()
    }

    func update(_ prompt: Prompt) {
        guard let index = prompts.firstIndex(where: { $0.id == prompt.id }) else { return }
        var updated = prompt
        updated.updatedAt = .now
        prompts[index] = updated
        scheduleSave()
    }

    func toggleFavorite(_ prompt: Prompt) {
        var copy = prompt
        copy.isFavorite.toggle()
        update(copy)
    }

    func copyToClipboard(_ prompt: Prompt, renderedValues: [String: String] = [:]) {
        let rendered = prompt.rendered(with: renderedValues)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(rendered, forType: .string)
        markUsed(prompt)
    }

    private func markUsed(_ prompt: Prompt) {
        guard let index = prompts.firstIndex(where: { $0.id == prompt.id }) else { return }
        prompts[index].usageCount += 1
        prompts[index].lastUsedAt = .now
        prompts[index].updatedAt = .now
        scheduleSave()
    }

    private func importPrompt(from url: URL) -> Prompt? {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let fileTitle = url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
        let title = fileTitle.isEmpty ? "Imported prompt" : fileTitle

        return Prompt(
            title: title,
            body: extractSnippetBody(from: trimmed),
            collection: userCollections.contains(selectedCollection) ? selectedCollection : "",
            tags: ["imported"]
        )
    }

    private func extractSnippetBody(from text: String) -> String {
        guard text.contains("<snippet>"), let start = text.range(of: "<content><![CDATA["), let end = text.range(of: "]]></content>") else {
            return text
        }
        return String(text[start.upperBound..<end.lowerBound])
    }

    private func load(from directory: URL) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try Data(contentsOf: storeURL)
            prompts = try JSONDecoder.promptDock.decode([Prompt].self, from: data)
        } catch {
            prompts = SeedData.prompts
            scheduleSave()
        }

        do {
            let data = try Data(contentsOf: collectionsURL)
            userCollections = try JSONDecoder.promptDock.decode([String].self, from: data)
        } catch {
            userCollections = []
            scheduleCollectionsSave()
        }

        selectedPromptID = prompts.first?.id
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let prompts = prompts
        let storeURL = storeURL
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            do {
                let data = try JSONEncoder.promptDock.encode(prompts)
                try data.write(to: storeURL, options: [.atomic])
            } catch {
                assertionFailure("Could not save prompts: \(error)")
            }
        }
    }

    private func scheduleCollectionsSave() {
        saveCollectionsTask?.cancel()
        let userCollections = userCollections
        let collectionsURL = collectionsURL
        saveCollectionsTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            do {
                let data = try JSONEncoder.promptDock.encode(userCollections)
                try data.write(to: collectionsURL, options: [.atomic])
            } catch {
                assertionFailure("Could not save folders: \(error)")
            }
        }
    }
}

private extension JSONDecoder {
    static var promptDock: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private extension JSONEncoder {
    static var promptDock: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
