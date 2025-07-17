import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // real data fields
  String? fullName;
  String? email;
  String? phone;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  static const double _sectionPadding = 24.0;
  static const double _itemSpacing = 16.0;
  static const double _smallSpacing = 8.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // load saved preferences
    _loadSettings();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString('full_name') ?? 'مستخدم';
      email = prefs.getString('email') ?? '';
      phone = prefs.getString('phone') ?? '';
      _darkModeEnabled = prefs.getBool('dark_mode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'الإعدادات',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: _sectionPadding),
          child: Column(
            children: [
              const SizedBox(height: _itemSpacing),
              _buildProfileCard(context),
              const SizedBox(height: _sectionPadding),
              _buildSettingsSection(
                title: 'التفضيلات',
                icon: Icons.tune_rounded,
                children: [
                  _buildSettingSwitch(
                    context,
                    label: 'الوضع المظلم',
                    icon: Icons.dark_mode_outlined,
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() => _darkModeEnabled = value);
                      _saveBool('dark_mode', value);
                      // TODO: also apply theme change
                    },
                  ),
                  _buildSettingSwitch(
                    context,
                    label: 'الإشعارات',
                    icon: Icons.notifications_active_outlined,
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                      _saveBool('notifications', value);
                    },
                  ),
                  _buildSettingOption(
                    context,
                    label: 'البريد الإلكتروني',
                    icon: Icons.email_outlined,
                    value: email,
                    onTap: () async {
                      // you might show a dialog to edit email, then save:
                      final newEmail = await _showEditDialog('البريد الإلكتروني', email);
                      if (newEmail != null) {
                        setState(() => email = newEmail);
                        final prefs = await SharedPreferences.getInstance();
                        prefs.setString('email', newEmail);
                      }
                    },
                  ),
                  _buildSettingOption(
                    context,
                    label: 'رقم الهاتف',
                    icon: Icons.phone_iphone_rounded,
                    value: phone,
                    onTap: () async {
                      final newPhone = await _showEditDialog('رقم الهاتف', phone);
                      if (newPhone != null) {
                        setState(() => phone = newPhone);
                        final prefs = await SharedPreferences.getInstance();
                        prefs.setString('phone', newPhone);
                      }
                    },
                  ),
                ],
              ),
              // ... keep the rest of your sections unchanged ...
              const SizedBox(height: _sectionPadding * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.1), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: cs.surfaceVariant,
            backgroundImage: const AssetImage('assets/images/profile.jpg'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              fullName ?? '',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_rounded, color: cs.primary),
            onPressed: () {
              // maybe navigate to a full profile edit page
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _showEditDialog(String title, String? current) {
    final ctrl = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('حفظ')),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: _itemSpacing),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withOpacity(0.1), width: 1),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingSwitch(
      BuildContext context, {
        required String label,
        required IconData icon,
        required bool value,
        required ValueChanged<bool> onChanged,
      }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), shape: BoxShape.circle),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: cs.primary),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(label, style: tt.bodyLarge)),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: cs.primary),
      ]),
    );
  }

  Widget _buildSettingOption(
      BuildContext context, {
        required String label,
        required IconData icon,
        String? value,
        required VoidCallback onTap,
      }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), shape: BoxShape.circle),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: tt.bodyLarge)),
          if (value != null)
            Text(value, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.6))),
          const SizedBox(width: 8),
          Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: cs.onSurface.withOpacity(0.4)),
        ]),
      ),
    );
  }
}


