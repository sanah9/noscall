# Desktop UI Architecture

## Overview

This directory contains the desktop-specific UI components for macOS/Windows/Linux platforms. The desktop UI features a two-column layout with a resizable sidebar and content area.

## Components

### 1. `DesktopScaffold`
The left sidebar navigation component with three main sections:
- **Recent**: Call history
- **Contacts**: Contact list  
- **Me**: Settings/Profile

The sidebar width is resizable by dragging the divider (min: 200px, max: 400px, default: 280px).

### 2. `DesktopPageWrapper`
A reusable wrapper component for content pages that provides:
- Consistent page title styling
- Optional trailing widget area (e.g., search bar)
- Fixed height header (64px) with bottom border

### 3. `DesktopSearchBar`
A standardized search bar component with:
- Fixed width: 280px
- Search icon prefix
- Rounded corners (8px)
- Subtle background color

### 4. Desktop Pages

#### `DesktopHomePage`
The main desktop home page that orchestrates the layout and navigation.

#### `DesktopRecentCallsPage`
Desktop-optimized version of the recent calls page featuring:
- Integrated search bar in header
- List view showing call details, direction, and timestamp
- Click to view contact details

#### `DesktopContactsPage`
Desktop-optimized version of the contacts page featuring:
- Integrated search bar in header
- List view with avatar, name, and about text
- Inline voice/video call buttons

#### `DesktopSettingsPage`
Desktop-optimized version of the settings page featuring:
- Profile card with avatar and actions
- Settings menu in card layout
- Keys, Relays, About, and Logout options

## Usage

### Using DesktopPageWrapper

To create a new desktop page, use `DesktopPageWrapper` with optional search bar:

```dart
import 'package:flutter/material.dart';
import '../desktop/desktop_page_wrapper.dart';

class MyDesktopPage extends StatefulWidget {
  @override
  State<MyDesktopPage> createState() => _MyDesktopPageState();
}

class _MyDesktopPageState extends State<MyDesktopPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DesktopPageWrapper(
      title: 'My Page',
      trailing: DesktopSearchBar(
        controller: _searchController,
        hintText: 'Search...',
        onChanged: (query) {
          // Handle search
        },
      ),
      child: YourPageContent(),
    );
  }
}
```

### Platform Detection

The app automatically detects the platform and shows:
- **Desktop (macOS/Windows/Linux)**: Two-column layout with sidebar
- **Mobile (iOS/Android)**: Bottom navigation bar

```dart
// Platform detection is handled in HomePage
bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}
```

## Window Settings

### macOS
Minimum window size is set to 900x600 in `MainFlutterWindow.swift`:

```swift
self.minSize = NSSize(width: 900, height: 600)
```

### Windows
The Windows runner also enforces a minimum window size of 900x600 in `windows/runner/flutter_window.cpp`.

Current Windows support is aimed at core desktop flows first: launch, login, navigation, contacts, recent calls, settings, and other in-app desktop pages. System-level incoming call UI and VoIP push remain mobile-specific for now.

## Design Guidelines

1. **Left Sidebar**: 
   - Resizable width (200px - 400px, default: 280px)
   - Drag divider for adjustment with visual feedback
   
2. **Page Header**: 
   - Fixed height: 64px
   - Title on the left
   - Optional trailing widget (search bar, actions) on the right
   - Bottom border for separation

3. **Search Bar**: 
   - Fixed width: 280px
   - Positioned in header trailing area
   - Consistent styling across all pages

4. **Content Area**: 
   - Fills remaining vertical space
   - Padding: 24px horizontal for list items
   - Card-based layouts for settings/profile

5. **Colors**: Uses Material 3 color scheme tokens consistently

## Implementation Notes

- **Platform Detection**: Automatically switches between mobile and desktop UI based on platform
- **State Management**: Each desktop page manages its own state independently
- **Code Reuse**: Shares data models and business logic with mobile pages
- **Separation of Concerns**: Desktop UI components are isolated in `/lib/desktop/` directory
