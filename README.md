# PromptDock

PromptDock is a fast native macOS prompt library and menu bar utility for people who repeatedly use high-value prompts in Codex, Claude Code, ChatGPT, Slack, Jira, terminals, and consulting workflows.

It is built for engineers, IT operators, consultants, and anyone who wants reusable AI instructions one keystroke away without running a heavy web wrapper.

## Why

Most prompt reuse starts as a notes file, a Sublime Text scratchpad, or a pile of copied messages. That works until prompts need folders, variables, search, token estimates, and quick access while another app is already in focus.

PromptDock keeps that workflow local, native, and fast.

## Current Build

- Native SwiftUI/AppKit macOS app, no Electron or web runtime.
- Menu bar quick search for copying reusable prompts.
- Main library with folders, favorites, search, add, edit, delete, and usage counts.
- Fillable variables using `{{variable_name}}` placeholders.
- Approximate token counts for each prompt.
- Import from `.txt`, `.md`, plain text, XML, and Sublime snippet-style files.
- Local JSON persistence in Application Support with debounced saves.

## Performance Direction

- Keep the app local-first and memory-light.
- Avoid long-lived background work unless it has a clear user-facing benefit.
- Use plain Codable files until the library size or sync model proves that SQLite/Core Data is needed.
- Keep menu bar search in memory and cap menu results for instant rendering.
- Prefer native controls and system materials over custom rendering-heavy effects.

## Run

```sh
swift run PromptDock
```

## Build

```sh
swift build
```

## Product Mock

An early product/design mock lives at [`docs/product-mock.html`](docs/product-mock.html).

## Storage

PromptDock stores local data in:

```text
~/Library/Application Support/PromptDock/
```

## Product Notes

The app should feel like Spotlight for prompts: open, search, fill variables, copy, and return to work. The full app is for library management; the menu bar is for speed.

## License

MIT
