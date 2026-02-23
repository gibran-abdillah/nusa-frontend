import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'home/home_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'trends/trends_page.dart';
import 'goals/goals_page.dart';
import 'settings/settings_page.dart';
import 'scan/add_food_page.dart';
import 'scan/camera_viewfinder_page.dart';
import 'scan/scan_camera_page.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();

  @override
  Widget build(BuildContext context) {
    final showFab =
        _currentIndex == 0 || _currentIndex == 1; // Home, Trends only
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(key: _homeKey, visible: _currentIndex == 0),
          TrendsPage(key: const ValueKey('trends'), visible: _currentIndex == 1),
          GoalsPage(key: const ValueKey('goals'), visible: _currentIndex == 2),
          SettingsPage(visible: _currentIndex == 3),
        ],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () => _showAddFoodOptions(context),
              backgroundColor: Colors.black,
              shape: const CircleBorder(),
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppTheme.cardColor,
        shape: showFab ? const CircularNotchedRectangle() : null,
        notchMargin: 10.0,
        elevation: 20,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_filled, 0),
              _buildNavItem(Icons.bar_chart_rounded, 1),
              if (showFab) const SizedBox(width: 48), // Space for FAB
              _buildNavItem(Icons.flag_rounded, 2),
              _buildNavItem(Icons.settings_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textLightGrey,
        size: 30,
      ),
      onPressed: () {
        final wasOnGoals = _currentIndex == 2;
        setState(() {
          _currentIndex = index;
        });
        if (index == 0 && wasOnGoals) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _homeKey.currentState?.refresh();
          });
        }
      },
    );
  }

  void _showAddFoodOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  title: const Text(
                    'Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'AI will analyze the food',
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CameraViewfinderPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  title: const Text(
                    'Upload from Gallery',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Select a saved image',
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.search,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  title: const Text(
                    'Search Database',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Log food manually',
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddFoodPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.gallery) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        final status = await Permission.photos.request();
        if (status.isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gallery permission is required')),
          );
          return;
        }
      }
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800, // Explicitly limits width shrinking memory & size
      imageQuality: 85, // Enforces compression (~400KB usually)
    );

    if (pickedFile != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanCameraPage(imagePath: pickedFile.path),
        ),
      );
    }
  }
}
