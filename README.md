# 🌐 LocalHost Overview

**Stop guessing what's running on your ports.**

LocalHost Overview is a premium macOS menu bar application designed for developers who juggle multiple local projects. It provides a clean, project-focused view of all active localhost ports, identifying them by folder name and website title while filtering out technical noise.

![App Icon](./app_icon.png)

## ✨ Features

- **📂 Project Identification**: Automatically detects the project folder name (e.g., "F925", "Frello") for every active port.
- **🏷️ Website Titles**: Fetches and displays the actual `<title>` of your sites in real-time.
- **🧼 Smart Deduplication**: Intelligent heuristic hides internal "function" ports and background processes, showing only what matters to you.
- **⚡ Performance First**: Instant UI updates with background title fetching and aggressive timeouts to ensure a smooth experience.
- **🎨 Premium Aesthetics**: A native macOS experience with a glassmorphic, Shortcuts-style translucent background and high-contrast typography.
- **🚀 One-Tap Navigation**: Click any project to open it immediately in your default browser.
- **📦 Zero Configuration**: No setup required. Just run it, and it finds your work.

## 🚀 Quick Install

You can build and install the app directly into your `/Applications` folder with a single command:

```bash
sh install.sh
```

This will compile the high-performance release version and move it to your system.

## 🛠️ Usage

1. Launch **LocalHost Overview** from your Applications folder.
2. Look for the network icon in your macOS Menu Bar.
3. Click to see all your active projects.
4. Hit the 🔄 icon for a manual refresh, or let the auto-refresh do its magic every few seconds.

## 🤝 Sharing with Others

To share the app with a friend:
1. Right-click **LocalHost Overview** in your Applications folder and select **Compress**.
2. Send them the `.zip`.

*Note: Since the app is unsigned, your friend should right-click and choose **Open** the first time they launch it to bypass the macOS security warning.*

---

*Built with SwiftUI & ❤️ for developers.*
