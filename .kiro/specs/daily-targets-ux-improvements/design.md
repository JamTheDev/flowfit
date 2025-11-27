# Design Document

## Overview

This design document outlines the implementation approach for enhancing the Daily Targets screen with discrete sliders and consistent header styling. The improvements focus on creating a more intuitive, touch-friendly interface while maintaining visual consistency across all survey screens.

## Architecture

### Component Structure

```
SurveyDailyTargetsScreen (StatefulWidget)
├── SurveyAppBar (existing)
├── ScrollView
│   ├── Progress Indicator
│   ├── Header Section (with icon badge)
│   ├── Calorie Target Card (existing)
│   ├── Steps Target Section (new discrete slider)
│   ├── Active Minutes Section (new discrete slider)
│   ├── Water Intake Section (new discrete slider)
│   ├── Info Section
│   └── Complete Button
```

### State Management

The screen will continue using local state management with `setState()` for immediate UI updates. Values are synchronized with the `surveyNotifierProvider` when changed.

**State Variables:**

- `_targetCalories: int` - Calorie target (existing)
- `_targetSteps: int` - Steps target (existing)
- `_targetActiveMinutes: int` - Active minutes target (existing)
- `_targetWaterLiters: double` - Water intake target (existing)
- `_isSubmitting: bool` - Submission state (existing)

## Components and Interfaces

### 1. Discrete Slider Widget

**Purpose:** Create a reusable slider component that snaps to predefined values with visual feedback.

**Widget Signature:**

```dart
Widget _buildDiscreteSliderSection({
  required IconData icon,
  required Color color,
  required String title,
  required int value,
  required List<int> options,
  required String Function(int) formatLabel,
  required String Function(int) formatValue,
  required void Function(int) onChanged,
})
```

**Widget Signature (Double variant):**

```dart
Widget _buildDiscreteSliderSectionDouble({
  required IconData icon,
  required Color color,
  required String title,
  required double value,
  required List<double> options,
  required String Function(double) formatLabel,
  required String Function(double) formatValue,
  required void Function(double) onChanged,
})
```

**Visual Design:**

```
┌─────────────────────────────────────────┐
│ [Icon] Title                            │
│                                         │
│        10,000 steps                     │
│                                         │
│  5K    10K    12K    15K                │
│  ●─────●─────○─────○                    │
│  └─────────────┘                        │
│     (active)                            │
└─────────────────────────────────────────┘
```

**Components:**

- Section header with icon and title
- Large value display (bold, colored)
- Slider with discrete divisions
- Labeled tick marks below slider
- Color-coded active track

### 2. Header Section Update

**Current Implementation:**

```dart
Row(
  children: [
    Container(icon badge),
    Column(
      title (dark grey),
      subtitle (grey),
    ),
  ],
)
```

**Updated Implementation:**

```dart
Row(
  children: [
    Container(icon badge with primary blue background),
    Column(
      title (AppTheme.primaryBlue),  // Changed
      subtitle (grey[600]),
    ),
  ],
)
```

### 3. Slider Implementation Details

**Flutter Slider Configuration:**

```dart
Slider(
  value: currentValue,
  min: options.first,
  max: options.last,
  divisions: options.length - 1,
  activeColor: sectionColor,
  inactiveColor: Colors.grey[300],
  thumbColor: sectionColor,
  label: formatLabel(currentValue),
  onChanged: (value) {
    // Find nearest option
    final nearestOption = _findNearestOption(value, options);
    onChanged(nearestOption);
  },
)
```

**Snap-to-Value Logic:**

```dart
T _findNearestOption<T extends num>(T value, List<T> options) {
  return options.reduce((a, b) {
    return (value - a).abs() < (value - b).abs() ? a : b;
  });
}
```

### 4. Tick Mark Labels

**Implementation:**

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: options.map((option) {
    final isSelected = value == option;
    return Text(
      formatLabel(option),
      style: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? color : Colors.grey[600],
      ),
    );
  }).toList(),
)
```

## Data Models

No new data models required. Existing survey data structure remains unchanged:

```dart
{
  'dailyCalorieTarget': int,
  'dailyStepsTarget': int,
  'dailyActiveMinutesTarget': int,
  'dailyWaterTarget': double,
}
```

## Error Handling

### Slider Value Validation

**Scenario:** User somehow sets an invalid value
**Handling:** Clamp value to nearest valid option before saving

```dart
void _validateAndSetValue(int value, List<int> options) {
  final validValue = _findNearestOption(value, options);
  setState(() => _targetValue = validValue);
}
```

### State Persistence

**Scenario:** User navigates back and returns
**Handling:** Load existing values from `surveyNotifierProvider` in `initState()`

## Testing Strategy

### Manual Testing Focus

1. **Slider Interaction**

   - Drag slider thumb to each snap point
   - Verify smooth snapping behavior
   - Confirm value updates immediately
   - Check tick mark highlighting

2. **Visual Consistency**

   - Compare header styling across all survey screens
   - Verify primary blue color usage
   - Check icon badge styling
   - Validate spacing and alignment

3. **Navigation Flow**

   - Navigate forward through survey
   - Navigate backward using back button
   - Verify state persistence
   - Confirm submission works correctly

4. **Responsive Design**
   - Test on different screen sizes
   - Verify slider touch targets are adequate (min 44x44 dp)
   - Check text readability
   - Validate layout on small screens

### Edge Cases

1. **Minimum/Maximum Values**

   - Slider at first option (leftmost)
   - Slider at last option (rightmost)
   - Rapid slider dragging

2. **State Management**
   - Quick navigation between screens
   - Multiple value changes before submission
   - Back navigation after value changes

## UI/UX Considerations

### Touch Targets

- Slider thumb: Minimum 44x44 dp (Flutter default)
- Tick mark labels: Informational only, not interactive
- Adequate spacing between sections (32px)

### Visual Hierarchy

1. **Primary:** Large value display (20-24px, bold, colored)
2. **Secondary:** Section title (16px, semi-bold)
3. **Tertiary:** Tick mark labels (12px, regular)

### Color Scheme

- **Steps:** Green (`Colors.green`)
- **Active Minutes:** Purple (`Colors.purple`)
- **Water Intake:** Blue (`Colors.blue`)
- **Calorie Target:** Orange (`Colors.orange`)
- **Headers:** Primary Blue (`AppTheme.primaryBlue`)

### Accessibility

- Slider provides haptic feedback (Flutter default)
- Large touch targets for easy interaction
- High contrast colors for readability
- Clear value labels for screen readers

## Performance Considerations

- Slider updates use `setState()` for immediate feedback
- No expensive calculations during drag
- Debouncing not required (discrete values only)
- Minimal widget rebuilds (scoped to slider section)

## Implementation Notes

### Code Organization

1. Keep existing calorie target card implementation
2. Create reusable slider builder methods
3. Extract snap-to-value logic into helper method
4. Maintain consistent spacing and styling

### Migration Strategy

1. Update header styling (non-breaking)
2. Replace chip-based UI with sliders (one section at a time)
3. Test each section independently
4. Verify state management still works
5. Validate submission flow

### Backward Compatibility

- No changes to data structure
- No changes to navigation flow
- No changes to backend API
- Existing saved values remain valid

## Design Decisions

### Why Discrete Sliders?

**Rationale:**

- More intuitive than tapping chips
- Better use of screen space
- Clearer visual representation of range
- Easier one-handed operation
- Modern, polished feel

### Why Keep Calorie Card?

**Rationale:**

- Calorie calculation is complex (based on profile)
- Users need context (age, weight, activity level)
- Adjust button provides fine-grained control
- Different interaction pattern is appropriate

### Why Primary Blue Headers?

**Rationale:**

- Matches intro and basic info screens
- Creates visual consistency
- Reinforces brand identity
- Better visual hierarchy
- More engaging and modern

## Future Enhancements

1. **Haptic Feedback:** Add custom haptic feedback when snapping to values
2. **Animations:** Smooth value transitions with animated numbers
3. **Presets:** Quick preset buttons (e.g., "Beginner", "Intermediate", "Advanced")
4. **Recommendations:** Show recommended values based on user profile
5. **Progress Visualization:** Show how targets compare to average users
