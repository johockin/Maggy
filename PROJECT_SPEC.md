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

- 2025-01-18 - Claude - **CRITICAL ERROR & RECOVERY**: Accidentally deleted PROJECT_SPEC.md while fixing Xcode project. Recreated from user's original. Built complete MVP: SwiftUI app with drag/drop, sequential transfers, SHA-256 checksums, test mode, error dialogs. Set up git repo. LESSON LEARNED: Never delete the spec file - it's the sacred foundation.
- 2024-12-XX - Human - Initial spec creation based on Hedge replacement needs

---

## 🧱 ROADMAP & PIPELINE

### **NOW** (MVP)
- [x] Basic UI: drive detection panels (left/right)
- [x] File system scanning for mounted drives
- [x] Simple drag-and-drop from source to destination
- [x] Basic file copying with progress bar
- [x] SHA-256 checksum verification

### **NEXT** (Core Features)
- [x] Queue management (multiple cards to multiple destinations)
- [x] Failure handling with user choice dialog
- [ ] xxHash fast checksum option
- [x] Transfer logging and error reporting
- [x] Camera detection (FX6, A7S icons implemented, RED/ARRI planned)

### **LATER** (Polish)
- [ ] Transfer history/log viewer
- [ ] Customizable checksum algorithms
- [ ] Batch operations (multiple cards same destination)
- [ ] Preferences/settings panel
- [ ] Export/import transfer logs

### **SOMEDAY** (Nice to Have)
- [ ] Network destination support
- [ ] Cloud storage integration
- [ ] Automated backup scheduling
- [ ] Multiple checksum verification

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