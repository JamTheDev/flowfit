# Implementation Plan

- [x] 1. Update SurveyAppBar widget to support custom back button handling

  - Modify the `SurveyAppBar` widget to accept an optional `onBack` callback parameter
  - Update the back button logic to use the callback if provided, otherwise default to `Navigator.pop()`
  - Ensure the back button is only shown when appropriate (currentStep > 0 or custom logic)
  - _Requirements: 2.2, 2.3_

- [x] 2. Update Survey Basic Info Screen navigation

  - Replace `pushReplacementNamed()` with `push()` for navigation to next step
  - Ensure arguments are passed through the navigation stack
  - Verify back button works correctly via `SurveyAppBar`
  - _Requirements: 1.1, 1.3, 2.1_

-

- [x] 4. Update Survey Body Measurements Screen navigation

  - Replace `pushReplacementNamed()` with `push()` for navigation to next step
  - Ensure arguments are passed through the navigation stack
  - Verify back button works correctly via `SurveyAppBar`
  - _Requirements: 1.1, 1.3, 2.1_

- [x] 5. Update Survey Activity Goals Screen navigation

  - Replace `pushReplacementNamed()` with `push()` for navigation to next step
  - Ensure arguments are passed through the navigation stack
  - Verify back button works correctly via `SurveyAppBar`
  - _Requirements: 1.1, 1.3, 2.1_

- [x] 6. Update Survey Daily Targets Screen navigation

  - Replace `pushReplacementNamed()` with `push()` for navigation to dashboard on completion
  - Use `pushReplacementNamed()` only for the final navigation to dashboard (to clear survey flow)
  - Ensure back button works correctly via `SurveyAppBar`
  - _Requirements: 1.1, 1.3, 2.1_

-

- [x] 7. Test back button navigation through all survey steps

  - Manually test back button at each survey step
  - Verify data is preserved when navigating back and forth
  - Verify no black screens appear
  - _Requirements: 1.1, 1.2, 1.4_
