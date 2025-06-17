import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
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

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
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
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
                      setState(() {
                        _darkModeEnabled = value;
                      });
                      // TODO: Implement dark mode toggle
                    },
                  ),
                  _buildSettingSwitch(
                    context,
                    label: 'الإشعارات',
                    icon: Icons.notifications_active_outlined,
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  _buildSettingOption(
                    context,
                    label: 'اللغة',
                    icon: Icons.language_rounded,
                    value: 'العربية',
                    onTap: () {
                      // TODO: Implement language selection
                    },
                  ),
                ],
              ),
              const SizedBox(height: _sectionPadding),
              _buildSettingsSection(
                title: 'الحساب',
                icon: Icons.account_circle_outlined,
                children: [
                  _buildSettingOption(
                    context,
                    label: 'تغيير كلمة المرور',
                    icon: Icons.lock_outline_rounded,
                    onTap: () {
                      // TODO: Implement password change
                    },
                  ),
                  _buildSettingOption(
                    context,
                    label: 'البريد الإلكتروني',
                    icon: Icons.email_outlined,
                    value: 'yehia@example.com',
                    onTap: () {
                      // TODO: Implement email change
                    },
                  ),
                  _buildSettingOption(
                    context,
                    label: 'رقم الهاتف',
                    icon: Icons.phone_iphone_rounded,
                    value: '+965 12345678',
                    onTap: () {
                      // TODO: Implement phone number change
                    },
                  ),
                ],
              ),
              const SizedBox(height: _sectionPadding),
              _buildSettingsSection(
                title: 'عام',
                icon: Icons.info_outline_rounded,
                children: [
                  _buildSettingOption(
                    context,
                    label: 'سياسة الخصوصية',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () {
                      // TODO: Show privacy policy
                    },
                  ),
                  _buildSettingOption(
                    context,
                    label: 'الشروط والأحكام',
                    icon: Icons.description_outlined,
                    onTap: () {
                      // TODO: Show terms and conditions
                    },
                  ),
                  _buildSettingOption(
                    context,
                    label: 'إصدار التطبيق',
                    icon: Icons.app_settings_alt_outlined,
                    value: '1.0.0',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: _sectionPadding),
              _buildSupportCard(context),
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
        border: Border.all(
          color: cs.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: cs.surfaceVariant,
              backgroundImage: const AssetImage('assets/images/profile.jpg'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'يحيى أحمد',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'عضو منذ 2023',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_rounded,
              color: cs.primary,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
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
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: cs.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: _itemSpacing),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outline.withOpacity(0.1),
              width: 1,
            ),
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
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: tt.bodyLarge)),
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: cs.primary),
        ],
      ),
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
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 20, color: cs.primary),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: tt.bodyLarge)),
            if (value != null)
              Text(value, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.6))),
            const SizedBox(width: 8),
            Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: cs.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.1), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, size: 24, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'الدعم الفني',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'إذا كنت بحاجة إلى مساعدة أو لديك أي استفسار، لا تتردد في التواصل مع فريق الدعم لدينا.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.8)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement contact support
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.contact_support_outlined, color: cs.primary),
              label: Text('تواصل معنا', style: tt.bodyLarge?.copyWith(color: cs.primary)),
            ),
          ),
        ],
      ),
    );
  }
}
