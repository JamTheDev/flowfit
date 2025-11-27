# Design Document

## Overview

This design enhances the existing `SurveyAppBar` widget to support an optional progress indicator display, ensuring all onboarding survey screens consistently show the user's progress through the survey flow. The solution maintains backward compatibility while providing a clean, reusable component that eliminates code duplication across survey screens.

## Architecture

### Component Structure

```
lib/widgets/
  └── survey_app_bar.dart
      ├── SurveyAppBar (enhanced)
      └── SurveyProgressIndicator (existing)

lib/screens/onboarding/
  ├── survey_intro_screen.dart (refactored)
  ├── survey_basic_info_screen.dart (already uses SurveyAppBar)
  ├── survey_body_measurements_screen.dart (already uses SurveyAppBar)
  ├── survey_activity_goals_screen.dart (refactored)
  └── survey_daily_targets_screen.dart (refactored)
```

### Design Pattern

The solution follows the **Composition Pattern** by enhancing the existing `SurveyAppBar` widget with an optional progress indicator parameter, rather than creating a new widget or using inheritance.

## Components and Interfaces

### Enhanced SurveyAppBar Widget

**Purpose**: Provide a consistent AppBar across all survey screens with optional progress indicator

**Properties**:

- `currentStep` (int, required): The current step number in the survey flow
- `totalSteps` (int, default: 4): Total number of steps in the survey
- `onBack` (VoidCallback?, optional): Custom back button handler
- `showProgressText` (bool, default: true): Whether to display the "X/Y" progress text
- `title` (String?, optional): Optional title text for the AppBar

**Behavior**:

- Displays a back arrow button when `currentStep > 0`
- Shows progress text in the format "X/Y" in the actions area when `showProgressText` is true
- Uses transparent background with no elevation for modern, clean appearance
- Applies consistent text styling (grey color, semi-bold weight)

### SurveyProgressIndicator Widget

**Status**: No changes required - this widget already exists and works correctly for the horizontal progress bars

## Data Models

No new data models are required. The component uses primitive types (int, bool, String) for configuration.

## Error Handling

### Edge Cases

1. **Invalid step numbers**: If `currentStep` exceeds `totalSteps`, display the values as-is (no clamping) to make the error obvious during development
2. **Zero or negative steps**: Display as-is for debugging purposes
3. **Missing title**: When title is null, the AppBar displays without a title (current behavior maintained)

### Validation

No runtime validation is needed as this is a presentation component. Invalid values will be caught during development/testing.

## Testing Strategy

### Manual Testing Checklist

1. **Visual Consistency**:

   - Verify progress indicator appears on all 5 survey screens
   - Confirm text format is "X/Y" with correct step numbers
   - Check text styling matches design (grey color, semi-bold)
   - Validate positioning in AppBar actions area

2. **Navigation Flow**:

   - Test back button functionality on each screen
   - Verify progress updates correctly when moving forward/backward
   - Confirm intro screen (step 0) shows "0/4"

3. **Responsive Behavior**:
   - Test on different screen sizes
   - Verify text doesn't overflow or get cut off
   - Check padding and spacing consistency

### Widget Testing (Optional)

If comprehensive testing is desired:

- Test SurveyAppBar renders with correct progress text
- Test back button callback invocation
- Test optional parameters (showProgressText, title)
- Test preferredSize returns correct height

## Implementation Notes

### Refactoring Strategy

1. **Phase 1**: Enhance `SurveyAppBar` widget

   - Add `showProgressText` parameter
   - Add progress text rendering in actions area
   - Maintain backward compatibility

2. **Phase 2**: Refactor survey screens

   - Update `survey_intro_screen.dart` to use `SurveyAppBar`
   - Update `survey_activity_goals_screen.dart` to use `SurveyAppBar`
   - Update `survey_daily_targets_screen.dart` to use `SurveyAppBar`
   - Remove duplicate AppBar code

3. **Phase 3**: Verification
   - Run app and navigate through entire survey flow
   - Verify visual consistency
   - Check for any regressions

### Code Reusability

The enhanced `SurveyAppBar` can be reused for:

- Future survey screens
- Multi-step forms in other parts of the app
- Any flow requiring step-by-step progress indication

### Backward Compatibility

Screens already using `SurveyAppBar` (basic info, body measurements) will continue to work without changes. The new `showProgressText` parameter defaults to `true`, automatically adding the progress indicator.

## Design Decisions

### Decision 1: Enhance Existing Widget vs. Create New Widget

**Chosen**: Enhance existing `SurveyAppBar` widget

**Rationale**:

- Reduces code duplication
- Maintains single source of truth for survey AppBar styling
- Easier to maintain and update in the future
- Backward compatible with optional parameters

**Alternatives Considered**:

- Create `SurveyAppBarWithProgress` widget: Rejected due to code duplication
- Use composition with wrapper widget: Rejected as unnecessarily complex

### Decision 2: Progress Text Format

**Chosen**: "X/Y" format (e.g., "2/4")

**Rationale**:

- Already used in 3 of 5 screens (established pattern)
- Clear and concise
- Universally understood format
- Minimal space requirement

**Alternatives Considered**:

- "Step X of Y": Rejected as too verbose
- Progress percentage: Rejected as less intuitive for small step counts

### Decision 3: Default Behavior

**Chosen**: Show progress text by default (`showProgressText: true`)

**Rationale**:

- Aligns with requirements (all screens should show progress)
- Opt-out is easier than opt-in for this use case
- Reduces boilerplate in screen implementations

## Visual Design

### AppBar Layout

```
┌─────────────────────────────────────────────┐
│ ← [Back]          [Title]           [2/4]   │
└─────────────────────────────────────────────┘
```

### Styling Specifications

- **Background**: Transparent
- **Elevation**: 0
- **Back Icon**: Color `#314158` (dark blue-grey)
- **Progress Text**:
  - Color: `Colors.grey[600]`
  - Font Weight: `FontWeight.w600` (semi-bold)
  - Padding: 16px right
- **Title** (when present):
  - Color: `#314158`
  - Font Weight: `FontWeight.w600`
