//
//  StyleSettingsViewController.swift
//  Countdown
//
//  A small settings sheet for choosing how the selected tick animates.
//  Lists every TickDialView.SelectStyle, checks the current one, and persists
//  the choice. Presented from the gear button on the countdown screen.
//

import UIKit

protocol StyleSettingsDelegate: AnyObject {
    func styleSettingsDidChange(_ style: TickDialView.SelectStyle)
}

final class StyleSettingsViewController: UITableViewController {

    weak var delegate: StyleSettingsDelegate?

    private let styles = TickDialView.SelectStyle.allCases

    private let blurbs: [TickDialView.SelectStyle: String] = [
        .classic:    "Steady accent tick, no animation.",
        .launch:     "Shoots out from the center to its slot.",
        .eject:      "The previous tick flies outward as the new one pops in.",
        .rippleIn:   "A faint wave arrives from the upcoming side and settles in.",
        .wake:       "Recent-past ticks glow and fade back; upcoming stay dim.",
        .rippleWake: "Ripple In plus the past-bright wake trail."
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tick Style"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self, action: #selector(done))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    @objc private func done() { dismiss(animated: true) }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        styles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let style = styles[indexPath.row]
        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            content.text = style.title
            content.secondaryText = blurbs[style]
            cell.contentConfiguration = content
        } else {
            cell.textLabel?.text = style.title
            cell.detailTextLabel?.text = blurbs[style]
        }
        cell.accessoryType = (style == TickDialView.savedStyle) ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let style = styles[indexPath.row]
        TickDialView.savedStyle = style
        delegate?.styleSettingsDidChange(style)
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
