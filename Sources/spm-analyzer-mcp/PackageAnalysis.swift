//
//  PackageAnalysis.swift
//  spm-analyzer-mcp
//
//  Created by Walid SASSI on 24/12/2025.
//

import Foundation

struct PackageAnalysis: Codable {

    let packageName: String?

    let dependencies: [PackageDependency]

    let products: [String]

    let targets: [String]
}
