import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/datasources/log_remote_datasource.dart';
import '../../data/models/api_models.dart';
import '../main_wrapper.dart';

class LogFoodPage extends StatefulWidget {
  final FoodPayload food;

  const LogFoodPage({Key? key, required this.food}) : super(key: key);

  @override
  State<LogFoodPage> createState() => _LogFoodPageState();
}

class _LogFoodPageState extends State<LogFoodPage> {
  final _logDataSource = LogRemoteDataSource();
  final _servingController = TextEditingController(text: '100');
  final _notesController = TextEditingController();
  String _mealType = 'lunch';
  bool _isLoading = false;

  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

  Future<void> _submitLog() async {
    final serving = num.tryParse(_servingController.text) ?? 100;

    setState(() {
      _isLoading = true;
    });

    final res = await _logDataSource.logFood(
      foodId: widget.food.id,
      mealType: _mealType,
      servingWeightG: serving,
      notes: _notesController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (res.success && res.data != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food logged successfully!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainWrapper()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${res.message} ${res.error ?? ""}'),
            backgroundColor: AppTheme.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _servingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Log Food',
          style: TextStyle(color: AppTheme.textBlack),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textBlack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.food.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.food.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.fastfood,
                            size: 80,
                            color: AppTheme.textGrey,
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: AppTheme.dividerColor,
                          child: const Icon(
                            Icons.fastfood,
                            color: AppTheme.textGrey,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.food.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.food.brand} • ${widget.food.per100g['calories']} kcal / 100g',
                        style: const TextStyle(color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildLabel('Serving weight (grams)'),
            TextField(
              controller: _servingController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('e.g., 200'),
            ),
            const SizedBox(height: 24),
            _buildLabel('Meal Type'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _mealType,
                  isExpanded: true,
                  items: _mealTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _mealType = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('Notes (Optional)'),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: _inputDecoration(
                'How did you feel after eating this?',
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Log',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textGrey,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
