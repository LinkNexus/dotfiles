// Tiny daemon that reacts to display configuration changes (monitor
// plugged/unplugged, resolution change, displays waking from sleep).
// CoreGraphics invokes the callback on every reconfiguration; on each
// settled change we run the command given on our command line -- see
// on-display-change for what actually happens.
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

// extraArgs lets the startup run announce itself to the hook, which
// waits for login to settle before acting
func runHook(_ extraArgs: [String] = []) {
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

// If registration fails (e.g. launchd started us before the window
// server session was ready), exit nonzero so KeepAlive relaunches us
// until it sticks -- silently continuing would leave a deaf daemon
let err = CGDisplayRegisterReconfigurationCallback({ _, flags, _ in
    if flags.contains(.beginConfigurationFlag) { return }
    scheduleHook()
}, nil)
guard err == .success else {
    FileHandle.standardError.write(Data("display-watcher: callback registration failed (\(err.rawValue)), retrying via launchd\n".utf8))
    exit(1)
}

// Reconcile once at startup so login lands in the right state, then
// wait for events
runHook(["startup"])
RunLoop.main.run()
