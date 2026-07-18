// Tiny daemon that reacts INSTANTLY to macOS light/dark switches.
//
// macOS broadcasts the distributed notification
// "AppleInterfaceThemeChangedNotification" the moment the appearance
// changes; observing it costs nothing (no polling). On each change we
// run the command given on our command line -- see on-theme-change
// for what actually happens.
//
// Compiled on demand by sketchybarrc (which also starts us at login):
//   swiftc -O -o theme-watcher theme-watcher.swift

import AppKit

let hook = Array(CommandLine.arguments.dropFirst())
guard !hook.isEmpty else {
    FileHandle.standardError.write(Data("usage: theme-watcher <command> [args...]\n".utf8))
    exit(1)
}

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil, queue: nil
) { _ in
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = hook
    try? p.run()
}

RunLoop.main.run()
