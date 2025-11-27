# Requirements Document

## Introduction

This feature addresses the inconsistency in the onboarding survey screens where some screens display a progress indicator (e.g., "0/4", "3/4") in the AppBar while others do not. The goal is to standardize the user experience by ensuring all onboarding screens consistently show progress information to help users understand where they are in the survey flow.

## Glossary

- **Survey Flow**: The sequence of onboarding screens that collect user information (intro, basic info, body measurements, activity goals, daily targets)
- **Progress Indicator**: A visual element showing the current step number and total steps (e.g., "2/4")
- **SurveyAppBar**: A reusable widget component that provides consistent AppBar styling across survey screens
- **AppBar Actions**: The right-side area of the AppBar where additional UI elements can be placed

## Requirements

### Requirement 1

**User Story:** As a user going through the onboarding survey, I want to see my progress on every screen, so that I know how many steps remain

#### Acceptance Criteria

1. WHEN THE Survey_System displays any survey screen, THE Survey_System SHALL render a progress indicator showing the current step and total steps
2. THE Survey_System SHALL display the progress indicator in the format "X/Y" WHERE X is the current step number and Y is the total number of steps
3. THE Survey_System SHALL position the progress indicator in the AppBar actions area on the right side
4. THE Survey_System SHALL style the progress indicator text with grey color and semi-bold font weight to maintain visual consistency
5. THE Survey_System SHALL ensure the progress indicator is visible on all five survey screens: intro (0/4), basic info (1/4), body measurements (2/4), activity goals (3/4), and daily targets (4/4)

### Requirement 2

**User Story:** As a developer maintaining the codebase, I want the AppBar implementation to be consistent across all survey screens, so that the code is easier to maintain and modify

#### Acceptance Criteria

1. THE Survey_System SHALL use the SurveyAppBar widget component for all survey screens that require an AppBar
2. THE Survey_System SHALL extend the SurveyAppBar widget to support displaying the progress indicator text
3. THE Survey_System SHALL remove duplicate AppBar implementations from individual survey screens
4. THE Survey_System SHALL maintain backward compatibility with existing SurveyAppBar usage patterns
5. WHERE a survey screen uses a custom AppBar implementation, THE Survey_System SHALL refactor it to use the standardized SurveyAppBar widget
