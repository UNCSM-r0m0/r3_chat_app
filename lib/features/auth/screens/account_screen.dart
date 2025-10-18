import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _UserCard(userName: user?.name ?? 'Usuario', email: user?.email ?? ''),
                      const SizedBox(height: 12),
                      _UsageCard(
                        used: auth.standardUsed,
                        limit: auth.standardLimit,
                      ),
                      const SizedBox(height: 12),
                      const _ShortcutsCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _UpgradeCard(isPro: auth.isPro, onUpgrade: () {
                        ref.read(authStateProvider.notifier).upgradeToPro();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Upgraded to Pro!')),
                        );
                      }),
                      const SizedBox(height: 12),
                      _BillingPrefsCard(
                        value: auth.emailReceipts,
                        onChanged: (v) => ref.read(authStateProvider.notifier).setEmailReceipts(v),
                      ),
                      const SizedBox(height: 12),
                      _DangerZoneCard(onDelete: () {
                        // Placeholder: in real app, call backend
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Delete account requested')),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String userName;
  final String email;
  const _UserCard({required this.userName, required this.email});

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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4B5563)),
                  ),
                  child: const Text('Free Plan', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
          const Text('Message Usage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Standard', style: TextStyle(color: Colors.white70)),
              const Spacer(),
              Text('$used/$limit', style: const TextStyle(color: Colors.white70)),
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
          Text('${(limit - used).clamp(0, limit)} messages remaining', style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
              child: Text(right, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
          const Text('Keyboard Shortcuts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
              Text('Upgrade to Pro', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              Text('\$8/month', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              _Benefit(icon: Icons.auto_awesome, text: 'Access to All Models'),
              SizedBox(width: 12),
              _Benefit(icon: Icons.bolt, text: 'Generous Limits'),
              SizedBox(width: 12),
              _Benefit(icon: Icons.headset_mic, text: 'Priority Support'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isPro ? null : onUpgrade,
                  icon: const Icon(Icons.upgrade),
                  label: Text(isPro ? 'You are Pro' : 'Upgrade Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No invoices in demo')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF374151)),
                  foregroundColor: Colors.white,
                ),
                child: const Text('View Previous Invoices'),
              )
            ],
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
            child: Text('Billing Preferences', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          const Text('Email me receipts', style: TextStyle(color: Colors.white70)),
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
          const Text('Danger Zone', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
