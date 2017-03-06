import UIKit

extension Array {
    func random() -> Iterator.Element {
        let index = Int(arc4random_uniform(UInt32(count)))
        return self[index]
    }
}
