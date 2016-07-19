import Foundation
import Moya

enum GitHub {
    case Users(since: Int)
}

extension GitHub: TargetType {
    var baseURL: NSURL { return NSURL(string: "https://api.github.com")! }
    var path: String {
        switch self {
        case .Users:
            return "/users"
        }
    }
    var method: Moya.Method {
        return .GET
    }
    var parameters: [String: AnyObject]? {
        switch self {
        case .Users(let since): return ["since": since]
        }
    }
    var sampleData: NSData {
        return "".dataUsingEncoding(NSUTF8StringEncoding)!
    }
}
