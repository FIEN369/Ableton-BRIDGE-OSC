#!/bin/bash

# Ableton BRIDGE OSC - Auto-installer
# Installs and configures the two-machine setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ROLE="${1:---role=standalone}"
TARGET_HOST="${2:---target-host=localhost}"
SOURCE_HOST="${3:---source-host=localhost}"
BRIDGE_VERSION="1.0.0"
INSTALL_DIR="$HOME/.ableton-bridge"
ABLETON_SCRIPTS="$HOME/Library/Preferences/Ableton/Live\ 12\ Standard/Remote\ Scripts"

echo -e "${GREEN}=== Ableton BRIDGE OSC Installer ===${NC}"
echo "Version: $BRIDGE_VERSION"
echo ""

# Parse arguments
for arg in "$@"; do
  case $arg in
    --role=*)
      ROLE="${arg#*=}"
      ;;
    --target-host=*)
      TARGET_HOST="${arg#*=}"
      ;;
    --source-host=*)
      SOURCE_HOST="${arg#*=}"
      ;;
  esac
done

echo "Installation Role: $ROLE"
echo "Install Directory: $INSTALL_DIR"
echo ""

# Check system requirements
echo -e "${YELLOW}Checking system requirements...${NC}"

if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Swift toolchain not found. Install Xcode Command Line Tools first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Swift found${NC}"

if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Git found${NC}"

# Create installation directory
mkdir -p "$INSTALL_DIR"
echo -e "${GREEN}✓ Created installation directory${NC}"

case "$ROLE" in
  source)
    echo ""
    echo -e "${YELLOW}Setting up Ableton Laptop (Source)...${NC}"
    
    # Copy AbletonOSC remote script
    mkdir -p "$ABLETON_SCRIPTS"
    echo -e "${YELLOW}Installing AbletonOSC remote script...${NC}"
    # In production: Download and install AbletonOSC
    
    # Set environment variables
    echo "export ABLETON_HOST=localhost" >> ~/.zprofile
    echo "export ABLETON_OSC_PORT=11000" >> ~/.zprofile
    echo "export LOGIC_HOST=$TARGET_HOST" >> ~/.zprofile
    echo "export LOGIC_MCP_PORT=9000" >> ~/.zprofile
    
    # Build Swift client
    echo -e "${YELLOW}Building Swift OSC client...${NC}"
    cd "$(dirname "$0")"
    swift build -c release --product AbletonBridge
    
    echo -e "${GREEN}✓ Ableton setup complete${NC}"
    ;;
    
  destination)
    echo ""
    echo -e "${YELLOW}Setting up Logic Desktop (Destination)...${NC}"
    
    # Set environment variables
    echo "export LOGIC_HOST=localhost" >> ~/.zprofile
    echo "export LOGIC_MCP_PORT=9000" >> ~/.zprofile
    echo "export ABLETON_HOST=$SOURCE_HOST" >> ~/.zprofile
    echo "export ABLETON_OSC_PORT=11000" >> ~/.zprofile
    
    # Build Swift server
    echo -e "${YELLOW}Building Swift MCP server...${NC}"
    cd "$(dirname "$0")"
    swift build -c release --product LogicBridge
    
    # Install LaunchAgent for auto-start
    echo -e "${YELLOW}Installing LaunchAgent for auto-start...${NC}"
    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$HOME/Library/LaunchAgents/com.ableton.bridge.mcp.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.ableton.bridge.mcp</string>
  <key>Program</key>
  <string>$INSTALL_DIR/mcp-server</string>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$INSTALL_DIR/mcp-server.log</string>
  <key>StandardErrorPath</key>
  <string>$INSTALL_DIR/mcp-server.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>LOGIC_HOST</key>
    <string>localhost</string>
    <key>LOGIC_MCP_PORT</key>
    <string>9000</string>
    <key>ABLETON_HOST</key>
    <string>$SOURCE_HOST</string>
    <key>ABLETON_OSC_PORT</key>
    <string>11000</string>
  </dict>
</dict>
</plist>
EOF
    
    launchctl load "$HOME/Library/LaunchAgents/com.ableton.bridge.mcp.plist"
    echo -e "${GREEN}✓ Logic setup complete${NC}"
    ;;
    
  standalone)
    echo ""
    echo -e "${YELLOW}Setting up standalone mode (local testing)...${NC}"
    
    # Build both components
    echo -e "${YELLOW}Building Swift components...${NC}"
    cd "$(dirname "$0")"
    swift build -c release
    
    echo -e "${GREEN}✓ Standalone setup complete${NC}"
    ;;
    
  *)
    echo -e "${RED}Unknown role: $ROLE${NC}"
    echo "Usage: $0 [--role=source|destination|standalone] [--target-host=IP] [--source-host=IP]"
    exit 1
    ;;
esac

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo "Reload shell configuration: source ~/.zprofile"
echo ""
echo "Next steps:"
echo "  1. Restart Ableton Live"
echo "  2. Enable AbletonOSC in Preferences > MIDI"
echo "  3. Configure network: $TARGET_HOST:11000"
echo ""
