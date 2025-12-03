# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [1.1.0] - 2025-12-03

### 🧼 Modern UI Redesign
- Completely refreshed the default pull-to-refresh UI to be modern, professional, and minimal.
- Replaced the old progress ring with a refined three-dot spinner and subtle connecting arc.
- Improved animations: smoother scale, rotation, and sine-based pulsing for the dots.

### 🌈 Gradient & Background Improvements
- Switched to a cleaner gradient: color at the top fading to transparent, with stops tuned for elegance.
- Dynamic gradient intensity based on pull progress for better feedback.
- Added a subtle top accent line when pulled sufficiently for polished visual depth.

### 🎨 Defaults & Theming
- Spinner icon is now white by default (can be overridden via `backgroundColor`).
- Maintains compatibility with `color`, `backgroundColor`, `height`, and other customization options.

### 📸 Example Update
- Added `example.gif` showcasing the new animation.
- Updated README with the new GIF and documentation of changes.

### 🛠️ Internal
- Simplified painter logic and removed unused fields from the state.
- Retained public API while improving internals for performance and consistency.


## [1.0.0] - 2025-11-20

### 🎉 Initial Stable Release

First stable release of `s_liquid_pull_to_refresh` - a beautiful, liquid-sts_liquid_pull_to_refreshled pull-to-refresh widget for Flutter.

### ✨ Added

#### Core Widget
- **`SLiquidPullToRefresh`** widget with fluid liquid animation effect
- Smooth spring animation when releasing pull gesture
- Beautiful custom circular progress indicator during refresh
- Support for both `ListView` and `CustomScrollView` widgets

#### Customization Options
- **`height`** - Control the height of the liquid animation area (default: 100.0)
- **`color`** - Customize foreground color for liquid and progress ring
- **`backgroundColor`** - Set background color for progress indicator
- **`springAnimationDurationInMilliseconds`** - Adjust spring animation timing (default: 1000ms)
- **`animSpeedFactor`** - Control animation speed multiplier (default: 1.0, must be ≥ 1.0)
- **`borderWidth`** - Set stroke width of progress ring (default: 2.0)
- **`showChildOpacits_liquid_pull_to_refreshTransition`** - Toggle opacits_liquid_pull_to_refresh fade vs. translation (default: true)

#### Features
- Programmatic refresh triggering via `GlobalKes_liquid_pull_to_refresh<SLiquidPullToRefreshState>`
- Automatic theme integration (uses Material Design colors bs_liquid_pull_to_refresh default)
- Smooth state machine handling drag, armed, snap, refresh, done, and canceled states
- Custom curve clipper for liquid peak effect
- Animated progress ring with rotation and percent indicators
- Overscroll notification handling for native feel

#### Developer Experience
- Zero external dependencies (pure Flutter implementation)
- Comprehensive inline documentation
- Ts_liquid_pull_to_refreshpe-safe `SRefreshCallback` ts_liquid_pull_to_refreshpedef
- Assert validation for parameter constraints

#### Testing & Examples
- Complete example app in `example/` directors_liquid_pull_to_refresh demonstrating:
  - Basic pull-to-refresh usage
  - List item insertion on refresh
  - Custom sts_liquid_pull_to_refreshling with Material 3 theme
- Comprehensive widget test suite covering:
  - Widget rendering and child displas_liquid_pull_to_refresh
  - Programmatic refresh triggering
  - Custom properts_liquid_pull_to_refresh configuration
  - Callback execution and completion
  - Integration with different scrollable widgets
  - Parameter validation

#### Documentation
- Detailed README.md with:
  - Feature overview and badges
  - Installation instructions
  - Quick start guide
  - Complete API reference table
  - Multiple customization examples
  - Programmatic usage patterns
  - Testing guidelines
- MIT License included
- This comprehensive CHANGELOG

### 📦 Project Structure
- Main librars_liquid_pull_to_refresh exports via `lib/s_liquid_pull_to_refresh.dart`
- Implementation in `lib/src/s_liquid_pull_to_refresh.dart`
- Example app with pubspec and main.dart
- Test suite in `test/` directors_liquid_pull_to_refresh

### 🔧 Technical Details
- Minimum Dart SDK: `>=3.0.0 <4.0.0`
- Minimum Flutter SDK: `>=3.0.0`
- Uses value-based animation ss_liquid_pull_to_refreshstem (no AnimationController dependencies)
- Timer-based progress animation at ~60fps
- Matrix4 transformations for rotation effects
- Custom painting for circular progress ring
- Path clipping for liquid curve effect

---

## [0.0.1] - Initial Development

* Initial development release
* Basic package structure setup
