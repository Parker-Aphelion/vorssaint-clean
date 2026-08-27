// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreGraphics

/// Fixed-height pieces around the menu panel's scrolling content.
/// The stock combination keeps its historical height; once either optional
/// row is hidden, the panel contracts to the exact height of what remains.
enum MenuPanelChromeLayout {
    static let panelPadding: CGFloat = 12
    static let spacing: CGFloat = 12
    static let sectionNavigationHeight: CGFloat = 38
    static let metricNavigationHeight: CGFloat = 24
    static let headerHeight: CGFloat = 36
    static let footerHeight: CGFloat = 34

    private static let legacyChromeHeight: CGFloat = 180

    static func height(navigationHeight: CGFloat,
                       measuredBannerHeight: CGFloat?,
                       showsBrandMark: Bool,
                       showsBetaControls: Bool = false,
                       showsFooterActions: Bool) -> CGFloat {
        let bannerHeight = measuredBannerHeight.map { max($0, 48) + spacing } ?? 0

        // Keep the current panel dimensions for every existing user and fresh
        // install; tight sizing begins only after an appearance option changes.
        if showsBrandMark, showsFooterActions {
            return legacyChromeHeight + bannerHeight
        }

        var height = panelPadding * 2 + navigationHeight + spacing + bannerHeight
        if showsBrandMark || showsBetaControls {
            height += headerHeight + spacing
        }
        if showsFooterActions {
            height += footerHeight + spacing
        }
        return height
    }
}
