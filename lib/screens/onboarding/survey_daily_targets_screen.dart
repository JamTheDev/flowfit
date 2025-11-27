import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../widgets/survey_app_bar.dart';

class SurveyDailyTargetsScreen extends ConsumerStatefulWidget {
  const SurveyDailyTargetsScreen({super.key});

  @override
  ConsumerState<SurveyDailyTargetsScreen> createState() =>
      _SurveyDailyTargetsScreenState();
}

class _SurveyDailyTargetsScreenState
    extends ConsumerState<SurveyDailyTargetsScreen> {
  int _targetCalories = 2450;
  int _targetSteps = 10000;
  int _targetActiveMinutes = 30;
  double _targetWaterLiters = 2.0;
  bool _isSubmitting = false;

  final List<int> _stepsOptions = [5000, 10000, 12000, 15000];
  final List<int> _minutesOptions = [20, 30, 45, 60];
  final List<double> _waterOptions = [1.5, 2.0, 2.5, 3.0];

  @override
  void initState() {
    super.initState();
    _calculateCalorieTarget();
  }

  void _calculateCalorieTarget() {
    final surveyState = ref.read(surveyNotifierProvider);
    final surveyData = surveyState.surveyData;

    // Get user data
    final age = surveyData['age'] as int? ?? 25;
    final gender = surveyData['gender'] as String? ?? 'male';
    final weight = surveyData['weight'] as double? ?? 70.0;
    final height = surveyData['height'] as double? ?? 170.0;
    final activityLevel =
        surveyData['activityLevel'] as String? ?? 'moderately_active';
    final goals = surveyData['goals'] as List<dynamic>? ?? [];

    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (gender == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // Apply activity multiplier
    double activityMultiplier;
    switch (activityLevel) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'lightly_active':
        activityMultiplier = 1.375;
        break;
      case 'moderately_active':
        activityMultiplier = 1.55;
        break;
      case 'very_active':
        activityMultiplier = 1.725;
        break;
      case 'extremely_active':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.55;
    }

    double tdee = bmr * activityMultiplier;

    // Adjust based on primary goal
    if (goals.contains('lose_weight')) {
      tdee -= 500; // Safe deficit
    } else if (goals.contains('build_muscle')) {
      tdee += 300; // Surplus
    }

    setState(() {
      _targetCalories = tdee.round();
    });

    // Save to survey data
    ref
        .read(surveyNotifierProvider.notifier)
        .updateSurveyData('dailyCalorieTarget', _targetCalories);
  }

  Future<void> _handleComplete() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Save daily targets to survey data
      final surveyNotifier = ref.read(surveyNotifierProvider.notifier);
      await surveyNotifier.updateSurveyData(
        'dailyCalorieTarget',
        _targetCalories,
      );
      await surveyNotifier.updateSurveyData('dailyStepsTarget', _targetSteps);
      await surveyNotifier.updateSurveyData(
        'dailyActiveMinutesTarget',
        _targetActiveMinutes,
      );
      await surveyNotifier.updateSurveyData(
        'dailyWaterTarget',
        _targetWaterLiters,
      );

      // Get user ID from arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final userId = args?['userId'] as String?;

      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Submit survey to backend
      final success = await surveyNotifier.submitSurvey(userId);

      if (!mounted) return;

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to dashboard
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        });
      } else {
        // Show error
        final errorMessage =
            ref.read(surveyNotifierProvider).errorMessage ??
            'Failed to save profile';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getActivityLevelDisplay() {
    final surveyData = ref.read(surveyNotifierProvider).surveyData;
    final activityLevel =
        surveyData['activityLevel'] as String? ?? 'moderately_active';

    switch (activityLevel) {
      case 'sedentary':
        return 'Sedentary';
      case 'lightly_active':
        return 'Lightly active';
      case 'moderately_active':
        return 'Moderately active';
      case 'very_active':
        return 'Very active';
      case 'extremely_active':
        return 'Extremely active';
      default:
        return 'Moderately active';
    }
  }

  String _getGoalsDisplay() {
    final surveyData = ref.read(surveyNotifierProvider).surveyData;
    final goals = surveyData['goals'] as List<dynamic>? ?? [];

    if (goals.isEmpty) return 'No goals selected';

    final goalNames = goals.map((goal) {
      switch (goal) {
        case 'lose_weight':
          return 'Lose weight';
        case 'maintain_weight':
          return 'Maintain weight';
        case 'build_muscle':
          return 'Build muscle';
        case 'improve_cardio':
          return 'Improve cardio';
        default:
          return goal.toString();
      }
    }).toList();

    return goalNames.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final surveyData = ref.watch(surveyNotifierProvider).surveyData;
    final age = surveyData['age'] as int? ?? 0;
    final gender = surveyData['gender'] as String? ?? 'male';
    final height = surveyData['height'] as double? ?? 0.0;
    final weight = surveyData['weight'] as double? ?? 0.0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SurveyAppBar(
        currentStep: 4,
        totalSteps: 4,
        title: 'Your Daily Targets',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Title with icon - consistent with other screens
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      SolarIconsBold.target,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalized Goals',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on your profile',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 24),

              // Calorie Target
              Row(
                children: [
                  const Icon(
                    SolarIconsBold.fire,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Calorie Target',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF314158),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_targetCalories calories',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Based on: $age${gender == 'male'
                          ? 'M'
                          : gender == 'female'
                          ? 'F'
                          : ''}, ${height.toStringAsFixed(0)}cm, ${weight.toStringAsFixed(0)}kg',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    Text(
                      '${_getActivityLevelDisplay()} • Goals: ${_getGoalsDisplay()}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        _showCalorieAdjustDialog();
                      },
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Adjust'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 24),

              // Steps Target
              _buildDiscreteSliderSection(
                icon: SolarIconsBold.walking,
                color: Colors.green,
                title: 'Steps Target',
                value: _targetSteps,
                options: _stepsOptions,
                formatLabel: (val) => '${(val / 1000).toStringAsFixed(0)}K',
                formatValue: (val) =>
                    '${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} steps',
                onChanged: (val) => setState(() => _targetSteps = val),
              ),

              const SizedBox(height: 32),

              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 24),

              // Active Minutes Target
              _buildDiscreteSliderSection(
                icon: SolarIconsBold.clockCircle,
                color: Colors.purple,
                title: 'Active Minutes',
                value: _targetActiveMinutes,
                options: _minutesOptions,
                formatLabel: (val) => '$val',
                formatValue: (val) => '$val minutes',
                onChanged: (val) => setState(() => _targetActiveMinutes = val),
              ),

              const SizedBox(height: 32),

              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 24),

              // Water Intake Target
              _buildDiscreteSliderSectionDouble(
                icon: Icons.water_drop,
                color: Colors.blue,
                title: 'Water Intake',
                value: _targetWaterLiters,
                options: _waterOptions,
                formatLabel: (val) => '${val.toStringAsFixed(1)}L',
                formatValue: (val) => '${val.toStringAsFixed(1)} liters',
                onChanged: (val) => setState(() => _targetWaterLiters = val),
              ),

              const SizedBox(height: 32),

              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 24),

              // Info
              Row(
                children: [
                  Icon(
                    SolarIconsBold.infoCircle,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can adjust these anytime in your profile settings',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 24),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == 3
                          ? AppTheme.primaryBlue
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Complete Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'COMPLETE & START APP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscreteSliderSection({
    required IconData icon,
    required Color color,
    required String title,
    required int value,
    required List<int> options,
    required String Function(int) formatLabel,
    required String Function(int) formatValue,
    required Function(int) onChanged,
  }) {
    final currentIndex = options.indexOf(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF314158),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Value Display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            formatValue(value),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 24),

        // Discrete Slider
        Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.2),
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                trackHeight: 6,
                tickMarkShape: const RoundSliderTickMarkShape(
                  tickMarkRadius: 4,
                ),
                activeTickMarkColor: Colors.white,
                inactiveTickMarkColor: color.withValues(alpha: 0.3),
              ),
              child: Slider(
                value: currentIndex.toDouble(),
                min: 0,
                max: (options.length - 1).toDouble(),
                divisions: options.length - 1,
                onChanged: (newIndex) {
                  onChanged(options[newIndex.round()]);
                },
              ),
            ),

            // Labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: options.map((opt) {
                  final isSelected = opt == value;
                  return Text(
                    formatLabel(opt),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? color : Colors.grey[600],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscreteSliderSectionDouble({
    required IconData icon,
    required Color color,
    required String title,
    required double value,
    required List<double> options,
    required String Function(double) formatLabel,
    required String Function(double) formatValue,
    required Function(double) onChanged,
  }) {
    final currentIndex = options.indexOf(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF314158),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Value Display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            formatValue(value),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 24),

        // Discrete Slider
        Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.2),
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                trackHeight: 6,
                tickMarkShape: const RoundSliderTickMarkShape(
                  tickMarkRadius: 4,
                ),
                activeTickMarkColor: Colors.white,
                inactiveTickMarkColor: color.withValues(alpha: 0.3),
              ),
              child: Slider(
                value: currentIndex.toDouble(),
                min: 0,
                max: (options.length - 1).toDouble(),
                divisions: options.length - 1,
                onChanged: (newIndex) {
                  onChanged(options[newIndex.round()]);
                },
              ),
            ),

            // Labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: options.map((opt) {
                  final isSelected = opt == value;
                  return Text(
                    formatLabel(opt),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? color : Colors.grey[600],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCalorieAdjustDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempCalories = _targetCalories;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adjust Calorie Target'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$tempCalories calories',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: tempCalories.toDouble(),
                    min: 1200,
                    max: 4000,
                    divisions: 56,
                    activeColor: Colors.orange,
                    label: '$tempCalories',
                    onChanged: (value) {
                      setDialogState(() {
                        tempCalories = value.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _targetCalories = tempCalories;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
