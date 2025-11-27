# Design Document

## Overview

The onboarding survey flow currently uses `pushReplacementNamed()` for navigation, which removes the previous route from the stack. This causes `Navigator.pop()` to fail when users tap the back button, resulting in black screens. The solution involves switching to `push()` for navigation between survey steps while maintaining data persistence through Riverpod state management.

## Architecture

### Navigation Strategy

**Current (Broken) Flow:**

```
Survey Intro → (pushReplacementNamed) → Basic Info → (pushReplacementNamed) → Body Measurements
                                              ↑
                                         pop() fails - black screen
```

**Fixed Flow:**

```
Survey Intro → (push) → Basic Info → (push) → Body Measurements
                             ↑
                        pop() works - returns to Survey Intro
```

### Key Design Decisions

1. **Use `push()` instead of `pushReplacementNamed()`**: This maintains the navigation stack, allowing back navigation to work properly.

2. **Preserve Data with Riverpod**: Since we're keeping the previous screens in the stack, user data is already preserved in the `surveyNotifierProvider`. No additional state management is needed.

3. **Custom Back Button Handling**: The `SurveyAppBar` widget will accept an optional `onBack` callback. If provided, it uses that; otherwise, it defaults to `Navigator.pop()`.

4. **Survey Intro Special Case**: The Survey Intro screen (Step 0) needs special handling:
   - If it's the entry point, the back button should navigate to the previous screen (dashboard/welcome)
   - If accessed from within the survey flow, it should pop normally

## Components and Interfaces

### Modified Components

#### 1. `SurveyAppBar` Widget

- **Current**: Uses `Navigator.pop()` directly
- **Updated**: Accepts optional `onBack` callback for custom back behavior
- **Behavior**:
  - If `onBack` is provided, use it
  - Otherwise, use `Navigator.pop(context)`
  - Only show back button if `currentStep > 0` or custom logic applies

#### 2. Survey Screens (All 4 Steps)

- **Current**: Use `pushReplacementNamed()` for navigation
- **Updated**: Use `push()` for navigation to next step
- **Behavior**:
  - Pass arguments (userId, name, etc.) to maintain context
  - Data is automatically preserved in Riverpod state
  - Back button works via `Navigator.pop()`

#### 3. Survey Intro Screen

- **Current**: No back button handling
- **Updated**: Add back button with custom logic
- **Behavior**:
  - If accessed from dashboard/welcome, back button navigates back
  - If accessed from within survey flow, back button pops normally

### Navigation Routes

```dart
// Current (broken)
Navigator.pushReplacementNamed(context, '/survey_basic_info', arguments: args);

// Fixed
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const SurveyBasicInfoScreen(),
    settings: RouteSettings(arguments: args),
  ),
);
```

## Data Models

No changes to data models. The `surveyNotifierProvider` already handles all data persistence:

```dart
// Data is automatically preserved when using push()
final surveyState = ref.watch(surveyNotifierProvider);
final age = surveyState.surveyData['age']; // Still available after pop()
```

## Error Handling

1. **Empty Navigation Stack**: If `Navigator.pop()` is called with an empty stack, Flutter handles it gracefully (no-op). However, we'll add explicit checks in the Survey Intro screen.

2. **Missing Arguments**: Arguments are passed through the navigation stack. If missing, screens have fallback values.

3. **Data Loss**: Since we're using `push()` instead of `pushReplacementNamed()`, data is preserved in Riverpod state even if the user navigates back and forth.

## Testing Strategy

### Unit Tests

- Verify that `SurveyAppBar` renders back button correctly based on `currentStep`
- Verify that `onBack` callback is called when provided

### Integration Tests

- Navigate through all survey steps and verify back button works at each step
- Verify data is preserved when navigating back and forth
- Verify Survey Intro back button navigates correctly
- Verify no black screens appear when tapping back buttons

### Manual Testing

1. Start survey from dashboard
2. Complete Step 1 (Basic Info)
3. Tap back button → should return to Survey Intro
4. Tap back button again → should return to dashboard
5. Tap "LET'S PERSONALIZE" → should return to Basic Info with data preserved
6. Continue through all steps, tapping back at each step to verify navigation

## Implementation Notes

- **Minimal Changes**: Only modify navigation calls and `SurveyAppBar` widget
- **Backward Compatible**: No breaking changes to existing APIs
- **Performance**: Using `push()` instead of `pushReplacementNamed()` has negligible performance impact
- **User Experience**: Users can now navigate back through the survey flow naturally

## Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Navigation Stack                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Dashboard                                                  │
│      ↓ (push)                                              │
│  Survey Intro (Step 0)                                     │
│      ↓ (push)                                              │
│  Basic Info (Step 1)                                       │
│      ↓ (push)                                              │
│  Body Measurements (Step 2)                                │
│      ↓ (push)                                              │
│  Activity Goals (Step 3)                                   │
│      ↓ (push)                                              │
│  Daily Targets (Step 4)                                    │
│      ↓ (pushReplacementNamed to /dashboard)               │
│  Dashboard                                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Back button at any step pops to previous step
```
