import Foundation
import NIO

/// OSC client for sending messages to Ableton Live
public class AbletonOSCClient {
    private let config: NetworkConfig
    private let eventLoop: EventLoop
    private var channel: Channel?
    
    public init(config: NetworkConfig, eventLoop: EventLoop) {
        self.config = config
        self.eventLoop = eventLoop
    }
    
    /// Connect to Ableton OSC port
    public func connect() async throws {
        let bootstrap = DatagramBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        
        let address = try SocketAddress(ipAddress: config.abletonHost, port: Int(config.abletonOSCPort))
        self.channel = try await bootstrap.connect(to: address).get()
    }
    
    /// Disconnect from Ableton
    public func disconnect() async throws {
        try await channel?.close()
        self.channel = nil
    }
    
    /// Send an OSC message
    public func sendMessage(_ address: String, args: [OSCArgument]) async throws {
        guard let channel = channel else {
            throw OSCError.notConnected
        }
        
        let message = OSCMessage(address: address, arguments: args)
        let data = message.encode()
        
        var buffer = channel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        
        try await channel.writeAndFlush(buffer)
    }
    
    /// Query Ableton project structure
    public func queryProjectStructure() async throws -> AbletonProject {
        try await sendMessage("/ableton/query", args: [.string("project_structure")])
        // Note: Would receive response via listener in production
        throw OSCError.notImplemented
    }
}

/// OSC message structure
public struct OSCMessage {
    public let address: String
    public let arguments: [OSCArgument]
    
    public init(address: String, arguments: [OSCArgument]) {
        self.address = address
        self.arguments = arguments
    }
    
    /// Encode message to OSC binary format (simplified)
    public func encode() -> [UInt8] {
        var data: [UInt8] = []
        data.append(contentsOf: address.utf8)
        data.append(0) // null terminator
        // Simplified: In production, include full OSC type tags and argument encoding
        return data
    }
}

/// OSC argument types
public enum OSCArgument {
    case int(Int32)
    case float(Float)
    case string(String)
    case blob([UInt8])
    case true_
    case false_
    case null
}

/// OSC Client errors
public enum OSCError: Error {
    case notConnected
    case connectionFailed
    case messageEncodingFailed
    case timeoutExpired
    case notImplemented
}
