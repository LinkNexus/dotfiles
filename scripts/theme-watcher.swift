// Tiny daemon that reacts to macOS light/dark switches.
//
// Two detection paths, because the distributed notification proved
// unreliable for a background launchd agent (same failure mode
// scripts/display-watcher.swift hit with its CG reconfiguration
// callback): the AppleInterfaceThemeChangedNotification for instant
// reaction, plus a 30s poll of AppleInterfaceStyle as a safety net --
// this matters most for the automatic light/dark schedule, which
// flips while the Mac is asleep and can fire its notification in a
// narrow window right at wake that a napped process misses. On each
// change we run the command given on our command line -- see
// on-theme-change for what actually happens.
//
// Compiled on demand by scripts/start-theme-watcher:
//   swiftc -O -o theme-watcher theme-watcher.swift

import AppKit

let hook = Array(CommandLine.arguments.dropFirst())
guard !hook.isEmpty else {
    FileHandle.standardError.write(Data("usage: theme-watcher <command> [args...]\n".utf8))
    exit(1)
}

// Opt out of App Nap: macOS suspends idle background processes, which
// can silently stop notification delivery to our run loop
let activity = ProcessInfo.processInfo.beginActivity(
    options: .userInitiatedAllowingIdleSystemSleep,
    reason: "reacting to macOS light/dark switches")
_ = activity

func currentStyle() -> String {
    UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
}

func runHook() {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = hook
    try? p.run()
}

var lastStyle = currentStyle()

// Path 1: distributed notification, for instant reaction while awake
DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil, queue: nil
) { _ in
    lastStyle = currentStyle()
    runHook()
}

// Path 2: poll. Only fires the hook when the style actually changed,
// so it is silent in steady state; catches anything path 1 missed
Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
    let style = currentStyle()
    if style != lastStyle {
        lastStyle = style
        runHook()
    }
}

RunLoop.main.run()
