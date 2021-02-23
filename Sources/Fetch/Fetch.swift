//
//  fetch.swift
//  yeslive2
//
//  Created by youga on 2021/1/19.
//

import Foundation

public extension Encodable
{
    func toMap() -> [String:String] {
        Mirror(reflecting: self).children.reduce(into: [String: String]()) {
            $0[$1.label!] = $1.value as? String
        }
    }
    
    func json() throws -> Data  {
        try JSONEncoder().encode(self)
    }
}

public extension DateFormatter
{
  static let iso8601Full: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }()
}

public extension Date
{
    var toLocalDateTime:String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: Bundle.main.preferredLocalizations.first!)
        return formatter.string(from: self)
    }
}

public extension Data {
    func text(encoding: String.Encoding = .utf8) -> String? {
        String(data: self, encoding: encoding)
    }
    
    func json() throws -> [String:Any]? {
        try JSONSerialization.jsonObject(with: self, options: []) as? [String:Any]
    }
    
    func decode<T:Decodable>() throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.iso8601Full)
        return try decoder.decode(T.self, from: self)
    }
    
    mutating func append(_ string: String) {
        guard let data = string.data(using: String.Encoding.utf8) else {
            print("can't append string to data")
            return
        }
        append(data)
    }
}

public protocol Requestable {
    associatedtype Response:Decodable
}

public struct Response
{
    public let headers:HTTPURLResponse
    public let data:Data
    
    public var status:Int { headers.statusCode }
    public var ok:Bool { headers.statusCode >= 200 && headers.statusCode < 300 }
}

public struct Options {
    public init(method: String = "GET", headers: [String : String] = [String:String](), body: Options.Body = .string(""), query: [String : String] = [String:String]()) {
        self.method = method
        self.headers = headers
        self.body = body
        self.query = query
    }
    
    public enum Body {
        case formData(FormData)
        case string(String)
    }
    public var method = "GET"
    public var headers = [String:String]()
    public var body:Body = .string("")
    public var query = [String:String]()
}

public struct FormData {
    public let boundary = arc4random()
    var _data = Data()
    
    var data:Data {
        var temp = Data(self._data)
        temp.append("--\(boundary)--")
        return temp
    }
    
    public init() {
        
    }
    
    public mutating func append(_ name:String, value:Data) {
        _data.append("--\(boundary)\r\n")
        _data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n")
        _data.append(value)
        _data.append("\r\n")
    }
    
    public mutating func append(filename:String, contentType:String ,name:String, value:Data) {
        _data.append("--\(boundary)\r\n")
        _data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        _data.append("Content-Type: \(contentType)\r\n\r\n")
        _data.append(value)
        _data.append("\r\n")
    }
}

public func fetch(_ api:String, _ options:Options = Options(), _ callback:@escaping (Swift.Result<Response, Error>) -> ()) {
        guard var uc = URLComponents(string: api) else {
            callback(.failure(URLError(.badURL)))
            return
        }
        if !options.query.isEmpty {
            uc.queryItems = options.query.map{ URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = uc.url else {
            callback(.failure(URLError(.unsupportedURL)))
            return
        }
        
        if case let .string(string) = options.body {
            uc.query = string
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = options.method
        
        if case let .formData(formData) = options.body {
            request.setValue("multipart/form-data; boundary=\(formData.boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = formData.data
        }
        
        options.headers.forEach{
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }
        
        URLSession.shared.dataTask(with: request) { (data, headers, error) in
            if let error = error {
                callback(.failure(error))
                return
            }
            guard let data = data, let headers = headers else {
                callback(.failure(URLError(.unknown)))
                return
            }
            callback(.success(Response(headers: headers as! HTTPURLResponse, data: data)))
        }.resume()
}

public extension Swift.Result {
    func get() throws -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
