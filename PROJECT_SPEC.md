# PROJECT_SPEC.md - Maggy

⚠️ This is the **living god file** for Maggy. Every architectural decision, user need, tech stack context, and collaborator expectation lives here.

---

## 🔰 PURPOSE OF THIS FILE

- Serves as the **canonical source of truth** for the project.
- Evolves over time, **growing with every decision**, mistake, fix, or insight.
- **Future collaborators (human or AI)** must be able to read this file and understand how the project works, why it's built the way it is, and what to do next.

---

## 🔍 LEVEL SET SUMMARY

- **Project name**: Maggy
- **Purpose**: Simple, reliable footage dumping app for filmmakers that replaces expensive Hedge subscription with free, focused tool. Named after film "magazines" (mag reels) with a friendly, approachable personality.
- **Audience / users**: Small crew DOPs, independent filmmakers, anyone needing secure footage transfers
- **Most important outcome**: **Reliability and trust** - footage is irreplaceable, tool must be bulletproof
- **Visual vs performance vs design**: Performance > Reliability > Clean UX. Visual polish is secondary to rock-solid operation
- **Performance priority**: High (1TB+ files, can't lock up UI)
- **SEO priority**: N/A (native macOS app)
- **Maintenance over time**: Ongoing (will be used regularly for shoots)
- **Deployment target(s)**: macOS native app (Swift/SwiftUI)
- **Initial feature list**:
  - [x] Detect mounted drives/cards (left panel)
  - [x] Select destination drives (right panel)
  - [x] Drag-and-drop interface for card → destination mapping
  - [x] Sequential copying with progress indication
  - [x] Checksum verification (SHA-256 default, xxHash option planned)
  - [x] Detailed failure handling with user education
  - [x] Camera detection and iconography (FX6, A7S implemented)
  - [x] Transfer queue management
- **Tech constraints / requests from user**:
  - [x] macOS native (Swift/SwiftUI)
  - [x] Sequential transfers only (no simultaneous)
  - [x] Checksum choice: SHA-256 (secure) vs xxHash (fast) - SHA-256 implemented, xxHash planned
  - [x] Transparent failure recovery with user choice
- **Other notes**: User shoots 1-3 128GB cards twice weekly on FX6, needs to dump to desktop RAID + archive drives

---

## 🏗️ INITIAL TECH ARCHITECTURE

- **Framework / language**: Swift/SwiftUI - Native macOS performance and system integration
- **Styling approach**: SwiftUI native components with minimal custom styling for reliability
- **State management**: SwiftUI @State/@ObservableObject for UI state, separate FileManager class for operations
- **Directory structure plan**: Standard Swift app structure with separate modules for file operations, checksum, and UI
- **Key dependencies**: Foundation (FileManager), CryptoKit (SHA-256), potentially xxHash library
- **Planned dev workflow**: Xcode with Swift Package Manager for dependencies
- **Testing tools / approach**: XCTest for file operations, manual testing with real cards/drives

---

## 📋 CORE REQUIREMENTS & CONSTRAINTS

### **Threading Strategy**
- **Sequential transfers only** - no simultaneous copying
- Rationale: Prevents bus contention, thermal throttling, and error cascade
- Queue-based approach with clear progress indication

### **Checksum Security**
- **Default: SHA-256** (industry standard, secure, ~200MB/s)
- **Fast option: xxHash** (~1GB/s, good corruption detection)
- **User choice** with clear explanation: "Maximum Security" vs "Fast Verification"
- **Never MD5** - deprecated and insecure

### **Failure Handling Philosophy**
```
On transfer failure:
├── Verify source is still readable
├── Check destination space/permissions
├── Present user with options:
│   ├── Retry (explain: attempts same operation)
│   ├── Skip file (explain: continues but logs missing file)
│   └── Abort transfer (explain: stops entire card transfer)
├── Provide detailed technical context
└── Log everything for post-mortem
```

### **User Experience Priorities**
1. **Transparency** - user always knows what's happening and why
2. **Safety** - no operation that could lose footage
3. **Simplicity** - minimal UI, obvious workflow
4. **Professional** - handles edge cases gracefully

---

## 📒 CHANGELOG (REVERSE CHRONOLOGICAL)

*[Date] - [Author] - [Change]*

- 2025-01-19 - Claude - **SPRINT 0.16 COMPLETE - SETTINGS & RUSH MODE UI**: Added complete Settings access (bottom-right gear button + Cmd+, menu), implemented Rush Mode toggle in bottom status bar, created Rush Mode warning popup system, updated verification messages based on mode. Fixed SettingsManager scope issues by switching to @AppStorage directly. **CRITICAL NOTE**: Rush Mode currently UI-only - changes text but still uses SHA-256. Sprint 0.17 will implement real xxHash for actual speed improvement.
- 2025-01-19 - Claude - **SPRINT 0.15 SERIES COMPLETE**: Completed comprehensive UX polish across 4 sub-sprints: (0.15.1) Fixed 8 critical transfer queue UX issues including sequential visibility and checksum confirmation, (0.15.2) Implemented sophisticated button polish with muted professional colors and staggered timing, (0.15.3) Created "one big button" philosophy with Queue All as commanding 480×80px star button, (0.15.4) Generated proper film magazine app icons and fixed duplicate source behavior to show disabled folders with inline explanations. App now has professional visual hierarchy and proper macOS integration.
- 2025-01-18 - Claude - **VERSION 0.1 FOUNDATION COMPLETE**: Implemented revolutionary batch queuing system, fixed critical transfer hanging bug, simplified UX to single-button workflow, added real folder selection with "New Folder" capability, and redesigned adaptive layout. App now ready for production testing with professional filmmaker workflow: browse sources/destinations → queue all → start transfers → walk away. QA scheduled for morning.
- 2025-01-18 - Claude - **XCODE PROJECT CONVERSION COMPLETE**: Successfully converted Swift Package to proper macOS Xcode project. Added proper window management, dock icon, app menu bar, Info.plist, entitlements for file access, and asset catalogs. App now launches as professional macOS application while preserving all transfer functionality.
- 2025-01-18 - Claude - **CRITICAL ERROR & RECOVERY**: Accidentally deleted PROJECT_SPEC.md while fixing Xcode project. Recreated from user's original. Built complete MVP: SwiftUI app with drag/drop, sequential transfers, SHA-256 checksums, test mode, error dialogs. Set up git repo. LESSON LEARNED: Never delete the spec file - it's the sacred foundation.
- 2024-12-XX - Human - Initial spec creation based on Hedge replacement needs

---

## 🧱 ROADMAP & PIPELINE

🎬 **MAGGY ROADMAP - HEDGE KILLER EDITION**

## 🎯 VERSION 0.1 - FOUNDATION ✅ COMPLETE!
**"Make it actually work reliably"**

- [x] Individual transfer cancellation
- [x] Fix permission issues  
- [x] Proper error recovery
- [x] Basic window management
- [x] Core transfer engine bulletproof
- [x] **Real folder selection (browse buttons with "New Folder" capability)**
- [x] **Flexible workflow: manual drop zones + auto-detection drawer**
- [x] **Multiple destination support (3 slots)**
- [x] **REVOLUTIONARY BATCH QUEUING SYSTEM** - One-click queue all sources to all destinations
- [x] **Fixed critical transfer hanging bug** - Sequential transfers now complete properly
- [x] **Simplified UX** - Single "Queue All" button replaces confusing multiple buttons
- [x] **Adaptive layout** - Source/destination always visible, transfer queue gets focus when active

**UX IMPROVEMENTS FOR 0.1:**
```
┌─────────────────────────────────────────────────┐
│ Maggy - Footage Dumper                 [⚙️]     │
├─────────────────┬───────────────────────────────┤
│ SOURCE          │ DESTINATIONS                  │
│ ┌─────────────┐ │ ┌─────────────┐ ┌─────────────┐ │
│ │[📁] Drop a  │ │ │[💾] Drop a  │ │[💾] Drop a  │ │
│ │    folder   │ │ │   folder    │ │   folder    │ │
│ │             │ │ │             │ │             │ │
│ │  (click to  │ │ │ (click to   │ │ │ (click to  │ │
│ │   browse)   │ │ │  browse)    │ │ │  browse)   │ │
│ └─────────────┘ │ └─────────────┘ └─────────────┘ │
├─────────────────┴───────────────────────────────┤
│ 🔽 Detected Cards & Drives [auto-detected]      │
│ 📷 FX6_Card (128GB)  💾 External SSD (1TB)     │
├─────────────────────────────────────────────────┤
│ TRANSFER QUEUE                                  │
│ 📁 Custom_Folder → Destination1 [████░] 80% [❌]│
│ 📷 FX6_Card → External_SSD [Queued]      [❌]│
├─────────────────────────────────────────────────┤
│ [Start Transfers]                    [Settings] │
└─────────────────────────────────────────────────┘
```

**Key UX Improvements:**
- **Drop zones**: Empty panes that say "Drop a folder" with browse fallback
- **Multiple destinations**: User can set up several destination folders  
- **Auto-detected drawer**: Cards/drives appear in middle section automatically
- **Flexible workflow**: Mix manual folders + auto-detected drives
- **Visual hierarchy**: Clear separation between manual vs auto-detected

## 🎯 SPRINT 0.17 - xxHash IMPLEMENTATION (CRITICAL)
**1-hour sprint: "Stop the phoney verification"**

**CRITICAL ISSUE**: Rush Mode currently just changes UI text but still uses SHA-256. This is misleading and unprofessional.

**Implementation Requirements:**
- [ ] ⚡ Add xxHash Swift package dependency
- [ ] ⚡ Implement REAL xxHash calculation in ChecksumManager
- [ ] ⚡ Actually switch between SHA-256 and xxHash based on mode
- [ ] ⚡ Make Rush Mode genuinely faster (~5x speed improvement)
- [ ] ⚡ Remove fake behavior where text changes live during verification
- [ ] ⚡ Fix Rush Mode warning popup not appearing

**Quality Standards:**
- Rush Mode must use actual xxHash algorithm
- Speed difference must be measurable (SHA-256: ~200MB/s vs xxHash: ~1GB/s)
- UI text should only change when verification method actually changes
- Warning popup must appear when enabling Rush Mode

---

## 🎯 SPRINT 0.18 - SMART DUPLICATE DETECTION
**2-hour sprint: "Never transfer the same footage twice"**

**Context**: Users often dump the same card multiple times by accident, wasting time and disk space. Since Maggy adds timestamps to folder names, simple name matching won't work.

**Implementation Details:**

**Detection Method:**
- [ ] Compare folder contents (file count, total size, file names)
- [ ] Create a "fingerprint" of each transferred folder  
- [ ] Store fingerprints in lightweight local database or JSON file
- [ ] Check new transfers against fingerprint database

**User Experience:**
- [ ] When queuing potentially duplicate source show warning: "This appears to match a previous transfer:"
- [ ] Display: "Transferred as 'FolderName_MAG_2025-07-19_081542' on July 19 at 8:15 AM"
- [ ] Options: "Transfer Anyway" / "Skip This Source" / "View Previous Transfer"

**Technical Considerations:**
- [ ] Don't block if unsure - err on side of allowing transfer
- [ ] Quick detection - shouldn't slow down queue process  
- [ ] Handle partial matches (90% similar = likely duplicate)

---

## 🎯 SPRINT 0.19 - PROFESSIONAL ERROR DIALOGS  
**2-hour sprint: "Errors that inspire confidence"**

**Context**: Current error dialogs use system alerts that feel alarming. Professional filmmakers need errors that feel like "mission control updates" not failures.

**Visual Design Requirements:**
- [ ] Color Palette: Dark background (#1a1a1a) with subtle blue-gray gradient
- [ ] Typography: SF Pro Display for headers, SF Pro Text for body
- [ ] Layout: Centered modal with generous padding, subtle shadow/glow
- [ ] Icons: Custom icons that suggest "decision needed" not "error"
  - [ ] Use symbols like: ⚡ (decision), 🎯 (target), 📡 (signal)
  - [ ] Avoid: ❌ ⚠️ ❗ (too alarming)

**Dialog Structure:**
```
┌─────────────────────────────────────────┐
│          Decision Required              │
│   ─────────────────────────────        │
│                                         │
│   Transfer Control requires your        │
│   input on the following:              │
│                                         │
│   [Technical description of situation]  │
│                                         │
│   [Primary Action]  [Secondary Action]  │
└─────────────────────────────────────────┘
```

**Specific Dialogs to Replace:**
- [ ] Folder Exists Dialog: Already implemented but needs visual upgrade
- [ ] Disk Full: "Destination capacity reached. Select alternate destination or free space."
- [ ] Permission Denied: "Access credentials required for [destination]"  
- [ ] File Corruption: "Source integrity check failed. Recommend source verification."
- [ ] Network Timeout: "Connection to [destination] interrupted. Awaiting reconnection..."

---

## 🎯 SPRINT 0.20 - DARK THEME FOUNDATION
**2-hour sprint: "Cinema-grade darkness"**

**Context**: Maggy should feel at home in a color grading suite or DIT station where ambient light is controlled and screens are calibrated.

**Design Specifications:**

**Background Colors:**
- [ ] Primary: #0a0a0a (near black)
- [ ] Secondary: #1a1a1a (raised surfaces)  
- [ ] Tertiary: #2a2a2a (active elements)

**Accent Colors:**
- [ ] Primary Action: Subtle blue gradient (#1e3a5f to #2d4a7c)
- [ ] Success: Muted green (#2d5016)
- [ ] Warning: Amber (#5c4416)
- [ ] Transfers: Cool gray-blue (#364156)

**Text Colors:**
- [ ] Primary: #ffffff at 90% opacity
- [ ] Secondary: #ffffff at 60% opacity
- [ ] Disabled: #ffffff at 30% opacity

**Visual Effects:**
- [ ] Subtle gradients on interactive elements
- [ ] Minimal shadows (0-2px, low opacity)
- [ ] No pure black or white (except text)
- [ ] Smooth rounded corners (8-12px radius)

---

## 🎯 SPRINT 0.21 - TYPOGRAPHY & SPACING
**2-hour sprint: "Premium feel through details"**

**Typography Hierarchy:**
- [ ] App Title: SF Pro Display, 18pt, Medium
- [ ] Section Headers: SF Pro Display, 16pt, Regular  
- [ ] Button Text: SF Pro Text, 15pt, Semibold
- [ ] Body Text: SF Pro Text, 13pt, Regular
- [ ] Metadata: SF Mono, 11pt, Regular (for checksums, file sizes)

**Spacing System (8pt grid):**
- [ ] Micro: 4pt (tight groups)
- [ ] Small: 8pt (related elements)
- [ ] Medium: 16pt (sections)
- [ ] Large: 24pt (major sections)  
- [ ] XLarge: 32pt (view separation)

**Number Formatting:**
- [ ] File sizes: "1.24 GB" not "1,240 MB"
- [ ] Progress: "68%" with no decimals during transfer
- [ ] Time remaining: "About 5 minutes" not "5:23 remaining"
- [ ] Transfer rate: "124 MB/s" with consistent precision

---

## 🎯 SPRINT 0.22 - ANIMATIONS & TRANSITIONS
**2-hour sprint: "Smooth as butter"**

**Animation Principles:**
- [ ] Duration: 200-300ms for most transitions
- [ ] Easing: EaseInOut for movements, EaseOut for appearances
- [ ] Stagger: 50ms between list items

**Specific Animations:**
- [ ] Queue Item Addition: Slide in from right with fade (200ms)
- [ ] Transfer Start: Progress bar expands from 0 with subtle bounce
- [ ] Transfer Complete: Checkmark scales in (150ms) + color transition
- [ ] View Transitions: Cross-fade with slight scale (250ms)  
- [ ] Button Hovers: Subtle brightness increase (100ms)
- [ ] Error Dialogs: Fade in with slight scale up (200ms)

**Performance Considerations:**
- [ ] Disable animations if "Reduce Motion" is enabled
- [ ] Keep animations GPU-accelerated
- [ ] No animation should block user interaction

---

## 🎯 SPRINT 0.23 - ICON & BRANDING (FINAL)
**2-hour sprint: "Professional identity"**

**App Icon Requirements:**
- [ ] Film magazine inspired but abstract
- [ ] Works at all sizes (16x16 to 1024x1024)
- [ ] Recognizable in dock at small sizes
- [ ] Professional without being generic

**In-App Icons:**
- [ ] Source types: Camera cards, folders, drives
- [ ] Destination types: Local, network, archive  
- [ ] Status indicators: Queued, active, complete, error
- [ ] Actions: Add, remove, start, pause

**Brand Elements:**
- [ ] Consistent corner radius (match macOS Big Sur style)
- [ ] Subtle gradient direction (top-left light source)
- [ ] Professional without being cold
- [ ] Technical without being intimidating

---

## 🎯 SPRINT 0.24 - SOUND DESIGN  
**2-hour sprint: "Subtle audio feedback"**

**Sound Principles:**
- [ ] Minimal and professional
- [ ] Never jarring or attention-seeking
- [ ] Optional with granular controls

**Specific Sounds:**
- [ ] Transfer Complete: Subtle chime (like macOS "Glass")
- [ ] All Transfers Complete: Slightly longer success sound
- [ ] Error Occurred: Soft alert (not alarming)
- [ ] Item Added to Queue: Minimal click
- [ ] Transfer Started: Soft whoosh

**Implementation:**
- [ ] Use NSSound for system-like sounds
- [ ] Respect system volume settings
- [ ] Provide master on/off toggle
- [ ] Individual sound type toggles

---

## 🎯 VERSION 0.3 - PRO FEATURES (Month 2)
**"Better than Hedge workflows"**

- [ ] 📁 Network drive support (SMB, NAS)
- [ ] 📁 Custom naming patterns (date stamps, camera IDs)
- [ ] 📁 Transfer templates (save common workflows)
- [ ] 📁 Verify-only mode (check existing transfers)

## 🎯 VERSION 0.4 - PROFESSIONAL POLISH (Month 3)
**"Tool DITs recommend to colleagues"**

- [ ] 📊 Transfer history and logging
- [ ] 📊 Performance metrics and health monitoring
- [ ] 📊 Batch operations (multiple cards simultaneously)
- [ ] 📊 Keyboard shortcuts and menu bar integration
- [ ] 📊 Export transfer reports

## 🎯 VERSION 0.5 - DISTRIBUTION READY (Month 4)
**"Ship it to the world"**

- [ ] 🚀 Code signing and notarization
- [ ] 🚀 Installer package
- [ ] 🚀 Auto-update system
- [ ] 🚀 User documentation and tutorials
- [ ] 🚀 Website and distribution strategy

---

## 🎪 LONG-TERM VISION (Months 6-12)

### **VERSION 1.0 - HEDGE REPLACEMENT**
- Industry adoption by small crews
- Word-of-mouth growth in film community
- Feature parity with Hedge essentials

### **VERSION 2.0 - INDUSTRY STANDARD**
- Advanced checksumming (multiple algorithms)
- Cloud integration (direct upload to post facilities)
- Multi-camera sync and organization
- Integration with editorial systems (Avid, Resolve, etc.)

### **VERSION 3.0 - ECOSYSTEM**
- Mobile companion app (iOS remote monitoring)
- Web dashboard for post houses
- API for integration with other tools
- Enterprise features for large productions

---

## 🎬 SUCCESS METRICS:
- **0.1**: "I can use this for my shoots"
- **0.2**: "This looks more professional than Hedge"
- **0.3**: "This is actually better workflow than Hedge"
- **0.4**: "I'm recommending this to other filmmakers"
- **0.5**: "I'd pay for this if it weren't free"

**The Goal**: By version 0.5, Maggy should be the tool that small crews reach for first, not just because it's free, but because it's genuinely better than the expensive alternatives.

---

## 📌 MILESTONE COMMITS

- **M1**: Basic UI with drive detection
- **M2**: Single card to single destination copying
- **M3**: Checksum verification working
- **M4**: Queue management and failure handling
- **M5**: Camera detection and iconography
- **M6**: Production-ready polish

---

## 📌 OPEN QUESTIONS

- Should we support network destinations (SMB/NFS) in v1?
- How granular should progress reporting be? (file level vs. byte level)
- Should we auto-eject cards after successful transfer?
- Do we need to handle partial transfers (resume from checkpoint)?
- Should we verify checksums on destination after transfer completes?

---

## 🎯 USER WORKFLOW

**Primary Use Case**: Small crew DOP dumps 1-3 cards after each shoot
1. Insert cards into reader(s)
2. Cards appear in left panel with camera icons
3. Drag cards to destination drives (right panel)
4. Hit "Start Transfer" - sequential copying begins
5. Watch progress, checksum verification happens automatically
6. Get clear success/failure feedback with detailed logs

**Secondary Use Case**: Batch archive to multiple destinations
1. Select multiple cards
2. Drag to multiple archive drives
3. App queues all transfers sequentially
4. User can walk away, returns to completion summary

---

## 🔧 TECHNICAL CONSIDERATIONS

### **File Operations**
- Use `FileManager` for basic operations
- Consider `NSTask` with `rsync` for better progress reporting
- Handle permissions and locked files gracefully
- Verify destination space before starting

### **Performance**
- Don't block UI thread during transfers
- Stream checksums during copy (don't double-read files)
- Handle thermal throttling gracefully
- Memory-efficient for large files

### **Security**
- Verify checksums match before marking transfer complete
- Never overwrite existing files without user confirmation
- Log all operations for audit trail
- Handle interrupted transfers safely

---

## 🤖 AI COLLABORATOR INSTRUCTIONS

- Always refer to this file first
- Before continuing any work, read this entire document top to bottom
- Never introduce dependencies without explaining and getting approval
- Update this spec file whenever you make a move
- For this macOS app, push to git after local QA for web-based review
- **Priority order**: Reliability > Performance > Features > Polish
- **When in doubt**: Ask user, don't assume
- **File operations**: Test with real hardware when possible
- **Error handling**: Always provide user context and choice

---

## 📁 FILES TO CREATE EARLY

- `README.md` with project overview and build instructions
- `.gitignore` for Xcode/Swift projects
- Basic Xcode project structure
- `FileOperations.swift` - core transfer logic
- `ChecksumManager.swift` - hash calculation
- `DriveDetector.swift` - system integration

---

This file is sacred. Tend to it.