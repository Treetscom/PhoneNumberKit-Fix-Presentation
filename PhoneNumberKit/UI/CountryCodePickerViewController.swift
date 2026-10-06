#if os(iOS)

import UIKit

public protocol CountryCodePickerDelegate: AnyObject {
    func countryCodePickerViewControllerDidPickCountry(_ country: CountryCodePickerViewController.Country)
}

public class CountryCodePickerViewController: UITableViewController {
    lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = NSLocalizedString(
            "PhoneNumberKit.CountryCodePicker.SearchBarPlaceholder",
            value: "Search Country Codes",
            comment: "Placeholder for country code search field")

        return searchController
    }()

    public let utility: PhoneNumberUtility

    public let options: CountryCodePickerOptions

    let commonCountryCodes: [String]

    var shouldRestoreNavigationBarToHidden = false

    var hasCurrent = true
    var hasCommon = true

    var topSectionCount: Int {
        guard !isFiltering else { return 0 }
        return (hasCurrent ? 1 : 0) + (hasCommon ? 1 : 0)
    }

    var letterSectionTitles: [String] {
        countries.dropFirst(topSectionCount).map { group in
            group.first?.name.first
                .map(String.init)?
                .folding(options: .diacriticInsensitive, locale: nil) ?? ""
        }
    }

    lazy var allCountries = utility
        .allCountries()
        .compactMap({ Country(for: $0, with: self.utility) })
        .sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })

    lazy var countries: [[Country]] = {
        let countries = allCountries
            .reduce([[Country]]()) { collection, country in
                var collection = collection
                guard var lastGroup = collection.last else { return [[country]] }
                let lhs = lastGroup.first?.name.folding(options: .diacriticInsensitive, locale: nil)
                let rhs = country.name.folding(options: .diacriticInsensitive, locale: nil)
                if lhs?.first == rhs.first {
                    lastGroup.append(country)
                    collection[collection.count - 1] = lastGroup
                } else {
                    collection.append([country])
                }
                return collection
            }

        let popular = commonCountryCodes.compactMap({ Country(for: $0, with: utility) })

        var result: [[Country]] = []
        // Note we should maybe use the user's current carrier's country code?
        if hasCurrent, let current = Country(for: PhoneNumberUtility.defaultRegionCode(), with: utility) {
            result.append([current])
        } else {
            hasCurrent = false
        }
        hasCommon = hasCommon && !popular.isEmpty
        if hasCommon {
            result.append(popular)
        }
        return result + countries
    }()

    var filteredCountries: [Country] = []

    var searchText = ""

    var sectionIndexView: SectionIndexView?

    public weak var delegate: CountryCodePickerDelegate?

    lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissAnimated))

    /// Init with a phone number kit instance. Because a `PhoneNumberUtility` initialization is expensive you can must pass a pre-initialized instance to avoid incurring perf penalties.
    ///
    /// - parameter utility: A `PhoneNumberUtility` instance to be used by the text field.
    /// - parameter commonCountryCodes: An array of country codes to display in the section below the current region section. defaults to `PhoneNumberUtility.CountryCodePicker.commonCountryCodes`
    public init(
        utility: PhoneNumberUtility,
        options: CountryCodePickerOptions?,
        commonCountryCodes: [String] = CountryCodePicker.commonCountryCodes) {
        self.utility = utility
        self.commonCountryCodes = commonCountryCodes
        self.options = options ?? CountryCodePickerOptions()
        super.init(style: .grouped)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        self.utility = PhoneNumberUtility()
        self.commonCountryCodes = CountryCodePicker.commonCountryCodes
        self.options = CountryCodePickerOptions()
        super.init(coder: aDecoder)
        self.commonInit()
    }

    func commonInit() {
        self.title = NSLocalizedString("PhoneNumberKit.CountryCodePicker.Title", value: "Choose your country", comment: "Title of CountryCodePicker ViewController")

        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseIdentifier)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.backgroundColor = .clear

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = !CountryCodePicker.alwaysShowsSearchBar

        definesPresentationContext = true

        if let tintColor = options.tintColor {
            view.tintColor = tintColor
            navigationController?.navigationBar.tintColor = tintColor
        }

        if let backgroundColor = options.backgroundColor {
            tableView.backgroundColor = backgroundColor
        }

        if let separator = options.separatorColor {
            tableView.separatorColor = separator
        }

        if let rowHeight = options.rowHeight {
            tableView.rowHeight = rowHeight + (options.rowSpacing ?? 0)
        }

        if options.rowSpacing != nil {
            tableView.separatorStyle = .none
        }

        if options.sectionFooterHeight != nil {
            tableView.estimatedSectionFooterHeight = 0
        }

        if let sectionIndexColor = options.sectionIndexColor {
            tableView.sectionIndexColor = sectionIndexColor
        }

        if let sectionIndexFont = options.sectionIndexFont {
            installSectionIndexView(font: sectionIndexFont)
        }
    }

    func installSectionIndexView(font: UIFont) {
        let indexView = SectionIndexView(
            titles: letterSectionTitles,
            options: options,
            font: font,
            scrollPanGesture: tableView.panGestureRecognizer
        )
        indexView.translatesAutoresizingMaskIntoConstraints = false
        indexView.onSelectIndex = { [weak self] index in
            guard let self = self else { return }
            let indexPath = IndexPath(row: 0, section: self.topSectionCount + index)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
        tableView.addSubview(indexView)
        NSLayoutConstraint.activate([
            indexView.trailingAnchor.constraint(equalTo: tableView.frameLayoutGuide.trailingAnchor),
            indexView.centerYAnchor.constraint(equalTo: tableView.frameLayoutGuide.centerYAnchor),
            indexView.widthAnchor.constraint(equalToConstant: SectionIndexView.width)
        ])
        sectionIndexView = indexView
    }

    /// Filters the list the same way the built-in search bar does, for callers that supply their own search field.
    public func filterCountries(by text: String) {
        searchText = text
        let query = text.lowercased()
        filteredCountries = allCountries.filter { country in
            country.name.lowercased().contains(query) ||
                country.code.lowercased().contains(query) ||
                country.prefix.lowercased().contains(query)
        }
        sectionIndexView?.isHidden = isFiltering
        tableView.reloadData()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nav = navigationController {
            shouldRestoreNavigationBarToHidden = nav.isNavigationBarHidden
            nav.setNavigationBarHidden(false, animated: true)
        }
        if let nav = navigationController, nav.isBeingPresented, nav.viewControllers.count == 1 {
            navigationItem.setRightBarButton(cancelButton, animated: true)
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(shouldRestoreNavigationBarToHidden, animated: true)
    }

    @objc func dismissAnimated() {
        dismiss(animated: true)
    }

    func country(for indexPath: IndexPath) -> Country {
        isFiltering ? filteredCountries[indexPath.row] : countries[indexPath.section][indexPath.row]
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        isFiltering ? 1 : countries.count
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isFiltering ? filteredCountries.count : countries[section].count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath)
        let country = self.country(for: indexPath)

        if let cellBackgroundColor = options.cellBackgroundColor {
            cell.backgroundColor = cellBackgroundColor
        }

        if let cellLayoutMargins = options.cellLayoutMargins {
            cell.preservesSuperviewLayoutMargins = false
            cell.directionalLayoutMargins = cellLayoutMargins
        }

        if let rowSpacing = options.rowSpacing, let cell = cell as? Cell {
            cell.setRowSpacing(rowSpacing, color: options.backgroundColor)
        }

        cell.textLabel?.text = country.prefix + " " + country.flag

        if let textLabelColor = options.textLabelColor {
            cell.textLabel?.textColor = textLabelColor
        }

        if let detailTextLabelColor = options.detailTextLabelColor {
            cell.detailTextLabel?.textColor = detailTextLabelColor
        }

        cell.detailTextLabel?.text = country.name

        if let textLabelFont = options.textLabelFont {
            cell.textLabel?.font = textLabelFont
        }

        if let detailTextLabelFont = options.detailTextLabelFont {
            cell.detailTextLabel?.font = detailTextLabelFont
        }

        if let cellBackgroundColorSelection = options.cellBackgroundColorSelection {
            let view = UIView()
            view.backgroundColor = cellBackgroundColorSelection
            cell.selectedBackgroundView = view
        }

        return cell
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isFiltering {
            return nil
        } else if section == 0, hasCurrent {
            return NSLocalizedString("PhoneNumberKit.CountryCodePicker.Current", value: "Current", comment: "Name of \"Current\" section")
        } else if section == 0, !hasCurrent, hasCommon {
            return NSLocalizedString("PhoneNumberKit.CountryCodePicker.Common", value: "Common", comment: "Name of \"Common\" section")
        } else if section == 1, hasCurrent, hasCommon {
            return NSLocalizedString("PhoneNumberKit.CountryCodePicker.Common", value: "Common", comment: "Name of \"Common\" section")
        }
        return countries[section].first?.name.first.map(String.init)
    }

    override public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = self.tableView(tableView, titleForHeaderInSection: section) else {
            return nil
        }
        let isTopSection = section < topSectionCount
        let font = isTopSection ? options.topSectionHeaderFont : options.sectionHeaderFont
        let color = isTopSection ? options.topSectionHeaderColor : options.sectionHeaderColor
        guard font != nil || color != nil || options.sectionHeaderLayoutMargins != nil else {
            return nil
        }
        return SectionHeaderView(title: title, font: font, color: color, margins: options.sectionHeaderLayoutMargins)
    }

    override public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let isTopSection = section < topSectionCount
        guard let textHeight = isTopSection ? options.topSectionHeaderHeight : options.sectionHeaderHeight else {
            return UITableView.automaticDimension
        }
        guard self.tableView(tableView, titleForHeaderInSection: section) != nil else {
            return .leastNormalMagnitude
        }
        let margins = options.sectionHeaderLayoutMargins
        return textHeight + (margins?.top ?? 0) + (margins?.bottom ?? 0)
    }

    override public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        options.sectionFooterHeight == nil ? nil : UIView()
    }

    override public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let sectionFooterHeight = options.sectionFooterHeight else {
            return UITableView.automaticDimension
        }
        // A grouped table swaps a zero height, or a footer with no view, for its default spacing.
        return max(sectionFooterHeight, .leastNormalMagnitude)
    }

    override public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard !isFiltering, sectionIndexView == nil else {
            return nil
        }
        var titles: [String] = []
        if hasCurrent {
            titles.append("•") // NOTE: SFSymbols are not supported otherwise we would use 􀋑
        }
        if hasCommon {
            titles.append("★") // This is a classic unicode star
        }
        return titles + letterSectionTitles
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let country = self.country(for: indexPath)
        delegate?.countryCodePickerViewControllerDidPickCountry(country)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension CountryCodePickerViewController: UISearchResultsUpdating {
    var isFiltering: Bool {
        !searchText.isEmpty
    }

    public func updateSearchResults(for searchController: UISearchController) {
        filterCountries(by: searchController.searchBar.text ?? "")
    }
}

// MARK: Types

public extension CountryCodePickerViewController {
    struct Country {
        public var code: String
        public var flag: String
        public var name: String
        public var prefix: String

        public init?(for countryCode: String, with utility: PhoneNumberUtility) {
            let flagBase = UnicodeScalar("🇦").value - UnicodeScalar("A").value
            guard
                let name = (Locale.current as NSLocale).localizedString(forCountryCode: countryCode),
                let prefix = utility.countryCode(for: countryCode)?.description
            else {
                return nil
            }

            self.code = countryCode
            self.name = name
            self.prefix = "+" + prefix
            self.flag = ""
            countryCode.uppercased().unicodeScalars.forEach {
                if let scaler = UnicodeScalar(flagBase + $0.value) {
                    flag.append(String(describing: scaler))
                }
            }
            if flag.count != 1 { // Failed to initialize a flag ... use an empty string
                return nil
            }
        }
    }

    class Cell: UITableViewCell {
        static let reuseIdentifier = "Cell"

        private let rowSpacingView = UIView()

        private lazy var rowSpacingHeightConstraint = rowSpacingView.heightAnchor.constraint(equalToConstant: 0)

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .value2, reuseIdentifier: Self.reuseIdentifier)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override public func layoutSubviews() {
            super.layoutSubviews()
            bringSubviewToFront(rowSpacingView)
        }

        func setRowSpacing(_ rowSpacing: CGFloat, color: UIColor?) {
            if rowSpacingView.superview == nil {
                rowSpacingView.translatesAutoresizingMaskIntoConstraints = false
                addSubview(rowSpacingView)
                NSLayoutConstraint.activate([
                    rowSpacingView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    rowSpacingView.trailingAnchor.constraint(equalTo: trailingAnchor),
                    rowSpacingView.bottomAnchor.constraint(equalTo: bottomAnchor),
                    rowSpacingHeightConstraint
                ])
            }
            rowSpacingView.backgroundColor = color
            rowSpacingHeightConstraint.constant = rowSpacing
        }
    }
}

// MARK: - Section Index View
extension CountryCodePickerViewController {
    /// Replaces the system section index so its font can be styled, and shows a bubble with the touched letter.
    final class SectionIndexView: UIView {
        static let width: CGFloat = 40

        private static let rowHeight: CGFloat = 20

        var onSelectIndex: ((Int) -> Void)?

        private let titles: [String]

        private let font: UIFont

        private let stackView = UIStackView()

        private let bubbleView: SectionIndexBubbleView

        private var selectedIndex: Int?

        private weak var scrollPanGesture: UIPanGestureRecognizer?

        init(titles: [String], options: CountryCodePickerOptions, font: UIFont, scrollPanGesture: UIPanGestureRecognizer) {
            self.titles = titles
            self.font = font
            self.bubbleView = SectionIndexBubbleView(options: options)
            self.scrollPanGesture = scrollPanGesture
            super.init(frame: .zero)
            layer.zPosition = 1

            let dragGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleDrag))
            dragGesture.minimumPressDuration = 0
            dragGesture.delegate = self
            addGestureRecognizer(dragGesture)

            stackView.axis = .vertical
            stackView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(stackView)
            addTitleLabels(color: options.sectionIndexColor)

            bubbleView.alpha = 0
            addSubview(bubbleView)

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
            ])
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc private func handleDrag(_ gesture: UILongPressGestureRecognizer) {
            switch gesture.state {
            case .began, .changed:
                selectTitle(atY: gesture.location(in: stackView).y)
            default:
                endSelection()
            }
        }

        private func addTitleLabels(color: UIColor?) {
            titles.forEach { title in
                let label = UILabel()
                label.text = title
                label.font = font
                label.textColor = color
                label.textAlignment = .center
                label.heightAnchor.constraint(equalToConstant: Self.rowHeight).isActive = true
                stackView.addArrangedSubview(label)
            }
        }

        private func selectTitle(atY locationY: CGFloat) {
            guard !titles.isEmpty else { return }
            let index = min(max(Int(locationY / Self.rowHeight), 0), titles.count - 1)
            guard index != selectedIndex else { return }
            selectedIndex = index

            bubbleView.title = titles[index]
            let bubbleSize = SectionIndexBubbleView.size
            let centerY = stackView.frame.minY + (CGFloat(index) + 0.5) * Self.rowHeight
            let bubbleOriginX = bounds.midX - font.pointSize / 2 - bubbleSize.width
            bubbleView.frame = CGRect(x: bubbleOriginX, y: centerY - bubbleSize.height / 2, width: bubbleSize.width, height: bubbleSize.height)
            bubbleView.alpha = 1
            onSelectIndex?(index)
        }

        private func endSelection() {
            selectedIndex = nil
            UIView.animate(withDuration: 0.2) {
                self.bubbleView.alpha = 0
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension CountryCodePickerViewController.SectionIndexView: UIGestureRecognizerDelegate {
    // Keeps a drag on the index from scrolling the table instead.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        otherGestureRecognizer == scrollPanGesture
    }
}

// MARK: - Section Header View
extension CountryCodePickerViewController {
    // A plain view on purpose: UIKit writes the section title into a UITableViewHeaderFooterView's own label too.
    final class SectionHeaderView: UIView {
        init(title: String, font: UIFont?, color: UIColor?, margins: NSDirectionalEdgeInsets?) {
            super.init(frame: .zero)
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = font
            titleLabel.textColor = color
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(titleLabel)

            let margins = margins ?? .zero
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margins.leading),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -margins.trailing),
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: margins.top),
                titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margins.bottom)
            ])
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: - Section Index Bubble View
extension CountryCodePickerViewController {
    final class SectionIndexBubbleView: UIView {
        static let size = CGSize(width: 32, height: 29)

        private static let bodyWidth: CGFloat = 28

        private static let pointerHeight: CGFloat = 9

        private static let cornerRadius: CGFloat = 7

        var title: String? {
            get { titleLabel.text }
            set { titleLabel.text = newValue }
        }

        private let options: CountryCodePickerOptions

        private let shapeLayer = CAShapeLayer()

        private let titleLabel = UILabel()

        init(options: CountryCodePickerOptions) {
            self.options = options
            super.init(frame: .zero)
            isUserInteractionEnabled = false

            let path = Self.bubblePath()
            shapeLayer.path = path.cgPath
            layer.addSublayer(shapeLayer)
            layer.shadowPath = path.cgPath
            layer.shadowOpacity = 0.1
            layer.shadowOffset = CGSize(width: 0, height: 3)
            layer.shadowRadius = 3

            titleLabel.font = options.sectionHeaderFont
            titleLabel.textColor = options.sectionIndexBubbleTextColor
            titleLabel.textAlignment = .center
            titleLabel.frame = CGRect(x: 0, y: 0, width: Self.bodyWidth, height: Self.size.height)
            addSubview(titleLabel)
            updateColors()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // CGColors don't follow light/dark changes on their own.
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            updateColors()
        }

        private func updateColors() {
            shapeLayer.fillColor = options.sectionIndexBubbleBackgroundColor?.cgColor
            layer.shadowColor = options.sectionIndexBubbleShadowColor?.cgColor
        }

        private static func bubblePath() -> UIBezierPath {
            let bodyRect = CGRect(x: 0, y: 0, width: bodyWidth, height: size.height)
            let path = UIBezierPath(roundedRect: bodyRect, cornerRadius: cornerRadius)
            let pointerTop = CGPoint(x: bodyWidth, y: (size.height - pointerHeight) / 2)
            let pointerTip = CGPoint(x: size.width, y: size.height / 2)
            let pointerBottom = CGPoint(x: bodyWidth, y: (size.height + pointerHeight) / 2)
            let pointer = UIBezierPath()
            pointer.move(to: pointerTop)
            pointer.addLine(to: pointerTip)
            pointer.addLine(to: pointerBottom)
            pointer.close()
            path.append(pointer)
            return path
        }
    }
}

#endif
