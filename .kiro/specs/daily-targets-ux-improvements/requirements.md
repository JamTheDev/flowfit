# Requirements Document

## Introduction

This specification defines improvements to the Daily Targets screen in the onboarding survey flow. The goal is to enhance user experience by replacing chip-based selection with intuitive discrete sliders and ensuring visual consistency with other survey screens through primary blue header styling.

## Glossary

- **Daily Targets Screen**: The final screen (step 4/4) in the onboarding survey where users set their daily fitness goals (calories, steps, active minutes, water intake)
- **Discrete Slider**: A slider control that snaps to predefined values rather than allowing continuous adjustment
- **Primary Blue**: The main brand color used throughout the application (AppTheme.primaryBlue)
- **Header Section**: The title area at the top of each survey screen containing an icon badge, title text, and subtitle
- **Target Value**: A specific fitness goal metric (e.g., 10,000 steps, 30 minutes of activity)

## Requirements

### Requirement 1: Implement Discrete Sliders for Target Selection

**User Story:** As a user completing the onboarding survey, I want to adjust my daily targets using intuitive sliders, so that I can quickly set my goals without tapping multiple chips.

#### Acceptance Criteria

1. WHEN the user views the Steps Target section, THE Daily Targets Screen SHALL display a discrete slider with exactly 4 snap points at values [5000, 10000, 12000, 15000]
2. WHEN the user views the Active Minutes section, THE Daily Targets Screen SHALL display a discrete slider with exactly 4 snap points at values [20, 30, 45, 60]
3. WHEN the user views the Water Intake section, THE Daily Targets Screen SHALL display a discrete slider with exactly 4 snap points at values [1.5, 2.0, 2.5, 3.0]
4. WHEN the user drags a slider thumb, THE Daily Targets Screen SHALL snap the value to the nearest predefined option
5. WHEN the user releases the slider thumb, THE Daily Targets Screen SHALL update the displayed target value immediately

### Requirement 2: Display Visual Feedback for Slider Values

**User Story:** As a user adjusting my daily targets, I want to see clear visual feedback of my selected values, so that I understand what goals I'm setting.

#### Acceptance Criteria

1. WHEN a slider is displayed, THE Daily Targets Screen SHALL show the current value in large, bold text above the slider
2. WHEN a slider is displayed, THE Daily Targets Screen SHALL show labeled tick marks at each snap point
3. WHEN the user drags a slider, THE Daily Targets Screen SHALL highlight the active track portion in the section's theme color
4. WHEN a slider reaches a snap point, THE Daily Targets Screen SHALL provide visual feedback through color change
5. WHEN the slider value changes, THE Daily Targets Screen SHALL update the displayed value text with smooth animation

### Requirement 3: Apply Consistent Primary Blue Header Styling

**User Story:** As a user navigating through survey screens, I want consistent visual design across all screens, so that the experience feels cohesive and professional.

#### Acceptance Criteria

1. WHEN the Daily Targets Screen is displayed, THE header title SHALL use AppTheme.primaryBlue color
2. WHEN the Body Measurements Screen is displayed, THE header title SHALL use AppTheme.primaryBlue color
3. WHEN any survey screen header is displayed, THE icon badge SHALL have a primary blue background with 10% opacity
4. WHEN any survey screen header is displayed, THE title text SHALL use headlineMedium theme with bold font weight
5. WHEN any survey screen header is displayed, THE subtitle text SHALL use 14px font size with grey[600] color

### Requirement 4: Remove Chip-Based Selection UI

**User Story:** As a user setting my daily targets, I want a cleaner interface without redundant selection methods, so that the screen is less cluttered and easier to use.

#### Acceptance Criteria

1. WHEN the Steps Target section is displayed, THE Daily Targets Screen SHALL NOT display chip buttons for value selection
2. WHEN the Active Minutes section is displayed, THE Daily Targets Screen SHALL NOT display chip buttons for value selection
3. WHEN the Water Intake section is displayed, THE Daily Targets Screen SHALL NOT display chip buttons for value selection
4. WHEN any target section is displayed, THE Daily Targets Screen SHALL use only the discrete slider for value selection
5. WHEN the Calorie Target section is displayed, THE Daily Targets Screen SHALL retain the existing card-based UI with adjust button

### Requirement 5: Maintain Existing Functionality

**User Story:** As a user completing the onboarding survey, I want all existing features to continue working, so that I can successfully save my profile and start using the app.

#### Acceptance Criteria

1. WHEN the user adjusts any target value, THE Daily Targets Screen SHALL save the updated value to the survey state
2. WHEN the user clicks "COMPLETE & START APP", THE Daily Targets Screen SHALL submit all target values to the backend
3. WHEN the survey submission succeeds, THE Daily Targets Screen SHALL navigate to the dashboard
4. WHEN the user clicks the back button, THE Daily Targets Screen SHALL navigate to the Activity Goals screen
5. WHEN the user adjusts the calorie target, THE Daily Targets Screen SHALL open the existing adjustment dialog
