import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'الملف الشخصي',
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _itemSpacing),
              _buildProfileHeader(cs, tt),
              const SizedBox(height: _sectionPadding),
              _buildProfileSection(
                title: 'المعلومات الشخصية',
                icon: Icons.person_outline_rounded,
                children: [
                  _buildInfoItem(
                    label: 'الاسم الكامل',
                    value: 'يحيى أحمد',
                    icon: Icons.person,
                  ),
                  const Divider(height: 1),
                  _buildInfoItem(
                    label: 'البريد الإلكتروني',
                    value: 'yehia@example.com',
                    icon: Icons.email_outlined,
                  ),
                  const Divider(height: 1),
                  _buildInfoItem(
                    label: 'رقم الهاتف',
                    value: '+965 12345678',
                    icon: Icons.phone_iphone_rounded,
                  ),
                ],
              ),
              const SizedBox(height: _sectionPadding),
              _buildProfileSection(
                title: 'الإعدادات',
                icon: Icons.settings_outlined,
                children: [
                  _buildActionItem(
                    label: 'تغيير كلمة المرور',
                    icon: Icons.lock_outline_rounded,
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildActionItem(
                    label: 'اللغة',
                    icon: Icons.language_rounded,
                    value: 'العربية',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildActionItem(
                    label: 'الإشعارات',
                    icon: Icons.notifications_active_outlined,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: _sectionPadding),
              _buildProfileSection(
                title: 'عام',
                icon: Icons.info_outline_rounded,
                children: [
                  _buildActionItem(
                    label: 'سياسة الخصوصية',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildActionItem(
                    label: 'الشروط والأحكام',
                    icon: Icons.description_outlined,
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildActionItem(
                    label: 'تواصل معنا',
                    icon: Icons.contact_support_outlined,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: _sectionPadding * 2),
              _buildLogoutButton(context),
              const SizedBox(height: _sectionPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme cs, TextTheme tt) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary.withOpacity(0.2), width: 3),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: cs.surfaceVariant,
                backgroundImage: const AssetImage('assets/images/profile.jpg'),
              ),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primary,
              child: Icon(Icons.edit_rounded, size: 18, color: cs.onPrimary),
            ),
          ],
        ),
        const SizedBox(height: _itemSpacing),
        Text(
          'يحيى أحمد',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: _smallSpacing),
        Text(
          'عضو منذ 2023',
          style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.6)),
        ),
      ],
    );
  }

  Widget _buildProfileSection({
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
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
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

  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primary.withOpacity(0.1),
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.6))),
                const SizedBox(height: 4),
                Text(value, style: tt.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
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
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.primary.withOpacity(0.1),
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

  Widget _buildLogoutButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return FilledButton.icon(
      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
      icon: Icon(Icons.logout_rounded, color: cs.onErrorContainer),
      label: Text('تسجيل الخروج', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      style: FilledButton.styleFrom(
        backgroundColor: cs.errorContainer,
        foregroundColor: cs.onErrorContainer,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
