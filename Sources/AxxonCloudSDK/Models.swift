//
//  File.swift
//  AxxonCloudSDK
//
//  Created by Логунов Даниил on 9/16/25.
//
import Foundation

public struct Token: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    
    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

public struct TokenResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    
    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

public struct Dashboard: Codable, Identifiable, Sendable {
    public let id: String
    public var title: String // Изменено на var
    public let description: String?
    public let revision: String?
    public let tags: String?
    public let owner: Bool
    public let version: Int
    public let lang: String?
    public let serviceMode: Bool
    public let commonFilter: Bool
    public let commonFilterValue: CommonFilterValue?
    public let layout: Layout?
    public var widgets: [Widget] // Изменено на var
}

public struct CommonFilterValue: Codable, Sendable {
    public let fields: [String]
    public let period: Period?
    public let clauses: [String]
    public let periods: [String]
    public let quickFilters: [String: String]
}

public struct Period: Codable, Sendable {
    public let type: String
    public let from: String?
    public let to: String?
}

public struct Layout: Codable, Sendable {
    public let lg: [LayoutItem]
    public let md: [LayoutItem]
    public let sm: [LayoutItem]
    public let xs: [LayoutItem]
    public let xxs: [LayoutItem]
    public let panels: [String]
}

public struct LayoutItem: Codable, Sendable {
    public let h: Int
    public let w: Int
    public let x: Int
    public let y: Int
    public let i: String
    public let minH: Int
    public let minW: Int
    public let moved: Bool?
    public let isStatic: Bool? // Переименовано из static
}

public struct Widget: Codable, Identifiable, Sendable {
    public let id: String
    public var title: String // Изменено на var
    public let description: String?
    public let widget: String
    public let isQL: Bool
    public let query: WidgetQuery?
    public let style: [String: String]
    public let visualization: Visualization?
    public let dependOn: [Dependency]?
    public let ignoreCommonFilter: Bool
}

public struct WidgetQuery: Codable, Sendable {
    public let view: String
    public let limit: Int
    public let table: String
    public let fields: [QueryField]
    public let filter: WidgetFilter?
    public let groupBy: [String]
    public let orderBy: [OrderBy]
}

public struct QueryField: Codable, Sendable {
    public let field: String
}

public struct WidgetFilter: Codable, Sendable {
    public let period: Period?
    public let clauses: [Clause]?
}

public struct Clause: Codable, Sendable {
    public let op: String
    public let field: String
    public let value: String
}

public struct OrderBy: Codable, Sendable {
    public let field: String
    public let desc: Bool?
}

public struct Visualization: Codable, Sendable {
    public let hidden: [String]
    public let noDataLink: String
    public let noDataValue: String
    public let noDataFormat: String
    public let rowsPerPage: String
    public let virtualFields: [String]
}

public struct Dependency: Codable, Sendable {
    public let id: String
    public let field: String
}
