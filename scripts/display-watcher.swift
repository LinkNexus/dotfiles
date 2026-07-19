// Tiny daemon that reacts to display configuration changes (monitor
// plugged/unplugged, resolution change). CoreGraphics invokes the
// callback on every reconfiguration; on each settled change we run the
// command given on our command line -- see on-display-change for what
// actually happens.
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

func runHook() {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = hook
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

CGDisplayRegisterReconfigurationCallback({ _, flags, _ in
    if flags.contains(.beginConfigurationFlag) { return }
    scheduleHook()
}, nil)

// Reconcile once at startup so login lands in the right state, then
// wait for events
runHook()
RunLoop.main.run()
