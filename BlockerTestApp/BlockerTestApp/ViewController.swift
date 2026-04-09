// ViewController.swift

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        let label = UILabel()
        label.text = "BlockerTestApp\nAppCompliance Scanner Test"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.frame = CGRect(x: 20, y: 200, width: 280, height: 100)
        label.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        view.addSubview(label)

        // Trigger blocker code paths
        TestBlockerRunner.runAll()
    }
}
