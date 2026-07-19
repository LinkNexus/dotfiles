// Tiny daemon that reacts to display configuration changes (monitor
// plugged/unplugged, resolution change, displays waking from sleep).
// Two detection paths, because CG callbacks proved unreliable for a
// background launchd agent: the CoreGraphics reconfiguration callback
// for instant reaction, plus a 10s poll of the widest screen as a
// safety net. On each settled change we run the command given on our
// command line -- see on-display-change for what actually happens.
//
// Compiled on demand by scripts/start-display-watcher:
//   swiftc -O -o display-watcher display-watcher.swift

import CoreGraphics
import Foundation

let hook = Array(CommandLine.arguments.dropFirst())
guard !hook.isEmpty else {
    FileHandle.standardError.write(Data("usage: display-watcher <command> [args...]\n".utf8))
    exit(1)
}

// Opt out of App Nap: macOS suspends idle background processes, which
// froze our run loop -- callbacks and timers were never delivered
let activity = ProcessInfo.processInfo.beginActivity(
    options: .userInitiatedAllowingIdleSystemSleep,
    reason: "reacting to display connect/disconnect")
_ = activity

// Widest active screen in points; -1 = could not measure (transient
// API failure -- never treat as "no screens"), 0 = truly no screens
func currentMaxWidth() -> CGFloat {
    var ids = [CGDirectDisplayID](repeating: 0, count: 16)
    var count: UInt32 = 0
    guard CGGetActiveDisplayList(16, &ids, &count) == .success else { return -1 }
    var maxWidth: CGFloat = 0
    for i in 0..<Int(count) {
        maxWidth = max(maxWidth, CGDisplayBounds(ids[i]).width)
    }
    return maxWidth
}

var lastWidth: CGFloat = -1

// extraArgs lets the startup run announce itself to the hook, which
// waits for login to settle before acting
func runHook(_ extraArgs: [String] = []) {
    lastWidth = currentMaxWidth()
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = hook + extraArgs
    try? p.run()
}

// One plug/unplug produces a burst of callbacks (one per display, plus
// begin/end passes); coalesce and act once things have settled
var pending: DispatchWorkItem?
func scheduleHook() {
    pending?.cancel()
    let work = DispatchWorkItem { runHook() }
    pending = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
}

// Path 1: CG reconfiguration callback. If registration fails (e.g.
// launchd started us before the window server session was ready),
// exit nonzero so KeepAlive relaunches us until it sticks
let err = CGDisplayRegisterReconfigurationCallback({ _, flags, _ in
    if flags.contains(.beginConfigurationFlag) { return }
    scheduleHook()
}, nil)
guard err == .success else {
    FileHandle.standardError.write(Data("display-watcher: callback registration failed (\(err.rawValue)), retrying via launchd\n".utf8))
    exit(1)
}

// Path 2: poll. Only fires the hook when the widest-screen width
// actually changes, so it is silent in steady state
Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
    let width = currentMaxWidth()
    if width >= 0 && width != lastWidth {
        scheduleHook()
    }
}

// Reconcile once at startup so login lands in the right state, then
// wait for events
runHook(["startup"])
RunLoop.main.run()
