//
//  NetworkManagerProtocol .swift
//  AxxonCloudDashboard
//
//  Created by Логунов Даниил on 9/15/25.
//

import Foundation

public enum NetworkError: Error {
    case invalidResponse
    case serverError(Int)
}

public final class NetworkManager: @unchecked Sendable {
    public static let shared = NetworkManager()
    
    private init() {}
    
    public func performRequest<T: Decodable>(_ endpoint: InternalEndpoint, baseURL: URL, accessToken: String?) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.allHTTPHeaderFields = endpoint.headers
        if let token = accessToken, endpoint.method == "GET" {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = endpoint.body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}



