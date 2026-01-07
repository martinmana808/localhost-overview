import Foundation

struct PortItem: Identifiable, Equatable {
    let id: String
    let port: Int
    let processName: String
    let pid: String
    let user: String
    var title: String?
    var command: String? // e.g. "npm run dev"
    var hostApp: String? // e.g. "Terminal", "VSCode"
    var projectName: String?
    var isBrowserConnected: Bool = false
    
    var url: URL? {
        URL(string: "http://localhost:\(port)")
    }
    
    var displayName: String {
        if let title = title, !title.isEmpty {
            return title
        }
        if let project = projectName {
            return project
        }
        return "Port \(port)"
    }
}
