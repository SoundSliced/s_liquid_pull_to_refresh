# SLiquidPullToRefresh Example App

This example app demonstrates various use cases and configurations of the `s_liquid_pull_to_refresh` package.

## Running the Example

1. Navigate to the example directory:
   ```bash
   cd example
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Examples Included

### 1. Basic Example
- Demonstrates default pull-to-refresh functionality
- Simple list with item insertion on refresh
- Default styling and animation timing

**Key Features:**
- Uses default height (100.0)
- Standard animation speed
- Material theme colors

### 2. Custom Colors
- Shows how to customize colors for your brand
- Custom height and border width
- Purple/deep purple color scheme

**Customizations:**
- `height: 150`
- `color: Colors.deepPurple`
- `backgroundColor: Colors.white`
- `borderWidth: 4.0`

### 3. Fast Animation
- Demonstrates faster animation speeds
- Reduced spring duration for snappy feel
- Orange color theme

**Customizations:**
- `animSpeedFactor: 2.0`
- `springAnimationDurationInMilliseconds: 600`
- Quick, responsive animations

### 4. Programmatic Trigger
- Shows how to trigger refresh via button press
- Uses `GlobalKey` to access widget state
- Demonstrates `show()` method usage

**Features:**
- Button to trigger refresh programmatically
- State management for refresh status
- Disabled button during refresh

### 5. GridView Example
- Demonstrates usage with GridView
- Shows color grid with dynamic items
- Uses `showChildOpacityTransition: false`

**Features:**
- 2-column grid layout
- Colorful cards with shadows
- Translation instead of opacity fade

## Code Structure

```
example/
├── lib/
│   └── main.dart          # All examples in one file
├── pubspec.yaml           # Dependencies
└── README.md              # This file
```

## Learning Resources

Each example page includes:
- Clear implementation of the widget
- Comments explaining key parameters
- Visual feedback for refresh actions
- Different scrollable widgets (ListView, GridView)

## Extending the Examples

Feel free to modify these examples to:
- Test different color combinations
- Experiment with animation timings
- Try with your own data sources
- Add network calls or database operations

## Related Documentation

- [Package README](../README.md) - Full API documentation
- [Main Library](../lib/s_liquid_pull_to_refresh.dart) - Library exports
- [Implementation](../lib/src/s_liquid_pull_to_refresh.dart) - Source code
- [Tests](../test/s_liquid_pull_to_refresh_test.dart) - Test suite
