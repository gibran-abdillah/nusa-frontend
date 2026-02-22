import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/datasources/food_remote_datasource.dart';

class CreateFoodPage extends StatefulWidget {
  const CreateFoodPage({Key? key}) : super(key: key);

  @override
  State<CreateFoodPage> createState() => _CreateFoodPageState();
}

class _CreateFoodPageState extends State<CreateFoodPage> {
  final _foodDataSource = FoodRemoteDataSource();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitFood() async {
    if (_nameController.text.isEmpty || _caloriesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and Calories are required!'),
          backgroundColor: AppTheme.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final res = await _foodDataSource.createCustomFood(
      name: _nameController.text,
      brand: _brandController.text.isEmpty ? 'Custom' : _brandController.text,
      caloriesPer100g: num.tryParse(_caloriesController.text) ?? 0,
      proteinPer100g: num.tryParse(_proteinController.text) ?? 0,
      carbsPer100g: num.tryParse(_carbsController.text) ?? 0,
      fatPer100g: num.tryParse(_fatController.text) ?? 0,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (res.success && res.data != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food created successfully!')),
        );
        Navigator.pop(context, true); // Retun true to refresh search
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
    _nameController.dispose();
    _brandController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Create Food',
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
            _buildLabel('Food Name *'),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('e.g., Homemade Nasi Goreng'),
            ),
            const SizedBox(height: 20),
            _buildLabel('Brand / Restaurant'),
            TextField(
              controller: _brandController,
              decoration: _inputDecoration('e.g., My Kitchen (Optional)'),
            ),

            const SizedBox(height: 32),
            const Text(
              'Nutritional values (per 100g or per serving)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),

            _buildLabel('Calories (kcal) *'),
            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('e.g., 250'),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Protein (g)'),
                      TextField(
                        controller: _proteinController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('0'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Carbs (g)'),
                      TextField(
                        controller: _carbsController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('0'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Fat (g)'),
                      TextField(
                        controller: _fatController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('0'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create & Save',
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
