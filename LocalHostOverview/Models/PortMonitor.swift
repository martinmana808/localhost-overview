import Foundation
import Combine

class PortMonitor: ObservableObject {
    @Published var activePorts: [PortItem] = []
    private var allPorts: [PortItem] = []
    private var failedPorts: Set<Int> = [] 
    private var checkedPorts: Set<Int> = [] // Ports we have already tried to fetch title for (success or fail)
    private var isRefreshing = false
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
        // Prevent overlapping refreshes
        guard !isRefreshing else { return }
        isRefreshing = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // 1. Scan Listeners (Existing Logic)
            var activeListeners = self.fetchListeners()
            
            // 2. Scan Browser Connections (New Logic)
            let browserPorts = self.fetchBrowserPorts()
            
            // 3. Fast enrichment with project names
            for i in 0..<activeListeners.count {
                activeListeners[i].projectName = self.getProjectName(for: activeListeners[i].pid)
            }
            
            // 4. Merge Data
            // We want to keep all listeners.
            // AND we want to ADD any port that is connected to by a browser, even if it wasn't a listener (or was hidden).
            
            var mergedPorts: [PortItem] = activeListeners
            
            // Mark listeners as browser connected if applicable
            for i in 0..<mergedPorts.count {
                if browserPorts.contains(mergedPorts[i].port) {
                    mergedPorts[i].isBrowserConnected = true
                }
            }
            
            // Find browser ports that are NOT in the listener list
            let existingPortNumbers = Set(mergedPorts.map { $0.port })
            for port in browserPorts {
                if !existingPortNumbers.contains(port) {
                    // This is a "Hidden" port!
                    // We don't know the PID or Project Name easily (since we didn't find a listener for it),
                    // but we know it's active.
                    let item = PortItem(
                        id: "browser-connected-\(port)",
                        port: port,
                        processName: "Unknown",
                        pid: "-1",
                        user: "Unknown",
                        title: nil,
                        command: nil,
                        hostApp: nil,
                        projectName: "External/System",
                        isBrowserConnected: true
                    )
                    mergedPorts.append(item)
                }
            }
            
            DispatchQueue.main.async {
                self.isRefreshing = false // Release lock
                
                var finalPorts = mergedPorts
                
                // 5. Merge with existing data (PRESERVE TITLES)
                for i in 0..<finalPorts.count {
                    if let existing = self.allPorts.first(where: { $0.port == finalPorts[i].port }) {
                        // Inherit title if we have it
                        finalPorts[i].title = existing.title
                    }
                }
                
                // 6. Update source of truth
                self.allPorts = finalPorts
                self.updateUI()
                
                // 7. Async Fetching Loop
                for i in 0..<self.allPorts.count {
                    let portItem = self.allPorts[i]
                    let port = portItem.port
                    
                    // Skip if:
                    // 1. We already have a title
                    // 2. We already FAILED this port (failedPorts)
                    // 3. We already CHECKED this port and found nothing (checkedPorts)
                    if portItem.title == nil,
                       let url = portItem.url,
                       !self.failedPorts.contains(port),
                       !self.checkedPorts.contains(port) {
                        
                        self.checkedPorts.insert(port)
                        
                        self.fetchTitle(for: url, port: port) { [weak self] title in
                            guard let self = self else { return }
                            
                            if let title = title {
                                DispatchQueue.main.async {
                                    // Update ALL ports with this number (could be 1)
                                    if let index = self.allPorts.firstIndex(where: { $0.port == port }) {
                                        self.allPorts[index].title = title
                                        self.updateUI()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateUI() {
        let filtered = self.getFilteredPorts(from: self.allPorts)
        if self.activePorts != filtered {
            self.activePorts = filtered
        }
    }
    
    private func getFilteredPorts(from ports: [PortItem]) -> [PortItem] {
        // 1. Filter out noise (root or empty) - UNLESS IT IS BROWSER CONNECTED
        let basicFiltered = ports.filter { item in
            if item.isBrowserConnected { return true }
            return item.projectName != "/" && item.projectName != "" && item.projectName != nil
        }
        
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
                // BUT PREFER BROWSER CONNECTED ONE
                
                if let browserConnected = projectPorts.first(where: { $0.isBrowserConnected }) {
                    finalPorts.append(browserConnected)
                } else if let lowestPort = projectPorts.min(by: { $0.port < $1.port }) {
                    finalPorts.append(lowestPort)
                }
            }
        }
        
        // Sort alphabetically by project name, then by port number
        return finalPorts.sorted {
            if $0.projectName == $1.projectName {
                return $0.port < $1.port
            }
            return $0.projectName ?? "" < $1.projectName ?? ""
        }
    }
    
    private func fetchListeners() -> [PortItem] {
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
            print("Error running lsof (listeners): \(error)")
            return []
        }
    }
    
    private func fetchBrowserPorts() -> Set<Int> {
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-i", "@localhost", "-P", "-n"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            var browserPorts: Set<Int> = []
            let lines = output.components(separatedBy: .newlines)
            
            // Expected line format:
            // COMMAND   PID   USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
            // Google    38799 user   39u  IPv4 0x123...      0t0  TCP localhost:56789->localhost:3000 (ESTABLISHED)
            
            let browserNames = ["browser", "google", "chrome", "arc", "safari", "firefox", "webkit"]
            
            for line in lines.dropFirst() {
                let lowerLine = line.lowercased()
                
                // 1. Check if it's a browser process
                let isBrowser = browserNames.contains { lowerLine.contains($0) }
                if !isBrowser { continue }
                
                // 2. Parse the connection "localhost:XXX->localhost:YYY"
                // We care about YYY (the destination port)
                
                if let arrowRange = line.range(of: "->") {
                     let destinationPart = String(line[arrowRange.upperBound...])
                     // destinationPart should look like "localhost:3000 (ESTABLISHED)"
                     
                     if let portString = destinationPart.split(separator: ":").last?.split(separator: " ").first,
                        let port = Int(portString) {
                         browserPorts.insert(port)
                     }
                }
            }
            
            return browserPorts
        } catch {
            print("Error running lsof (browser): \(error)")
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
    
    private func fetchTitle(for url: URL, port: Int, completion: @escaping (String?) -> Void) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.0 // Very fast timeout
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if error != nil {
                // Network error (refused, timeout, lost connection) -> Blacklist this port
                DispatchQueue.main.async {
                    self?.failedPorts.insert(port)
                }
                completion(nil)
                return
            }
            
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
    
    func killProcess(pid: String) {
        guard let pidInt = Int32(pid) else { return }
        kill(pidInt, SIGTERM)
        
        // Optimistically remove from UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.activePorts.removeAll { $0.pid == pid }
            self.allPorts.removeAll { $0.pid == pid }
            
            // Re-trigger refresh to confirm
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.5) {
                self.refreshPorts()
            }
        }
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
                        command: nil,
                        hostApp: nil,
                        projectName: nil
                    )
                    items.append(item)
                }
            }
        }
        
        return items.sorted(by: { $0.port < $1.port })
    }
}
