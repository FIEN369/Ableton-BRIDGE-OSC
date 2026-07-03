import Foundation

/// Handles exporting Ableton projects to stems and MIDI
public class AbletonProjectExporter {
    private let fileManager = FileManager.default
    private var exportProgress: Double = 0.0
    
    public var onProgressUpdate: ((Double) -> Void)?
    
    public init() {}
    
    /// Export project to audio stems and MIDI
    public func exportProject(_ project: AbletonProject, to outputDir: URL) async throws -> ExportResult {
        updateProgress(0.1)
        
        // Create output directory structure
        let stemsDir = outputDir.appendingPathComponent("stems")
        let midiDir = outputDir.appendingPathComponent("midi")
        let metadataDir = outputDir.appendingPathComponent("metadata")
        
        try fileManager.createDirectory(at: stemsDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: midiDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: metadataDir, withIntermediateDirectories: true)
        
        updateProgress(0.2)
        
        // Export audio stems
        var exportedStems: [AudioStem] = []
        for (index, stem) in project.stems.enumerated() {
            let progress = 0.2 + (0.5 * Double(index) / Double(project.stems.count))
            updateProgress(progress)
            
            let fileName = sanitizeFileName(stem.trackName) + ".\(stem.format.rawValue)"
            let outputPath = stemsDir.appendingPathComponent(fileName)
            
            try fileManager.copyItem(atPath: stem.filePath, toPath: outputPath.path)
            exportedStems.append(stem)
        }
        
        updateProgress(0.7)
        
        // Export MIDI clips
        var exportedMIDI: [MIDIClip] = []
        for (index, clip) in project.midiClips.enumerated() {
            let progress = 0.7 + (0.2 * Double(index) / Double(project.midiClips.count))
            updateProgress(progress)
            
            let fileName = sanitizeFileName(clip.name) + ".mid"
            let outputPath = midiDir.appendingPathComponent(fileName)
            
            // Convert MIDI clip to SMF file
            let midiData = encodeMIDIToSMF(clip)
            try midiData.write(to: outputPath)
            exportedMIDI.append(clip)
        }
        
        updateProgress(0.9)
        
        // Export metadata
        let metadataFile = metadataDir.appendingPathComponent("project.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let metadataJSON = try encoder.encode(project.metadata)
        try metadataJSON.write(to: metadataFile)
        
        updateProgress(1.0)
        
        return ExportResult(
            projectName: project.name,
            outputDirectory: outputDir,
            exportedStems: exportedStems,
            exportedMIDI: exportedMIDI,
            metadata: project.metadata,
            timestamp: Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func updateProgress(_ value: Double) {
        self.exportProgress = value
        onProgressUpdate?(value)
    }
    
    private func sanitizeFileName(_ name: String) -> String {
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return name
            .components(separatedBy: invalidChars)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func encodeMIDIToSMF(_ clip: MIDIClip) -> Data {
        // Simplified MIDI encoder (Standard MIDI File format)
        // In production: Use proper MIDI library
        var data = Data()
        
        // SMF header
        data.append(contentsOf: [0x4D, 0x54, 0x68, 0x64]) // "MThd"
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x06]) // Header length
        data.append(contentsOf: [0x00, 0x00]) // Format 0
        data.append(contentsOf: [0x00, 0x01]) // 1 track
        data.append(contentsOf: [0x00, 0x60]) // 96 ticks per quarter
        
        // Track data
        data.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B]) // "MTrk"
        
        // Placeholder for track length (will be filled later)
        let trackLengthIndex = data.count
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        var trackData = Data()
        
        // Add note events
        for note in clip.notes {
            trackData.append(encodeVariableLength(UInt32(note.startTime * 96)))
            trackData.append(0x90) // Note on
            trackData.append(UInt8(note.pitch))
            trackData.append(UInt8(note.velocity))
            
            trackData.append(encodeVariableLength(UInt32(note.duration * 96)))
            trackData.append(0x80) // Note off
            trackData.append(UInt8(note.pitch))
            trackData.append(0x40)
        }
        
        // End of track
        trackData.append(0x00)
        trackData.append(0xFF)
        trackData.append(0x2F)
        trackData.append(0x00)
        
        // Update track length
        let trackLength = UInt32(trackData.count)
        data[trackLengthIndex] = UInt8((trackLength >> 24) & 0xFF)
        data[trackLengthIndex + 1] = UInt8((trackLength >> 16) & 0xFF)
        data[trackLengthIndex + 2] = UInt8((trackLength >> 8) & 0xFF)
        data[trackLengthIndex + 3] = UInt8(trackLength & 0xFF)
        
        data.append(trackData)
        return data
    }
    
    private func encodeVariableLength(_ value: UInt32) -> [UInt8] {
        var result: [UInt8] = []
        var val = value
        
        result.append(UInt8(val & 0x7F))
        val >>= 7
        
        while val > 0 {
            result.insert(UInt8((val & 0x7F) | 0x80), at: 0)
            val >>= 7
        }
        
        return result
    }
}

/// Result of project export
public struct ExportResult {
    public let projectName: String
    public let outputDirectory: URL
    public let exportedStems: [AudioStem]
    public let exportedMIDI: [MIDIClip]
    public let metadata: ProjectMetadata
    public let timestamp: Date
}
