//
//  StyleSettingsViewController.swift
//  Countdown
//
//  A small settings sheet with two choices: how the selected tick animates
//  each second, and how the ring resets when a dial rolls over. Both persist
//  to UserDefaults. Presented from the gear button on the countdown screen.
//

import UIKit

protocol StyleSettingsDelegate: AnyObject {
    func stylesDidChange()
}

final class StyleSettingsViewController: UITableViewController {

    weak var delegate: StyleSettingsDelegate?

    private let selectStyles = TickDialView.SelectStyle.allCases
    private let resetStyles = TickDialView.ResetStyle.allCases

    private let selectBlurbs: [TickDialView.SelectStyle: String] = [
        .classic:    "Steady accent tick, no animation.",
        .launch:     "Shoots out from the center to its slot.",
        .eject:      "The previous tick flies outward as the new one pops in.",
        .rippleIn:   "A faint wave arrives from the upcoming side and settles in.",
        .wake:       "Recent-past ticks glow and fade back; upcoming stay dim.",
        .rippleWake: "Ripple In plus the past-bright wake trail."
    ]

    private let resetBlurbs: [TickDialView.ResetStyle: String] = [
        .none:     "No rollover flourish.",
        .dissolve: "Ticks scatter out and speckle back in.",
        .twist:    "Ticks spin on themselves, then unwind into place."
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Animations"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self, action: #selector(done))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    @objc private func done() { dismiss(animated: true) }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Selected tick" : "Rollover (at zero)"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? selectStyles.count : resetStyles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let title: String
        let subtitle: String?
        let checked: Bool
        if indexPath.section == 0 {
            let style = selectStyles[indexPath.row]
            title = style.title; subtitle = selectBlurbs[style]
            checked = style == TickDialView.savedStyle
        } else {
            let style = resetStyles[indexPath.row]
            title = style.title; subtitle = resetBlurbs[style]
            checked = style == TickDialView.savedResetStyle
        }
        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            content.text = title
            content.secondaryText = subtitle
            cell.contentConfiguration = content
        } else {
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = subtitle
        }
        cell.accessoryType = checked ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            TickDialView.savedStyle = selectStyles[indexPath.row]
        } else {
            TickDialView.savedResetStyle = resetStyles[indexPath.row]
        }
        delegate?.stylesDidChange()
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
