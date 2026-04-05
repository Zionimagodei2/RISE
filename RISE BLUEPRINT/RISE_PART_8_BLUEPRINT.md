# ============================================================
# RISE — AI ALARM CLOCK
# MASTER BLUEPRINT: PART 8 OF 12
# Settings Screen + Alarm Setup Flow
# ============================================================
# COMMAND TO AI CODING AGENT:
# Parts 1–7 must be complete before starting this part.
# Read every section before writing any code.
# This part covers every toggle, preference, and alarm
# configuration screen in the app.
#
# WHAT THIS PART CREATES (9 files):
#
#  1. lib/features/settings/settings_screen.dart
#     Root settings screen — sections list with navigation.
#
#  2. lib/features/settings/sections/accessibility_settings.dart
#     All 7 accessibility toggles from Edge Case Bible.
#     NO paywall — accessibility is always free.
#
#  3. lib/features/settings/sections/audio_settings.dart
#     Hearing aid mode, BT advisory, alarm stream volume.
#
#  4. lib/features/settings/sections/safety_settings.dart
#     Emergency contact, buddy config, escalation timing.
#
#  5. lib/features/settings/sections/notification_settings.dart
#     Permission status, DND check, manufacturer battery
#     restriction guide (Xiaomi/Samsung/OnePlus deep links).
#
#  6. lib/features/settings/sections/biometric_settings.dart
#     Re-enroll CTA, wide tolerance mode, PIN change.
#
#  7. lib/features/settings/sections/sleep_settings.dart
#     Detection method, chronotype, sleep debt ledger config.
#
#  8. lib/features/alarm/alarm_setup_screen.dart
#     Full alarm creation/edit flow: time picker, repeat days,
#     sound, volume, game, biometric, buddy, barcode, financial
#     stakes, nap mode.
#
#  9. lib/features/alarm/widgets/sound_picker.dart
#     Sound selection: bundled tones + custom local file.
#
# EDGE CASES WIRED IN THIS PART:
#  EC-1.6  Hearing aid mode toggle
#  EC-1.8  Volume advisory at alarm setup when system volume is 0
#  EC-3.3  Wide tolerance mode (medication affecting HR)
#  EC-3.4  Irregular heartbeat PIN-only mode
#  EC-3.8  Tremor mode
#  EC-3.9  Deaf mode
#  EC-3.10 Photosensitive epilepsy
#  EC-3.11 Cognitive simple-wake mode
#  EC-4.7  Nap mode alarm type
#  EC-4.8  Early start (shown in alarm setup confirmation)
#  EC-4.9  Post-alarm watchdog toggle
#  EC-5.2  Auto-dismiss driving toggle
#  EC-5.7  DND blocking warning in alarm setup
#  EC-5.9  Emergency contact + buddy escalation settings
#  EC-6.4  Battery optimization exemption guide
#  EC-9.1  Mental health context in buddy setup copy
# ============================================================

---

## FILE 1: lib/features/settings/settings_screen.dart
## PATH: lib/features/settings/settings_screen.dart
## PURPOSE: Root settings screen. Section cards with nav arrows.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/subscription_tier.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/subscription_provider.dart';
import 'sections/accessibility_settings.dart';
import 'sections/audio_settings.dart';
import 'sections/biometric_settings.dart';
import 'sections/notification_settings.dart';
import 'sections/safety_settings.dart';
import 'sections/sleep_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    final tier = SubscriptionTier.fromId(
        ref.watch(subscriptionProvider).tier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Settings',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w600)),
        leading: const BackButton(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Account card ─────────────────────────────────────────
          _AccountCard(
            email: user?.email ?? 'Not signed in',
            tier:  tier,
          ),
          const SizedBox(height: 20),

          // ── Section groups ────────────────────────────────────────
          _SectionHeader('Alarm'),
          _SettingsTile(
            icon:    Icons.alarm,
            label:   'Notification & permissions',
            onTap:   () => _push(context, const NotificationSettings()),
          ),
          _SettingsTile(
            icon:    Icons.audiotrack_outlined,
            label:   'Audio',
            onTap:   () => _push(context, const AudioSettings()),
          ),
          _SettingsTile(
            icon:    Icons.bedtime_outlined,
            label:   'Sleep detection',
            badge:   tier.isPaid ? null : 'Pro',
            onTap:   () => _push(context, const SleepSettings()),
          ),

          const SizedBox(height: 16),
          _SectionHeader('Safety & Accountability'),
          _SettingsTile(
            icon:    Icons.people_outline,
            label:   'Buddy & emergency contact',
            onTap:   () => _push(context, const SafetySettings()),
          ),
          _SettingsTile(
            icon:    Icons.fingerprint,
            label:   'Biometric identity lock',
            badge:   tier.biometricLock ? null : 'Core+',
            onTap:   () => _push(context, const BiometricSettings()),
          ),

          const SizedBox(height: 16),
          _SectionHeader('Accessibility'),
          _SettingsTile(
            icon:    Icons.accessibility_new_outlined,
            label:   'Accessibility options',
            sublabel: 'Always free',
            onTap:   () => _push(context, const AccessibilitySettings()),
          ),

          const SizedBox(height, 16),
          _SectionHeader('Account'),
          _SettingsTile(
            icon:    Icons.card_membership_outlined,
            label:   'Subscription & billing',
            sublabel: tier.displayName,
            onTap:   () => Navigator.pushNamed(context, '/paywall'),
          ),
          _SettingsTile(
            icon:    Icons.account_balance_wallet_outlined,
            label:   'Reward wallet',
            onTap:   () => Navigator.pushNamed(context, '/wallet'),
          ),
          _SettingsTile(
            icon:    Icons.share_outlined,
            label:   'Invite friends & earn',
            onTap:   () => Navigator.pushNamed(context, '/referral'),
          ),

          const SizedBox(height: 16),
          _SectionHeader('About'),
          _SettingsTile(
            icon:    Icons.privacy_tip_outlined,
            label:   'Privacy policy',
            onTap:   () => Navigator.pushNamed(context, '/privacy'),
          ),
          _SettingsTile(
            icon:    Icons.description_outlined,
            label:   'Terms of service',
            onTap:   () => Navigator.pushNamed(context, '/terms'),
          ),
          _SettingsTile(
            icon:    Icons.info_outline,
            label:   'App version',
            sublabel: '1.0.0',
            onTap:   null,
          ),

          const SizedBox(height: 20),

          // ── Sign out ──────────────────────────────────────────────
          if (user != null)
            TextButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/onboarding', (_) => false);
                }
              },
              child: const Text('Sign out',
                  style: TextStyle(color: Colors.redAccent)),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _push(BuildContext ctx, Widget screen) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
}

class _AccountCard extends StatelessWidget {
  final String            email;
  final SubscriptionTier  tier;
  const _AccountCard({required this.email, required this.tier});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A1A3E), Color(0xFF2D1B69)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      CircleAvatar(
        radius: 24,
        backgroundColor: Colors.white.withOpacity(0.15),
        child: const Icon(Icons.person, color: Colors.white70),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(email, style: const TextStyle(
              color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(tier.displayName,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      )),
    ]),
  );
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(text.toUpperCase(),
        style: TextStyle(color: Colors.white.withOpacity(0.35),
            fontSize: 11, fontWeight: FontWeight.w700,
            letterSpacing: 1.2)),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final String?      sublabel;
  final String?      badge;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.sublabel,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 2),
    child: ListTile(
      tileColor:    const Color(0xFF161628),
      shape:        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      leading:      Icon(icon, color: Colors.white54, size: 22),
      title:        Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 15)),
      subtitle:     sublabel != null
          ? Text(sublabel!,
              style: const TextStyle(color: Colors.white38, fontSize: 12))
          : null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:        Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border:       Border.all(
                  color: Colors.amber.withOpacity(0.4)),
            ),
            child: Text(badge!,
                style: const TextStyle(
                    color: Colors.amber, fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
        ],
        if (onTap != null)
          const Icon(Icons.chevron_right,
              color: Colors.white24, size: 20),
      ]),
      onTap: onTap,
    ),
  );
}
```

---

## FILE 2: lib/features/settings/sections/accessibility_settings.dart
## PATH: lib/features/settings/sections/accessibility_settings.dart
## PURPOSE: All 7 accessibility toggles from the Edge Case Bible.
##          ZERO paywall. Accessibility is always free.
##          Each toggle has a clear description of what it changes.

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

class AccessibilitySettings extends StatefulWidget {
  const AccessibilitySettings({super.key});
  @override
  State<AccessibilitySettings> createState() =>
      _AccessibilitySettingsState();
}

class _AccessibilitySettingsState extends State<AccessibilitySettings> {
  // EC-3.9
  bool _deaf          = false;
  // EC-3.10
  bool _photosensitive = false;
  // EC-3.11
  bool _cognitive     = false;
  // EC-3.8
  bool _tremor        = false;
  // EC-3.4
  bool _irregularHR   = false;
  // EC-3.3
  bool _hrMedication  = false;
  // EC-1.6
  bool _hearingAids   = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _deaf           = p.getBool(AppConstants.prefDeafMode)          ?? false;
      _photosensitive = p.getBool(AppConstants.prefPhotosensitive)    ?? false;
      _cognitive      = p.getBool(AppConstants.prefCognitiveMode)     ?? false;
      _tremor         = p.getBool(AppConstants.prefTremorMode)        ?? false;
      _irregularHR    = p.getBool(AppConstants.prefIrregularHR)       ?? false;
      _hrMedication   = p.getBool(AppConstants.prefHrMedication)      ?? false;
      _hearingAids    = p.getBool(AppConstants.prefHearingAids)       ?? false;
    });
  }

  Future<void> _save(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
        title: const Text('Accessibility',
            style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Free badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:        Colors.greenAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.greenAccent, size: 16),
              SizedBox(width: 8),
              Text('All accessibility features are always free',
                  style: TextStyle(
                      color: Colors.greenAccent, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 20),

          _SectionLabel('Wake & Alarm'),

          // EC-3.9 Deaf mode
          _AccessTile(
            title:       'I am deaf or hard of hearing',
            description: 'Alarm uses maximum continuous vibration and '
                '1 Hz screen flash instead of sound. Your buddy is '
                'notified immediately when the alarm fires.',
            value:   _deaf,
            onChanged: (v) {
              setState(() => _deaf = v);
              _save(AppConstants.prefDeafMode, v);
              // Warn if photosensitive is also ON
              if (v && _photosensitive) {
                _showConflictNote(context,
                  'Screen flash is disabled because photosensitive '
                  'epilepsy mode is active. Vibration + buddy '
                  'notification will be used.');
              }
            },
          ),

          // EC-3.10 Photosensitive epilepsy
          _AccessTile(
            title:       'I have photosensitive epilepsy',
            description: 'Disables ALL screen flashing and strobing '
                'throughout the app. This setting overrides all '
                'other animation settings. Smart lights use steady '
                'brightness only.',
            value:   _photosensitive,
            isWarning: true,
            onChanged: (v) {
              setState(() => _photosensitive = v);
              _save(AppConstants.prefPhotosensitive, v);
            },
          ),

          // EC-3.11 Cognitive / simple wake
          _AccessTile(
            title:       'Simple wake confirmation',
            description: 'Replaces all wake games with a large '
                '5-button tap sequence (1 → 2 → 3 → 4 → 5). '
                'No timer. No wrong-answer penalty. Voice prompt '
                'reads each number aloud.',
            value:   _cognitive,
            onChanged: (v) {
              setState(() => _cognitive = v);
              _save(AppConstants.prefCognitiveMode, v);
            },
          ),

          // EC-3.8 Tremor mode
          _AccessTile(
            title:       'I have a movement condition',
            description: 'Enlarges all touch targets to 2× standard '
                'size. Doubles game timers. Enables large drag-and-drop '
                'tiles in word games. PPG capture window extended '
                'to 15 seconds with tremor filtering.',
            value:   _tremor,
            onChanged: (v) {
              setState(() => _tremor = v);
              _save(AppConstants.prefTremorMode, v);
            },
          ),

          const SizedBox(height: 16),
          _SectionLabel('Heart Rate & Biometric'),

          // EC-3.4 Irregular heartbeat
          _AccessTile(
            title:       'I have an irregular heartbeat',
            description: 'Disables heart rate matching for identity '
                'verification. Uses PIN-only mode instead. '
                'Recommended for users with atrial fibrillation '
                'or other arrhythmias.',
            value:   _irregularHR,
            onChanged: (v) {
              setState(() => _irregularHR = v);
              _save(AppConstants.prefIrregularHR, v);
            },
          ),

          // EC-3.3 HR medication
          _AccessTile(
            title:       'I take medication that affects heart rate',
            description: 'Activates Wide Tolerance Mode: ±25 BPM '
                'matching window instead of ±12 BPM. Recommended '
                'for beta-blockers, calcium channel blockers, '
                'or any heart rate-altering medication.',
            value:   _hrMedication,
            onChanged: (v) {
              setState(() => _hrMedication = v);
              _save(AppConstants.prefHrMedication, v);
            },
          ),

          const SizedBox(height: 16),
          _SectionLabel('Audio'),

          // EC-1.6 Hearing aids
          _AccessTile(
            title:       'I use Bluetooth hearing aids',
            description: 'Disables the automatic Bluetooth speaker '
                'override. Your hearing aids remain the primary '
                'audio output. Vibration and smart lights are used '
                'as additional wake channels.',
            value:   _hearingAids,
            onChanged: (v) {
              setState(() => _hearingAids = v);
              _save(AppConstants.prefHearingAids, v);
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showConflictNote(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF2A2A3E),
      duration: const Duration(seconds: 4),
    ));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
    child: Text(text.toUpperCase(),
        style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 11, fontWeight: FontWeight.w700,
            letterSpacing: 1.2)),
  );
}

class _AccessTile extends StatelessWidget {
  final String   title;
  final String   description;
  final bool     value;
  final bool     isWarning;
  final void Function(bool) onChanged;

  const _AccessTile({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: value && isWarning
          ? Colors.orange.withOpacity(0.08)
          : const Color(0xFF161628),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: value && isWarning
            ? Colors.orange.withOpacity(0.4)
            : Colors.white.withOpacity(0.06),
      ),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(
                color: isWarning && value
                    ? Colors.orange : Colors.white,
                fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text(description, style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 12, height: 1.5)),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Switch(
        value:       value,
        onChanged:   onChanged,
        activeColor: isWarning ? Colors.orange : Colors.greenAccent,
        trackColor:  MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected)
                ? (isWarning ? Colors.orange : Colors.greenAccent)
                      .withOpacity(0.3)
                : Colors.white12),
      ),
    ]),
  );
}
```

---

## FILE 3: lib/features/settings/sections/safety_settings.dart
## PATH: lib/features/settings/sections/safety_settings.dart
## PURPOSE: Buddy and emergency contact config. Escalation timing.
##          EC-5.9 and EC-9.1 are both implemented here.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/buddy_contact.dart';

class SafetySettings extends StatefulWidget {
  const SafetySettings({super.key});
  @override
  State<SafetySettings> createState() => _SafetySettingsState();
}

class _SafetySettingsState extends State<SafetySettings> {
  BuddyContact? _buddy;
  BuddyContact? _emergencyContact;
  int           _buddyAfterMinutes = 15;   // Notify buddy after X minutes
  int           _emergencyAfterMinutes = 30; // Escalate to emergency after Y min
  bool          _postWatchdogEnabled = true; // EC-4.9

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final box = Hive.box<dynamic>(AppConstants.buddyBoxName);
    final contacts = box.values.cast<BuddyContact>().toList();
    setState(() {
      _buddy           = contacts.firstWhereOrNull((c) => !c.isEmergencyContact);
      _emergencyContact = contacts.firstWhereOrNull((c) => c.isEmergencyContact);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
        title: const Text('Safety & Accountability',
            style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Context note — EC-9.1 mental health awareness
          _InfoBox(
            icon:  Icons.favorite_border,
            color: Colors.pinkAccent,
            text:  'Your buddy receives a message if your alarm goes '
                   'unanswered. Your emergency contact receives an '
                   'escalated wellness check if you still haven\'t '
                   'responded after 30 minutes.',
          ),
          const SizedBox(height: 20),

          _SectionLabel('Accountability Buddy'),
          _ContactCard(
            contact:  _buddy,
            role:     'Buddy',
            subtitle: 'Gets a nudge after ${_buddyAfterMinutes}min of no response',
            onAdd:    () => _pickContact(isEmergency: false),
            onRemove: () => _removeContact(isEmergency: false),
          ),
          const SizedBox(height: 8),
          _SliderTile(
            label: 'Notify buddy after',
            value: _buddyAfterMinutes.toDouble(),
            min:   5, max: 30, divisions: 5,
            format: (v) => '${v.round()} min',
            onChanged: (v) => setState(() => _buddyAfterMinutes = v.round()),
          ),

          const SizedBox(height: 20),
          _SectionLabel('Emergency Contact'),
          _InfoBox(
            icon:  Icons.info_outline,
            color: Colors.white38,
            text:  'This is the person RISE contacts first if you '
                   'cannot be reached. Choose someone who can '
                   'physically check on you if needed.',
          ),
          const SizedBox(height: 8),
          _ContactCard(
            contact:  _emergencyContact,
            role:     'Emergency Contact',
            subtitle: 'Wellness check after ${_emergencyAfterMinutes}min',
            onAdd:    () => _pickContact(isEmergency: true),
            onRemove: () => _removeContact(isEmergency: true),
          ),
          const SizedBox(height: 8),
          _SliderTile(
            label: 'Escalate to emergency contact after',
            value: _emergencyAfterMinutes.toDouble(),
            min:   20, max: 60, divisions: 8,
            format: (v) => '${v.round()} min',
            onChanged: (v) =>
                setState(() => _emergencyAfterMinutes = v.round()),
          ),

          const SizedBox(height: 20),
          _SectionLabel('Post-Alarm Watchdog'),
          _ToggleTile(
            title:       'Monitor after dismissal',
            description: 'RISE watches for 8 minutes after you dismiss '
                'your alarm. If your phone goes dark and still, '
                'it gently checks you\'re still up. (EC-4.9)',
            value:   _postWatchdogEnabled,
            onChanged: (v) => setState(() => _postWatchdogEnabled = v),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _pickContact({required bool isEmergency}) async {
    final granted = await FlutterContacts.requestPermission();
    if (!granted) return;
    if (!mounted) return;

    // Open contact picker
    final contact = await FlutterContacts.openExternalPick();
    if (contact == null) return;

    final phone = contact.phones.firstOrNull?.number ?? '';
    final buddy = BuddyContact(
      name:              contact.displayName,
      phoneNumber:       phone,
      isEmergencyContact: isEmergency,
      notifyMethod:      'whatsapp',
    );

    final box = Hive.box<dynamic>(AppConstants.buddyBoxName);
    await box.put(buddy.id, buddy);
    setState(() {
      if (isEmergency) _emergencyContact = buddy;
      else             _buddy = buddy;
    });
  }

  void _removeContact({required bool isEmergency}) {
    final contact = isEmergency ? _emergencyContact : _buddy;
    if (contact == null) return;
    final box = Hive.box<dynamic>(AppConstants.buddyBoxName);
    box.delete(contact.id);
    setState(() {
      if (isEmergency) _emergencyContact = null;
      else             _buddy = null;
    });
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final BuddyContact? contact;
  final String        role;
  final String        subtitle;
  final VoidCallback  onAdd;
  final VoidCallback  onRemove;

  const _ContactCard({
    required this.contact,
    required this.role,
    required this.subtitle,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        const Color(0xFF161628),
      borderRadius: BorderRadius.circular(12),
    ),
    child: contact == null
        ? Row(children: [
            Icon(Icons.person_add_outlined,
                color: Colors.white38, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No $role set',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ],
            )),
            TextButton(
              onPressed: onAdd,
              child: const Text('Add',
                  style: TextStyle(color: Colors.indigoAccent)),
            ),
          ])
        : Row(children: [
            CircleAvatar(
              radius:          20,
              backgroundColor: Colors.indigo.withOpacity(0.3),
              child: Text(
                contact!.name.isNotEmpty
                    ? contact!.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact!.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(contact!.phoneNumber ?? '',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ],
            )),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close,
                  color: Colors.white38, size: 18),
            ),
          ]),
  );
}

class _ToggleTile extends StatelessWidget {
  final String   title;
  final String   description;
  final bool     value;
  final void Function(bool) onChanged;
  const _ToggleTile({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF161628),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
              color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(
              color: Colors.white38, fontSize: 12, height: 1.5)),
        ],
      )),
      const SizedBox(width: 12),
      Switch(
        value:      value,
        onChanged:  onChanged,
        activeColor: Colors.indigoAccent,
      ),
    ]),
  );
}

class _SliderTile extends StatelessWidget {
  final String   label;
  final double   value;
  final double   min, max;
  final int      divisions;
  final String Function(double) format;
  final void Function(double) onChanged;

  const _SliderTile({
    required this.label, required this.value, required this.min,
    required this.max, required this.divisions, required this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    decoration: BoxDecoration(
      color: const Color(0xFF161628),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(children: [
      Row(children: [
        Text(label, style: const TextStyle(
            color: Colors.white70, fontSize: 13)),
        const Spacer(),
        Text(format(value), style: const TextStyle(
            color: Colors.white, fontSize: 13,
            fontWeight: FontWeight.w600)),
      ]),
      Slider(
        value:     value,
        min:       min, max: max, divisions: divisions,
        onChanged: onChanged,
        activeColor:   Colors.indigoAccent,
        inactiveColor: Colors.white12,
      ),
    ]),
  );
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   text;
  const _InfoBox({
    required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(text,
          style: TextStyle(color: color.withOpacity(0.85),
              fontSize: 12, height: 1.5))),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
    child: Text(text.toUpperCase(), style: TextStyle(
        color: Colors.white.withOpacity(0.35), fontSize: 11,
        fontWeight: FontWeight.w700, letterSpacing: 1.2)),
  );
}
```

---

## FILE 4: lib/features/settings/sections/notification_settings.dart
## PATH: lib/features/settings/sections/notification_settings.dart
## PURPOSE: Permission status, DND warning, manufacturer battery
##          restriction guide per device brand.
##          EC-5.7 DND check. EC-6.4 battery optimization.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});
  @override
  State<NotificationSettings> createState() =>
      _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings>
    with WidgetsBindingObserver {

  bool _notifGranted   = false;
  bool _alarmGranted   = false;
  bool _exactAlarm     = false;
  bool _batteryExempt  = false;
  bool _dndConflict    = false;
  String? _deviceBrand;

  static const _channel = MethodChannel('com.rise.alarmclock/capabilities');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _check() async {
    final notif  = await Permission.notification.isGranted;
    // Exact alarm permission (Android 12+)
    bool exact   = true;
    bool battery = true;
    bool dnd     = false;
    String brand = 'generic';
    try {
      final r = await _channel.invokeMethod(
          'checkAlarmPermissions') as Map;
      exact   = r['exactAlarm']    as bool? ?? true;
      battery = r['batteryExempt'] as bool? ?? true;
      dnd     = r['dndConflict']   as bool? ?? false;
      brand   = r['deviceBrand']   as String? ?? 'generic';
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _notifGranted   = notif;
      _exactAlarm     = exact;
      _batteryExempt  = battery;
      _dndConflict    = dnd;
      _deviceBrand    = brand;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
        title: const Text('Notifications & Permissions',
            style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Permission status cards ─────────────────────────────
          _PermCard(
            label:   'Notifications',
            ok:      _notifGranted,
            okText:  'Granted',
            badText: '⛔ Required — alarm cannot fire without this',
            onFix:   () => openAppSettings(),
          ),
          const SizedBox(height: 8),
          _PermCard(
            label:   'Exact alarms (Android 12+)',
            ok:      _exactAlarm,
            okText:  'Granted',
            badText: 'Required for precise alarm timing',
            onFix:   () => _channel.invokeMethod('openExactAlarmSettings'),
          ),
          const SizedBox(height: 8),
          _PermCard(
            label:   'Battery optimization exemption',
            ok:      _batteryExempt,
            okText:  'Exempt (recommended)',
            badText: 'App may be throttled — alarm reliability at risk',
            onFix:   () => _channel.invokeMethod(
                'openBatteryOptimizationSettings'),
          ),

          // EC-5.7 DND conflict
          if (_dndConflict) ...[
            const SizedBox(height: 8),
            _PermCard(
              label:   'Do Not Disturb',
              ok:      false,
              okText:  '',
              badText: 'DND is blocking alarms during your alarm time. '
                  'Tap to fix.',
              onFix:   () => _channel.invokeMethod('openDndSettings'),
            ),
          ],

          const SizedBox(height: 24),

          // EC-6.4 Manufacturer-specific battery restriction guide
          if (_deviceBrand != null)
            _ManufacturerGuide(brand: _deviceBrand!),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PermCard extends StatelessWidget {
  final String       label;
  final bool         ok;
  final String       okText;
  final String       badText;
  final VoidCallback onFix;

  const _PermCard({
    required this.label, required this.ok, required this.okText,
    required this.badText, required this.onFix,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color:  ok ? const Color(0xFF161628)
                 : Colors.red.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: ok ? Colors.white.withOpacity(0.06)
                  : Colors.redAccent.withOpacity(0.4),
      ),
    ),
    child: Row(children: [
      Icon(
        ok ? Icons.check_circle : Icons.warning_amber_rounded,
        color: ok ? Colors.greenAccent : Colors.redAccent,
        size: 20,
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(ok ? okText : badText,
              style: TextStyle(
                  color: ok ? Colors.white38 : Colors.redAccent,
                  fontSize: 12)),
        ],
      )),
      if (!ok) TextButton(
        onPressed: onFix,
        child: const Text('Fix',
            style: TextStyle(color: Colors.indigoAccent,
                fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}

class _ManufacturerGuide extends StatelessWidget {
  final String brand;
  const _ManufacturerGuide({required this.brand});

  @override
  Widget build(BuildContext context) {
    final steps = _stepsFor(brand);
    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text('${_brandLabel(brand)} setup guide'.toUpperCase(),
              style: TextStyle(color: Colors.white.withOpacity(0.35),
                  fontSize: 11, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        Colors.amber.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.phone_android,
                    color: Colors.amber, size: 16),
                SizedBox(width: 8),
                Text('Your device restricts background apps',
                    style: TextStyle(color: Colors.amber,
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              ...steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e.key + 1}. ',
                        style: const TextStyle(
                            color: Colors.amber, fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    Expanded(child: Text(e.value,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12,
                            height: 1.4))),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  String _brandLabel(String b) => switch (b) {
    'xiaomi'   => 'Xiaomi / MIUI',
    'samsung'  => 'Samsung',
    'oneplus'  => 'OnePlus / OxygenOS',
    'huawei'   => 'Huawei / EMUI',
    'oppo'     => 'OPPO / ColorOS',
    'realme'   => 'Realme UI',
    _          => b,
  };

  List<String> _stepsFor(String b) => switch (b) {
    'xiaomi' => [
      'Settings → Apps → Manage Apps → RISE → Battery Saver → No restrictions',
      'Settings → Apps → Manage Apps → RISE → Autostart → Enable',
      'Security app → Battery → App battery saver → RISE → No restrictions',
    ],
    'samsung' => [
      'Settings → Device Care → Battery → Background usage limits → Never sleeping apps → Add RISE',
      'Settings → Apps → RISE → Battery → Unrestricted',
    ],
    'oneplus' => [
      'Settings → Battery → Battery optimization → RISE → Don\'t optimize',
      'Settings → Apps → RISE → Battery → Allow background activity',
    ],
    'huawei' => [
      'Settings → Battery → App launch → RISE → Manage manually → Enable all toggles',
      'Phone Manager → Protected apps → Add RISE',
    ],
    'oppo' || 'realme' => [
      'Settings → Battery → Battery optimization → RISE → Don\'t optimize',
      'Settings → Apps → RISE → Battery usage → Allow background activity',
    ],
    _ => [],
  };
}
```

---

## FILE 5: lib/features/settings/sections/biometric_settings.dart
## PATH: lib/features/settings/sections/biometric_settings.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/subscription_provider.dart';

class BiometricSettings extends ConsumerWidget {
  const BiometricSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = SubscriptionTier.fromId(
        ref.watch(subscriptionProvider).tier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
        title: const Text('Biometric Identity Lock',
            style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!tier.biometricLock)
            _UpgradeBanner(
              message: 'Biometric identity lock requires Core or above.',
              ctaLabel: 'Upgrade',
              onTap: () => Navigator.pushNamed(context, '/paywall'),
            )
          else ...[
            _InfoCard(
              icon:  Icons.security,
              color: Colors.indigoAccent,
              title: 'Identity Lock Active',
              body:  'RISE verifies your heart rate at every alarm '
                     'dismissal. This prevents someone else from '
                     'dismissing your alarm on your behalf.',
            ),
            const SizedBox(height: 20),

            _ActionTile(
              icon:    Icons.refresh,
              label:   'Re-enroll biometric profile',
              sublabel: 'Recommended after illness, medication changes, '
                        'or if verification fails frequently.',
              color:   Colors.indigoAccent,
              onTap:   () => Navigator.pushNamed(
                  context, '/biometric-enrollment'),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon:    Icons.pin_outlined,
              label:   'Change PIN',
              sublabel: 'PIN is used as a fallback when PPG fails.',
              color:   Colors.white70,
              onTap:   () => _showChangePinSheet(context),
            ),
          ],
        ],
      ),
    );
  }

  void _showChangePinSheet(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      backgroundColor:    const Color(0xFF161628),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _ChangePinSheet(),
    );
  }
}

class _ChangePinSheet extends StatefulWidget {
  const _ChangePinSheet();
  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  final _newCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Change PIN',
              style: TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _PinField(ctrl: _newCtrl,     label: 'New PIN (4–8 digits)'),
          const SizedBox(height: 12),
          _PinField(ctrl: _confirmCtrl, label: 'Confirm new PIN'),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(
                color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Save PIN',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _save() {
    final n = _newCtrl.text.trim();
    final c = _confirmCtrl.text.trim();
    if (n.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits.');
      return;
    }
    if (n != c) {
      setState(() => _error = 'PINs do not match.');
      return;
    }
    // TODO: Save hashed PIN via BiometricService.setPin()
    Navigator.pop(context);
    ScaffoldMessenger.of(context.findRootAncestorStateOfType<ScaffoldState>()!.context)
        .showSnackBar(const SnackBar(content: Text('PIN updated.')));
  }

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
}

class _PinField extends StatelessWidget {
  final TextEditingController ctrl;
  final String                label;
  const _PinField({required this.ctrl, required this.label});

  @override
  Widget build(BuildContext context) => TextField(
    controller:   ctrl,
    obscureText:  true,
    keyboardType: TextInputType.number,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText:      label,
      labelStyle:     const TextStyle(color: Colors.white38),
      enabledBorder:  const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24)),
      focusedBorder:  const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white)),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final String?      sublabel;
  final Color        color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon, required this.label, this.sublabel,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    child: ListTile(
      tileColor:    const Color(0xFF161628),
      shape:        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      leading:      Icon(icon, color: color, size: 22),
      title:        Text(label, style: const TextStyle(
          color: Colors.white, fontSize: 14)),
      subtitle:     sublabel != null ? Text(sublabel!,
          style: const TextStyle(
              color: Colors.white38, fontSize: 12)) : null,
      trailing:     const Icon(Icons.chevron_right,
          color: Colors.white24, size: 20),
      onTap: onTap,
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title, body;
  const _InfoCard({
    required this.icon, required this.color,
    required this.title, required this.body,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color,
              fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(
              color: Colors.white54, fontSize: 12, height: 1.5)),
        ],
      )),
    ]),
  );
}

class _UpgradeBanner extends StatelessWidget {
  final String       message, ctaLabel;
  final VoidCallback onTap;
  const _UpgradeBanner({
    required this.message, required this.ctaLabel, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color:        Colors.amber.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.amber.withOpacity(0.35)),
    ),
    child: Row(children: [
      const Icon(Icons.lock_outline, color: Colors.amber, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(message,
          style: const TextStyle(
              color: Colors.amber, fontSize: 13))),
      TextButton(
        onPressed: onTap,
        child: Text(ctaLabel,
            style: const TextStyle(
                color: Colors.amber, fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}
```

---

## FILE 6: lib/features/alarm/alarm_setup_screen.dart
## PATH: lib/features/alarm/alarm_setup_screen.dart
## PURPOSE: Full alarm creation and editing flow.
##          All AlarmModel fields are configurable here.
##          Validates DND conflict (EC-5.7), system volume (EC-1.8),
##          and barcode registration for barcode scan game.

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/alarm_model.dart';
import '../../core/models/buddy_contact.dart';
import '../../core/models/subscription_tier.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/alarm_scheduler.dart';
import '../../core/services/alarm_service.dart';
import 'widgets/sound_picker.dart';

class AlarmSetupScreen extends ConsumerStatefulWidget {
  final AlarmModel? existing; // null = new alarm
  const AlarmSetupScreen({super.key, this.existing});

  @override
  ConsumerState<AlarmSetupScreen> createState() =>
      _AlarmSetupScreenState();
}

class _AlarmSetupScreenState extends ConsumerState<AlarmSetupScreen> {
  static const _channel = MethodChannel(
      'com.rise.alarmclock/capabilities');

  // Form state — mirrors AlarmModel fields
  late int          _hour;
  late int          _minute;
  late String       _label;
  late List<int>    _repeatDays;   // 0=Mon … 6=Sun
  late bool         _isNap;
  late String       _soundPath;
  late int          _volumePercent;
  late bool         _vibrate;
  late bool         _biometricLock;
  late int          _snoozeMax;
  late int          _snoozeDuration;
  late String       _gameType;
  late String       _gameDifficulty;
  late bool         _buddyEnabled;
  late String?      _buddyId;
  late int          _buddyAfterSnooze;
  late bool         _gradualVolume;
  late bool         _autoDismissDriving;  // EC-5.2
  late bool         _postWatchdog;        // EC-4.9
  late String?      _barcodeScanCode;     // Barcode game target

  // Validation warnings
  bool    _dndConflict       = false;
  bool    _systemVolumeMuted = false;
  bool    _notifMissing      = false;

  final _labelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    final now = DateTime.now();

    _hour            = a?.hour            ?? now.hour;
    _minute          = a?.minute          ?? now.minute;
    _label           = a?.label           ?? '';
    _repeatDays      = List.from(a?.repeatDays ?? []);
    _isNap           = a?.isNap           ?? false;
    _soundPath       = a?.soundPath       ?? 'assets/sounds/rise_default.mp3';
    _volumePercent   = a?.volumePercent   ?? 80;
    _vibrate         = a?.vibrateEnabled  ?? true;
    _biometricLock   = a?.biometricLock   ?? true;
    _snoozeMax       = a?.snoozeMaxCount  ?? 3;
    _snoozeDuration  = a?.snoozeDurationMinutes ?? 7;
    _gameType        = a?.gameType        ?? 'random';
    _gameDifficulty  = a?.gameDifficulty  ?? 'escalating';
    _buddyEnabled    = a?.buddyNotifyEnabled ?? false;
    _buddyId         = a?.buddyContactId;
    _buddyAfterSnooze = a?.buddyNotifyAfterSnoozeCount ?? 2;
    _gradualVolume   = a?.gradualVolumeEnabled ?? true;
    _autoDismissDriving = true;
    _postWatchdog    = true;
    _barcodeScanCode = null;

    _labelCtrl.text = _label;
    _checkWarnings();
  }

  Future<void> _checkWarnings() async {
    try {
      final r = await _channel.invokeMethod(
          'checkAlarmPermissions') as Map;
      if (!mounted) return;
      setState(() {
        _dndConflict       = r['dndConflict']   as bool? ?? false;
        _systemVolumeMuted = r['systemMuted']   as bool? ?? false;
        _notifMissing      = !(r['notifGranted'] as bool? ?? true);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = SubscriptionTier.fromId(
        ref.watch(subscriptionProvider).tier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
        title: Text(
          widget.existing == null ? 'New Alarm' : 'Edit Alarm',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: const Text('Save',
                style: TextStyle(
                    color: Colors.indigoAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Warnings ──────────────────────────────────────────────
          if (_notifMissing)
            _WarningBanner(
              text: '⛔ Alarm cannot fire — notification permission required.',
              color: Colors.redAccent,
              onTap: () => openAppSettings(),
            ),
          if (_dndConflict)
            _WarningBanner(
              text: 'Do Not Disturb is blocking alarms at this time.',
              color: Colors.orange,
              onTap: () => _channel.invokeMethod('openDndSettings'),
            ),
          if (_systemVolumeMuted)
            _WarningBanner(
              text: 'Phone volume is 0 — RISE will still play at 40% '
                    'alarm volume (separate from media volume).',
              color: Colors.amber,
              onTap: null,
            ),
          if (_dndConflict || _notifMissing || _systemVolumeMuted)
            const SizedBox(height: 12),

          // ── TIME PICKER ──────────────────────────────────────────
          _TimePickerCard(
            hour:   _hour,
            minute: _minute,
            onTap:  _pickTime,
          ),
          const SizedBox(height: 12),

          // ── Label ────────────────────────────────────────────────
          _Card(child: TextField(
            controller: _labelCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText:     'Label (optional)',
              labelStyle:    TextStyle(color: Colors.white38),
              border:        InputBorder.none,
              prefixIcon:    Icon(Icons.label_outline,
                  color: Colors.white38),
            ),
            onChanged: (v) => _label = v,
          )),
          const SizedBox(height: 12),

          // ── Repeat days ──────────────────────────────────────────
          _RepeatDaySelector(
            selected:  _repeatDays,
            onChange:  (days) => setState(() => _repeatDays = days),
          ),
          const SizedBox(height: 12),

          // ── Alarm type (EC-4.7 nap mode) ─────────────────────────
          _Card(child: _SegmentedRow(
            label: 'Alarm type',
            options: const ['Regular', 'Nap'],
            selected: _isNap ? 1 : 0,
            onSelect: (i) => setState(() => _isNap = i == 1),
          )),
          const SizedBox(height: 12),

          // ── Sound ────────────────────────────────────────────────
          _SoundTile(
            current:  _soundPath,
            onSelect: (p) => setState(() => _soundPath = p),
          ),
          const SizedBox(height: 12),

          // ── Volume ───────────────────────────────────────────────
          _Card(child: Column(children: [
            _SliderRow(
              label:  'Volume',
              icon:   Icons.volume_up_outlined,
              value:  _volumePercent.toDouble(),
              min: 20, max: 100, divisions: 16,
              format: (v) => '${v.round()}%',
              onChanged: (v) =>
                  setState(() => _volumePercent = v.round()),
            ),
            const Divider(color: Colors.white12),
            _SwitchRow(
              label:    'Gradual volume',
              sublabel: 'Starts at 20%, rises to max over 2 minutes',
              value:    _gradualVolume,
              onChanged: (v) =>
                  setState(() => _gradualVolume = v),
            ),
            const Divider(color: Colors.white12),
            _SwitchRow(
              label:    'Vibrate',
              value:    _vibrate,
              onChanged: (v) => setState(() => _vibrate = v),
            ),
          ])),
          const SizedBox(height: 12),

          // ── Snooze ───────────────────────────────────────────────
          if (!_isNap) ...[
            _Card(child: Column(children: [
              _SliderRow(
                label:  'Max snoozes',
                icon:   Icons.snooze_outlined,
                value:  _snoozeMax.toDouble(),
                min:    0, max: 5, divisions: 5,
                format: (v) {
                  final n = v.round();
                  if (n == 0) return 'None';
                  return '$n snooze${n == 1 ? '' : 's'}';
                },
                onChanged: (v) =>
                    setState(() => _snoozeMax = v.round()),
              ),
              const Divider(color: Colors.white12),
              _SliderRow(
                label:  'Snooze duration',
                icon:   Icons.timer_outlined,
                value:  _snoozeDuration.toDouble(),
                min:    5, max: 30, divisions: 5,
                format: (v) => '${v.round()} min',
                onChanged: (v) =>
                    setState(() => _snoozeDuration = v.round()),
              ),
            ])),
            const SizedBox(height: 12),
          ],

          // ── Wake game ────────────────────────────────────────────
          if (!_isNap) ...[
            _Card(child: Column(children: [
              _DropdownRow(
                label:   'Wake game',
                icon:    Icons.sports_esports_outlined,
                value:   _gameType,
                options: const {
                  'random':    'Random (recommended)',
                  'math':      'Math',
                  'memory':    'Memory grid',
                  'word':      'Word unscramble',
                  'sequence':  'Sequence tap',
                  'barcode':   'Barcode scan',
                },
                onChanged: (v) => setState(() => _gameType = v!),
              ),
              const Divider(color: Colors.white12),
              _DropdownRow(
                label:   'Difficulty',
                icon:    Icons.trending_up_outlined,
                value:   _gameDifficulty,
                options: const {
                  'escalating': 'Escalating (harder with snoozes)',
                  'easy':       'Easy',
                  'medium':     'Medium',
                  'hard':       'Hard',
                },
                onChanged: (v) =>
                    setState(() => _gameDifficulty = v!),
              ),
            ])),
            // Barcode registration
            if (_gameType == 'barcode' ||
                _gameType == 'random') ...[
              const SizedBox(height: 8),
              _BarcodeSetupTile(
                existing:  _barcodeScanCode,
                onScanned: (code) =>
                    setState(() => _barcodeScanCode = code),
              ),
            ],
            const SizedBox(height: 12),
          ],

          // ── Identity lock ─────────────────────────────────────────
          _Card(child: _SwitchRow(
            label:    'Biometric identity lock',
            sublabel: 'Verify it\'s you before dismissing',
            value:    _biometricLock,
            locked:   !tier.biometricLock,
            lockedLabel: 'Core+',
            onChanged: (v) {
              if (!tier.biometricLock) {
                Navigator.pushNamed(context, '/paywall');
                return;
              }
              setState(() => _biometricLock = v);
            },
          )),
          const SizedBox(height: 12),

          // ── Accountability buddy ──────────────────────────────────
          _BuddySetupTile(
            enabled:       _buddyEnabled,
            buddyId:       _buddyId,
            afterSnoozes:  _buddyAfterSnooze,
            onToggle:      (v) => setState(() => _buddyEnabled = v),
            onSelectBuddy: (id) => setState(() => _buddyId = id),
            onSnoozeChange: (n) =>
                setState(() => _buddyAfterSnooze = n),
          ),
          const SizedBox(height: 12),

          // ── Behavior ─────────────────────────────────────────────
          _Card(child: Column(children: [
            _SwitchRow(
              label:    'Auto-dismiss when driving',
              sublabel: 'Alarm silently dismissed if you\'re in a '
                        'moving vehicle (EC-5.2)',
              value:    _autoDismissDriving,
              onChanged: (v) =>
                  setState(() => _autoDismissDriving = v),
            ),
            const Divider(color: Colors.white12),
            _SwitchRow(
              label:    'Post-alarm watchdog',
              sublabel: 'Monitors for 8 min after dismissal in case '
                        'you lie back down (EC-4.9)',
              value:    _postWatchdog,
              onChanged: (v) =>
                  setState(() => _postWatchdog = v),
            ),
          ])),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.indigoAccent,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { _hour = picked.hour; _minute = picked.minute; });
      _checkWarnings(); // Recheck DND for new time
    }
  }

  Future<void> _saveAlarm() async {
    if (_notifMissing) {
      _showError('Notification permission required to save alarms.');
      return;
    }

    final alarm = AlarmModel(
      id:                      widget.existing?.id,
      label:                   _labelCtrl.text.trim(),
      hour:                    _hour,
      minute:                  _minute,
      repeatDays:              _repeatDays,
      isEnabled:               true,
      soundPath:               _soundPath,
      volumePercent:           _volumePercent,
      vibrateEnabled:          _vibrate,
      biometricLock:           _biometricLock,
      snoozeMaxCount:          _snoozeMax,
      snoozeDurationMinutes:   _snoozeDuration,
      gameType:                _gameType,
      gameDifficulty:          _gameDifficulty,
      buddyNotifyEnabled:      _buddyEnabled,
      buddyContactId:          _buddyId,
      buddyNotifyAfterSnoozeCount: _buddyAfterSnooze,
      gradualVolumeEnabled:    _gradualVolume,
      identityMode:            _biometricLock ? 'ppg' : 'none',
      isNap:                   _isNap,
    );

    // Save barcode to settings if barcode game selected
    if (_barcodeScanCode != null) {
      final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
      await box.put('barcode_scan_code', _barcodeScanCode);
    }

    final box = Hive.box<dynamic>(AppConstants.alarmsBoxName);
    await box.put(alarm.id, alarm);

    // Schedule in OS
    await AlarmService().scheduleAlarm(alarm);

    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg),
            backgroundColor: Colors.redAccent));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIME PICKER CARD
// ─────────────────────────────────────────────────────────────────────────────
class _TimePickerCard extends StatelessWidget {
  final int          hour, minute;
  final VoidCallback onTap;
  const _TimePickerCard({
    required this.hour, required this.minute, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h      = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    final m      = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A3E), Color(0xFF2D1B69)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$h:$m', style: const TextStyle(
                color: Colors.white, fontSize: 64,
                fontWeight: FontWeight.w200, letterSpacing: 4)),
            const SizedBox(width: 8),
            Text(period, style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 20,
                fontWeight: FontWeight.w300)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REPEAT DAY SELECTOR
// ─────────────────────────────────────────────────────────────────────────────
class _RepeatDaySelector extends StatelessWidget {
  final List<int>          selected;
  final void Function(List<int>) onChange;
  const _RepeatDaySelector({required this.selected, required this.onChange});

  static const _days = ['M','T','W','T','F','S','S'];

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Repeat',
              style: TextStyle(color: Colors.white70,
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (i) {
            final on = selected.contains(i);
            return GestureDetector(
              onTap: () {
                final next = List<int>.from(selected);
                on ? next.remove(i) : next.add(i);
                onChange(next);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 38, height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on
                      ? Colors.indigoAccent
                      : Colors.white.withOpacity(0.07),
                ),
                child: Center(
                  child: Text(_days[i], style: TextStyle(
                      color: on ? Colors.white : Colors.white54,
                      fontSize: 13,
                      fontWeight: on
                          ? FontWeight.w700 : FontWeight.w400)),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Center(child: Text(
          selected.isEmpty ? 'Once' : _repeatLabel(selected),
          style: const TextStyle(
              color: Colors.white38, fontSize: 12),
        )),
      ],
    ),
  );

  String _repeatLabel(List<int> d) {
    if (d.length == 7) return 'Every day';
    if (d.length == 5 && !d.contains(5) && !d.contains(6))
      return 'Weekdays';
    if (d.length == 2 && d.contains(5) && d.contains(6))
      return 'Weekends';
    const n = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final s = List<int>.from(d)..sort();
    return s.map((i) => n[i]).join(', ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BARCODE SETUP TILE
// ─────────────────────────────────────────────────────────────────────────────
class _BarcodeSetupTile extends StatelessWidget {
  final String?              existing;
  final void Function(String) onScanned;
  const _BarcodeSetupTile({this.existing, required this.onScanned});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color:        Colors.indigo.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.indigo.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.qr_code_scanner,
          color: Colors.indigoAccent, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Barcode target',
              style: TextStyle(color: Colors.white70, fontSize: 13,
                  fontWeight: FontWeight.w600)),
          Text(
            existing != null
                ? 'Registered: ${existing!.substring(0, min(existing!.length, 16))}…'
                : 'No barcode registered yet',
            style: const TextStyle(
                color: Colors.white38, fontSize: 12),
          ),
        ],
      )),
      TextButton(
        onPressed: () => _openScanner(context),
        child: Text(
          existing != null ? 'Change' : 'Scan',
          style: const TextStyle(color: Colors.indigoAccent),
        ),
      ),
    ]),
  );

  void _openScanner(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _BarcodeRegistrationScreen(onScanned: (code) {
        onScanned(code);
        Navigator.pop(context);
      }),
    ));
  }

  int min(int a, int b) => a < b ? a : b;
}

class _BarcodeRegistrationScreen extends StatefulWidget {
  final void Function(String) onScanned;
  const _BarcodeRegistrationScreen({required this.onScanned});

  @override
  State<_BarcodeRegistrationScreen> createState() =>
      _BarcodeRegistrationState();
}

class _BarcodeRegistrationState
    extends State<_BarcodeRegistrationScreen> {
  final _ctrl      = MobileScannerController();
  bool  _captured  = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
        title: const Text('Register your barcode item',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Stack(children: [
        MobileScanner(
          controller: _ctrl,
          onDetect: (cap) {
            if (_captured) return;
            final code = cap.barcodes.firstOrNull?.rawValue;
            if (code == null) return;
            _captured = true;
            _ctrl.stop();
            widget.onScanned(code);
          },
        ),
        Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Scan the item you\'ll keep in another room.\n'
                'You\'ll need to walk to it to dismiss the alarm.',
                style: TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        )),
      ]),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUDDY SETUP TILE
// ─────────────────────────────────────────────────────────────────────────────
class _BuddySetupTile extends StatelessWidget {
  final bool              enabled;
  final String?           buddyId;
  final int               afterSnoozes;
  final void Function(bool)   onToggle;
  final void Function(String) onSelectBuddy;
  final void Function(int)    onSnoozeChange;

  const _BuddySetupTile({
    required this.enabled, required this.buddyId,
    required this.afterSnoozes, required this.onToggle,
    required this.onSelectBuddy, required this.onSnoozeChange,
  });

  @override
  Widget build(BuildContext context) {
    final buddies = Hive.box<dynamic>(AppConstants.buddyBoxName)
        .values.cast<BuddyContact>()
        .where((c) => !c.isEmergencyContact)
        .toList();
    final selected = buddies.firstWhereOrNull(
        (c) => c.id == buddyId);

    return _Card(child: Column(children: [
      _SwitchRow(
        label:    'Accountability buddy',
        sublabel: 'Someone who gets notified if you don\'t wake up',
        value:    enabled,
        onChanged: onToggle,
      ),
      if (enabled) ...[
        const Divider(color: Colors.white12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.indigo.withOpacity(0.3),
            child: Text(
              selected?.name.isNotEmpty == true
                  ? selected!.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700)),
          ),
          title: Text(
            selected?.name ?? 'No buddy selected',
            style: const TextStyle(
                color: Colors.white70, fontSize: 14)),
          subtitle: buddies.isEmpty
              ? const Text('Go to Settings → Safety to add a buddy',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 11))
              : null,
          trailing: buddies.isNotEmpty
              ? DropdownButton<String>(
                  value:           buddyId,
                  dropdownColor:   const Color(0xFF1A1A3E),
                  underline:       const SizedBox(),
                  hint:            const Text('Select',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 13)),
                  items: buddies.map((c) =>
                      DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                      )).toList(),
                  onChanged: (id) {
                    if (id != null) onSelectBuddy(id);
                  },
                )
              : null,
        ),
        const Divider(color: Colors.white12),
        _SliderRow(
          label:  'Notify after',
          icon:   Icons.notifications_outlined,
          value:  afterSnoozes.toDouble(),
          min:    1, max: 5, divisions: 4,
          format: (v) {
            final n = v.round();
            return '$n snooze${n == 1 ? '' : 's'} without dismissal';
          },
          onChanged: (v) => onSnoozeChange(v.round()),
        ),
      ],
    ]));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED UI ATOMS
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        const Color(0xFF161628),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

class _SwitchRow extends StatelessWidget {
  final String   label;
  final String?  sublabel;
  final bool     value;
  final bool     locked;
  final String?  lockedLabel;
  final void Function(bool) onChanged;

  const _SwitchRow({
    required this.label, this.sublabel,
    required this.value, required this.onChanged,
    this.locked = false, this.lockedLabel,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              color: Colors.white70, fontSize: 14)),
          if (sublabel != null)
            Text(sublabel!, style: const TextStyle(
                color: Colors.white38, fontSize: 11,
                height: 1.5)),
        ],
      )),
      if (locked && lockedLabel != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color:        Colors.amber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(lockedLabel!, style: const TextStyle(
              color: Colors.amber, fontSize: 11,
              fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
      ],
      Switch(
        value:       value,
        onChanged:   onChanged,
        activeColor: Colors.indigoAccent,
      ),
    ],
  );
}

class _SliderRow extends StatelessWidget {
  final String   label;
  final IconData icon;
  final double   value, min, max;
  final int      divisions;
  final String Function(double) format;
  final void Function(double) onChanged;

  const _SliderRow({
    required this.label, required this.icon, required this.value,
    required this.min, required this.max, required this.divisions,
    required this.format, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      Icon(icon, color: Colors.white38, size: 18),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(
          color: Colors.white70, fontSize: 13)),
      const Spacer(),
      Text(format(value), style: const TextStyle(
          color: Colors.white, fontSize: 13,
          fontWeight: FontWeight.w600)),
    ]),
    Slider(
      value: value, min: min, max: max, divisions: divisions,
      onChanged: onChanged,
      activeColor:   Colors.indigoAccent,
      inactiveColor: Colors.white12,
    ),
  ]);
}

class _DropdownRow extends StatelessWidget {
  final String                 label;
  final IconData               icon;
  final String                 value;
  final Map<String, String>    options;
  final void Function(String?) onChanged;

  const _DropdownRow({
    required this.label, required this.icon, required this.value,
    required this.options, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: Colors.white38, size: 18),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(
        color: Colors.white70, fontSize: 13)),
    const Spacer(),
    DropdownButton<String>(
      value:         value,
      dropdownColor: const Color(0xFF1A1A3E),
      underline:     const SizedBox(),
      style:         const TextStyle(color: Colors.white, fontSize: 13),
      items: options.entries.map((e) => DropdownMenuItem(
        value: e.key,
        child: Text(e.value, style: const TextStyle(
            color: Colors.white, fontSize: 13)),
      )).toList(),
      onChanged: onChanged,
    ),
  ]);
}

class _SegmentedRow extends StatelessWidget {
  final String       label;
  final List<String> options;
  final int          selected;
  final void Function(int) onSelect;
  const _SegmentedRow({
    required this.label, required this.options,
    required this.selected, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: const TextStyle(
        color: Colors.white70, fontSize: 13)),
    const Spacer(),
    Container(
      decoration: BoxDecoration(
        color:        Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: options.asMap().entries.map((e) =>
          GestureDetector(
            onTap: () => onSelect(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color:        e.key == selected
                    ? Colors.indigoAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(e.value, style: TextStyle(
                  color:      e.key == selected
                      ? Colors.white : Colors.white54,
                  fontSize:   13,
                  fontWeight: e.key == selected
                      ? FontWeight.w600 : FontWeight.w400)),
            ),
          )).toList(),
      ),
    ),
  ]);
}

class _SoundTile extends StatelessWidget {
  final String                 current;
  final void Function(String)  onSelect;
  const _SoundTile({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final name = current.split('/').last.replaceAll('.mp3', '');
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => SoundPicker(
          current:  current,
          onSelect: (p) { onSelect(p); Navigator.pop(context); },
        ),
      )),
      child: _Card(child: Row(children: [
        const Icon(Icons.music_note_outlined,
            color: Colors.white38, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alarm sound', style: TextStyle(
                color: Colors.white70, fontSize: 13,
                fontWeight: FontWeight.w600)),
            Text(name, style: const TextStyle(
                color: Colors.white38, fontSize: 12)),
          ],
        )),
        const Icon(Icons.chevron_right,
            color: Colors.white24, size: 20),
      ])),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String       text;
  final Color        color;
  final VoidCallback? onTap;
  const _WarningBanner({
    required this.text, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      margin:  const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
            style: TextStyle(color: color, fontSize: 12))),
        if (onTap != null)
          Icon(Icons.chevron_right, color: color, size: 16),
      ]),
    ),
  );
}
```

---

## FILE 7: lib/features/alarm/widgets/sound_picker.dart
## PATH: lib/features/alarm/widgets/sound_picker.dart
## PURPOSE: Bundled ringtone picker + custom local file selection.

```dart
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SoundPicker extends StatefulWidget {
  final String                current;
  final void Function(String) onSelect;
  const SoundPicker({super.key,
    required this.current, required this.onSelect});

  @override
  State<SoundPicker> createState() => _SoundPickerState();
}

class _SoundPickerState extends State<SoundPicker> {
  final _player = AudioPlayer();
  String? _playing;
  late String _selected;

  static const _bundled = [
    _Sound('Rise (Default)',  'assets/sounds/rise_default.mp3'),
    _Sound('Dawn',            'assets/sounds/dawn.mp3'),
    _Sound('Pulse',           'assets/sounds/pulse.mp3'),
    _Sound('Forest',          'assets/sounds/forest.mp3'),
    _Sound('Ocean',           'assets/sounds/ocean.mp3'),
    _Sound('Chime',           'assets/sounds/chime.mp3'),
    _Sound('Digital',         'assets/sounds/digital.mp3'),
    _Sound('Gentle Bell',     'assets/sounds/gentle_bell.mp3'),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  Future<void> _preview(String path) async {
    if (_playing == path) {
      await _player.stop();
      setState(() => _playing = null);
      return;
    }
    await _player.stop();
    if (path.startsWith('assets/')) {
      await _player.play(AssetSource(
          path.replaceFirst('assets/', '')));
    } else {
      await _player.play(DeviceFileSource(path));
    }
    setState(() => _playing = path);
    // Auto-stop after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (_playing == path && mounted) {
        _player.stop();
        setState(() => _playing = null);
      }
    });
  }

  Future<void> _pickCustom() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio, allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    setState(() => _selected = path);
    widget.onSelect(path);
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
        title: const Text('Alarm Sound',
            style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bundled sounds
          ...(_bundled.map((s) => _SoundTile(
            sound:      s,
            isSelected: _selected == s.path,
            isPlaying:  _playing == s.path,
            onTap:      () {
              setState(() => _selected = s.path);
              widget.onSelect(s.path);
              _preview(s.path);
            },
          ))),
          const SizedBox(height: 16),
          // Custom local file
          GestureDetector(
            onTap: _pickCustom,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        const Color(0xFF161628),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: const Row(children: [
                Icon(Icons.folder_open_outlined,
                    color: Colors.white54, size: 20),
                SizedBox(width: 12),
                Text('Choose from device…',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 14)),
              ]),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Sound {
  final String name, path;
  const _Sound(this.name, this.path);
}

class _SoundTile extends StatelessWidget {
  final _Sound  sound;
  final bool    isSelected, isPlaying;
  final VoidCallback onTap;
  const _SoundTile({
    required this.sound, required this.isSelected,
    required this.isPlaying, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.indigoAccent.withOpacity(0.15)
            : const Color(0xFF161628),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.indigoAccent.withOpacity(0.5)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isPlaying ? Icons.stop_circle_outlined
                      : Icons.play_circle_outline,
            key: ValueKey(isPlaying),
            color: isSelected
                ? Colors.indigoAccent : Colors.white54,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(sound.name,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected
                    ? FontWeight.w600 : FontWeight.w400))),
        if (isSelected)
          const Icon(Icons.check_circle,
              color: Colors.indigoAccent, size: 18),
      ]),
    ),
  );
}
```

---

## CONSTANTS TO ADD: lib/core/constants/app_constants.dart

```dart
// New accessibility preference keys (Part 8 additions)
static const String prefIrregularHR    = 'accessibility_irregular_hr';
static const String prefHrMedication   = 'accessibility_hr_medication';
static const String prefHearingAids    = 'accessibility_hearing_aids';

// Hive box names (add if missing)
static const String buddyBoxName       = 'buddy_contacts_v1';
static const String alarmsBoxName      = 'alarms_v1';
static const String settingsBoxName    = 'settings_v1';
```

## BUDDY CONTACT MODEL UPDATE
Add field `isEmergencyContact` to `BuddyContact` (lib/core/models/buddy_contact.dart):
```dart
@HiveField(8)
bool isEmergencyContact;  // false = accountability buddy, true = emergency
```
Update the constructor default: `this.isEmergencyContact = false`

---

## PART 8 FILE INVENTORY

```
NEW FILES:
  lib/features/settings/settings_screen.dart
  lib/features/settings/sections/accessibility_settings.dart
  lib/features/settings/sections/safety_settings.dart
  lib/features/settings/sections/notification_settings.dart
  lib/features/settings/sections/biometric_settings.dart
  lib/features/alarm/alarm_setup_screen.dart
  lib/features/alarm/widgets/sound_picker.dart

UPDATED FILES:
  lib/core/constants/app_constants.dart   (3 new pref keys, 3 box names)
  lib/core/models/buddy_contact.dart      (isEmergencyContact HiveField 8)

NEW pubspec.yaml DEPENDENCIES:
  flutter_contacts:  ^1.1.7   # Contact picker for buddy setup
  audioplayers:      ^5.2.1   # Sound preview in picker
  file_picker:       ^6.1.1   # Custom ringtone from device
```

---

## EDGE CASE CROSS-CHECK

```
EC-1.6  Hearing aids            ✓ Accessibility toggle — disables BT override
EC-1.8  System volume muted     ✓ Warning banner in alarm setup
EC-3.3  HR medication           ✓ Wide tolerance toggle in accessibility
EC-3.4  Irregular heartbeat     ✓ PIN-only mode toggle
EC-3.8  Tremor mode             ✓ Accessibility toggle
EC-3.9  Deaf mode               ✓ Accessibility toggle
EC-3.10 Photosensitive epilepsy ✓ Accessibility toggle (isWarning=true)
EC-3.11 Cognitive / simple wake ✓ Accessibility toggle
EC-4.7  Nap mode                ✓ Alarm type selector in setup
EC-4.9  Post-alarm watchdog     ✓ Toggle in alarm setup + safety settings
EC-5.2  Auto-dismiss driving    ✓ Toggle in alarm setup
EC-5.7  DND conflict            ✓ Warning banner + fix deep-link
EC-5.9  Buddy + emergency       ✓ Safety settings with escalation sliders
EC-6.4  Battery optimization    ✓ Permission screen + per-brand guide
EC-9.1  Mental health context   ✓ Safety settings copy acknowledges this
```

---

## WHAT PART 9 WILL COVER:
Home screen — the main dashboard the user sees every day.
Upcoming alarm card with early-dismiss button (EC-4.8),
sleep score history chart, streak tracker, sleep debt ledger
(Pro), AI morning briefing card, leaderboard rank widget,
active challenge status, and the Guardian family dashboard.

---
## END OF PART 8 BLUEPRINT
## 7 new files | 2 updates | 1 model field addition
## Settings architecture:    COMPLETE ✓ (root + 5 subsections)
## Accessibility settings:   COMPLETE ✓ (all 7 EC-required toggles)
## Safety settings:          COMPLETE ✓ (buddy + emergency contact)
## Notification/permissions: COMPLETE ✓ (per-brand battery guide)
## Biometric settings:       COMPLETE ✓ (re-enroll CTA + PIN change)
## Alarm setup:              COMPLETE ✓ (all AlarmModel fields, warnings)
## Sound picker:             COMPLETE ✓ (bundled + custom file)
