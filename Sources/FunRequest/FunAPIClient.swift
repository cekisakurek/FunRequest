//
//  FunClient.swift
//  FunRequest
//
//  Created by Cihan Emre Kisakurek on 19.05.22.
//

import Foundation
import Combine
import os.log

extension URLSession.DataTaskPublisher {
    
    func authorization(bearer token: String) -> URLSession.DataTaskPublisher {
        var request = self.request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return URLSession.DataTaskPublisher(request: request, session: self.session)
    }
    
    func decodeUsingJSONDecoder<T: Decodable>(to type: T.Type) -> AnyPublisher<T, NSError> {
        tryMap() { element -> T in
            let str = String(data: element.data, encoding: .utf8)
            FunAPIClient.log(message: str)
            if let httpResponse = element.response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                let err = FunAPIClient.Error(domain: "FunAPIClient.Error",
                                  code: httpResponse.statusCode,
                                  userInfo: [NSLocalizedFailureReasonErrorKey: "Server response is not 200"])
                err.data = element.data
                throw err
            }

            let response = try JSONDecoder().decode(T.self, from: element.data)
            return response
        }
        .mapError({ error in error as NSError })
        .eraseToAnyPublisher()
    }
}

public struct FunAPIClient {
    
    static var systemName = "rocks.cihan.FunAPIClient"
    
    var hostname: String = ""
    
    var defaultHeaders: [String: String]
    
    var sessionConfiguration: URLSessionConfiguration
    
    public init(hostname: String, defaultHeaders: [String: String] = [:]) {
        self.hostname = hostname
        self.defaultHeaders = defaultHeaders
        self.sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.httpAdditionalHeaders = defaultHeaders
    }
    
    
    static func log(message: String?, type: OSLogType = .default) {
        guard let message = message else { return }
        let oslog = OSLog(subsystem: Self.systemName, category: "FunAPIClient")
        os_log("%@", log: oslog, type: type, message)
    }
    
    func publisher(for request: FunRequest.Endpoint) -> URLSession.DataTaskPublisher {
        
        var urlRequest = URLRequest(url: URL(string: self.hostname + request.path)!)
        urlRequest.httpMethod = request.httpMethod.rawValue
        
        if let bodyData = request.bodyData {
            urlRequest.httpBody = bodyData
        }
        
        for (key, value) in defaultHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // request headers are prioritized
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        return URLSession.shared
            .dataTaskPublisher(for: urlRequest)
    }
    
    func send<T: Decodable>(_ request: FunRequest.Endpoint, response: T.Type)  -> AnyPublisher<T, NSError> {
        
        var urlRequest = URLRequest(url: URL(string: self.hostname + request.path)!)
        urlRequest.httpMethod = request.httpMethod.rawValue
        
        if let bodyData = request.bodyData {
            urlRequest.httpBody = bodyData
        }
        
        for (key, value) in defaultHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // request headers are prioritized
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        return URLSession.shared
            .dataTaskPublisher(for: urlRequest)
            .tryMap() { element -> T in
                let str = String(data: element.data, encoding: .utf8)
                Self.log(message: str)
                
                if let httpResponse = element.response as? HTTPURLResponse,
                   httpResponse.statusCode != 200 {
                    let err = Error(domain: "FunAPIClient.Error",
                                    code: httpResponse.statusCode,
                                    userInfo: [NSLocalizedFailureReasonErrorKey: "Server response is not 200"])
                    err.data = element.data
                    throw err
                }
                let response = try JSONDecoder().decode(T.self, from: element.data)
                return response
            }
            .mapError({ error in error as NSError })
            .eraseToAnyPublisher()
    }
    
    public class Error: NSError {
        
        var data: Data?
        
        public override init(domain: String, code: Int, userInfo dict: [String : Any]? = nil) {
            super.init(domain: domain, code: code, userInfo: dict)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
