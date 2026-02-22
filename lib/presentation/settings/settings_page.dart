import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode, color: AppTheme.redAccent),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          _buildProfileSection(),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _buildStatCard('12', 'DAY STREAK')),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('45', 'TOTAL LOGS')),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'ACCOUNT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsGroup([
            _buildSettingItem(
              Icons.person,
              AppTheme.blueAccent.withOpacity(0.2),
              AppTheme.blueAccent,
              'Profile Settings',
            ),
            _buildSettingItem(
              Icons.notifications,
              Colors.orangeAccent.withOpacity(0.2),
              Colors.orangeAccent,
              'Notifications',
            ),
            _buildSettingItem(
              Icons.security,
              AppTheme.greenAccent.withOpacity(0.2),
              AppTheme.greenAccent,
              'Account Security',
            ),
          ]),
          const SizedBox(height: 24),
          const Text(
            'GENERAL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsGroup([
            _buildSettingItem(
              Icons.sync,
              Colors.purpleAccent.withOpacity(0.2),
              Colors.purpleAccent,
              'Health Integration',
            ),
            _buildSettingItem(
              Icons.support_agent,
              AppTheme.redAccent.withOpacity(0.2),
              AppTheme.redAccent,
              'Help & Support',
            ),
          ]),
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppTheme.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Version 2.4.0 (Build 2024)',
              style: TextStyle(color: AppTheme.textLightGrey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 4,
                ),
              ),
              child: const CircleAvatar(
                radius: 48,
                backgroundColor: Colors.orangeAccent,
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: Colors.white,
                ), // placeholder for image
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Jason Alexander',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textBlack,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'jason.alexander@example.com',
          style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
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
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.redAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem(IconData icon, Color bg, Color fg, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppTheme.textBlack,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textLightGrey),
      onTap: () {},
    );
  }
}
