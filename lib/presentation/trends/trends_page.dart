import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../data/datasources/trends_remote_datasource.dart';
import '../../data/models/api_models.dart';

class TrendsPage extends StatefulWidget {
  final bool visible;

  const TrendsPage({Key? key, this.visible = false}) : super(key: key);

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  final TrendsRemoteDataSource _dataSource = TrendsRemoteDataSource();
  bool _isLoading = true;
  bool _hasFetched = false;
  TrendsData? _trendsData;
  String _selectedSegment = 'Monthly';

  @override
  void didUpdateWidget(covariant TrendsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !_hasFetched) {
      _hasFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchTrends());
    }
  }

  Future<void> _fetchTrends() async {
    setState(() {
      _isLoading = true;
      _trendsData = null;
    });

    String periodParam = 'monthly';
    if (_selectedSegment == 'This Week') {
      periodParam = 'weekly';
    } else if (_selectedSegment == 'Custom') {
      periodParam = 'custom';
    }

    final response = await _dataSource.getTrends(periodParam);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _trendsData = response.data;
        } else {
          debugPrint('Failed to load trends: ${response.message}');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    num totalProtein = 0;
    num totalCarbs = 0;
    num totalFat = 0;
    if (_trendsData != null) {
      for (var point in _trendsData!.chart) {
        totalProtein += point['protein_g'] ?? 0;
        totalCarbs += point['carbs_g'] ?? 0;
        totalFat += point['fat_g'] ?? 0;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trends',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textBlack,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppTheme.cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_today_outlined, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.dividerColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _buildSegment('This Week', _selectedSegment == 'This Week'),
                  _buildSegment('Monthly', _selectedSegment == 'Monthly'),
                  _buildSegment('Custom', _selectedSegment == 'Custom'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              ..._buildSkeletonLoading()
            else if (_trendsData != null) ...[
              _buildChartCard(_trendsData!, _selectedSegment),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nutrient Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textBlack,
                    ),
                  ),
                  Text(
                    '${_selectedSegment.toUpperCase()} TOTAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGrey.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildNutrientCard(
                      '${totalProtein.toInt()}g',
                      'PROTEIN',
                      AppTheme.blueAccent,
                      Icons.restaurant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNutrientCard(
                      '${totalCarbs.toInt()}g',
                      'CARBS',
                      AppTheme.greenAccent,
                      Icons.rice_bowl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNutrientCard(
                      '${totalFat.toInt()}g',
                      'FAT',
                      AppTheme.redAccent,
                      Icons.water_drop,
                    ),
                  ),
                ],
              ),
            ] else
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: Text('Could not load trends data')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedSegment != title) {
            setState(() {
              _selectedSegment = title;
            });
            _fetchTrends();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.textBlack : AppTheme.textGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// X value in "days" (epoch ms / 86400000) for chart scaling.
  static double _dayValue(DateTime dt) {
    return dt.millisecondsSinceEpoch / 86400000.0;
  }

  Widget _buildChartCard(dynamic trends, String selectedSegment) {
    List<FlSpot> spots = [];
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    final now = DateTime.now();

    for (var i = 0; i < trends.chart.length; i++) {
      final point = trends.chart[i];
      final dateStr = point['date'].toString();

      double x;
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        x = _dayValue(dt);
      } else {
        x = double.tryParse(dateStr) ?? i.toDouble();
      }

      final y = (point['calories'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(x, y));

      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    if (spots.isEmpty) {
      minX = 1;
      maxX = 30;
      minY = 1500;
      maxY = 3000;
    } else {
      spots.sort((a, b) => a.x.compareTo(b.x));

      // X-axis: use full period so first day (e.g. Monday) is on the left, not center
      if (selectedSegment == 'This Week') {
        final weekday = now.weekday;
        final todayStart = DateTime(now.year, now.month, now.day);
        final startOfWeek = todayStart.subtract(Duration(days: weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        minX = _dayValue(startOfWeek);
        maxX = _dayValue(endOfWeek);
      } else if (selectedSegment == 'Monthly') {
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1);
        minX = _dayValue(startOfMonth);
        maxX = _dayValue(endOfMonth);
      } else {
        if (minX == maxX) {
          minX -= 1;
          maxX += 1;
        }
      }

      // Y-axis: anchor at 0 so one point isn't in the vertical middle
      final dataMaxY = maxY;
      minY = 0;
      maxY = (dataMaxY * 1.2).clamp(1500.0, double.infinity);
      if (maxY < 1500) maxY = 1500;
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL CALORIES',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${trends.totalCalories}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textBlack,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${trends.changePct >= 0 ? '+' : ''}${trends.changePct}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: trends.changePct >= 0
                              ? AppTheme.greenAccent
                              : AppTheme.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'AVG CALORIES',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${trends.avgCaloriesPerDay}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.redAccent,
                        ),
                      ),
                      const Text(
                        ' kcal/day',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        AppTheme.primaryColor.withOpacity(0.8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        String title = 'Day ${spot.x.toInt()}';
                        if (spot.x > 10000) {
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                            (spot.x * 86400000).toInt(),
                            isUtc: true,
                          );
                          title = '${dt.day}/${dt.month}';
                        }
                        return LineTooltipItem(
                          '$title\n',
                          const TextStyle(color: Colors.white70, fontSize: 12),
                          children: [
                            TextSpan(
                              text: '${spot.y.toInt()} kcal',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.dividerColor.withOpacity(0.5),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.redAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 31,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.redAccent,
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.redAccent.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(
    String amount,
    String title,
    Color color,
    IconData icon,
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
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 0.7, // Random fill
                  strokeWidth: 4,
                  backgroundColor: AppTheme.dividerColor,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
                Center(child: Icon(icon, color: color, size: 24)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAverageCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF2EC), // Peach background
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFFF8A5C),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Calories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Burned during exercise',
                    style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '420 kcal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textBlack,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '+15%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.greenAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSkeletonLoading() {
    final skeletonColor = AppTheme.textLightGrey.withOpacity(0.35);
    return [
      Container(
        height: 310,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 80, color: skeletonColor),
                    const SizedBox(height: 8),
                    Container(height: 32, width: 100, color: skeletonColor),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(height: 12, width: 80, color: skeletonColor),
                    const SizedBox(height: 8),
                    Container(height: 32, width: 80, color: skeletonColor),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: skeletonColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 32),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 20,
            width: 160,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          Container(
            height: 14,
            width: 80,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _buildSkeletonNutrientCard(skeletonColor)),
          const SizedBox(width: 12),
          Expanded(child: _buildSkeletonNutrientCard(skeletonColor)),
          const SizedBox(width: 12),
          Expanded(child: _buildSkeletonNutrientCard(skeletonColor)),
        ],
      ),
    ];
  }

  Widget _buildSkeletonNutrientCard(Color color) {
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
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 16),
          Container(
            height: 16,
            width: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            width: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
