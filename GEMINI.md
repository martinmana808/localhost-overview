# Project Brain - LocalHost Overview

## Tech Stack
- SwiftUI (macOS)
- Native Menu Bar Integration
- Shell Integration (`lsof`)

## History
### [2026-01-07] LocalHost Overview App Implementation | [Technical Details](./GEMINI--logs.md#log-20260107-localhost-overview)
- Implemented a native macOS Menu Bar app using SwiftUI.
- Created a `PortMonitor` service using `lsof` to detect active localhost ports.
- Designed a premium glassmorphic UI for real-time process monitoring.
- **Refinement**: Simplified UI to focus on Project Names and Website Titles, removing technical details (PID, User).
- **Automation**: Added automatic detection of project directories and HTML title fetching.
- **Filtering**: Added logic to hide noise-producing ports (e.g., from the root directory `/`).
- **Deduplication**: Implemented smart filtering to remove non-web "function" ports when the main app is detected.
- **Performance**: Optimized refreshing logic to be instant and added request timeouts.
- **UI Polish**: Increased window height to 800px, darkened background, and improved contrast.
- **Optimization**: Fixed critical console spam/cpu usage by implementing a "Failed Port Blacklist" and preventing retry loops on non-web ports.
- **Feature**: Added "Terminate Process" button (available on hover) to kill active servers directly from the menu.
- **Git**: Published source code to GitHub with a comprehensive `README.md`.
- Fixed AppKit SF Symbol initialization error.

- **2026-01-07**: Initial Project setup and manifesto creation.
