# Requirements Document

## Introduction

The onboarding survey flow has a critical navigation bug where back buttons redirect to black screens. This occurs because survey screens use `pushReplacementNamed()` for navigation, which removes the previous route from the stack, making `Navigator.pop()` fail. The fix requires implementing proper back navigation that either returns to the previous survey step or handles the case where no previous step exists.

## Glossary

- **Survey Flow**: The 4-step onboarding process (Basic Info → Body Measurements → Activity Goals → Daily Targets)
- **Back Button**: The navigation button in the AppBar that allows users to return to the previous screen
- **Navigation Stack**: Flutter's internal stack of routes; `pushReplacementNamed()` removes the current route before adding the new one
- **Black Screen**: The result when `Navigator.pop()` is called with an empty navigation stack

## Requirements

### Requirement 1: Back Button Navigation in Survey Screens

**User Story:** As a user, I want to navigate back through the survey steps without encountering black screens, so that I can correct my answers.

#### Acceptance Criteria

1. WHEN the user taps the back button on any survey screen (Step 1-4), THE system SHALL navigate to the previous survey step
2. WHEN the user is on the first survey step (Basic Info), THE system SHALL either disable the back button or navigate to the survey intro screen
3. WHILE navigating between survey steps, THE system SHALL preserve the user's previously entered data
4. IF the user navigates back and then forward again, THE system SHALL retain the data from the previous navigation

### Requirement 2: Consistent Navigation Pattern

**User Story:** As a developer, I want a consistent navigation pattern across all survey screens, so that the codebase is maintainable and predictable.

#### Acceptance Criteria

1. THE system SHALL use a consistent navigation method across all survey screens (either `push` or `pushReplacement`)
2. WHEN navigating between survey steps, THE system SHALL pass arguments (userId, name, etc.) to maintain context
3. THE system SHALL implement proper back button handling in the `SurveyAppBar` widget
4. WHERE the back button is customized with an `onBack` callback, THE system SHALL use that callback instead of the default `Navigator.pop()`

### Requirement 3: Survey Intro Back Navigation

**User Story:** As a user, I want to navigate back from the survey intro screen to the previous screen, so that I can change my mind about starting the survey.

#### Acceptance Criteria

1. WHEN the user taps the back button on the Survey Intro screen, THE system SHALL navigate back to the previous screen (likely the dashboard or welcome screen)
2. IF no previous screen exists, THE system SHALL navigate to the dashboard as a fallback
