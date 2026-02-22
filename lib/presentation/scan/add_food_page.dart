import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/datasources/food_remote_datasource.dart';
import '../../data/models/api_models.dart';
import 'log_food_page.dart';
import 'create_food_page.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({Key? key}) : super(key: key);

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final _foodDataSource = FoodRemoteDataSource();
  final _searchController = TextEditingController();

  List<FoodPayload> _foods = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchFoods(''); // initial fetch
  }

  Future<void> _searchFoods(String query) async {
    setState(() {
      _isLoading = true;
    });

    final res = await _foodDataSource.listFoods(query: query);

    if (mounted) {
      setState(() {
        _foods = res.data ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Add Food',
          style: TextStyle(color: AppTheme.textBlack),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textBlack),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _searchFoods,
                      decoration: InputDecoration(
                        hintText: 'Search food...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.textGrey,
                        ),
                        filled: true,
                        fillColor: AppTheme.cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () async {
                        final created = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateFoodPage(),
                          ),
                        );
                        if (created == true) {
                          _searchFoods(_searchController.text);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : _foods.isEmpty
                  ? const Center(
                      child: Text(
                        'No foods found. Add a custom one!',
                        style: TextStyle(color: AppTheme.textGrey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _foods.length,
                      itemBuilder: (context, index) {
                        final food = _foods[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: AppTheme.cardColor,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.dividerColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: food.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        food.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.fastfood,
                                              color: AppTheme.textGrey,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.fastfood,
                                      color: AppTheme.textGrey,
                                    ),
                            ),
                            title: Text(
                              food.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '${food.brand} • ${food.per100g['calories']} kcal/100g',
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppTheme.textGrey,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LogFoodPage(food: food),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
