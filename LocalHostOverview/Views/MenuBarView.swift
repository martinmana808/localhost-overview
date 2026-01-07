import SwiftUI

struct MenuBarView: View {
    @StateObject private var monitor = PortMonitor()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            if monitor.activePorts.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(monitor.activePorts) { item in
                            PortRow(item: item)
                        }
                    }
                    .padding(12)
                }
            }
            
            Divider().opacity(0.1)
            footer
        }
        .frame(width: 320, height: 800)
        .background(
            ZStack {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                Color.black.opacity(0.15) // Subtle dark overlay to match Shortcuts look
            }
            .ignoresSafeArea()
        )
    }
    
    private var header: some View {
        HStack {
            Text("Active Projects")
                .font(.system(size: 14, weight: .bold, design: .rounded))
            Spacer()
            Button(action: {
                monitor.refreshPorts()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No projects running")
                .font(.system(size: 13, weight: .medium))
            Text("Start a dev server to see it here.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var footer: some View {
        HStack {
            Text("\(monitor.activePorts.count) Ports")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer()
            Button("Quit App") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 10))
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(12)
    }
}

struct PortRow: View {
    let item: PortItem
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            if let url = item.url {
                NSWorkspace.shared.open(url)
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "globe")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.9))
                    Text(item.url?.absoluteString ?? "http://localhost:\(item.port)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                }
                
                if let title = item.title {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                } else if let projectName = item.projectName {
                    Text(projectName)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                } else {
                    Text(item.processName)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
