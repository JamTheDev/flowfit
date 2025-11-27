# Implementation Plan

- [x] 1. Enhance SurveyAppBar widget to support progress indicator

  - Add `showProgressText` boolean parameter (default: true)
  - Add `title` optional String parameter for AppBar title
  - Implement progress text rendering in actions area with format "X/Y"
  - Apply consistent styling: grey color, semi-bold font weight, 16px right padding
  - Ensure backward compatibility with existing usage
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.2, 2.4_

-

- [x] 2. Refactor survey_intro_screen.dart to use SurveyAppBar

  - Replace custom AppBar implementation with SurveyAppBar widget
  - Pass currentStep: 0, totalSteps: 4, title: 'Quick Setup'
  - Remove duplicate AppBar code (lines 69-91)
  - Verify progress indicator shows "0/4"
  - _Requirements: 1.5, 2.1, 2.3, 2.5_

-

- [x] 3. Refactor survey_activity_goals_screen.dart to use SurveyAppBar

  - Replace custom AppBar implementation with SurveyAppBar widget
  - Pass currentStep: 3, totalSteps: 4, title: 'Activity & Goals'
  - Remove duplicate AppBar code
  - Verify progress indicator shows "3/4"
  - _Requirements: 1.5, 2.1, 2.3, 2.5_

- [x] 4. Refactor survey_daily_targets_screen.dart to use SurveyAppBar

  - Replace custom AppBar implementation with SurveyAppBar widget
  - Pass currentStep: 4, totalSteps: 4, title: 'Your Daily Targets'
  - Remove duplicate AppBar code
  - Verify progress indicator shows "4/4"
  - _Requirements: 1.5, 2.1, 2.3, 2.5_

- [x] 5. Verify visual consistency across all survey screens

  - Navigate through complete survey flow (intro → basic info → body measurements → activity goals → daily targets)
  - Confirm progress indicator appears on all screens with correct step numbers
  - Verify text styling and positioning is consistent
  - Test back button navigation updates progress correctly
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
