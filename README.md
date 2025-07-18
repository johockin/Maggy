# Maggy - Footage Dumper

A reliable footage dumping app for filmmakers that replaces expensive Hedge subscriptions with a free, focused tool. Named after film "magazines" (mag reels) with a friendly, approachable personality.

## 🎯 Purpose
Simple, reliable footage transfers for small crew DOPs and independent filmmakers. **Reliability > Performance > Features > Polish** - because footage is irreplaceable.

## ⚡ Key Features
- **Sequential transfers only** (prevents bus contention & thermal throttling)
- **SHA-256 checksum verification** (industry standard security)
- **Drag & drop interface** (cards → destination drives)
- **Test mode by default** (safe testing with simulated data)
- **Transparent error handling** (Retry/Skip/Abort with context)
- **Camera detection** (FX6, A7S with proper icons)

## Setup for Testing

### Option 1: Swift Package Manager (Recommended)
```bash
cd Maggy
swift run
```

### Option 2: Xcode
```bash
cd Maggy
open Package.swift
```
Then press ⌘+R to build and run

## What to Test

### 1. **Drive Detection**
- Launch the app in Test Mode (enabled by default)
- Check that test cards appear in the left panel:
  - FX6_Card (128GB)
  - A7S_Card (64GB)
- Verify destination drives appear in the right panel:
  - RAID Drive (2TB free)
  - Archive Drive (8TB free)

### 2. **Drag & Drop**
- Drag test cards from left panel to destination drives on right
- Visual feedback should show during drag (green border on drop zone)
- Transfer jobs should appear in the queue panel below

### 3. **Transfer Process**
- Click "Start Transfers" to begin sequential copying
- Watch progress bars update in real-time
- Only one transfer should run at a time (sequential processing)

### 4. **Checksum Verification**
- After each file copies, SHA-256 checksum is calculated
- Status should show "Verifying" during checksum phase
- Completed transfers should show green checkmark

### 5. **Error Handling**
To simulate errors:
- Fill up destination (create large file in `~/Desktop/MaggyDestination/`)
- Remove source during transfer
- Deny permissions to destination folder

Expected dialog options:
- **Retry**: Attempts the same operation again
- **Skip**: Continues with next file (logs skipped file)
- **Stop**: Aborts entire card transfer

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