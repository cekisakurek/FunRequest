//
//  FunRequest.swift
//  FunRequest
//
//  Created by Cihan Emre Kisakurek on 19.05.22.
//

import Foundation

public struct FunRequest {

    public struct Endpoint {
        var path: String
        var httpMethod: HTTPMethod
        var queryItems: [URLQueryItem]?
        var headers: [String: String]
        var bodyEncoding: BodyEncoding = .none
        var bodyData: Data?
        
        public init(path: String,
                    httpMethod: HTTPMethod = .GET,
                    queryItems: [URLQueryItem]? = nil,
                    headers: [String: String] = [:],
                    body: BodyEncoding = .none ) {
            
            self.path = path
            self.httpMethod = httpMethod
            self.queryItems = queryItems
            self.headers = headers
            self.bodyEncoding = body
        }
        
        mutating func addHeader(_ header: HTTPHeader) {
            
            switch header {
            case .accept(let string):
                addHeader("Accept", value: string)
            case .authorization(let string):
                addHeader("Authorization", value: string)
            case .userAgent(let string):
                addHeader("User-Agent", value: string)
            case .contentType(let string):
                addHeader("Content-Type", value: string)
            }
        }
        
        mutating func addHeader(_ key: String, value: String) {
            self.headers[key] = value
        }
        
        mutating func setRequestBody<T: Encodable>(_ body: T, encoding: BodyEncoding) throws {
            let data = try JSONEncoder().encode(body)
            self.bodyData = data
        }
    }
}


extension FunRequest.Endpoint {
    
    public enum HTTPMethod: String {
        case GET
        case HEAD
        case POST
        case PUT
        case DELETE
        case CONNECT
        case OPTIONS
        case TRACE
        case PATCH
    }
    
    public enum HTTPHeader {
        case accept(String)
        case authorization(String)
        case userAgent(String)
        case contentType(String)
    }
    
    public enum BodyEncoding {
        case none
        case formData
        case json
        case xml
    }
}
