//
// LilySwift Library Project
//
// Copyright (c) Watanabe-Denki, Inc. and Kengo Watanabe.
//   https://wdkk.co.jp/
//
// This software is released under the MIT License.
//   https://opensource.org/licenses/mit-license.php
//

#if os(macOS)

import AppKit

extension NSToolbar {
    
    class GenericDelegate: NSObject, NSToolbarDelegate {
        var selectableItemIdentifiers: [NSToolbarItem.Identifier] = []
        var defaultItemIdentifiers: [NSToolbarItem.Identifier] = []
        var allowedItemIdentifiers: [NSToolbarItem.Identifier] = []
        
        var eventHandler: ((LifeCycle) -> Void)?
        var makeItemCallback: ((_ itemIdentifier: NSToolbarItem.Identifier, _ willBeInserted: Bool) -> NSToolbarItem?)?
    }
}

extension NSToolbar.GenericDelegate {
    enum LifeCycle {
        case willAddItem(item: NSToolbarItem, index: Int)
        case didRemoveItem(item: NSToolbarItem)
    }
}

extension NSToolbar.GenericDelegate {
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        return makeItemCallback?(itemIdentifier, flag)
    }
    
    func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        return defaultItemIdentifiers
    }
    
    func toolbarAllowedItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        return allowedItemIdentifiers
    }
    
    func toolbarSelectableItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        return selectableItemIdentifiers
    }
    
    func toolbarWillAddItem(_ notification: Notification) {
        if let toolbarItem = notification.userInfo?["item"] as? NSToolbarItem,
            let index = notification.userInfo?["newIndex"] as? Int {
            eventHandler?(.willAddItem(item: toolbarItem, index: index))
        }
    }
    
    func toolbarDidRemoveItem(_ notification: Notification) {
        if let toolbarItem = notification.userInfo?["item"] as? NSToolbarItem {
            eventHandler?(.didRemoveItem(item: toolbarItem))
        }
    }
}

#endif
