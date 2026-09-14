import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var store: PromptStore
    @State private var isImporting = false

    var body: some View {
        HStack(spacing: 0) {
            CollectionRail()
                .frame(width: 228)

            PromptColumn()
                .frame(width: 392)

            Divider()
                .overlay(DockColor.line)

            PromptEditor()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(DockColor.paper)
        .preferredColorScheme(.light)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.plainText, .text, .xml, .data],
            allowsMultipleSelection: true
        ) { result in
            if case let .success(urls) = result {
                store.importPrompts(from: urls)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    isImporting = true
                } label: {
                    Label("Import prompts", systemImage: "square.and.arrow.down")
                }

                Button {
                    store.addPrompt()
                } label: {
                    Label("Add prompt", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}

private struct CollectionRail: View {
    @EnvironmentObject private var store: PromptStore
    @State private var isAddingFolder = false
    @State private var newFolderName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                AppMark()
                VStack(alignment: .leading, spacing: 1) {
                    Text("PromptDock")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(DockColor.ink)
                    Text("Local prompt shelf")
                        .font(.caption)
                        .foregroundStyle(DockColor.muted)
                }
            }
            .padding(.top, 18)

            VStack(alignment: .leading, spacing: 6) {
                Text("Library")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DockColor.muted)
                    .padding(.horizontal, 10)

                ForEach(store.collections, id: \.self) { collection in
                    Button {
                        store.selectedCollection = collection
                        store.selectedPromptID = store.filteredPrompts.first?.id
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: icon(for: collection))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(collection == store.selectedCollection ? Color.white : DockColor.spruce)
                                .frame(width: 22)
                            Text(collection)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(collection == store.selectedCollection ? Color.white : DockColor.ink)
                            Spacer()
                            Text("\(count(for: collection))")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(collection == store.selectedCollection ? Color.white.opacity(0.85) : DockColor.muted)
                        }
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 38)
                        .background(collection == store.selectedCollection ? DockColor.spruce : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    newFolderName = ""
                    isAddingFolder = true
                } label: {
                    Label("New folder", systemImage: "folder.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DockColor.spruce)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 36)
                        .padding(.horizontal, 10)
                        .background(DockColor.mist)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Label("Fast by design", systemImage: "bolt.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DockColor.spruce)
                Text("Local JSON storage, native SwiftUI controls, no web runtime.")
                    .font(.caption)
                    .foregroundStyle(DockColor.muted)
                    .lineSpacing(2)
            }
            .padding(12)
            .background(DockColor.mist)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .background(DockColor.panel)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(DockColor.line)
                .frame(width: 1)
        }
        .sheet(isPresented: $isAddingFolder) {
            VStack(alignment: .leading, spacing: 16) {
                Text("New folder")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(DockColor.ink)
                TextField("Folder name", text: $newFolderName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addFolder)
                HStack {
                    Spacer()
                    Button("Cancel") {
                        isAddingFolder = false
                    }
                    Button("Create") {
                        addFolder()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DockColor.spruce)
                    .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            .frame(width: 360)
            .background(DockColor.paper)
        }
    }

    private func count(for collection: String) -> Int {
        switch collection {
        case "All": store.prompts.count
        case "Favorites": store.prompts.filter(\.isFavorite).count
        default: store.prompts.filter { $0.collection == collection }.count
        }
    }

    private func icon(for collection: String) -> String {
        switch collection {
        case "All": "tray.full"
        case "Favorites": "star.fill"
        default: "folder"
        }
    }

    private func addFolder() {
        store.addCollection(named: newFolderName)
        isAddingFolder = false
    }
}

private struct PromptColumn: View {
    @EnvironmentObject private var store: PromptStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Text(store.selectedCollection)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(DockColor.ink)
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(DockColor.muted)
                    TextField("Find prompts, tags, or variables", text: $store.query)
                        .textFieldStyle(.plain)
                        .foregroundStyle(DockColor.ink)
                }
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(DockColor.line))
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)

            if store.filteredPrompts.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    ContentUnavailableView("No prompts found", systemImage: "text.magnifyingglass")
                        .foregroundStyle(DockColor.ink)
                    AddPromptCard {
                        store.addPrompt()
                    }
                    .frame(maxWidth: 320)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.filteredPrompts) { prompt in
                            PromptCard(prompt: prompt, isSelected: store.selectedPromptID == prompt.id)
                                .onTapGesture {
                                    store.selectedPromptID = prompt.id
                                }
                        }
                        AddPromptCard {
                            store.addPrompt()
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 18)
                }
            }
        }
        .background(DockColor.paper)
    }
}

private struct AddPromptCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Add prompt")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
            }
            .foregroundStyle(DockColor.spruce)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(DockColor.mist)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(DockColor.line, style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }
}

private struct PromptCard: View {
    let prompt: Prompt
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(prompt.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DockColor.ink)
                    .lineLimit(1)
                Spacer()
                if prompt.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(DockColor.copper)
                }
            }

            Text(prompt.body.replacingOccurrences(of: "\n", with: " "))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DockColor.muted)
                .lineLimit(3)
                .lineSpacing(2)

            HStack(spacing: 6) {
                Text(prompt.collection).tagChip()
                ForEach(prompt.tags.prefix(3), id: \.self) { tag in
                    Text(tag).tagChip()
                }
                Spacer()
                Text("~\(prompt.approximateTokenCount) tok")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DockColor.steel)
                Text("\(prompt.usageCount)x")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DockColor.muted)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? DockColor.spruce : DockColor.line, lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: isSelected ? DockColor.spruce.opacity(0.12) : Color.black.opacity(0.035), radius: isSelected ? 12 : 5, y: 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct PromptEditor: View {
    @EnvironmentObject private var store: PromptStore
    @State private var draft: Prompt?
    @State private var variableValues: [String: String] = [:]
    @State private var copiedSignal = false

    var body: some View {
        Group {
            if let prompt = store.selectedPrompt {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        topActions(prompt)
                        editableFields
                        VariableComposer(prompt: draft ?? prompt, variableValues: $variableValues, copiedSignal: copiedSignal) {
                            store.copyToClipboard(draft ?? prompt, renderedValues: variableValues)
                            showCopied()
                        }
                    }
                    .padding(28)
                }
                .id(prompt.id)
                .onAppear { resetDraft(prompt) }
                .onChange(of: prompt.id) { _, _ in resetDraft(prompt) }
            } else {
                ContentUnavailableView("Select a prompt", systemImage: "text.badge.plus")
                    .foregroundStyle(DockColor.ink)
            }
        }
        .background(DockColor.paper)
        .overlay(alignment: .bottom) {
            if copiedSignal {
                CopyToast()
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func topActions(_ prompt: Prompt) -> some View {
        HStack(spacing: 10) {
            Button {
                store.copyToClipboard(prompt, renderedValues: variableValues)
                showCopied()
            } label: {
                Label(copiedSignal ? "Copied" : "Copy prompt", systemImage: copiedSignal ? "checkmark" : "doc.on.doc")
                    .frame(minWidth: 118)
            }
            .buttonStyle(.borderedProminent)
            .tint(DockColor.spruce)
            .keyboardShortcut("c", modifiers: [.command, .shift])

            Button {
                store.toggleFavorite(prompt)
            } label: {
                Label(prompt.isFavorite ? "Favorited" : "Favorite", systemImage: prompt.isFavorite ? "star.fill" : "star")
            }
            .foregroundStyle(DockColor.ink)

            Text("~\(prompt.approximateTokenCount) tokens")
                .font(.caption.weight(.bold))
                .foregroundStyle(DockColor.steel)
                .padding(.horizontal, 8)
                .frame(height: 28)
                .background(DockColor.mist)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Spacer()

            Button(role: .destructive) {
                store.delete(prompt)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var editableFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let draftBinding = Binding($draft) {
                TextField("Prompt title", text: draftBinding.title)
                    .font(.system(size: 26, weight: .bold))
                    .textFieldStyle(.plain)
                    .foregroundStyle(DockColor.ink)

                HStack(spacing: 12) {
                    FieldBox(title: "Collection") {
                        TextField("Collection", text: draftBinding.collection)
                            .textFieldStyle(.plain)
                            .foregroundStyle(DockColor.ink)
                    }
                    FieldBox(title: "Tags") {
                        TextField("status, client, writing", text: tagsBinding(draftBinding))
                            .textFieldStyle(.plain)
                            .foregroundStyle(DockColor.ink)
                    }
                }

                TextEditor(text: draftBinding.body)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(DockColor.ink)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 260)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(DockColor.line))
                    .onChange(of: draft) { _, newValue in
                        guard let newValue else { return }
                        store.update(newValue)
                    }
            }
        }
    }

    private func resetDraft(_ prompt: Prompt) {
        draft = prompt
        variableValues = Dictionary(uniqueKeysWithValues: prompt.variables.map { ($0, variableValues[$0, default: ""]) })
    }

    private func showCopied() {
        withAnimation(.snappy(duration: 0.14)) {
            copiedSignal = true
        }
        Task {
            try? await Task.sleep(for: .milliseconds(1800))
            await MainActor.run {
                withAnimation(.snappy(duration: 0.14)) {
                    copiedSignal = false
                }
            }
        }
    }

    private func tagsBinding(_ prompt: Binding<Prompt>) -> Binding<String> {
        Binding {
            prompt.wrappedValue.tags.joined(separator: ", ")
        } set: { value in
            prompt.wrappedValue.tags = value
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
    }
}

private struct VariableComposer: View {
    let prompt: Prompt
    @Binding var variableValues: [String: String]
    let copiedSignal: Bool
    let copyAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Variable composer", systemImage: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DockColor.ink)
                Spacer()
                Text(prompt.variables.isEmpty ? "No fields" : "\(prompt.variables.count) fields")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DockColor.muted)
            }

            if prompt.variables.isEmpty {
                Text("Add variables like {{audience}} or {{risk_area}} to make prompts fillable.")
                    .font(.callout)
                    .foregroundStyle(DockColor.muted)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                    ForEach(prompt.variables, id: \.self) { variable in
                        FieldBox(title: variable) {
                            TextField(variable, text: binding(for: variable))
                                .textFieldStyle(.plain)
                                .foregroundStyle(DockColor.ink)
                        }
                    }
                }

                Text(prompt.rendered(with: variableValues))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(DockColor.ink)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(DockColor.mist)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button(action: copyAction) {
                    Label(copiedSignal ? "Copied" : "Copy filled prompt", systemImage: copiedSignal ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(DockColor.spruce)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(DockColor.line))
    }

    private func binding(for key: String) -> Binding<String> {
        Binding {
            variableValues[key, default: ""]
        } set: { value in
            variableValues[key] = value
        }
    }
}

private struct FieldBox<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(DockColor.muted)
            content
                .padding(.horizontal, 10)
                .frame(height: 36)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(DockColor.line))
        }
    }
}

private struct CopyToast: View {
    var body: some View {
        Label("Copied to clipboard", systemImage: "checkmark.circle.fill")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(DockColor.spruce)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 18, y: 8)
    }
}

private struct AppMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(DockColor.spruce)
            VStack(spacing: 4) {
                Capsule().fill(DockColor.warm).frame(width: 17, height: 2)
                Capsule().fill(DockColor.copper).frame(width: 22, height: 2)
            }
        }
        .frame(width: 34, height: 34)
    }
}

private extension Text {
    func tagChip() -> some View {
        self
            .font(.caption.weight(.bold))
            .foregroundStyle(DockColor.spruce)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(DockColor.mist)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
