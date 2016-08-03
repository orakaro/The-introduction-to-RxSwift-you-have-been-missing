import UIKit
import RxSwift
import RxCocoa
import Moya

class FollowTableViewController: UIViewController {

    @IBOutlet weak var refresh: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var disposeBag = DisposeBag()
    var provider: RxMoyaProvider<GitHub>! = RxMoyaProvider<GitHub>()
    var dataSource = [User]()
    var responseStream: Observable<[User]> = Observable.just([])

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 70.0
        rxBind()
    }

    func rxBind() {
        let requestStream: Observable<Int> = refresh.rx_tap.startWith(())
            .map { _ in
                Array(1...1000).random()
            }
        responseStream = requestStream
            .flatMap{ since in
                UserModel(provider: self.provider).findUsers(since)
            }
    }

}

extension FollowTableViewController: UITableViewDataSource {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FollowCell", forIndexPath: indexPath) as! FollowTableViewCell
        cell.cancel.showsTouchWhenHighlighted = true
        cell.avatar.layer.cornerRadius = cell.avatar.frame.size.width / 2
        cell.avatar.clipsToBounds = true

        let closeStream = cell.cancel.rx_tap.startWith(())
        let userStream: Observable<User?> = Observable.combineLatest(
            closeStream,
            responseStream)
        { (_, users) in
            guard users.count > 0 else {return nil}
            return users.random()
        }
        let nilOnRefreshTapStream: Observable<User?> = refresh.rx_tap.map {_ in return nil}
        let suggestionStream = Observable.of(userStream, nilOnRefreshTapStream)
            .merge()
            .startWith(.None)

        suggestionStream.subscribeNext{ op in
            guard let u = op else { return self.clearCell(cell) }
            return self.setCell(cell, user: u )
        }.addDisposableTo(cell.disposeBagCell)
        
        return cell
    }

    func clearCell(cell: FollowTableViewCell) {
        cell.cancel.hidden = true
        cell.avatar.image = nil
        cell.name.text = nil
    }

    func setCell(cell: FollowTableViewCell, user: User) {
        clearCell(cell)
        guard let url = NSURL(string: user.avatarUrl) else {return}
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            guard let data = NSData(contentsOfURL: url) else {return}
            dispatch_async(dispatch_get_main_queue(), {
                cell.cancel.hidden = false
                cell.avatar.image = UIImage(data: data)
                cell.name.text = user.name
            })
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}