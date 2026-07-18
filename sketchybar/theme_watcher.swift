// Tiny daemon that reacts INSTANTLY to macOS light/dark switches.
//
// macOS broadcasts the distributed notification
// "AppleInterfaceThemeChangedNotification" the moment the appearance
// changes; observing it costs nothing (no polling). On each change we
// re-trigger the workspace rebuild, which re-reads the theme.
//
// Compiled on demand by sketchybarrc:
//   swiftc -O -o theme_watcher theme_watcher.swift

import AppKit

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil, queue: nil
) { _ in
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = ["sketchybar", "--trigger", "aerospace_workspace_change"]
    try? p.run()
}

RunLoop.main.run()
