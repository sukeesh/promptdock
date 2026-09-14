import Foundation

struct Prompt: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var body: String
    var collection: String
    var tags: [String]
    var isFavorite: Bool
    var usageCount: Int
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        collection: String,
        tags: [String] = [],
        isFavorite: Bool = false,
        usageCount: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.collection = collection
        self.tags = tags
        self.isFavorite = isFavorite
        self.usageCount = usageCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsedAt = lastUsedAt
    }

    var variables: [String] {
        let pattern = #"\{\{\s*([A-Za-z0-9_\- ]+)\s*\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(body.startIndex..., in: body)
        let matches = regex.matches(in: body, range: range)
        let names = matches.compactMap { match -> String? in
            guard let nameRange = Range(match.range(at: 1), in: body) else { return nil }
            return String(body[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return Array(Set(names)).sorted()
    }

    var approximateTokenCount: Int {
        TokenEstimator.count(body)
    }

    func rendered(with values: [String: String]) -> String {
        variables.reduce(body) { output, key in
            let value = values[key, default: "{{\(key)}}"]
            return output
                .replacingOccurrences(of: "{{\(key)}}", with: value)
                .replacingOccurrences(of: "{{ \(key) }}", with: value)
        }
    }
}

enum TokenEstimator {
    static func count(_ text: String) -> Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }

        let words = trimmed.split { character in
            character.isWhitespace || character.isPunctuation
        }.count
        let characterEstimate = Int(ceil(Double(trimmed.count) / 4.0))

        return max(1, Int(round((Double(words) * 1.25 + Double(characterEstimate)) / 2.0)))
    }
}

enum SeedData {
    static let prompts: [Prompt] = [
        Prompt(
            title: "Code review: risk-first pass",
            body: """
            Review this change as a senior engineer.

            Focus on {{risk_area}}.
            Return:
            1. Blocking bugs with file references
            2. Missing tests
            3. Clear next action

            Keep it concise and put the highest-risk issue first.
            """,
            collection: "Engineering",
            tags: ["codex", "review", "risk"],
            isFavorite: true,
            usageCount: 26
        ),
        Prompt(
            title: "Explain production log cluster",
            body: """
            Analyze these logs from {{service_name}}.

            Identify:
            1. The likely failure mode
            2. Evidence from the log lines
            3. What to check next
            4. Whether this appears user-facing

            Do not invent facts that are not present in the logs.
            """,
            collection: "Incidents",
            tags: ["sre", "logs", "incident"],
            usageCount: 14
        ),
        Prompt(
            title: "Rewrite client update",
            body: """
            Rewrite this update for {{audience}}.

            Tone: {{tone}}
            Format:
            - Current status
            - Decisions needed
            - Risks
            - Next steps

            Keep it direct and executive-ready.
            """,
            collection: "Consulting",
            tags: ["status", "client", "writing"],
            isFavorite: true,
            usageCount: 19
        ),
        Prompt(
            title: "Convert notes to acceptance criteria",
            body: """
            Convert these notes into Jira-ready acceptance criteria.

            Feature: {{feature_name}}
            Include:
            - User story
            - Acceptance criteria
            - Edge cases
            - Test notes
            """,
            collection: "Product",
            tags: ["jira", "pm", "spec"],
            usageCount: 8
        )
    ]
}
