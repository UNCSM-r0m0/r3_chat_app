import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';
import '../providers/usage_providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Account', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            final leftColumn = Column(
              children: [
                _UserCard(
                  userName: user?.name ?? 'Usuario',
                  email: user?.email ?? '',
                  isPro: auth.isPro,
                ),
                const SizedBox(height: 12),
                const _UsageCard(),
                const SizedBox(height: 12),
                const _ShortcutsCard(),
              ],
            );

            final rightColumn = Column(
              children: [
                _UpgradeCard(
                  isPro: auth.isPro,
                  onUpgrade: () {
                    ref.read(authStateProvider.notifier).upgradeToPro();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Upgraded to Pro!')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _BillingPrefsCard(
                  value: auth.emailReceipts,
                  onChanged: (v) =>
                      ref.read(authStateProvider.notifier).setEmailReceipts(v),
                ),
                const SizedBox(height: 12),
                _DangerZoneCard(
                  onDelete: () {
                    // Placeholder: in real app, call backend
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delete account requested')),
                    );
                  },
                ),
              ],
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftColumn),
                  const SizedBox(width: 12),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: rightColumn),
                ],
              );
            }

            // Mobile: una sola columna
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [leftColumn, const SizedBox(height: 12), rightColumn],
            );
          },
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String userName;
  final String email;
  final bool isPro;
  const _UserCard({
    required this.userName,
    required this.email,
    this.isPro = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              (userName.isNotEmpty ? userName[0] : '?').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPro
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPro
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF4B5563),
                    ),
                  ),
                  child: Text(
                    isPro ? 'Pro Plan' : 'Free Plan',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final int used;
  final int limit;
  const _UsageCard({required this.used, required this.limit});

  @override
  Widget build(BuildContext context) {
    final percent = (limit == 0) ? 0.0 : (used / limit).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Message Usage',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Standard', style: TextStyle(color: Colors.white70)),
              Text(
                '$used/$limit',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: const Color(0xFF374151),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(limit - used).clamp(0, limit)} messages remaining',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ShortcutsCard extends StatelessWidget {
  const _ShortcutsCard();
  @override
  Widget build(BuildContext context) {
    Widget row(String left, String right) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(left, style: const TextStyle(color: Colors.white70)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF374151),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF4B5563)),
          ),
          child: Text(
            right,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keyboard Shortcuts',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          row('Search', 'Ctrl K'),
          const SizedBox(height: 6),
          row('New Chat', 'Ctrl Shift O'),
          const SizedBox(height: 6),
          row('Toggle Sidebar', 'Ctrl B'),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final bool isPro;
  final VoidCallback onUpgrade;
  const _UpgradeCard({required this.isPro, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Upgrade to Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text('\$8/month', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: const [
              _Benefit(icon: Icons.auto_awesome, text: 'Access to All Models'),
              _Benefit(icon: Icons.bolt, text: 'Generous Limits'),
              _Benefit(icon: Icons.headset_mic, text: 'Priority Support'),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 360;

              final upgradeBtn = SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isPro ? null : onUpgrade,
                  icon: const Icon(Icons.upgrade),
                  label: Text(isPro ? 'You are Pro' : 'Upgrade Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              );

              final invoicesBtn = OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No invoices in demo')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF374151)),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                ),
                child: const Text('View Previous Invoices'),
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    upgradeBtn,
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: invoicesBtn),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: upgradeBtn),
                  const SizedBox(width: 12),
                  invoicesBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            '* Premium credits are used for models marked with a gem in the model selector.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Benefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4B5563),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _BillingPrefsCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _BillingPrefsCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Billing Preferences',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'Email me receipts',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }
}

class _DangerZoneCard extends StatelessWidget {
  final VoidCallback onDelete;
  const _DangerZoneCard({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danger Zone',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Account'),
            ),
          ),
        ],
      ),
    );
  }
}
