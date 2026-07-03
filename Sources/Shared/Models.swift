import Foundation

// MARK: - Project Models

/// Represents an Ableton Live project structure
public struct AbletonProject: Codable {
    public let id: String
    public let name: String
    public let filePath: String
    public let tempo: Double
    public let bpm: Int
    public let timeSignature: TimeSignature
    public let tracks: [AudioTrack]
    public let stems: [AudioStem]
    public let midiClips: [MIDIClip]
    public let metadata: ProjectMetadata
    
    public init(id: String, name: String, filePath: String, tempo: Double, bpm: Int,
                timeSignature: TimeSignature, tracks: [AudioTrack], stems: [AudioStem],
                midiClips: [MIDIClip], metadata: ProjectMetadata) {
        self.id = id
        self.name = name
        self.filePath = filePath
        self.tempo = tempo
        self.bpm = bpm
        self.timeSignature = timeSignature
        self.tracks = tracks
        self.stems = stems
        self.midiClips = midiClips
        self.metadata = metadata
    }
}

/// Time signature configuration
public struct TimeSignature: Codable {
    public let numerator: Int
    public let denominator: Int
    
    public init(numerator: Int, denominator: Int) {
        self.numerator = numerator
        self.denominator = denominator
    }
}

/// Audio track representation
public struct AudioTrack: Codable, Identifiable {
    public let id: String
    public let name: String
    public let volume: Double  // 0.0 to 1.0
    public let pan: Double    // -1.0 (left) to 1.0 (right)
    public let isMuted: Bool
    public let soloState: SoloState
    public let effects: [AudioEffect]
    public let automation: [AutomationEnvelope]
    public let children: [String]?  // Group track children IDs
    
    public init(id: String, name: String, volume: Double, pan: Double, isMuted: Bool,
                soloState: SoloState, effects: [AudioEffect], automation: [AutomationEnvelope],
                children: [String]? = nil) {
        self.id = id
        self.name = name
        self.volume = volume
        self.pan = pan
        self.isMuted = isMuted
        self.soloState = soloState
        self.effects = effects
        self.automation = automation
        self.children = children
    }
}

public enum SoloState: String, Codable {
    case off
    case solo
    case soloLocked
}

/// Audio effect configuration
public struct AudioEffect: Codable, Identifiable {
    public let id: String
    public let name: String
    public let type: String  // e.g., "Reverb", "Delay", "EQ"
    public let isActive: Bool
    public let parameters: [String: Double]
    
    public init(id: String, name: String, type: String, isActive: Bool,
                parameters: [String: Double]) {
        self.id = id
        self.name = name
        self.type = type
        self.isActive = isActive
        self.parameters = parameters
    }
}

/// Automation envelope
public struct AutomationEnvelope: Codable, Identifiable {
    public let id: String
    public let parameter: String  // e.g., "volume", "pan"
    public let points: [AutomationPoint]
    
    public init(id: String, parameter: String, points: [AutomationPoint]) {
        self.id = id
        self.parameter = parameter
        self.points = points
    }
}

/// Automation point
public struct AutomationPoint: Codable {
    public let time: Double  // In beats
    public let value: Double // 0.0 to 1.0
    public let curveType: CurveType
    
    public init(time: Double, value: Double, curveType: CurveType) {
        self.time = time
        self.value = value
        self.curveType = curveType
    }
}

public enum CurveType: String, Codable {
    case linear
    case exponential
    case logarithmic
    case smooth
}

// MARK: - Audio Stem

/// Exported audio stem from a track
public struct AudioStem: Codable, Identifiable {
    public let id: String
    public let trackId: String
    public let trackName: String
    public let filePath: String
    public let format: AudioFormat
    public let channels: ChannelConfiguration
    public let sampleRate: Int
    public let bitDepth: Int
    public let duration: Double  // In seconds
    
    public init(id: String, trackId: String, trackName: String, filePath: String,
                format: AudioFormat, channels: ChannelConfiguration, sampleRate: Int,
                bitDepth: Int, duration: Double) {
        self.id = id
        self.trackId = trackId
        self.trackName = trackName
        self.filePath = filePath
        self.format = format
        self.channels = channels
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
        self.duration = duration
    }
}

public enum AudioFormat: String, Codable {
    case wav
    case aif
    case mp3
    case m4a
}

public enum ChannelConfiguration: String, Codable {
    case mono
    case stereo
    case surround5_1
}

// MARK: - MIDI Clip

/// MIDI clip representation
public struct MIDIClip: Codable, Identifiable {
    public let id: String
    public let trackId: String
    public let name: String
    public let startTime: Double  // In beats
    public let duration: Double   // In beats
    public let notes: [MIDINote]
    public let timeSignature: TimeSignature
    
    public init(id: String, trackId: String, name: String, startTime: Double,
                duration: Double, notes: [MIDINote], timeSignature: TimeSignature) {
        self.id = id
        self.trackId = trackId
        self.name = name
        self.startTime = startTime
        self.duration = duration
        self.notes = notes
        self.timeSignature = timeSignature
    }
}

/// Individual MIDI note
public struct MIDINote: Codable {
    public let pitch: Int  // 0-127 MIDI note number
    public let velocity: Int  // 0-127
    public let startTime: Double  // In beats
    public let duration: Double   // In beats
    
    public init(pitch: Int, velocity: Int, startTime: Double, duration: Double) {
        self.pitch = pitch
        self.velocity = velocity
        self.startTime = startTime
        self.duration = duration
    }
}

// MARK: - Project Metadata

/// Metadata about the project export
public struct ProjectMetadata: Codable {
    public let exportDate: Date
    public let exportedBy: String
    public let abletonVersion: String
    public let bridgeVersion: String
    public let notes: String?
    public let tags: [String]
    
    public init(exportDate: Date, exportedBy: String, abletonVersion: String,
                bridgeVersion: String, notes: String? = nil, tags: [String] = []) {
        self.exportDate = exportDate
        self.exportedBy = exportedBy
        self.abletonVersion = abletonVersion
        self.bridgeVersion = bridgeVersion
        self.notes = notes
        self.tags = tags
    }
}

// MARK: - OSC Message Envelope

/// Wrapper for OSC messages
public struct OSCMessageEnvelope: Codable {
    public let messageType: String
    public let timestamp: Date
    public let sourceHost: String
    public let payload: [String: AnyCodable]
    
    public init(messageType: String, timestamp: Date = Date(), sourceHost: String,
                payload: [String: AnyCodable]) {
        self.messageType = messageType
        self.timestamp = timestamp
        self.sourceHost = sourceHost
        self.payload = payload
    }
}

/// Type-erased Codable for flexible payloads
public enum AnyCodable: Codable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([AnyCodable])
    case dictionary([String: AnyCodable])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([AnyCodable].self) {
            self = .array(array)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self = .dictionary(dict)
        } else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Cannot decode AnyCodable")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let bool):
            try container.encode(bool)
        case .int(let int):
            try container.encode(int)
        case .double(let double):
            try container.encode(double)
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        case .dictionary(let dict):
            try container.encode(dict)
        }
    }
}
