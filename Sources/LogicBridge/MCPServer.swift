import Foundation
import NIO

/// MCP (Model Context Protocol) server running on Logic Desktop
public class LogicMCPServer {
    private let config: NetworkConfig
    private let eventLoop: EventLoop
    private var channel: ServerSocketChannel?
    
    public init(config: NetworkConfig, eventLoop: EventLoop) {
        self.config = config
        self.eventLoop = eventLoop
    }
    
    /// Start the MCP server
    public func start() async throws {
        let bootstrap = ServerBootstrap(group: eventLoop)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.addHandler(MCPMessageHandler(server: self))
            }
        
        let address = try SocketAddress(ipAddress: config.logicHost, port: Int(config.logicMCPPort))
        self.channel = try await bootstrap.bind(to: address).get()
        print("MCP Server started on \(config.logicHost):\(config.logicMCPPort)")
    }
    
    /// Stop the MCP server
    public func stop() async throws {
        try await channel?.close()
        self.channel = nil
    }
}

/// Handler for MCP messages
class MCPMessageHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    private let server: LogicMCPServer
    
    init(server: LogicMCPServer) {
        self.server = server
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = self.unwrapInboundIn(data)
        
        // Parse incoming JSON-RPC message
        if let jsonData = buffer.readData(length: buffer.readableBytes),
           let request = try? JSONDecoder().decode(MCPRequest.self, from: jsonData) {
            
            handleRequest(request, context: context)
        }
    }
    
    private func handleRequest(_ request: MCPRequest, context: ChannelHandlerContext) {
        // Route to appropriate handler
        switch request.method {
        case "project/create":
            handleCreateProject(request, context: context)
        case "import/audio":
            handleImportAudio(request, context: context)
        case "import/midi":
            handleImportMIDI(request, context: context)
        case "mixer/apply":
            handleApplyMixer(request, context: context)
        default:
            sendError("Unknown method: \(request.method)", context: context)
        }
    }
    
    private func handleCreateProject(_ request: MCPRequest, context: ChannelHandlerContext) {
        // Create new Logic project
        // TODO: Implement AppleScript execution
        let response = MCPResponse(id: request.id, result: ["status": "ok"])
        sendResponse(response, context: context)
    }
    
    private func handleImportAudio(_ request: MCPRequest, context: ChannelHandlerContext) {
        // Import audio stem into Logic track
        let response = MCPResponse(id: request.id, result: ["status": "ok"])
        sendResponse(response, context: context)
    }
    
    private func handleImportMIDI(_ request: MCPRequest, context: ChannelHandlerContext) {
        // Import MIDI clip into Logic
        let response = MCPResponse(id: request.id, result: ["status": "ok"])
        sendResponse(response, context: context)
    }
    
    private func handleApplyMixer(_ request: MCPRequest, context: ChannelHandlerContext) {
        // Apply mixer settings (volume, pan, effects)
        let response = MCPResponse(id: request.id, result: ["status": "ok"])
        sendResponse(response, context: context)
    }
    
    private func sendResponse(_ response: MCPResponse, context: ChannelHandlerContext) {
        if let jsonData = try? JSONEncoder().encode(response) {
            var buffer = context.channel.allocator.buffer(capacity: jsonData.count)
            buffer.writeBytes(jsonData)
            context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
        }
    }
    
    private func sendError(_ message: String, context: ChannelHandlerContext) {
        let error = MCPError(code: -1, message: message)
        let response = MCPResponse(id: nil, error: error)
        sendResponse(response, context: context)
    }
}

// MARK: - MCP Protocol Types

public struct MCPRequest: Codable {
    public let jsonrpc: String = "2.0"
    public let id: String?
    public let method: String
    public let params: [String: AnyCodable]?
}

public struct MCPResponse: Codable {
    public let jsonrpc: String = "2.0"
    public let id: String?
    public let result: [String: AnyCodable]?
    public let error: MCPError?
}

public struct MCPError: Codable {
    public let code: Int
    public let message: String
}
