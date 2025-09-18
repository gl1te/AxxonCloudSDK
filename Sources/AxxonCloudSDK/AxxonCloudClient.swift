//
//  AxxonCloudClient.swift
//  AxxonCloudSDK
//
//  Created by Логунов Даниил on 9/16/25.
//
import Foundation

public enum AuthError: Error, Sendable {
    case invalidCredentials
    case serverError
    case tokenExpired
}

public typealias EndpointProvider = (EndpointType) -> (path: String, method: String, headers: [String: String], body: Data?)

public enum EndpointType {
    case login(email: String, password: String)
    case dashboards
    case refreshToken(refreshToken: String)
}

public struct InternalEndpoint {
    let path: String
    let method: String
    let headers: [String: String]
    let body: Data?

    init(path: String, method: String, headers: [String: String], body: Data?) {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = body
    }
}

public final class AxxonCloudClient: @unchecked Sendable {
    private let api: URL
    private let accessToken: String?
    private let endpointProvider: EndpointProvider

    public init(api: URL, accessToken: String? = nil, endpointProvider: @escaping EndpointProvider) {
        self.api = api
        self.accessToken = accessToken
        self.endpointProvider = endpointProvider
    }

    public func login(email: String, password: String) async throws -> Token {
        let (path, method, headers, body) = endpointProvider(.login(email: email, password: password))
        let endpoint = InternalEndpoint(path: path, method: method, headers: headers, body: body)
        let response = try await NetworkManager.shared.performRequest(endpoint, baseURL: api, accessToken: nil) as TokenResponse
        try KeychainManager.shared.saveToken(response.accessToken, forKey: "accessToken")
        try KeychainManager.shared.saveToken(response.refreshToken, forKey: "refreshToken")
        return Token(accessToken: response.accessToken, refreshToken: response.refreshToken)
    }

    public func refreshToken(_ refreshToken: String) async throws -> Token {
        guard !refreshToken.isEmpty else {
            throw AuthError.tokenExpired
        }
        let (path, method, headers, body) = endpointProvider(.refreshToken(refreshToken: refreshToken))
        let endpoint = InternalEndpoint(path: path, method: method, headers: headers, body: body)
        let response = try await NetworkManager.shared.performRequest(endpoint, baseURL: api, accessToken: nil) as TokenResponse

        try KeychainManager.shared.saveToken(response.accessToken, forKey: "accessToken")
        try KeychainManager.shared.saveToken(response.refreshToken, forKey: "refreshToken")
        return Token(accessToken: response.accessToken, refreshToken: response.refreshToken)
    }

    public func fetchDashboards() async throws -> [Dashboard] {
        guard let token = accessToken ?? (try? KeychainManager.shared.getToken(forKey: "accessToken")) else {
            throw AuthError.tokenExpired
        }

        do {
            let (path, method, headers, body) = endpointProvider(.dashboards)
            let endpoint = InternalEndpoint(path: path, method: method, headers: headers, body: body)
            return try await NetworkManager.shared.performRequest(endpoint, baseURL: api, accessToken: token)
        } catch NetworkError.serverError(401) {
            guard let refreshToken = try KeychainManager.shared.getToken(forKey: "refreshToken") else {
                throw AuthError.tokenExpired
            }
            let (path, method, headers, body) = endpointProvider(.dashboards)
            let endpoint = InternalEndpoint(path: path, method: method, headers: headers, body: body)
            let newToken = try await self.refreshToken(refreshToken)
            return try await NetworkManager.shared.performRequest(endpoint, baseURL: api, accessToken: newToken.accessToken)
        }
    }

    actor DashboardProcessor {
        private var dashboards: [Dashboard]

        init(dashboards: [Dashboard]) {
            self.dashboards = dashboards
        }

        func process(at index: Int) {
            dashboards[index].widgets = dashboards[index].widgets.map { widget in
                var newWidget = widget
                newWidget.title = widget.title.uppercased()
                return newWidget
            }
        }

        func getDashboards() -> [Dashboard] {
            dashboards
        }
    }

    public func processDashboards(_ dashboards: [Dashboard]) async -> [Dashboard] {
        let processor = DashboardProcessor(dashboards: dashboards)

        await withTaskGroup(of: Void.self) { group in
            for index in dashboards.indices {
                group.addTask {
                    await processor.process(at: index)
                }
            }
        }

        return await processor.getDashboards()
    }
}

