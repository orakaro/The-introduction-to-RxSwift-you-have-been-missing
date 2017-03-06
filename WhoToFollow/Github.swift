import Foundation
import Moya

enum GitHub {
    case users(since: Int)
}

extension GitHub: TargetType {
    public var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    
    public var task: Task {
        return .request
    }
    
    public var baseURL: URL { return URL(string: "https://api.github.com")! }
    
    public var path: String {
        switch self {
        case .users:
            return "/users"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    public var parameters: [String: Any]? {
        switch self {
        case .users(let since): return ["since": since as Any]
        }
    }
    
    var sampleData: Data {
        return "".data(using: String.Encoding.utf8)!
    }
}
