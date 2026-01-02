//
//  PackageParserTests.swift
//  spm-analyzer-mcp
//
//  Created by Walid SASSI on 02/01/2026.
//

import Testing

@testable import spm_analyzer_mcp

@Suite("PackageParserTests")
struct PackageParserTests {

    @Test("Extract package name")
    func extractPackageName() throws {
        let content = """
            let package = Package(
                name: "MyAwesomePackage",
                products: []
            )
            """

        let result = try PackageParser.parse(content: content)
        #expect(result.packageName == "MyAwesomePackage")
    }

    @Test("Extract package name with extra spaces")
    func extractPackageNameWithSpaces() throws {
        let content = """
            let package = Package(
                name:     "MyPackage"    ,
                products: []
            )
            """

        let result = try PackageParser.parse(content: content)
        #expect(result.packageName == "MyPackage")
    }

    @Test("Missing package name returns nil")
        func missingPackageName() throws {
            let content = """
            let package = Package(
                products: []
            )
            """

            let result = try PackageParser.parse(content: content)
            #expect(result.packageName == nil)
        }
}

