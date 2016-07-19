import UIKit
import RxSwift

class FollowTableViewCell: UITableViewCell {
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var cancel: UIButton!
    var disposeBagCell:DisposeBag = DisposeBag()

    override func prepareForReuse() {
        disposeBagCell = DisposeBag()
    }
}
