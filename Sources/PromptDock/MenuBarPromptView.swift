import SwiftUI

struct MenuBarPromptView: View {
    @EnvironmentObject private var store: PromptStore
    @State private var search = ""
    @State private var focusedPromptID: Prompt.ID?
    @State private var variableValues: [String: String] = [:]
    @State private var copiedPromptID: Prompt.ID?

    private var matches: [Prompt] {
        let needle = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return store.prompts
            .filter { prompt in
                guard !needle.isEmpty else { return true }
                return ([prompt.title, prompt.body, prompt.collection] + prompt.tags)
                    .joined(separator: " ")
                    .lowercased()
                    .contains(needle)
            }
            .sorted { lhs, rhs in
                if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }
                return (lhs.lastUsedAt ?? lhs.updatedAt) > (rhs.lastUsedAt ?? rhs.updatedAt)
            }
            .prefix(7)
            .map { $0 }
    }

    private var focusedPrompt: Prompt? {
        if let focusedPromptID, let prompt = store.prompts.first(where: { $0.id == focusedPromptID }) {
            return prompt
        }
        return matches.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DockColor.muted)
                TextField("Find prompt", text: $search)
                    .textFieldStyle(.plain)
                    .foregroundStyle(DockColor.ink)
            }
            .padding(10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(DockColor.line))

            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 6) {
                    ForEach(matches) { prompt in
                        QuickPromptRow(prompt: prompt, isSelected: (focusedPrompt?.id ?? matches.first?.id) == prompt.id)
                            .onTapGesture {
                                focusedPromptID = prompt.id
                                if prompt.variables.isEmpty {
                                    store.copyToClipboard(prompt)
                                    showCopied(prompt.id)
                                }
                            }
                    }
                }
                .frame(width: 300)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    if let prompt = focusedPrompt {
                        Text(prompt.title)
                            .font(.headline)
                            .foregroundStyle(DockColor.ink)
                            .lineLimit(2)

                        if prompt.variables.isEmpty {
                            Text(prompt.body)
                                .font(.caption)
                                .foregroundStyle(DockColor.muted)
                                .lineLimit(8)
                            Text("~\(prompt.approximateTokenCount) tokens")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(DockColor.steel)
                            Button {
                                store.copyToClipboard(prompt)
                                showCopied(prompt.id)
                            } label: {
                                Label(copiedPromptID == prompt.id ? "Copied" : "Copy", systemImage: copiedPromptID == prompt.id ? "checkmark" : "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(DockColor.spruce)
                        } else {
                            Text("~\(prompt.approximateTokenCount) tokens")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(DockColor.steel)
                            ForEach(prompt.variables, id: \.self) { variable in
                                TextField(variable, text: binding(for: variable), prompt: Text(variable))
                                    .textFieldStyle(.roundedBorder)
                                    .foregroundStyle(DockColor.ink)
                            }
                            Button {
                                store.copyToClipboard(prompt, renderedValues: variableValues)
                                showCopied(prompt.id)
                            } label: {
                                Label(copiedPromptID == prompt.id ? "Copied" : "Copy filled prompt", systemImage: copiedPromptID == prompt.id ? "checkmark" : "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(DockColor.spruce)
                        }
                    } else {
                        ContentUnavailableView("No matches", systemImage: "text.magnifyingglass")
                    }
                }
                .frame(width: 240)
            }
        }
        .padding(14)
        .frame(width: 590)
        .background(DockColor.paper)
        .overlay(alignment: .bottom) {
            if copiedPromptID != nil {
                MenuCopyToast()
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            focusedPromptID = matches.first?.id
        }
        .onChange(of: search) { _, _ in
            focusedPromptID = matches.first?.id
        }
    }

    private func showCopied(_ id: Prompt.ID) {
        withAnimation(.snappy(duration: 0.14)) {
            copiedPromptID = id
        }
        Task {
            try? await Task.sleep(for: .milliseconds(1800))
            await MainActor.run {
                withAnimation(.snappy(duration: 0.14)) {
                    if copiedPromptID == id {
                        copiedPromptID = nil
                    }
                }
            }
        }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding {
            variableValues[key, default: ""]
        } set: { value in
            variableValues[key] = value
        }
    }
}

private struct QuickPromptRow: View {
    let prompt: Prompt
    let isSelected: Bool

    private var subtitle: String {
        let tagText = prompt.tags.prefix(2).joined(separator: ", ")
        if prompt.collection.isEmpty {
            return tagText
        }
        if tagText.isEmpty {
            return prompt.collection
        }
        return "\(prompt.collection) · \(tagText)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: prompt.isFavorite ? "star.fill" : "text.quote")
                .foregroundStyle(prompt.isFavorite ? DockColor.copper : DockColor.spruce)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 3) {
                Text(prompt.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DockColor.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(DockColor.muted)
                    .lineLimit(1)
            }
            Spacer()
            Text("~\(prompt.approximateTokenCount)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(DockColor.steel)
            if !prompt.variables.isEmpty {
                Text("\(prompt.variables.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(DockColor.spruce)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(DockColor.mist)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
        }
        .padding(9)
        .background(isSelected ? DockColor.mist : Color.white.opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? DockColor.spruce : DockColor.line)
        )
    }
}

private struct MenuCopyToast: View {
    var body: some View {
        Label("Copied to clipboard", systemImage: "checkmark.circle.fill")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(DockColor.spruce)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 14, y: 6)
    }
}
