# Maggy - Footage Dumper

A reliable footage dumping app for filmmakers that replaces expensive Hedge subscriptions with a free, focused tool. Named after film "magazines" (mag reels) with a friendly, approachable personality.

## 🎯 Purpose
Simple, reliable footage transfers for small crew DOPs and independent filmmakers. **Reliability > Performance > Features > Polish** - because footage is irreplaceable.

## ⚡ Key Features
- **Revolutionary batch queuing** (one-click queue all sources to all destinations)
- **Sequential transfers only** (prevents bus contention & thermal throttling)
- **SHA-256 checksum verification** (industry standard security)
- **Real folder selection** (browse with "New Folder" capability)
- **Flexible workflow** (manual folders + auto-detected drives)
- **Individual transfer cancellation** (cancel specific transfers while others continue)
- **Test mode by default** (safe testing with simulated data)
- **Transparent error handling** (Retry/Skip/Abort with context)
- **Camera detection** (FX6, A7S with proper icons)

## Setup for Testing

### Xcode (Recommended)
```bash
cd Maggy
open Maggy.xcodeproj
```
Then press ⌘+R to build and run

## What to Test - VERSION 0.1 🎬

### **Professional Filmmaker Workflow:**
```
1. Browse for 3 camera cards    (Click "Drop a folder" in SOURCE)
2. Browse for 2 backup drives   (Click "Drop a folder" in DESTINATIONS)  
3. Click "🎯 Queue All Sources → All Destinations"
4. See "6 transfers queued" 
5. Click "▶️ Start Transfers (6)"
6. Walk away - all transfers complete sequentially!
```

### 1. **Real Folder Selection**
- Click "📁 Drop a folder (click to browse)" in SOURCE panel
- Use "New Folder" button in browse dialog to create organized structure
- Add multiple source folders (up to 3 destination slots available)
- Toggle between Test Mode and Real Mode in Settings

### 2. **Batch Queuing System**
- Select multiple sources and destinations
- One click "🎯 Queue All" creates matrix of all combinations
- Example: 3 sources × 2 destinations = 6 transfers automatically queued
- Clear queue if needed before starting

### 3. **Sequential Transfer Process**
- Click "▶️ Start Transfers (X)" shows count
- Progress visible in real-time with adaptive UI
- Source/destination panels stay accessible during transfers
- Individual transfers can be cancelled with ❌ buttons

### 4. **Professional Features**
- SHA-256 checksum verification on every file
- Proper macOS app with dock icon and window controls
- Collapsible sections for clean workspace
- Error recovery with Retry/Skip/Stop options

## Expected Behavior

✅ Cards show camera icons and proper sizes  
✅ Drag creates transfer jobs in queue  
✅ Transfers run sequentially (one at a time)  
✅ Progress bars update smoothly  
✅ Checksums verified after each file  
✅ Clear error messages with user choices  
✅ Test mode clearly indicated in UI  

## Settings

Click the gear icon to access settings:
- **Test Mode**: Toggle between test data and real drives
- **Detailed Logs**: Show verbose transfer information
- **Checksum Algorithm**: SHA-256 (xxHash coming soon)

## Known Limitations in MVP

- Uses test data by default (for safety during testing)
- SHA-256 only (xxHash in future version)
- Basic UI styling (function over form)
- Limited camera detection (FX6, A7S only)
- No network destination support yet

## Switching to Real Drives

⚠️ **WARNING**: Only switch to real drives after thorough testing!

1. Open Settings (gear icon)
2. Toggle "Test Mode" OFF
3. Real drives will appear automatically
4. **Always test with non-critical data first**

## Debug Information

The app logs all operations to the Console:
1. Open Console.app
2. Filter by "Maggy"
3. Watch for detailed transfer logs

## Test Data Location

- Test cards: `~/Desktop/MaggyTestData/`
- Test destinations: `~/Desktop/MaggyDestination/`

## Report Issues

When reporting issues, please include:
- UI freezes or crashes (with crash logs)
- Incorrect progress reporting (expected vs actual)
- Checksum mismatches (source and destination hashes)
- Confusing error messages (screenshot the dialog)
- Missing functionality from spec

## Safety First

This MVP includes several safety features:
- Test mode enabled by default
- Sequential transfers only (prevents corruption)
- Checksum verification on every file
- No overwrites without confirmation
- Detailed error recovery options

Remember: This tool handles irreplaceable footage. Always have backups!