// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Stable identities for the actions in the menu bar icon's right-click menu.
/// Case order is the default menu order; raw values are persisted and must not
/// be renamed after release.
enum StatusItemContextMenuItemID: String, CaseIterable, Identifiable {
    case keepAwakeToggle, activateFor, cleaningMode
    case settings, about, uninstaller, shelf, checkForUpdates
    case quit

    var id: String { rawValue }

    /// Settings and Quit remain available as the reliable ways to configure or
    /// leave the app, even when every optional action is hidden.
    var canHide: Bool {
        self != .settings && self != .quit
    }

    var group: StatusItemContextMenuGroup {
        switch self {
        case .keepAwakeToggle, .activateFor, .cleaningMode:
            return .actions
        case .settings, .about, .uninstaller, .shelf, .checkForUpdates:
            return .application
        case .quit:
            return .termination
        }
    }

    /// Hub availability controls whether feature-specific actions participate
    /// in either the menu or its editor. Runtime state can narrow this further:
    /// Activate for is omitted while Keep Awake is already active, and Shelf
    /// additionally requires its own enable preference.
    var isAvailable: Bool {
        switch self {
        case .keepAwakeToggle, .activateFor:
            return AppFeature.keepAwake.isAvailable
        case .cleaningMode:
            return AppFeature.cleaningMode.isAvailable
        case .uninstaller:
            return AppFeature.uninstaller.isAvailable
        case .shelf:
            return AppFeature.shelf.isAvailable
        case .settings, .about, .checkForUpdates, .quit:
            return true
        }
    }

    /// Stable editor titles. The live Keep Awake menu item may replace its
    /// title with the current Enable/Disable wording when the menu opens.
    func title(_ strings: Strings) -> String {
        switch self {
        case .keepAwakeToggle: return strings.keepAwakeTitle
        case .activateFor: return strings.menuActivateFor
        case .cleaningMode: return strings.cleaningMenuItem
        case .settings: return strings.menuSettings
        case .about: return strings.menuAbout
        case .uninstaller: return strings.uninstallerMenuItem
        case .shelf: return strings.shelfMenuItem
        case .checkForUpdates: return strings.menuCheckUpdates
        case .quit: return strings.menuQuit
        }
    }
}

/// Semantic menu groups. Dividers are derived after unavailable and hidden
/// items are removed, preventing leading, trailing or adjacent separators.
enum StatusItemContextMenuGroup {
    case actions, application, termination
}

/// Persistence and normalization for the right-click menu. Missing or corrupt
/// entries never make an action disappear: known saved IDs come first and any
/// newly introduced IDs are appended in canonical order.
enum StatusItemContextMenuLayout {
    static let defaultOrder = StatusItemContextMenuItemID.allCases

    static func order(defaults: UserDefaults = .standard) -> [StatusItemContextMenuItemID] {
        let raw = defaults.string(forKey: DefaultsKey.statusItemContextMenuOrder) ?? ""
        var seen = Set<StatusItemContextMenuItemID>()
        var result = raw.split(separator: ",")
            .compactMap { StatusItemContextMenuItemID(rawValue: String($0)) }
            .filter { seen.insert($0).inserted }
        result.append(contentsOf: defaultOrder.filter { seen.insert($0).inserted })
        return result
    }

    static func setOrder(_ items: [StatusItemContextMenuItemID],
                         defaults: UserDefaults = .standard) {
        var seen = Set<StatusItemContextMenuItemID>()
        var normalized = items.filter { seen.insert($0).inserted }
        normalized.append(contentsOf: defaultOrder.filter { seen.insert($0).inserted })
        defaults.set(normalized.map(\.rawValue).joined(separator: ","),
                     forKey: DefaultsKey.statusItemContextMenuOrder)
    }

    static func hiddenItems(defaults: UserDefaults = .standard) -> Set<StatusItemContextMenuItemID> {
        let raw = defaults.string(forKey: DefaultsKey.statusItemContextMenuHiddenItems) ?? ""
        return Set(raw.split(separator: ",")
            .compactMap { StatusItemContextMenuItemID(rawValue: String($0)) }
            .filter(\.canHide))
    }

    static func setHiddenItems(_ items: Set<StatusItemContextMenuItemID>,
                               defaults: UserDefaults = .standard) {
        let normalized = defaultOrder.filter { $0.canHide && items.contains($0) }
        defaults.set(normalized.map(\.rawValue).joined(separator: ","),
                     forKey: DefaultsKey.statusItemContextMenuHiddenItems)
    }

    static func isShown(_ item: StatusItemContextMenuItemID,
                        defaults: UserDefaults = .standard) -> Bool {
        !hiddenItems(defaults: defaults).contains(item)
    }

    /// Applies the user's visibility choices. The menu renderer separately
    /// removes commands that are unavailable in the current runtime state.
    static func visibleOrder(defaults: UserDefaults = .standard) -> [StatusItemContextMenuItemID] {
        let hidden = hiddenItems(defaults: defaults)
        return order(defaults: defaults).filter { !hidden.contains($0) }
    }

    /// Zero-based indexes before which AppKit should insert a separator.
    /// Transitions are computed from the final visible order so no empty group
    /// can leave an orphaned divider behind.
    static func separatorIndexes(for items: [StatusItemContextMenuItemID]) -> IndexSet {
        guard let first = items.first else { return [] }
        var indexes = IndexSet()
        var previousGroup = first.group
        for index in items.indices.dropFirst() {
            let group = items[index].group
            if group != previousGroup {
                indexes.insert(index)
            }
            previousGroup = group
        }
        return indexes
    }
}
