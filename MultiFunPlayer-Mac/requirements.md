# MultiFunPlayer macOS Port

**Target Location:** `/Users/simonyam/Projects/MultiFunPlayer-Mac`
**Approach:** Full feature parity port using Avalonia UI

---

# Analysis

## Project Overview

**MultiFunPlayer** is a Windows application for synchronizing devices with media playback. It's written in C# targeting .NET 8.0 with a WPF-based UI.

## Current Technology Stack (Windows-Only)

| Component | Technology | Cross-Platform? |
|-----------|------------|-----------------|
| UI Framework | WPF (Windows Presentation Foundation) | No |
| UI Styling | MahApps.Metro + MaterialDesignThemes | No (WPF-specific) |
| MVVM Framework | Stylet | No (WPF-specific) |
| Input Handling | RawInput.Sharp | No (Windows API) |
| Controller Input | Vortice.XInput | No (Windows XInput) |
| System Info | System.Management (WMI) | No (Windows-only) |
| Serial Ports | System.IO.Ports | Yes |
| Device Protocol | Buttplug.Net | Yes (macOS supported) |
| Logging | NLog | Yes |
| JSON | Newtonsoft.Json | Yes |

## Porting Challenges

### 1. UI Framework (Critical - Largest Effort)
WPF is Windows-only. The entire UI layer must be rewritten.

**Recommended Replacement:** Avalonia UI
- Cross-platform (macOS, Linux, Windows)
- XAML-based, spiritual successor to WPF
- Production-ready (used by JetBrains, GitHub, Unity)
- MaterialDesign.Avalonia available for Material Design styling

### 2. Windows-Specific Libraries

| Library | Purpose | macOS Alternative |
|---------|---------|-------------------|
| RawInput.Sharp | Low-level input | Not needed on macOS - use standard input APIs |
| Vortice.XInput | Controller input | SDL2 bindings or remove |
| System.Management | WMI queries | macOS system APIs via P/Invoke or use platform detection |

### 3. Buttplug.io (Good News!)
Buttplug.io **fully supports macOS** via:
- Bluetooth LE (btleplug library)
- Serial ports
- WebSocket connections

This is the core functionality and it works cross-platform.

---

## Porting Strategies

### Option A: Full Avalonia Port (Recommended)
**Effort: High | Maintainability: Best**

1. Replace WPF with Avalonia UI
2. Replace MahApps.Metro with Avalonia themes
3. Replace Stylet with CommunityToolkit.Mvvm or ReactiveUI
4. Abstract Windows-specific code behind interfaces
5. Create platform-specific implementations for input handling

**Pros:**
- Single codebase for Windows + macOS + Linux
- Familiar XAML development experience
- Best long-term maintainability

**Cons:**
- Significant rewrite of UI layer
- Need to rebuild all custom controls/styling

### Option B: Web-Based UI with Backend Service
**Effort: Medium | Architecture: Different**

1. Keep C# business logic as a headless service
2. Expose REST/WebSocket API
3. Build web frontend (React/Vue/Svelte)
4. Run as a local web server

**Pros:**
- Modern web UI with rich libraries
- Could run on any device with a browser
- Easier to find web developers

**Cons:**
- Different architecture from original
- Additional complexity (web server, bundling)
- May not feel as "native"

### Option C: macOS-Native Swift UI with Shared Core
**Effort: High | Platform: macOS-only**

1. Extract core logic into a cross-platform .NET library
2. Build native macOS app in Swift/SwiftUI
3. Bridge via .NET MAUI or native interop

**Pros:**
- Best native macOS experience
- Access to all macOS APIs

**Cons:**
- macOS-only (no Linux)
- Requires Swift expertise
- Complex interop layer

---

## Recommended Approach: Option A (Avalonia Port)

### Phase 1: Preparation
1. Fork the repository
2. Analyze all Windows-specific code paths
3. Create abstraction interfaces for platform-specific features
4. Set up Avalonia project structure

### Phase 2: Core Library Extraction
1. Separate UI-independent code into a shared library
2. Keep device communication, script parsing, media sync logic
3. Move all Buttplug.io integration to shared library

### Phase 3: Avalonia UI Implementation
1. Create new Avalonia UI project
2. Port XAML views (with modifications for Avalonia syntax)
3. Implement ViewModels using CommunityToolkit.Mvvm
4. Recreate Material Design styling with MaterialDesign.Avalonia

### Phase 4: Platform Abstraction
1. Create `IPlatformService` interfaces for:
   - Input handling
   - System information
   - File dialogs
   - Notifications
2. Implement macOS-specific versions

### Phase 5: Testing & Polish
1. Test all device connections on macOS
2. Verify Bluetooth LE functionality
3. Test with various media players (MPV, VLC)
4. Handle macOS-specific permissions (Bluetooth, Accessibility)

---

## Key Files to Modify

Based on the project structure, these areas need attention:
- `/Source/MultiFunPlayer/*.xaml` - All WPF views → Avalonia
- `/Source/MultiFunPlayer/ViewModels/` - MVVM layer
- `/Source/MultiFunPlayer/Input/` - Input handling (platform-specific)
- `/Source/MultiFunPlayer/MediaPlayers/` - Media player integrations

---

## macOS-Specific Considerations

1. **Permissions**: macOS requires explicit permissions for Bluetooth, Accessibility
2. **Code Signing**: App needs to be signed for Gatekeeper
3. **Media Players**: MPV and VLC work on macOS; DeoVR may have limitations
4. **Serial Ports**: May appear as `/dev/tty.*` devices

---

## Alternative: Request Cross-Platform from Maintainer

There's an open issue (#3) requesting Linux support, targeted for v2.0.0. You could:
1. Comment on the issue expressing macOS interest
2. Offer to contribute to cross-platform effort
3. Collaborate with the maintainer on architecture decisions

---

## Implementation Plan

### Step 0: Create Project & Requirements
1. Create `/Users/simonyam/Projects/MultiFunPlayer-Mac` directory
2. Create `requirements.md` with this plan documentation
3. Initialize git repository

### Step 1: Clone Original Source
```bash
cd /Users/simonyam/Projects/MultiFunPlayer-Mac
git clone https://github.com/Yoooi0/MultiFunPlayer.git original
```
This keeps the original source as a reference while we build the cross-platform version.

### Step 2: Create New Solution Structure
```
MultiFunPlayer.CrossPlatform/
├── MultiFunPlayer.Core/           # Shared business logic (extracted)
│   ├── Devices/                   # Buttplug.io integration
│   ├── MediaPlayers/              # Media player protocols
│   ├── Scripts/                   # Script parsing/sync
│   └── Services/                  # Core services
├── MultiFunPlayer.Avalonia/       # New Avalonia UI
│   ├── Views/                     # XAML views (ported)
│   ├── ViewModels/                # MVVM ViewModels
│   └── Styles/                    # Material Design styling
└── MultiFunPlayer.Platform.Mac/   # macOS-specific code
    ├── Input/                     # macOS input handling
    └── Services/                  # Platform services
```

### Step 3: Core Library Extraction
1. Identify all UI-independent code in the original project
2. Extract into `MultiFunPlayer.Core`:
   - Device communication (Buttplug.io)
   - Script format parsing (funscript, etc.)
   - Media synchronization logic
   - Video player protocols (MPV, VLC, etc.)
   - Settings/configuration management

### Step 4: Avalonia UI Setup
```xml
<!-- New .csproj targeting cross-platform -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <RuntimeIdentifiers>osx-x64;osx-arm64;win-x64;linux-x64</RuntimeIdentifiers>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Avalonia" Version="11.*" />
    <PackageReference Include="Avalonia.Desktop" Version="11.*" />
    <PackageReference Include="Material.Avalonia" Version="3.*" />
    <PackageReference Include="CommunityToolkit.Mvvm" Version="8.*" />
    <PackageReference Include="Buttplug.Net" Version="0.1.0-ci0094" />
  </ItemGroup>
</Project>
```

### Step 5: Port Views (WPF → Avalonia)
For each XAML file, convert WPF syntax to Avalonia:
- Replace `xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"`
  with `xmlns="https://github.com/avaloniaui"`
- Update binding syntax differences
- Replace MahApps controls with Material.Avalonia equivalents

### Step 6: Platform Abstraction Layer
```csharp
// IPlatformService interface
public interface IPlatformService
{
    Task<IEnumerable<string>> GetSerialPorts();
    Task<bool> RequestBluetoothPermission();
    Task ShowNotification(string title, string message);
    string GetAppDataPath();
}

// macOS implementation
public class MacPlatformService : IPlatformService
{
    public string GetAppDataPath() =>
        Path.Combine(Environment.GetFolderPath(
            Environment.SpecialFolder.ApplicationSupport),
            "MultiFunPlayer");
    // ... other implementations
}
```

### Step 7: Replace Windows-Specific Dependencies

| Original | Replacement |
|----------|-------------|
| RawInput.Sharp | Remove (not needed for core functionality) |
| Vortice.XInput | SDL2-CS for cross-platform controller support |
| System.Management | IOKit bindings for macOS (or remove) |
| MahApps.Metro | Material.Avalonia |
| Stylet | CommunityToolkit.Mvvm |

### Step 8: macOS-Specific Handling
1. **Info.plist** configuration for permissions:
   - `NSBluetoothAlwaysUsageDescription` (Bluetooth access)
   - `NSBluetoothPeripheralUsageDescription`
2. **Entitlements** for App Sandbox (if needed)
3. **Code signing** for distribution

### Step 9: Testing Matrix
- [ ] Buttplug.io device connection via Bluetooth
- [ ] Serial device connection
- [ ] MPV media player integration
- [ ] VLC media player integration
- [ ] Script loading and synchronization
- [ ] Settings persistence
- [ ] All UI functionality

---

## Estimated Scope

| Component | Original Lines | Effort |
|-----------|---------------|--------|
| Core Library | ~15,000 | Medium (refactoring) |
| Avalonia Views | ~5,000 | High (rewrite) |
| ViewModels | ~8,000 | Medium (adapt MVVM) |
| Platform Layer | New | Medium (new code) |
| Tests | ~2,000 | Medium (adapt) |

**Total: Significant project** - This is a substantial undertaking.

---

## Verification Plan

1. **Device Connectivity**: Connect a Buttplug.io-compatible device on macOS
2. **Media Sync**: Play a video in MPV and verify synchronization
3. **UI Completeness**: Compare every screen/feature with Windows version
4. **Performance**: Ensure smooth sync without latency issues
5. **Settings**: Verify all settings persist and load correctly
