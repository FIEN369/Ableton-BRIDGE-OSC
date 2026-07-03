import Foundation

/// Network configuration for OSC and MCP communication
public struct NetworkConfig {
    public let abletonHost: String
    public let abletonOSCPort: UInt16
    public let logicHost: String
    public let logicMCPPort: UInt16
    public let timeout: TimeInterval
    public let retryAttempts: Int
    
    public init(
        abletonHost: String = ProcessInfo.processInfo.environment["ABLETON_HOST"] ?? "localhost",
        abletonOSCPort: UInt16 = UInt16(ProcessInfo.processInfo.environment["ABLETON_OSC_PORT"] ?? "11000") ?? 11000,
        logicHost: String = ProcessInfo.processInfo.environment["LOGIC_HOST"] ?? "localhost",
        logicMCPPort: UInt16 = UInt16(ProcessInfo.processInfo.environment["LOGIC_MCP_PORT"] ?? "9000") ?? 9000,
        timeout: TimeInterval = 30.0,
        retryAttempts: Int = 3
    ) {
        self.abletonHost = abletonHost
        self.abletonOSCPort = abletonOSCPort
        self.logicHost = logicHost
        self.logicMCPPort = logicMCPPort
        self.timeout = timeout
        self.retryAttempts = retryAttempts
    }
}

/// Network status tracking
public struct NetworkStatus {
    public let isConnected: Bool
    public let lastChecked: Date
    public let latency: TimeInterval
    
    public init(isConnected: Bool, lastChecked: Date = Date(), latency: TimeInterval = 0) {
        self.isConnected = isConnected
        self.lastChecked = lastChecked
        self.latency = latency
    }
}
