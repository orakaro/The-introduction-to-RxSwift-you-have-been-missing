import Foundation
import RxSwift
import RxOptional
import Moya
import Moya_ModelMapper

struct UserModel {
    let provider: RxMoyaProvider<GitHub>

    func findUsers(since: Int) -> Observable<[User]> {
        return self.provider
            .request(GitHub.Users(since: since))
            .debug()
            .mapArrayOptional(User.self)
            .replaceNilWith([])
    }
}
