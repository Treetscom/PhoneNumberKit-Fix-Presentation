//
//  CountryCodePickerOptions.swift
//  PhoneNumberKit
//
//  Created by Joao Vitor Molinari on 19/09/23.
//  Copyright © 2021 Roy Marmelstein. All rights reserved.
//

#if os(iOS)
import UIKit

/// CountryCodePickerOptions object
/// - Parameter backgroundColor: UIColor used for background
/// - Parameter separatorColor: UIColor used for the separator line between cells
/// - Parameter textLabelColor: UIColor for the TextLabel (Country code)
/// - Parameter textLabelFont: UIFont for the TextLabel (Country code)
/// - Parameter detailTextLabelColor: UIColor for the DetailTextLabel (Country name)
/// - Parameter detailTextLabelFont: UIFont for the DetailTextLabel (Country name)
/// - Parameter tintColor: Default TintColor used on the view
/// - Parameter cellBackgroundColor: UIColor for the cell background
/// - Parameter cellBackgroundColorSelection: UIColor for the cell selectedBackgroundView
/// - Parameter cellLayoutMargins: Insets for the cell content
/// - Parameter rowHeight: Fixed height for every cell, excluding `rowSpacing`
/// - Parameter rowSpacing: Gap below every cell, in the background color, replacing the separator line
/// - Parameter sectionHeaderFont: UIFont for the alphabetical section headers and the section index bubble letter
/// - Parameter sectionHeaderColor: UIColor for the alphabetical section headers
/// - Parameter topSectionHeaderFont: UIFont for the "Current" and "Common" section headers
/// - Parameter topSectionHeaderColor: UIColor for the "Current" and "Common" section headers
/// - Parameter sectionHeaderHeight: Height of the alphabetical section header text, excluding `sectionHeaderLayoutMargins`
/// - Parameter topSectionHeaderHeight: Height of the "Current" and "Common" section header text, excluding `sectionHeaderLayoutMargins`
/// - Parameter sectionHeaderLayoutMargins: Insets for the section header text
/// - Parameter sectionFooterHeight: Height of the gap below every section
/// - Parameter sectionIndexColor: UIColor for the section index titles
/// - Parameter sectionIndexFont: UIFont for the section index titles; setting it swaps the system index for a letters-only one with a bubble
/// - Parameter sectionIndexBubbleTextColor: UIColor for the letter in the section index bubble
/// - Parameter sectionIndexBubbleBackgroundColor: UIColor for the section index bubble
/// - Parameter sectionIndexBubbleShadowColor: UIColor for the section index bubble shadow
public struct CountryCodePickerOptions {
    public init() { }

    public init(backgroundColor: UIColor? = nil,
                separatorColor: UIColor? = nil,
                textLabelColor: UIColor? = nil,
                textLabelFont: UIFont? = nil,
                detailTextLabelColor: UIColor? = nil,
                detailTextLabelFont: UIFont? = nil,
                tintColor: UIColor? = nil,
                cellBackgroundColor: UIColor? = nil,
                cellBackgroundColorSelection: UIColor? = nil,
                cellLayoutMargins: NSDirectionalEdgeInsets? = nil,
                rowHeight: CGFloat? = nil,
                rowSpacing: CGFloat? = nil,
                sectionHeaderFont: UIFont? = nil,
                sectionHeaderColor: UIColor? = nil,
                topSectionHeaderFont: UIFont? = nil,
                topSectionHeaderColor: UIColor? = nil,
                sectionHeaderHeight: CGFloat? = nil,
                topSectionHeaderHeight: CGFloat? = nil,
                sectionHeaderLayoutMargins: NSDirectionalEdgeInsets? = nil,
                sectionFooterHeight: CGFloat? = nil,
                sectionIndexColor: UIColor? = nil,
                sectionIndexFont: UIFont? = nil,
                sectionIndexBubbleTextColor: UIColor? = nil,
                sectionIndexBubbleBackgroundColor: UIColor? = nil,
                sectionIndexBubbleShadowColor: UIColor? = nil) {
        self.backgroundColor = backgroundColor
        self.separatorColor = separatorColor
        self.textLabelColor = textLabelColor
        self.textLabelFont = textLabelFont
        self.detailTextLabelColor = detailTextLabelColor
        self.detailTextLabelFont = detailTextLabelFont
        self.tintColor = tintColor
        self.cellBackgroundColor = cellBackgroundColor
        self.cellBackgroundColorSelection = cellBackgroundColorSelection
        self.cellLayoutMargins = cellLayoutMargins
        self.rowHeight = rowHeight
        self.rowSpacing = rowSpacing
        self.sectionHeaderFont = sectionHeaderFont
        self.sectionHeaderColor = sectionHeaderColor
        self.topSectionHeaderFont = topSectionHeaderFont
        self.topSectionHeaderColor = topSectionHeaderColor
        self.sectionHeaderHeight = sectionHeaderHeight
        self.topSectionHeaderHeight = topSectionHeaderHeight
        self.sectionHeaderLayoutMargins = sectionHeaderLayoutMargins
        self.sectionFooterHeight = sectionFooterHeight
        self.sectionIndexColor = sectionIndexColor
        self.sectionIndexFont = sectionIndexFont
        self.sectionIndexBubbleTextColor = sectionIndexBubbleTextColor
        self.sectionIndexBubbleBackgroundColor = sectionIndexBubbleBackgroundColor
        self.sectionIndexBubbleShadowColor = sectionIndexBubbleShadowColor
    }

    public var backgroundColor: UIColor?
    public var separatorColor: UIColor?
    public var textLabelColor: UIColor?
    public var textLabelFont: UIFont?
    public var detailTextLabelColor: UIColor?
    public var detailTextLabelFont: UIFont?
    public var tintColor: UIColor?
    public var cellBackgroundColor: UIColor?
    public var cellBackgroundColorSelection: UIColor?
    public var cellLayoutMargins: NSDirectionalEdgeInsets?
    public var rowHeight: CGFloat?
    public var rowSpacing: CGFloat?
    public var sectionHeaderFont: UIFont?
    public var sectionHeaderColor: UIColor?
    public var topSectionHeaderFont: UIFont?
    public var topSectionHeaderColor: UIColor?
    public var sectionHeaderHeight: CGFloat?
    public var topSectionHeaderHeight: CGFloat?
    public var sectionHeaderLayoutMargins: NSDirectionalEdgeInsets?
    public var sectionFooterHeight: CGFloat?
    public var sectionIndexColor: UIColor?
    public var sectionIndexFont: UIFont?
    public var sectionIndexBubbleTextColor: UIColor?
    public var sectionIndexBubbleBackgroundColor: UIColor?
    public var sectionIndexBubbleShadowColor: UIColor?
}
#endif
