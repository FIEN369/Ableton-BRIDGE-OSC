# Ableton BRIDGE OSC

**Automated Ableton Live → Logic Pro project transfer via OSC/MCP with remote execution across two machines.**

## Overview

Ableton BRIDGE OSC is a multi-machine Swift agent that automates the export of Ableton Live projects to Logic Pro with complete audio stems, MIDI data, and settings preservation. It uses:

- **OSC (Open Sound Control)** for real-time communication between Ableton and Logic
- **MCP (Model Context Protocol)** for AI-assisted orchestration
- **Swift agent** running on Logic Desktop as the "brain"
- **Automatic installer** for zero-manual-setup deployment
- **Remote execution** via SSH/AppleScript for headless Logic processing

## Architecture

```
Ableton Laptop                          Logic Desktop
┌──────────────────┐                   ┌──────────────────┐
│  Ableton Live    │                   │   Logic Pro      │
│  + AbletonOSC    │                   │   + AppleScript  │
└────────┬─────────┘                   └────────┬─────────┘
         │                                      │
         │         UDP OSC Port 11000-11001     │
         ├──────────────────────────────────────┤
         │                                      │
┌────────▼──────────────────┐         ┌────────▼─────────────────┐
│  Swift OSC Client         │         │  MCP Server (Swift)      │
│  (Asset Export Handler)   │◄────────┤  (Logic Project Builder) │
└───────────────────────────┘         └──────────────────────────┘
         │
         │ SSH + AppleScript
         │ (Remote Execution)
         │
    [Project Files]
    [Audio Stems]
    [MIDI Data]
```

## Key Features

✅ **Two-Machine Architecture**
- Origin Mac (Ableton): Exports stems, MIDI, and project metadata via OSC
- Remote Mac (Logic): Receives OSC commands, builds Logic projects via AppleScript

✅ **Automatic Installation**
- One-line installer script that sets up AbletonOSC, MCP server, LaunchAgent
- Zero manual configuration for end users

✅ **Seamless Export Integration**
- Custom "Export to Logic" menu item in Ableton
- Keyboard shortcut support
- Progress UI with real-time status updates

✅ **File Preservation**
- All audio stems collected and organized by track
- MIDI clips extracted with original timing and names
- Mixer settings, automation, effects preserved
- Project settings persisted to JSON metadata

✅ **Error Recovery**
- Automatic retry on network failure
- Session state persisted to disk
- Graceful fallback to manual mode

## Installation

### Quick Start (Single Machine)

```bash
git clone https://github.com/FIEN369/Ableton-BRIDGE-OSC.git
cd Ableton-BRIDGE-OSC
bash install.sh
```

### Two-Machine Setup

**On Ableton Laptop:**
```bash
bash install.sh --role=source --target-host=192.168.1.100
```

**On Logic Desktop:**
```bash
bash install.sh --role=destination --source-host=192.168.1.50
```

## Quick Start

1. **Prepare Ableton project**
   - Organize tracks into groups (drums, bass, synths, etc.)
   - Save as `.als` file

2. **Export to Logic**
   - In Ableton, press `Cmd+Shift+E` (or use File > Export to Logic)
   - Select destination Logic project or create new
   - Wait for OSC sync to complete (progress shown in UI)

3. **Logic project ready**
   - All stems imported as separate tracks
   - MIDI clips on dedicated MIDI tracks
   - Mixer organization matches Ableton structure

## Configuration

### Environment Variables

```bash
# On Ableton Laptop
export ABLETON_HOST=localhost
export ABLETON_OSC_PORT=11000
export LOGIC_HOST=192.168.1.100  # Logic Desktop IP
export LOGIC_MCP_PORT=9000

# On Logic Desktop
export LOGIC_MCP_PORT=9000
export ABLETON_HOST=192.168.1.50  # Ableton Laptop IP
export ABLETON_OSC_PORT=11000
```

### Firewall Configuration

**macOS (both machines):**
```bash
# Allow UDP on OSC ports
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setoptions /usr/local/bin/oscd

# Allow TCP for MCP server
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/Logic\ Pro.app
```

## Project Structure

```
Ableton-BRIDGE-OSC/
├── README.md                          # This file
├── install.sh                         # Auto-installer script
├── Sources/
│   ├── AbletonBridge/                 # Swift OSC client (Ableton laptop)
│   │   ├── OSCClient.swift
│   │   ├── ProjectExporter.swift
│   │   ├── AssetCollector.swift
│   │   └── ExportUI.swift
│   ├── LogicBridge/                   # Swift MCP server (Logic desktop)
│   │   ├── MCPServer.swift
│   │   ├── ProjectBuilder.swift
│   │   ├── AppleScriptExecutor.swift
│   │   └── AudioImporter.swift
│   └── Shared/
│       ├── Models.swift               # Codable project/track models
│       ├── OSCMessage.swift           # OSC serialization
│       └── NetworkConfig.swift        # IP/port configuration
├── Scripts/
│   ├── setup-ableton.sh               # Ableton setup script
│   ├── setup-logic.sh                 # Logic setup script
│   ├── launch-agent.plist             # LaunchAgent configuration
│   └── build-swift.sh                 # Swift compilation
├── Tests/
│   ├── OSCClientTests.swift
│   ├── ProjectExporterTests.swift
│   └── MCPServerTests.swift
└── Package.swift                      # Swift Package manifest
```

## Development

### Building Locally

```bash
swift build -c release
```

### Running Tests

```bash
swift test
```

### Creating a Custom Tool via AI

The project supports defining new tools via natural language. In the UI:

1. Click **Settings** → **AI Tool Generator**
2. Describe tool in natural language: *"Create a tool that extracts drum loops from Ableton clips"*
3. OpenAI generates Swift code
4. Tool is compiled and registered automatically

## Efficiency: Origin Mac vs. Remote Mac

### Recommendation: **Bounce/Collect on Origin Mac (Ableton Laptop)**

**Why:**
- ✅ Ableton has native access to `.als` files and Live API
- ✅ Audio bounce is fastest locally (no network latency)
- ✅ MIDI extraction is deterministic in Live environment
- ✅ Metadata collection avoids SSH overhead
- ❌ Logic Desktop receives pre-processed assets (less coupling)

**Workflow:**
```
1. Ableton Laptop: Read project → Extract MIDI → Bounce stems (local)
2. Transfer: Stems + metadata → OSC to Logic Desktop (11000)
3. Logic Desktop: Receive + Import → Build Logic project → AppleScript apply mixer
```

### Why NOT on Logic Desktop:
- ❌ Would require Logic to SSH into Ableton and control it (slow)
- ❌ Live API not available remotely without AppleScript bridge
- ❌ Network latency compounds for each file operation
- ❌ Ableton must stay open during entire remote processing

## API Reference

### OSC Message Format (Ableton → Logic)

```
/ableton/project
  ├─ /metadata      {projectName, tempo, bpm, timeSignature}
  ├─ /tracks        [{name, volume, pan, effects}]
  ├─ /stems         [{trackId, filePath, format, channels}]
  └─ /midi          [{trackId, clipName, notesJson}]
```

### MCP Server Endpoints (Logic Desktop)

```swift
// Define project structure
POST /mcp/project/create
  → {projectPath, tracks: [...], tempo, timeSignature}

// Import audio stem
POST /mcp/import/audio
  → {trackId, filePath, startTime, volume}

// Import MIDI clip
POST /mcp/import/midi
  → {trackId, clipName, notes: [...], timeSignature}

// Apply mixer settings
POST /mcp/mixer/apply
  → {trackId, volume, pan, effects: [...]}
```

## Troubleshooting

### OSC Connection Fails

```bash
# Check firewall
sudo lsof -i :11000

# Test OSC echo
swift run OSCTest 192.168.1.50 11000

# Check network
ping -c 1 192.168.1.100
```

### Logic Import Hangs

```bash
# Check MCP server status
launchctl list | grep com.ableton.bridge.mcp

# View logs
log stream --predicate 'process == "Logic Pro"'
```

## Contributing

We welcome contributions! See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## License

MIT
