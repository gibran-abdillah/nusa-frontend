import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/token_storage.dart';
import '../../core/goals_calculator.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/models/api_models.dart';
import '../auth/login_page.dart';

/// Activity level keys (API) and display labels
const List<MapEntry<String, String>> kActivityLevels = [
  MapEntry('sedentary', 'Sedentary'),
  MapEntry('lightly_active', 'Lightly Active'),
  MapEntry('moderate', 'Moderate'),
  MapEntry('very_active', 'Very Active'),
];

class GoalsPage extends StatefulWidget {
  final bool visible;

  const GoalsPage({Key? key, this.visible = false}) : super(key: key);

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final _profileDataSource = ProfileRemoteDataSource();

  bool _isLoading = true;
  bool _hasFetched = false;
  bool _isSaving = false;
  String? _errorMessage;
  UserProfile? _profile;

  String _weightGoal = 'maintain';
  num _targetWeightKg = 75;
  num _weightKg = 70;
  num _heightCm = 170;
  int _age = 25;
  String _activityLevel = 'moderate';
  late TextEditingController _targetWeightController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;

  Map<String, double> _dailyTargets = {};

  static double _numFromMap(
    Map<String, dynamic> m,
    String key,
    double fallback,
  ) {
    final v = m[key];
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _targetWeightController = TextEditingController(text: '75');
    _ageController = TextEditingController(text: '25');
    _heightController = TextEditingController(text: '170');
  }

  @override
  void didUpdateWidget(covariant GoalsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !_hasFetched) {
      _hasFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
    }
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = await TokenStorage.getUserId();
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please log in to view goals.';
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _profileDataSource.getProfile(userId);

    if (res.statusCode == 401) {
      await TokenStorage.clearTokens();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
      return;
    }

    if (!mounted) return;
    if (res.success && res.data != null) {
      final p = res.data!;
      _profile = p;
      _weightGoal = p.weightGoal ?? 'maintain';
      _targetWeightKg = p.targetWeightKg ?? 75;
      _weightKg = p.weightKg ?? 70;
      _heightCm = p.heightCm ?? 170;
      _age = p.age ?? 25;
      _activityLevel = p.activityLevel ?? 'moderate';
      _targetWeightController.text = _targetWeightKg.toString();
      _ageController.text = _age.toString();
      _heightController.text = _heightCm.toString();

      final hasValidTargets =
          p.dailyTargets.isNotEmpty &&
          p.dailyTargets['calories'] != null &&
          (p.dailyTargets['calories'] is num) &&
          (p.dailyTargets['calories'] as num) > 0;
      if (hasValidTargets) {
        _dailyTargets = {
          'calories': _numFromMap(p.dailyTargets, 'calories', 2000),
          'protein_g': _numFromMap(p.dailyTargets, 'protein_g', 100),
          'carbs_g': _numFromMap(p.dailyTargets, 'carbs_g', 200),
          'fat_g': _numFromMap(p.dailyTargets, 'fat_g', 65),
        };
      } else {
        _recalculateTargets();
      }
    } else {
      _weightGoal = 'maintain';
      _targetWeightKg = 75;
      _weightKg = 70;
      _heightCm = 170;
      _age = 25;
      _activityLevel = 'moderate';
      _ageController.text = '25';
      _heightController.text = '170';
      _recalculateTargets();
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _recalculateTargets() {
    final age = _age;
    final heightCm = _heightCm.toDouble();
    final weightKg = _weightKg.toDouble();
    final isFemale = (_profile?.gender ?? 'male').toLowerCase() == 'female';
    _dailyTargets = GoalsCalculator.calculateDailyTargets(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age is int ? age : 25,
      activityLevel: _activityLevel,
      weightGoal: _weightGoal,
      isFemale: isFemale,
    );
  }

  Future<void> _saveProfile() async {
    final userId = await TokenStorage.getUserId();
    if (userId == null || userId.isEmpty) return;

    setState(() => _isSaving = true);

    final body = <String, dynamic>{
      'weight_goal': _weightGoal,
      'target_weight_kg': _targetWeightKg,
      'activity_level': _activityLevel,
      'weight_kg': _weightKg,
      'height_cm': _heightCm,
      'age': _age,
    };

    final res = await _profileDataSource.updateProfile(userId, body);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res.statusCode == 401) {
      await TokenStorage.clearTokens();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }

    if (res.success && res.data != null) {
      _profile = res.data;
      final d = res.data!.dailyTargets;
      final hasValidCalories =
          d.isNotEmpty &&
          d['calories'] != null &&
          (d['calories'] is num) &&
          (d['calories'] as num) > 0;
      if (hasValidCalories) {
        _dailyTargets = {
          'calories': _numFromMap(d, 'calories', 2000),
          'protein_g': _numFromMap(d, 'protein_g', 100),
          'carbs_g': _numFromMap(d, 'carbs_g', 200),
          'fat_g': _numFromMap(d, 'fat_g', 65),
        };
      } else {
        _recalculateTargets();
      }
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Goals saved.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: AppTheme.redAccent,
        ),
      );
    }
  }

  void _onWeightGoalOrActivityChanged() {
    _recalculateTargets();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.chevron_left, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Fitness Goals',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: (_isLoading || _isSaving) ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.redAccent,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppTheme.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textGrey),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppTheme.primaryColor,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                children: [
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
                  const SizedBox(height: 80),
                ],
              ),
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
      isFemale: (_profile?.gender ?? 'male').toString().toLowerCase() == 'female',
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
                      _onWeightGoalOrActivityChanged();
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
                        _onWeightGoalOrActivityChanged();
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
                      _onWeightGoalOrActivityChanged();
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
                      _onWeightGoalOrActivityChanged();
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
                        _onWeightGoalOrActivityChanged();
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
                      _onWeightGoalOrActivityChanged();
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
        if (_weightGoal != 'maintain') ...[
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
                          _onWeightGoalOrActivityChanged();
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
                            _onWeightGoalOrActivityChanged();
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
                          _onWeightGoalOrActivityChanged();
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
            _onWeightGoalOrActivityChanged();
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
            : key == 'light'
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
              _onWeightGoalOrActivityChanged();
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
}
