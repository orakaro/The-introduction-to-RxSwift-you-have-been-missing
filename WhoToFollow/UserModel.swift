import Foundation
import RxSwift
import RxOptional
import Moya
import Moya_ModelMapper

struct UserModel {
    let provider: RxMoyaProvider<GitHub>

    func findUsers(_ since: Int) -> Observable<[User]> {
        return self.provider
            .request(GitHub.users(since: since))
            .debug()
            .mapArrayOptional(type: User.self)
            .replaceNilWith([])
    }
}
