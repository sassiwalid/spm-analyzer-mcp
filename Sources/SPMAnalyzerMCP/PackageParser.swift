//
//  PackageParser.swift
//  spm-analyzer-mcp
//
//  Created by Walid SASSI on 24/12/2025.
//

import Foundation

struct PackageParser {

    static func parse(content: String) throws -> PackageAnalysis {

        var dependencies: [PackageDependency] = []

        var products: [String] = []

        var targets: [String] = []

        var packageName: String?

        if let nameMatch = content.range(
            of: "name: ([^\n]+)",
            options: .regularExpression
        ) {

            let nameString = String(content[nameMatch])

            if let extractedName = extractQuotedString(from: nameString) {

                packageName = extractedName
            }
        }

        let dependenciesPattern = #"\.package\s*\(\s*url:\s*"([^"]+)"[^)]*\)"#

        let dependenciesMatching = extractMatches(
            in: content,
            pattern: dependenciesPattern
        )

        for depString in dependenciesMatching {
            guard let url = extractQuotedString(from: depString) else { continue }
            let name = extractRepoName(from: url)
            let requirement = extractRequirement(from: depString)

            dependencies.append(PackageDependency(
                name: name,
                url: url,
                requirement: requirement
            ))
        }

        let productPattern = #"\.(library|executable)\s*\(\s*name:\s*"([^"]+)""#
        let productMatches = extractMatches(in: content, pattern: productPattern)

        for productString in productMatches {
            if let name = extractQuotedString(from: productString) {
                products.append(name)
            }
        }

        let targetPattern = #"\.(target|testTarget|executableTarget)\s*\(\s*name:\s*"([^"]+)""#
        let targetMatches = extractMatches(in: content, pattern: targetPattern)

        for targetString in targetMatches {
            if let name = extractQuotedString(from: targetString) {
                targets.append(name)
            }
        }

        return PackageAnalysis(
            packageName: packageName,
            dependencies: dependencies,
            products: products,
            targets: targets
        )

    }

    private static func extractQuotedString(from text: String) -> String? {
        guard let range = text.range(of: #""([^"]+)""#, options: .regularExpression) else {
            return nil
        }

        let matched = String(text[range])

        return matched.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

    }

    private static func extractMatches(in content: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let nsString = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))

        return matches.compactMap { match in
            guard match.range.location != NSNotFound else { return nil }
            return nsString.substring(with: match.range)
        }
    }

    private static func extractRepoName(from url: String) -> String {
        let components = url.components(separatedBy: "/")
        guard let last = components.last else { return "Unknown" }
        return last.replacingOccurrences(of: ".git", with: "")
    }

    private static func extractRequirement(from depString: String) -> String {
        if depString.contains(".upToNextMajor") {
            if let version = extractVersion(from: depString, after: ".upToNextMajor") {
                return "^\(version)"
            }
            return "upToNextMajor"
        } else if depString.contains(".upToNextMinor") {
            if let version = extractVersion(from: depString, after: ".upToNextMinor") {
                return "~\(version)"
            }
            return "upToNextMinor"
        } else if depString.contains(".exact") {
            if let version = extractVersion(from: depString, after: ".exact") {
                return "==\(version)"
            }
            return "exact"
        } else if depString.contains("from:") {
            if let version = extractVersion(from: depString, after: "from:") {
                return ">=\(version)"
            }
            return "from"
        } else if depString.contains("branch:") {
            if let branch = extractVersion(from: depString, after: "branch:") {
                return "branch:\(branch)"
            }
            return "branch"
        }
        return "unspecified"
    }

    private static func extractVersion(from text: String, after keyword: String) -> String? {
        guard let keywordRange = text.range(of: keyword) else { return nil }
        let afterKeyword = String(text[keywordRange.upperBound...])
        return extractQuotedString(from: afterKeyword)
    }

}
