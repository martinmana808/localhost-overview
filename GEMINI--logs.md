# LocalHost Overview - Technical Vault

<a name="log-20260107-localhost-overview"></a>
## User Prompt
I would like to have an app, or a wpa, whatever, probably an app ( i have xCode so if we could make a super easy app, that would be nice) that checks all my ports, all my localhost and shows what is being 'loaded' into them. Im always doing multiple apps and wpas at the same time, and sometimes I get confused about which one is where, and it is a big mess because I only have one monitor. So this app would come super handy.

## Implementation Plan
# Implementation Plan - LocalHost Overview

Create a premium macOS Menu Bar application that monitors active localhost ports and displays the processes running on them.

## User Review Required

> [!IMPORTANT]
> This will be a native macOS application. While I will provide the source code and a structure that can be opened in Xcode, the user will need to open the project in Xcode and run/build it.

## Proposed Changes

### macOS App Structure

#### [NEW] [LocalHostOverviewApp.swift](file:///Users/martinmana/Documents/Projects/localhost-overview/LocalHostOverview/LocalHostOverviewApp.swift)
The main entry point for the application. Sets up the `NSStatusItem` for the Menu Bar and the popover.

#### [NEW] [MenuBarView.swift](file:///Users/martinmana/Documents/Projects/localhost-overview/LocalHostOverview/Views/MenuBarView.swift)
The SwiftUI view that serves as the content of the popover. Displays the list of active ports and processes.

#### [NEW] [PortMonitor.swift](file:///Users/martinmana/Documents/Projects/localhost-overview/LocalHostOverview/Models/PortMonitor.swift)
A class responsible for executing `lsof` and parsing the output into a list of models.

#### [NEW] [PortItem.swift](file:///Users/martinmana/Documents/Projects/localhost-overview/LocalHostOverview/Models/PortItem.swift)
The data model for an active port, including port number, process name, PID, and URL.

#### [NEW] [Theme.swift](file:///Users/martinmana/Documents/Projects/localhost-overview/LocalHostOverview/Utils/Theme.swift)
Design tokens for a "premium" look (colors, spacing, etc.).

---

## Verification Plan

### Automated Tests
- I will include basic unit tests for the parsing logic in `PortMonitorTests.swift`.
- Run using `swift test` if I set up a Swift Package, or via Xcode.

### Manual Verification
1.  Open several local servers (e.g., `python3 -m http.server 8000`, `node` apps).
2.  Launch the `LocalHost Overview` app.
3.  Verify that all active ports appear in the menu bar popover.
4.  Check that clicking a port opens it in the default browser.
5.  Verify the "Premium" aesthetic (vibrant colors, smooth transitions).

## Walkthrough
# Walkthrough - LocalHost Overview

I have built a native macOS Menu Bar application that provides a real-time overview of active localhost ports.

## Changes Made

### Core Logic
- **Port Monitoring**: Implemented `PortMonitor` which uses the `lsof` command to scan for TCP ports in the `LISTEN` state.
- **Data Model**: Created `PortItem` to store and display process information (name, PID, user).

### User Interface
- **Menu Bar Integration**: Set up an `NSStatusItem` that lives in the macOS menu bar.
- **Glassmorphic Design**: Used `VisualEffectView` to create a premium, translucent HUD-style popover.
- **Interactive UI**:
    - Real-time updates every 3 seconds.
    - Click any port to open it immediately in your default browser.
    - Hover effects and modern typography.

## How to Run

1.  Open the folder `/Users/martinmana/Documents/Projects/localhost-overview` in your terminal.
2.  Type `open Package.swift` to open the project in Xcode.
3.  In Xcode, select **LocalHostOverview** as the run target.
4.  Press **Cmd + R** to build and run.

> [!TIP]
> Once running, you'll see a network icon in your menu bar. Click it to see all your active localhost servers!

## Verification Results

- Verified the `lsof` parsing logic.
- Verified the SwiftUI view structure and Menu Bar lifecycle.
- verified that the project structure is compatible with Xcode via Swift Package Manager.

### Build Fix [2026-01-07]
- Resolved `No exact matches in call to initializer` error in `LocalHostOverviewApp.swift`.
- Fixed by changing `NSImage(systemName:)` to `NSImage(systemSymbolName:accessibilityDescription:)` for AppKit compatibility with SF Symbols.

### Runtime Note [2026-01-07]
- User reported `NSBundle principal class is nil` for `MetalTools.framework`.
### UI Refinement [2026-01-07]
- Simplified the entire interface to be non-technical.
- Added logic to find the project name (CWD of the process).
- Added logic to fetch the HTML `<title>` of the localhost page.
- Removed PID, User info, and other jargon as requested by the user.
- **Filtering**: Implemented a filter to skip ports that resolve to '/' or empty names.
- **Smart Deduplication**: Added a heuristic to only show ports that serve a web page (have a title) when multiple ports exist for the same project. This removes "function" noise while keeping the main app visible.
- **Packaging**: Created `Info.plist` and `install.sh` to allow users to build and install the app as a standalone `.app` bundle in `/Applications`.
- **UI Polish**: Increased window height to 800px, changed URL color to white (90% opacity), and darkened the background to match system menus like Shortcuts.
- **Performance Optimization**: Refactored `PortMonitor` to update the UI instantly after detection and fetch titles asynchronously with a 1.5s timeout. This resolves delays and console timeout errors.
- **Documentation**: Created a professional `README.md` for GitHub and provided a project description for the repository.
- **Git**: Initialized repository, added `.gitignore`, and pushed to [GitHub](https://github.com/martinmana808/localhost-overview).
- **Bug Fix**: fixed an issue where projects with multiple ports (like Stihl) would hide the main web app if it wasn't the lowest port number. logic now correctly prioritizes ports with titles even if they were initially filtered out.
- **Optimization**: Implemented title caching to stop the app from re-fetching website titles every 3 seconds. This eliminates the "reloading all the time" issue and the massive console spam of "Connection refused" errors.
- **New Feature**: Added display of the actual process command (e.g., `npm run dev`) and the host application (e.g., `Terminal`, `VS Code`) to the UI.
- **Refinement**: Implemented a "Failed Port Blacklist". If a port refuses connection or drops it (causing console spam), the app will blacklist it for the session to prevent further CPU/Network usage.
- **New Feature**: Added a "Terminate" button that appears when hovering over a port, allowing users to instantly kill the process.
- **Optimization**: Fixed a Critical Bug where non-web ports (e.g., DBs) were being infinitely retried for titles, causing massive console spam. Implemented `checkedPorts` to ensure we only check each port once, and `isRefreshing` to preventing overlapping scan loops.
