// ViewController.swift
// Displays font samples — demonstrates embedded commercial + open source fonts

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)

        let titleLabel = UILabel()
        titleLabel.text = "FontPrivacyTestApp"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = "AppCompliance Scanner Test\nFonts · Deprecated SDKs · Privacy Manifest"
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .gray

        let fontDemos: [(String, String)] = [
            // 5 Commercial fonts (Apple rejection: unlicensed redistribution)
            ("HelveticaNeue-Bold",           "Helvetica Neue Bold   [COMMERCIAL – Linotype]"),
            ("ProximaNova-Regular",          "Proxima Nova Regular  [COMMERCIAL – Mark Simonson]"),
            ("GothamBook",                   "Gotham Book           [COMMERCIAL – Hoefler&Co]"),
            ("BrandonGrotesque-Regular",     "Brandon Grotesque     [COMMERCIAL – HVD Fonts]"),
            ("FuturaPT-Medium",              "Futura PT Medium      [COMMERCIAL – ParaType]"),
            // 1 Open source font (SIL OFL — permitted)
            ("Inter-Regular",               "Inter Regular         [OPEN SOURCE – SIL OFL]"),
        ]

        var stackViews: [UIView] = [titleLabel, subtitleLabel]

        for (psName, description) in fontDemos {
            let label = UILabel()
            let font = UIFont(name: psName, size: 16) ?? UIFont.systemFont(ofSize: 16)
            label.font = font
            label.text = description
            label.numberOfLines = 0
            label.adjustsFontSizeToFitWidth = true
            stackViews.append(label)
        }

        let deprecatedNote = UILabel()
        deprecatedNote.text = "⚠️ AddressBook + OpenGLES linked (deprecated)\n⚠️ NSURLConnection used (deprecated)\n⚠️ PrivacyInfo.xcprivacy incomplete\n⚠️ Embedded SDK frameworks lack valid privacy manifests"
        deprecatedNote.numberOfLines = 0
        deprecatedNote.font = UIFont.systemFont(ofSize: 11)
        deprecatedNote.textColor = .systemRed
        stackViews.append(deprecatedNote)

        let stack = UIStackView(arrangedSubviews: stackViews)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
        ])
    }
}
