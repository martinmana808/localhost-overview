import Foundation
import Combine

class PortMonitor: ObservableObject {
    @Published var activePorts: [PortItem] = []
    private var timer: AnyCancellable?
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        refreshPorts()
        timer = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshPorts()
            }
    }
    
    func refreshPorts() {
        DispatchQueue.global(qos: .background).async {
            var ports = self.scanPorts()
            
            // 1. Fast enrichment with project names
            for i in 0..<ports.count {
                ports[i].projectName = self.getProjectName(for: ports[i].pid)
            }
            
            // 2. Update UI with initial list immediately
            self.updateUI(with: ports)
            
            // 3. Fetch titles asynchronously (one by one) and update UI as they arrive
            for i in 0..<ports.count {
                guard let url = ports[i].url else { continue }
                let portId = ports[i].id
                
                self.fetchTitle(for: url) { [weak self] title in
                    guard let self = self, let title = title else { return }
                    DispatchQueue.main.async {
                        if let index = self.activePorts.firstIndex(where: { $0.id == portId }) {
                            self.activePorts[index].title = title
                            // Re-filter to handle deduplication logic once we have a title
                            self.refilterUI()
                        }
                    }
                }
            }
        }
    }
    
    private func updateUI(with ports: [PortItem]) {
        let filtered = self.getFilteredPorts(from: ports)
        DispatchQueue.main.async {
            if self.activePorts != filtered {
                self.activePorts = filtered
            }
        }
    }
    
    private func refilterUI() {
        let filtered = self.getFilteredPorts(from: self.activePorts)
        if self.activePorts != filtered {
            self.activePorts = filtered
        }
    }
    
    private func getFilteredPorts(from ports: [PortItem]) -> [PortItem] {
        // 1. Filter out noise (root or empty)
        let basicFiltered = ports.filter { $0.projectName != "/" && $0.projectName != "" && $0.projectName != nil }
        
        // 2. Group by project name
        let grouped = Dictionary(grouping: basicFiltered, by: { $0.projectName ?? "unknown" })
        
        var finalPorts: [PortItem] = []
        
        for (_, projectPorts) in grouped {
            // 3. Heuristic: If any port in the project has a title, prioritize it.
            let withTitles = projectPorts.filter { $0.title != nil }
            
            if !withTitles.isEmpty {
                finalPorts.append(contentsOf: withTitles)
            } else {
                // 4. If no ports have titles, show the lowest port
                if let lowestPort = projectPorts.min(by: { $0.port < $1.port }) {
                    finalPorts.append(lowestPort)
                }
            }
        }
        
        return finalPorts.sorted(by: { $0.projectName ?? "" < $1.projectName ?? "" })
    }
    
    private func scanPorts() -> [PortItem] {
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-iTCP", "-sTCP:LISTEN", "-P", "-n"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            return parseLsofOutput(output)
        } catch {
            print("Error running lsof: \(error)")
            return []
        }
    }
    
    private func getProjectName(for pid: String) -> String? {
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-a", "-d", "cwd", "-p", pid, "-Fn"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return nil }
            
            // Output format: p<PID>\nn<CWD>
            let lines = output.components(separatedBy: .newlines)
            for line in lines {
                if line.hasPrefix("n") {
                    let path = String(line.dropFirst())
                    return URL(fileURLWithPath: path).lastPathComponent
                }
            }
        } catch {
            return nil
        }
        return nil
    }
    
    private func fetchTitle(for url: URL, completion: @escaping (String?) -> Void) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.5 // Fast timeout for local servers
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }
            
            if let titleRange = html.range(of: "<title[^>]*>(.*?)</title>", options: [.regularExpression, .caseInsensitive]) {
                let titleWithTags = html[titleRange]
                if let startRange = titleWithTags.range(of: ">"),
                   let endRange = titleWithTags.range(of: "</", options: .backwards) {
                    let title = String(titleWithTags[startRange.upperBound..<endRange.lowerBound])
                    completion(title.trimmingCharacters(in: .whitespacesAndNewlines))
                    return
                }
            }
            completion(nil)
        }
        task.resume()
    }
    
    private func parseLsofOutput(_ output: String) -> [PortItem] {
        let lines = output.components(separatedBy: .newlines)
        var items: [PortItem] = []
        
        // Skip header
        for line in lines.dropFirst() {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard parts.count >= 9 else { continue }
            
            let processName = parts[0]
            let pid = parts[1]
            let user = parts[2]
            let namePart = parts[8]
            
            if let portString = namePart.components(separatedBy: ":").last,
               let port = Int(portString) {
                
                if !items.contains(where: { $0.port == port }) {
                    let item = PortItem(
                        id: "\(pid)-\(port)",
                        port: port,
                        processName: processName,
                        pid: pid,
                        user: user,
                        title: nil,
                        projectName: nil
                    )
                    items.append(item)
                }
            }
        }
        
        return items.sorted(by: { $0.port < $1.port })
    }
}
