import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/token_storage.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/models/api_models.dart';
import '../auth/login_page.dart';
import '../details/details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final _homeDataSource = HomeRemoteDataSource();
  final _profileDataSource = ProfileRemoteDataSource();

  bool _isLoading = true;
  FullDailySummary? _summary;
  UserProfile? _profile;
  List<FoodLog> _logs = [];

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatCalories(num value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final dateStr = _formatDateForApi(_selectedDate);
    final userId = await TokenStorage.getUserId();

    final summaryRes = await _homeDataSource.getDailySummary(dateStr);

    if (summaryRes.statusCode == 401) {
      await TokenStorage.clearTokens();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
      return;
    }

    final logsRes = await _homeDataSource.getLogs(dateStr);
    if (logsRes.statusCode == 401) {
      await TokenStorage.clearTokens();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
      return;
    }

    UserProfile? profile;
    if (userId != null && userId.isNotEmpty) {
      final profileRes = await _profileDataSource.getProfile(userId);
      if (profileRes.success && profileRes.data != null) {
        profile = profileRes.data;
      }
    }

    if (mounted) {
      setState(() {
        _summary = summaryRes.data;
        _profile = profile;
        _logs = logsRes.data ?? [];
        _isLoading = false;
      });
    }
  }

  /// Call from MainWrapper when user switches back to Home tab (e.g. after updating Goals).
  void refresh() {
    _fetchData();
  }

  static double _numFrom(dynamic v, double fallback) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final consumed = _summary?.consumed ?? {};
    final summaryItems = {
      'calories': _numFrom(consumed['calories'], 0),
      'protein_g': _numFrom(consumed['protein_g'], 0),
      'carbs_g': _numFrom(consumed['carbs_g'], 0),
      'fat_g': _numFrom(consumed['fat_g'], 0),
    };

    final profileTargets = _profile?.dailyTargets;
    final hasProfileTargets = profileTargets != null &&
        profileTargets.isNotEmpty &&
        profileTargets['calories'] != null &&
        (profileTargets['calories'] is num) &&
        (profileTargets['calories'] as num) > 0;

    final targets = {
      'calories': hasProfileTargets
          ? _numFrom(profileTargets!['calories'], 2000)
          : _numFrom(_summary?.targets['calories'], 2000),
      'protein_g': hasProfileTargets
          ? _numFrom(profileTargets!['protein_g'], 100)
          : _numFrom(_summary?.targets['protein_g'], 100),
      'carbs_g': hasProfileTargets
          ? _numFrom(profileTargets!['carbs_g'], 200)
          : _numFrom(_summary?.targets['carbs_g'], 200),
      'fat_g': hasProfileTargets
          ? _numFrom(profileTargets!['fat_g'], 65)
          : _numFrom(_summary?.targets['fat_g'], 65),
    };

    final calTarget = targets['calories']! > 0 ? targets['calories']! : 2000.0;
    final proteinTarget = targets['protein_g']! > 0 ? targets['protein_g']! : 100.0;
    final carbsTarget = targets['carbs_g']! > 0 ? targets['carbs_g']! : 200.0;
    final fatTarget = targets['fat_g']! > 0 ? targets['fat_g']! : 65.0;

    final progress = {
      'calories': calTarget > 0 ? (summaryItems['calories']! / calTarget).clamp(0.0, 1.0) : 0.0,
      'protein_pct': proteinTarget > 0 ? ((summaryItems['protein_g']! / proteinTarget) * 100).clamp(0.0, 100.0) : 0.0,
      'carbs_pct': carbsTarget > 0 ? ((summaryItems['carbs_g']! / carbsTarget) * 100).clamp(0.0, 100.0) : 0.0,
      'fat_pct': fatTarget > 0 ? ((summaryItems['fat_g']! / fatTarget) * 100).clamp(0.0, 100.0) : 0.0,
    };

    const double kMaxContentWidth = 520.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: AppTheme.primaryColor,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: _isLoading
                  ? ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      children: _buildSkeletonLoading(),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      children: [
                    const Text(
                      'NUSA',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textBlack,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCalorieCard(
                      summaryItems['calories']!,
                      calTarget,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildMacroCard(
                            'Protein',
                            '${summaryItems['protein_g']!.round()} / ${proteinTarget.round()}g',
                            AppTheme.blueAccent,
                            Icons.lunch_dining,
                            (progress['protein_pct'] as num) / 100.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMacroCard(
                            'Carbs',
                            '${summaryItems['carbs_g']!.round()} / ${carbsTarget.round()}g',
                            AppTheme.greenAccent,
                            Icons.rice_bowl,
                            (progress['carbs_pct'] as num) / 100.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMacroCard(
                            'Fat',
                            '${summaryItems['fat_g']!.round()} / ${fatTarget.round()}g',
                            AppTheme.redAccent,
                            Icons.water_drop,
                            (progress['fat_pct'] as num) / 100.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildDateSelector(),
                    const SizedBox(height: 32),
                    const Text(
                      'Recently Uploaded',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textBlack,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_logs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No food logged today.',
                            style: TextStyle(color: AppTheme.textGrey),
                          ),
                        ),
                      )
                    else
                      ..._logs.take(3).map((log) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildRecentUploadCard(log, context),
                        );
                      }).toList(),
                    const SizedBox(height: 80),
                  ],
                ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSkeletonLoading() {
    final skeletonColor = AppTheme.textLightGrey.withOpacity(0.35);
    return [
      Container(
        height: 32,
        width: 120,
        decoration: BoxDecoration(
          color: skeletonColor,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: skeletonColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 28,
                    width: 140,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: _buildSkeletonMacroCard(skeletonColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSkeletonMacroCard(skeletonColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSkeletonMacroCard(skeletonColor),
          ),
        ],
      ),
      const SizedBox(height: 32),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          5,
          (_) => Container(
            height: 56,
            width: 48,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      const SizedBox(height: 32),
      Container(
        height: 18,
        width: 160,
        decoration: BoxDecoration(
          color: skeletonColor,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      const SizedBox(height: 16),
      for (int i = 0; i < 3; i++) ...[
        _buildSkeletonLogCard(skeletonColor),
        const SizedBox(height: 16),
      ],
      const SizedBox(height: 80),
    ];
  }

  Widget _buildSkeletonMacroCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 18,
            width: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 14,
            width: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLogCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      height: 12,
                      width: 50,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 12,
                      width: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieCard(num current, num target) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Calories',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _formatCalories(current),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textBlack,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      ' /${_formatCalories(target)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: current / target,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.dividerColor,
                  color: AppTheme.redAccent,
                  strokeCap: StrokeCap.round,
                ),
                const Center(
                  child: Icon(
                    Icons.local_fire_department,
                    color: AppTheme.redAccent,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
    String title,
    String amount,
    Color color,
    IconData icon,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: AppTheme.dividerColor,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    // Generate the last 5 days up to today
    final startDate = now.subtract(const Duration(days: 4));

    final dates = List.generate(5, (index) {
      final d = startDate.add(Duration(days: index));
      final weekday = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][d.weekday - 1];
      return {
        'day': weekday,
        'date': '${d.day}',
        'fullDate': d,
        'selected':
            d.year == _selectedDate.year &&
            d.month == _selectedDate.month &&
            d.day == _selectedDate.day,
      };
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: dates.map((d) {
        final isSelected = d['selected'] as bool;
        final fullDate = d['fullDate'] as DateTime;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = fullDate;
            });
            _fetchData();
          },
          child: Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      ),
                    ],
            ),
            child: Column(
              children: [
                Text(
                  d['day'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white70 : AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  d['date'] as String,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.textBlack,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentUploadCard(FoodLog log, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailsPage(log: log)),
        ).then((_) {
          if (mounted) _fetchData();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
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
            Hero(
              tag: 'hero-image-${log.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  log.food.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.dividerColor,
                    child: const Icon(Icons.fastfood, color: AppTheme.textGrey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          log.food.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textBlack,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '09:20 am', // hardcoded time as per UI
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLightGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: AppTheme.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${log.calculated['calories']} kcal',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.redAccent,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildMacroDot(
                            AppTheme.blueAccent,
                            '${log.calculated['protein_g']}g',
                          ),
                          const SizedBox(width: 8),
                          _buildMacroDot(
                            AppTheme.greenAccent,
                            '${log.calculated['carbs_g']}g',
                          ),
                          const SizedBox(width: 8),
                          _buildMacroDot(
                            AppTheme.redAccent,
                            '${log.calculated['fat_g']}g',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textBlack,
          ),
        ),
      ],
    );
  }
}
