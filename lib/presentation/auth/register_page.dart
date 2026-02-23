import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme.dart';
import '../../core/token_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../core/goals_calculator.dart';
import '../main_wrapper.dart';
import 'login_page.dart';

const List<MapEntry<String, String>> kActivityLevels = [
  MapEntry('sedentary', 'Sedentary'),
  MapEntry('lightly_active', 'Lightly Active'),
  MapEntry('moderate', 'Moderate'),
  MapEntry('very_active', 'Very Active'),
];
class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _currentStep = 1;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authDataSource = AuthRemoteDataSource();
  final _profileDataSource = ProfileRemoteDataSource();

  bool _isLoading = false;
  String? _passwordError;
  bool _hasTouchedPassword = false;

  final passwordRegExp = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  // Step 2 variables
  String _weightGoal = 'maintain';
  num _targetWeightKg = 75;
  num _weightKg = 70;
  num _heightCm = 170;
  int _age = 25;
  String _activityLevel = 'moderate';
  String _gender = 'male';

  late TextEditingController _targetWeightController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  Map<String, double> _dailyTargets = {};

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    
    _targetWeightController = TextEditingController(text: '75');
    _ageController = TextEditingController(text: '25');
    _heightController = TextEditingController(text: '170');
    _weightController = TextEditingController(text: '70');

    _recalculateTargets();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _targetWeightController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    if (!_hasTouchedPassword) return;
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password is required';
      });
    } else if (!passwordRegExp.hasMatch(password)) {
      setState(() {
        _passwordError = 'Must be at least 8 characters, with 1 letter and 1 number';
      });
    } else {
      setState(() {
        _passwordError = null;
      });
    }
  }

  void _recalculateTargets() {
    _dailyTargets = GoalsCalculator.calculateDailyTargets(
      weightKg: _weightKg.toDouble(),
      heightCm: _heightCm.toDouble(),
      age: _age,
      activityLevel: _activityLevel,
      weightGoal: _weightGoal,
      isFemale: _gender == 'female',
    );
  }

  void _onGoalOrActivityChanged() {
    _recalculateTargets();
    setState(() {});
  }

  void _nextStep() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _hasTouchedPassword = true;
    });
    _validatePassword();

    if (_passwordError != null) return;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _currentStep = 2;
    });
  }

  Future<void> _handleRegister() async {
    // Only allow actual registration from step 2 (goals step).
    if (_currentStep != 2) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _isLoading = true;
    });

    final response = await _authDataSource.register(
      name: name,
      email: email,
      password: password,
      passwordConfirm: confirmPassword,
    );

    if (!mounted) {
      return;
    }

    if (response.success && response.data != null) {
      await TokenStorage.saveTokens(
        response.data!.accessToken,
        response.data!.refreshToken,
        userId: response.data!.user.id,
      );

      final userId = response.data!.user.id;
      final body = <String, dynamic>{
        'weight_goal': _weightGoal,
        'target_weight_kg': _targetWeightKg,
        'activity_level': _activityLevel,
        'weight_kg': _weightKg,
        'height_cm': _heightCm,
        'age': _age,
        'gender': _gender,
      };

      final profileRes = await _profileDataSource.updateProfile(userId, body);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (profileRes.statusCode == 401) {
        await TokenStorage.clearTokens();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
        return;
      }

      if (!profileRes.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileRes.message),
            backgroundColor: AppTheme.redAccent,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful!')));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _currentStep = 1;
      });

      String errorMsg = response.readableErrorMessage;
      if (response.error is Map) {
         final errorMap = response.error as Map;
         if (errorMap.containsKey('detail') && errorMap['detail'] is Map) {
             final detailMap = errorMap['detail'] as Map;
             List<String> messages = [];
             detailMap.forEach((key, value) {
               String fieldName = key.toString();
               if (fieldName.isNotEmpty) {
                 fieldName = fieldName[0].toUpperCase() + fieldName.substring(1);
               }
               fieldName = fieldName.replaceAll('_', ' ');

               if (value is List) {
                 //", ".join([str(v) for v in value])}' if isinstance(value, list) else f'{fieldName}: {value}') # pseudo python list comprehension bug protection, wait, this is Dart generation!
                                  messages.add('${fieldName}: ${value.join(', ')}');
                 messages.add('${fieldName}: ${value.join(', ')}');
               } else {
                 messages.add('${fieldName}: ${value}');
               }
             });
             if (messages.isNotEmpty) {
               errorMsg = messages.join('\n');
             }
         }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _currentStep == 2
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                onPressed: () {
                  setState(() {
                    _currentStep = 1;
                  });
                },
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final isStep2 = child.key == const ValueKey('step2');
                  final offset = Tween<Offset>(
                    begin: Offset(isStep2 ? 0.15 : -0.15, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ));
                  final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                    ),
                  );
                  return SlideTransition(
                    position: offset,
                    child: FadeTransition(
                      opacity: opacity,
                      child: child,
                    ),
                  );
                },
                child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          _stepDot(1),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          _stepDot(2),
        ],
      ),
    );
  }

  Widget _stepDot(int step) {
    final isCurrent = _currentStep == step;
    final isCompleted = _currentStep > step;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent
            ? AppTheme.primaryColor
            : isCompleted
                ? AppTheme.greenAccent
                : AppTheme.primaryColor.withOpacity(0.2),
        border: (!isCurrent && !isCompleted)
            ? Border.all(color: AppTheme.primaryColor.withOpacity(0.4))
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : Text(
                '$step',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? Colors.white : AppTheme.textGrey,
                ),
              ),
      ),
    );
  }

  Widget _buildStep1() {
    return Center(
      key: const ValueKey('step1'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign up to track your nutrition goals',
              style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            _buildTextField(
              'Full Name',
              _nameController,
              Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Email Address',
              _emailController,
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  setState(() {
                    _hasTouchedPassword = true;
                  });
                  _validatePassword();
                }
              },
              child: _buildTextField(
                'Password',
                _passwordController,
                Icons.lock_outline,
                obscureText: true,
                errorText: _passwordError,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Confirm Password',
              _confirmPasswordController,
              Icons.lock_outline,
              obscureText: true,
            ),

            const SizedBox(height: 24),
            const Text(
              'You\'ll set your goals in the next step.',
              style: TextStyle(fontSize: 13, color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      color: AppTheme.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tell Us About Yourself',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textBlack,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'We use this to calculate your daily targets',
            style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildCalorieTargetCard(),
          const SizedBox(height: 32),
          const Text(
            'MACRO NUTRIENTS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          _buildMacrosCard(),
          const SizedBox(height: 32),
          const Text(
            'GENDER',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          _buildGenderCard(),
          const SizedBox(height: 32),
          const Text(
            'AGE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          _buildAgeCard(),
          const SizedBox(height: 32),
          const Text(
            'HEIGHT',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          _buildHeightCard(),
          const SizedBox(height: 32),
          const Text(
            'CURRENT WEIGHT',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          _buildWeightCard(),
          const SizedBox(height: 32),
          const Text(
            'WEIGHT GOAL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          _buildWeightGoalCard(),
          const SizedBox(height: 32),
          const Text(
            'ACTIVITY LEVEL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityLevelGrid(),
          const SizedBox(height: 48),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Register & Save Goals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }


Widget _buildCalorieTargetCard() {
    final targetCal = _dailyTargets['calories'] ?? 2000.0;
    final tdeeVal = GoalsCalculator.tdee(
      weightKg: _weightKg,
      heightCm: _heightCm,
      age: _age,
      activityLevel: _activityLevel,
      isFemale: _gender == 'female',
    );
    final daysToGoal = GoalsCalculator.estimatedDaysToTargetWeight(
      currentWeightKg: _weightKg,
      targetWeightKg: _targetWeightKg,
      targetCaloriesPerDay: targetCal,
      tdeeValue: tdeeVal,
      weightGoal: _weightGoal,
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 10,
                  backgroundColor: AppTheme.dividerColor,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.redAccent),
                  strokeCap: StrokeCap.round,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Daily',
                      style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                    ),
                    Text(
                      targetCal.round().toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textBlack,
                      ),
                    ),
                    const Text(
                      'kcal',
                      style: TextStyle(fontSize: 10, color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Calorie\nTarget',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textBlack,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Based on BMR, activity level and weight goal.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textGrey),
                ),
                if (daysToGoal != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '~$daysToGoal days to reach ${_targetWeightKg.toStringAsFixed(0)} kg',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildMacrosCard() {
    final protein = _dailyTargets['protein_g'] ?? 0.0;
    final carbs = _dailyTargets['carbs_g'] ?? 0.0;
    final fat = _dailyTargets['fat_g'] ?? 0.0;
    final total = protein + carbs + fat;
    final proteinPct = total > 0 ? protein / total : 0.33;
    final carbsPct = total > 0 ? carbs / total : 0.45;
    final fatPct = total > 0 ? fat / total : 0.22;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (proteinPct * 100).round().clamp(1, 99),
                    child: Container(color: AppTheme.blueAccent),
                  ),
                  Expanded(
                    flex: (carbsPct * 100).round().clamp(1, 99),
                    child: Container(color: AppTheme.greenAccent),
                  ),
                  Expanded(
                    flex: (fatPct * 100).round().clamp(1, 99),
                    child: Container(color: AppTheme.redAccent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChartLegend(
                'Protein',
                '${protein.round()}g',
                '${(proteinPct * 100).round()}%',
                AppTheme.blueAccent,
              ),
              _buildChartLegend(
                'Carbs',
                '${carbs.round()}g',
                '${(carbsPct * 100).round()}%',
                AppTheme.greenAccent,
              ),
              _buildChartLegend(
                'Fat',
                '${fat.round()}g',
                '${(fatPct * 100).round()}%',
                AppTheme.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildChartLegend(
    String name,
    String amount,
    String pct,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              amount,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textBlack,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              pct,
              style: const TextStyle(fontSize: 14, color: AppTheme.textGrey),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildAgeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Age',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textBlack,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppTheme.textGrey,
                ),
                onPressed: () {
                  setState(() {
                    if (_age > 13) {
                      _age--;
                      _ageController.text = _age.toString();
                      _onGoalOrActivityChanged();
                    }
                  });
                },
              ),
              SizedBox(
                width: 48,
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textBlack,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null) {
                      setState(() {
                        _age = parsed.clamp(13, 120);
                        _onGoalOrActivityChanged();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'years',
                style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.textGrey,
                ),
                onPressed: () {
                  setState(() {
                    if (_age < 120) {
                      _age++;
                      _ageController.text = _age.toString();
                      _onGoalOrActivityChanged();
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildHeightCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Height',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textBlack,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppTheme.textGrey,
                ),
                onPressed: () {
                  setState(() {
                    if (_heightCm > 100) {
                      _heightCm = _heightCm - 1;
                      _heightController.text = _heightCm.toString();
                      _onGoalOrActivityChanged();
                    }
                  });
                },
              ),
              SizedBox(
                width: 52,
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textBlack,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    final parsed = num.tryParse(val);
                    if (parsed != null) {
                      setState(() {
                        _heightCm = parsed.clamp(100, 250);
                        _onGoalOrActivityChanged();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'cm',
                style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.textGrey,
                ),
                onPressed: () {
                  setState(() {
                    if (_heightCm < 250) {
                      _heightCm = _heightCm + 1;
                      _heightController.text = _heightCm.toString();
                      _onGoalOrActivityChanged();
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildWeightGoalCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildSegment('lose', 'Lose'),
              _buildSegment('maintain', 'Maintain'),
              _buildSegment('gain', 'Gain'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Target Weight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textBlack,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppTheme.textGrey,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_targetWeightKg > 30) {
                          _targetWeightKg = _targetWeightKg - 1;
                          _targetWeightController.text = _targetWeightKg
                              .toString();
                          _onGoalOrActivityChanged();
                        }
                      });
                    },
                  ),
                  SizedBox(
                    width: 48,
                    child: TextField(
                      controller: _targetWeightController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textBlack,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        final parsed = num.tryParse(val);
                        if (parsed != null) {
                          setState(() {
                            _targetWeightKg = parsed.clamp(30, 300);
                            _onGoalOrActivityChanged();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'kg',
                    style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.textGrey,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_targetWeightKg < 300) {
                          _targetWeightKg = _targetWeightKg + 1;
                          _targetWeightController.text = _targetWeightKg
                              .toString();
                          _onGoalOrActivityChanged();
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

Widget _buildSegment(String value, String title) {
    final isSelected = _weightGoal == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _weightGoal = value;
            _onGoalOrActivityChanged();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textBlack,
              ),
            ),
          ),
        ),
      ),
    );
  }

Widget _buildActivityLevelGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: kActivityLevels.map((e) {
        final key = e.key;
        final label = e.value;
        final isSelected = _activityLevel == key;
        final icon = key == 'sedentary'
            ? Icons.chair
            : key == 'lightly_active'
            ? Icons.directions_walk
            : key == 'moderate'
            ? Icons.fitness_center
            : Icons.bolt;
        final color = key == 'sedentary'
            ? AppTheme.blueAccent
            : key == 'lightly_active'
            ? AppTheme.redAccent
            : key == 'moderate'
            ? AppTheme.greenAccent
            : Colors.orangeAccent;
        return _buildActivityCard(
          label,
          icon,
          color.withOpacity(0.2),
          color,
          isSelected,
          () {
            setState(() {
              _activityLevel = key;
              _onGoalOrActivityChanged();
            });
          },
        );
      }).toList(),
    );
  }

Widget _buildActivityCard(
    String title,
    IconData icon,
    Color bg,
    Color fg,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: fg, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textBlack,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildWeightCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Current Weight',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textBlack,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppTheme.textGrey,
                ),
                onPressed: () {
                  setState(() {
                    if (_weightKg > 30) {
                      _weightKg = _weightKg - 1;
                      _weightController.text = _weightKg.toString();
                      _onGoalOrActivityChanged();
                    }
                  });
                },
              ),
              SizedBox(
                width: 52,
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textBlack,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    final parsed = num.tryParse(val);
                    if (parsed != null) {
                      setState(() {
                        _weightKg = parsed.clamp(30, 300);
                        _onGoalOrActivityChanged();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'kg',
                style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.textGrey,
                ),
                onPressed: () {
                  setState(() {
                    if (_weightKg < 300) {
                      _weightKg = _weightKg + 1;
                      _weightController.text = _weightKg.toString();
                      _onGoalOrActivityChanged();
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildGenderCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Gender',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textBlack,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() { _gender = 'male'; _onGoalOrActivityChanged(); });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _gender == 'male' ? AppTheme.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Male', style: TextStyle(color: _gender == 'male' ? Colors.white : AppTheme.textBlack, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() { _gender = 'female'; _onGoalOrActivityChanged(); });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _gender == 'female' ? AppTheme.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Female', style: TextStyle(color: _gender == 'female' ? Colors.white : AppTheme.textBlack, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null ? AppTheme.redAccent : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppTheme.textBlack, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.textLightGrey),
              prefixIcon: Icon(icon, color: AppTheme.textGrey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText,
              style: const TextStyle(color: AppTheme.redAccent, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}
