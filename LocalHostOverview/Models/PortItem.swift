import Foundation

struct PortItem: Identifiable, Equatable {
    let id: String
    let port: Int
    let processName: String
    let pid: String
    let user: String
    var title: String?
    var projectName: String?
    
    var url: URL? {
        URL(string: "http://localhost:\(port)")
    }
    
    var displayName: String {
        projectName ?? processName
    }
}
