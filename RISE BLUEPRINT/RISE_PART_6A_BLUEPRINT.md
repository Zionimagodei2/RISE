# ============================================================
# RISE — AI ALARM CLOCK
# MASTER BLUEPRINT: PART 6 OF 12  (FILE 1 OF 2)
# Economy System + Wake Games + Social Features
# ============================================================
# COMMAND TO AI CODING AGENT:
# Parts 1–5 must be complete. Read BOTH Part 6 files before
# writing any code. Part 6A covers: economics specification,
# subscription tiers, data models, economy/referral/dream
# services, and the wake game engine + 5 game implementations.
# Part 6B covers: leaderboard, challenge, social UI screens,
# subscription paywall, and wallet screen.
#
# ALL DOLLAR AMOUNTS ARE IN USD CENTS INTERNALLY.
# Never use floating-point arithmetic for money. Always use
# integer cents and format for display only.
# ============================================================

# ══════════════════════════════════════════════════════════════
# THE ECONOMICS SPECIFICATION
# These numbers are exact. Implement them precisely.
# ══════════════════════════════════════════════════════════════

## THE FOUR PAID TIERS (plus free)

### TIER 0: STARTER — $0/month
- Basic alarm only (no biometric lock)
- Math game only (easy difficulty)
- 7-day sleep history, score only (no phase breakdown)
- Manual calorie entry (no barcode scan)
- 0 AI messages/day
- 1 accountability buddy
- No challenges, no leaderboard prizes
- Max 1 snooze per alarm
- Banner ads between game completions
- CAN join sleep challenges (max $5 stake)
- CAN see leaderboard (not prize eligible)

### TIER 1: CORE — $5.99/month | $47.99/year
- All 5 wake game types, all difficulties
- Full biometric identity lock
- 30-day sleep history + phase breakdown (labeled "estimated")
- Barcode calorie scanning
- AI morning briefing 3× per week
- Up to 3 accountability buddies
- Leaderboard visible + ranked (NOT prize eligible)
- Referral earnings active ($2 per converted referral)
- No ads
- Up to 3 snoozes per alarm
- Dream journal (manual entry, no AI interpretation)
- Sleep challenges up to $5 stake

### TIER 2: PRO — $9.99/month | $79.99/year
- Daily AI morning briefing
- Dream journal + AI faith-based interpretation
- 5 AI chat messages/day (rolling 24h window)
- Sleep challenges up to $50 stake
- $100 sleep quality reward ELIGIBLE
- Global leaderboard PRIZE eligible
- Chronotype optimizer + weekly AI coaching
- Sleep debt ledger
- Financial Stakes Mode (real money alarms)
- Up to 5 accountability buddies
- Gift subscriptions to others
- Unlimited snoozes (difficulty escalates)

### TIER 3: GUARDIAN — $16.99/month | $134.99/year
- All Pro features for up to 5 family members
- Partner alarm sync (both must dismiss)
- Parent-teen monitoring dashboard
- 10 AI messages/day per member
- Each member individually prize eligible
- Family private leaderboard

### TIER 4: LIFETIME — $119.99 one-time
- All Pro features, permanent
- Family add-on available at $59.99 one-time

---

## REWARD 1: $100 SLEEP QUALITY AWARD
Eligibility rules (ALL must be true):
1. User on PRO or GUARDIAN for the ENTIRE 90-day window
2. 90 consecutive calendar days of recorded sessions (no gaps)
   - no_sleep_detected days count as recorded, score = 0
3. Average quality score across all 90 sessions ≥ 90.0
4. ONE-TIME per user lifetime — once claimed, never again
5. Monthly payout cap: 200 per calendar month
   - Overflow rolls to next month's 200 slots (FIFO queue)
6. Paid to in-app reward wallet as $100 credit
7. Withdrawable when wallet ≥ $10 via PayPal or Stripe

Revenue math: 200 rewards/month = $20,000 outflow.
At 10,000 Pro subscribers ($99,900/month): cost = 2%. Sustainable.

---

## REWARD 2: MONTHLY LEADERBOARD PRIZES
- 1st: $100  |  2nd: $70  |  3rd: $50  (total: $220/month)
- PRO/GUARDIAN only. Reset on 1st, pay out on 3rd.
- Must have ≥ 20 recorded days in the month to qualify.
- Score formula (0–100):
    (avgSleepQuality × 0.40)
  + (wakeGameFirstAttemptRate × 0.20)
  + (alarmConsistency × 0.25)       ← % days without max snooze
  + (nutritionAccuracy × 0.15)      ← % logged days hitting goal ±10%
  × participationMultiplier (0.80/0.90/1.00 for 20/25/30 days)

Prize pool scales with user growth:
  < 50K Pro users:   $220/month
  50K–200K:          $500/month  (1st: $250, 2nd: $150, 3rd: $100)
  200K–500K:         $1,000/month
  500K+:             $2,500/month

---

## REWARD 3: FRIEND SLEEP CHALLENGE (P2P WAGER)
- 2–6 friends, equal stakes ($1–$50), duration 7/14/30 days
- RISE takes 10% platform fee; winner gets 90%
- Tiebreaker: higher alarm consistency score

DISQUALIFICATION edge cases:
- Lost phone / 0 sessions for 3 consecutive days → disqualified,
  stake refunded in full to that player only
- App uninstall = 0 sessions = same as lost phone
- Only 1 player remains → that player wins, RISE takes no fee
- No illness exceptions (cannot verify)
- Cheating: server validates scores; impossible values excluded
- 48h dispute hold after challenge ends before payout

---

## REWARD 4: REFERRAL SYSTEM
- Referrer earns $2, referee gets $1 (on first subscription)
- Subscriber must stay active ≥ 14 days before payout
- Max 500 referrals per account (anti-abuse)
- Code expires after 30 days if unused
- Wallet hold: 30 days before withdrawal
- Anti-fraud: no self-referral, no IP bulk creation (>5/day flagged)
- Same device fingerprint = blocked

Revenue math (Core $5.99): $5.99 - $2 - $1 = $2.99 first month.
Still cheaper than any ad platform acquisition ($15–$80 CAC).

---

## REWARD 5: GIFT + RESELLER PROGRAM
- Any Pro/Guardian can gift subscriptions to others
- When gifter has gifted to 30+ DIFFERENT active users (each active ≥30 days):
  → Permanent 15% commission on ALL their giftees' future renewals
  → Paid monthly as wallet credit
  → 60-day hold before withdrawal (anti-fraud)
  → Max 500 giftees per reseller account
  → Commission only on renewals (not the original gift purchase)

Example: 30 giftees on Pro ($9.99 each) = $299.70/month revenue
15% commission = $44.96/month to reseller. RISE nets $254.74.

---

## WALLET RULES
- Min withdrawal: $10 | Max: $500 per transaction
- Methods: PayPal or Stripe bank transfer
- Balance never expires
- Tax notice shown at $600 cumulative lifetime earnings (US 1099)
- International: PayPal handles conversion

---

## CONSTANTS TO ADD: lib/core/constants/app_constants.dart

```dart
// Subscription product IDs (match App Store / Play Store exactly)
static const String productCoreMonthly     = 'rise_core_monthly_599';
static const String productCoreYearly      = 'rise_core_yearly_4799';
static const String productProMonthly      = 'rise_pro_monthly_999';
static const String productProYearly       = 'rise_pro_yearly_7999';
static const String productGuardianMonthly = 'rise_guardian_monthly_1699';
static const String productGuardianYearly  = 'rise_guardian_yearly_13499';
static const String productLifetime        = 'rise_lifetime_11999';
static const String productSnoozePack3     = 'rise_snooze_pack_3';

// Tier identifiers
static const String tierStarter  = 'starter';
static const String tierCore     = 'core';
static const String tierPro      = 'pro';
static const String tierGuardian = 'guardian';
static const String tierLifetime = 'lifetime';

// Reward amounts in CENTS (never use floats for money)
static const int rewardSleepQualityCents   = 10000; // $100.00
static const int rewardLeaderboard1Cents   = 10000; // $100.00
static const int rewardLeaderboard2Cents   =  7000; // $70.00
static const int rewardLeaderboard3Cents   =  5000; // $50.00
static const int referralEarnerCents       =    200; // $2.00
static const int referralReceiverCents     =    100; // $1.00
static const int walletMinWithdrawalCents  =   1000; // $10.00
static const int walletMaxWithdrawalCents  =  50000; // $500.00
static const int walletTaxWarningCents     =  60000; // $600.00

// Sleep quality reward rules
static const int    sqrRequiredDays        = 90;
static const double sqrRequiredAvgScore    = 90.0;
static const int    sqrMonthlyPayoutCap    = 200;

// Challenge rules
static const double challengePlatformFee   = 0.10;
static const int    challengeMinStakeCents = 100;   // $1
static const int    challengeMaxStakeCents = 5000;  // $50 (Pro)
static const int    challengeMaxParticipants = 6;
static const int    challengeDisqualifyDays  = 3;
static const int    challengePayoutHoldHours = 48;

// Referral rules
static const int    referralMinSubDays     = 14;
static const int    referralMaxPerUser     = 500;
static const int    referralCodeExpiryDays = 30;
static const int    referralWalletHoldDays = 30;

// Reseller rules
static const int    resellerMinGiftees     = 30;
static const double resellerCommission     = 0.15;
static const int    resellerMaxGiftees     = 500;
static const int    resellerWalletHoldDays = 60;

// AI chat limits (per 24h rolling window)
static const int aiMessagesStarter  = 0;
static const int aiMessagesCore     = 0;
static const int aiMessagesPro      = 5;
static const int aiMessagesGuardian = 10;

// Leaderboard weights
static const double lbWeightSleep       = 0.40;
static const double lbWeightGame        = 0.20;
static const double lbWeightAlarm       = 0.25;
static const double lbWeightNutrition   = 0.15;
static const int    lbMinDays           = 20;

// Wake game difficulty thresholds (snooze count)
static const int gameEasyUntilSnoozes   = 1;  // snooze 0–1: easy
static const int gameMediumUntilSnoozes = 3;  // snooze 2–3: medium
// snooze 4+: hard

// Box names
static const String dreamsBoxName       = 'dreams_v1';
static const String gameResultsBoxName  = 'game_results_v1';
static const String challengesBoxName   = 'challenges_v1';
```

---

## FILE 1: lib/core/models/subscription_tier.dart

```dart
import '../constants/app_constants.dart';

/// Single source of truth for what each tier can and cannot do.
/// Every feature gate in the app calls SubscriptionTier.fromId(tierId).
class SubscriptionTier {
  final String id;
  final String displayName;
  final String tagline;
  final int    monthlyPriceCents;
  final int    yearlyPriceCents;
  final bool   isLifetime;

  // Feature flags
  final bool  biometricLock;
  final bool  allWakeGames;
  final bool  barcodeCalorieScanning;
  final bool  fullSleepHistory;
  final bool  dailyAiMorningBriefing;
  final int   aiMorningBriefingsPerWeek; // 0 = daily unlimited
  final int   aiChatMessagesPerDay;
  final bool  dreamJournalAi;
  final bool  financialStakesMode;
  final bool  challengeParticipation;
  final int   challengeMaxStakeCents;
  final bool  leaderboardEligible;
  final bool  prizeEligible;
  final bool  sleepQualityRewardEligible;
  final int   maxBuddies;
  final bool  chronotypeOptimizer;
  final bool  sleepDebtLedger;
  final bool  canGiftSubscriptions;
  final int   maxSnoozes;        // -1 = unlimited (difficulty escalates)
  final bool  adsShown;
  final int   maxFamilyMembers;
  final bool  partnerAlarmSync;
  final bool  parentTeenDashboard;
  final bool  referralEarningsActive;

  const SubscriptionTier._({
    required this.id,
    required this.displayName,
    required this.tagline,
    required this.monthlyPriceCents,
    required this.yearlyPriceCents,
    this.isLifetime               = false,
    this.biometricLock            = false,
    this.allWakeGames             = false,
    this.barcodeCalorieScanning   = false,
    this.fullSleepHistory         = false,
    this.dailyAiMorningBriefing   = false,
    this.aiMorningBriefingsPerWeek = 0,
    this.aiChatMessagesPerDay     = 0,
    this.dreamJournalAi           = false,
    this.financialStakesMode      = false,
    this.challengeParticipation   = false,
    this.challengeMaxStakeCents   = 0,
    this.leaderboardEligible      = false,
    this.prizeEligible            = false,
    this.sleepQualityRewardEligible = false,
    this.maxBuddies               = 1,
    this.chronotypeOptimizer      = false,
    this.sleepDebtLedger          = false,
    this.canGiftSubscriptions     = false,
    this.maxSnoozes               = 1,
    this.adsShown                 = false,
    this.maxFamilyMembers         = 1,
    this.partnerAlarmSync         = false,
    this.parentTeenDashboard      = false,
    this.referralEarningsActive   = false,
  });

  static const starter = SubscriptionTier._(
    id:                    AppConstants.tierStarter,
    displayName:           'Starter',
    tagline:               'Free forever',
    monthlyPriceCents:     0,
    yearlyPriceCents:      0,
    challengeParticipation: true,
    challengeMaxStakeCents: 500,  // $5 max
    leaderboardEligible:   true,
    prizeEligible:         false,
    maxBuddies:            1,
    maxSnoozes:            1,
    adsShown:              true,
  );

  static const core = SubscriptionTier._(
    id:                       AppConstants.tierCore,
    displayName:              'Core',
    tagline:                  'Real accountability, no compromises',
    monthlyPriceCents:        599,
    yearlyPriceCents:         4799,
    biometricLock:            true,
    allWakeGames:             true,
    barcodeCalorieScanning:   true,
    fullSleepHistory:         true,
    aiMorningBriefingsPerWeek: 3,
    challengeParticipation:   true,
    challengeMaxStakeCents:   500,
    leaderboardEligible:      true,
    prizeEligible:            false,
    maxBuddies:               3,
    canGiftSubscriptions:     true,
    maxSnoozes:               3,
    referralEarningsActive:   true,
  );

  static const pro = SubscriptionTier._(
    id:                          AppConstants.tierPro,
    displayName:                 'Pro',
    tagline:                     'AI coaching + rewards that pay real money',
    monthlyPriceCents:           999,
    yearlyPriceCents:            7999,
    biometricLock:               true,
    allWakeGames:                true,
    barcodeCalorieScanning:      true,
    fullSleepHistory:            true,
    dailyAiMorningBriefing:      true,
    aiChatMessagesPerDay:        AppConstants.aiMessagesPro,
    dreamJournalAi:              true,
    financialStakesMode:         true,
    challengeParticipation:      true,
    challengeMaxStakeCents:      5000,
    leaderboardEligible:         true,
    prizeEligible:               true,
    sleepQualityRewardEligible:  true,
    maxBuddies:                  5,
    chronotypeOptimizer:         true,
    sleepDebtLedger:             true,
    canGiftSubscriptions:        true,
    maxSnoozes:                  -1,
    maxFamilyMembers:            1,
    referralEarningsActive:      true,
  );

  static const guardian = SubscriptionTier._(
    id:                          AppConstants.tierGuardian,
    displayName:                 'Guardian',
    tagline:                     'The whole family, one subscription',
    monthlyPriceCents:           1699,
    yearlyPriceCents:            13499,
    biometricLock:               true,
    allWakeGames:                true,
    barcodeCalorieScanning:      true,
    fullSleepHistory:            true,
    dailyAiMorningBriefing:      true,
    aiChatMessagesPerDay:        AppConstants.aiMessagesGuardian,
    dreamJournalAi:              true,
    financialStakesMode:         true,
    challengeParticipation:      true,
    challengeMaxStakeCents:      5000,
    leaderboardEligible:         true,
    prizeEligible:               true,
    sleepQualityRewardEligible:  true,
    maxBuddies:                  10,
    chronotypeOptimizer:         true,
    sleepDebtLedger:             true,
    canGiftSubscriptions:        true,
    maxSnoozes:                  -1,
    maxFamilyMembers:            5,
    partnerAlarmSync:            true,
    parentTeenDashboard:         true,
    referralEarningsActive:      true,
  );

  static const lifetime = SubscriptionTier._(
    id:                          AppConstants.tierLifetime,
    displayName:                 'Lifetime',
    tagline:                     'Pay once. Wake up forever.',
    monthlyPriceCents:           0,
    yearlyPriceCents:            0,
    isLifetime:                  true,
    biometricLock:               true,
    allWakeGames:                true,
    barcodeCalorieScanning:      true,
    fullSleepHistory:            true,
    dailyAiMorningBriefing:      true,
    aiChatMessagesPerDay:        AppConstants.aiMessagesPro,
    dreamJournalAi:              true,
    financialStakesMode:         true,
    challengeParticipation:      true,
    challengeMaxStakeCents:      5000,
    leaderboardEligible:         true,
    prizeEligible:               true,
    sleepQualityRewardEligible:  true,
    maxBuddies:                  5,
    chronotypeOptimizer:         true,
    sleepDebtLedger:             true,
    canGiftSubscriptions:        true,
    maxSnoozes:                  -1,
    referralEarningsActive:      true,
  );

  static SubscriptionTier fromId(String id) => switch (id) {
    AppConstants.tierCore     => core,
    AppConstants.tierPro      => pro,
    AppConstants.tierGuardian => guardian,
    AppConstants.tierLifetime => lifetime,
    _                         => starter,
  };

  bool get isPaid => monthlyPriceCents > 0 || isLifetime;

  String get monthlyPriceDisplay => monthlyPriceCents == 0
      ? 'Free'
      : '\$${(monthlyPriceCents / 100).toStringAsFixed(2)}/mo';

  /// Per-month cost if billed yearly (shown as "only $X/mo")
  String get yearlyPerMonthDisplay {
    if (yearlyPriceCents == 0) return '';
    final perMonth = yearlyPriceCents / 12 / 100;
    return '\$${perMonth.toStringAsFixed(2)}/mo';
  }

  /// Savings percentage compared to monthly billing
  int get yearlySavingsPercent {
    if (yearlyPriceCents == 0 || monthlyPriceCents == 0) return 0;
    final yearlyIfMonthly = monthlyPriceCents * 12;
    return (((yearlyIfMonthly - yearlyPriceCents) / yearlyIfMonthly) * 100)
        .round();
  }
}
```

---

## FILE 2: lib/core/models/reward_ledger.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

enum RewardType {
  sleepQualityAchievement,
  leaderboardFirst,
  leaderboardSecond,
  leaderboardThird,
  referralEarned,
  referralReceived,
  challengeWon,
  resellerCommission,
  withdrawal,
  adminAdjustment,
}

class RewardTransaction {
  final String     id;
  final String     userId;
  final RewardType type;
  final int        amountCents;    // Positive = credit, negative = withdrawal
  final DateTime   createdAt;
  final DateTime?  availableAt;   // Null = immediately spendable
  final bool       isAvailable;
  final String     description;
  final String?    referenceId;

  const RewardTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amountCents,
    required this.createdAt,
    this.availableAt,
    this.isAvailable = true,
    required this.description,
    this.referenceId,
  });

  factory RewardTransaction.fromFirestore(Map<String, dynamic> d, String id) {
    return RewardTransaction(
      id:           id,
      userId:       d['userId'] as String,
      type:         RewardType.values.byName(d['type'] as String),
      amountCents:  d['amountCents'] as int,
      createdAt:    (d['createdAt'] as Timestamp).toDate(),
      availableAt:  d['availableAt'] != null
          ? (d['availableAt'] as Timestamp).toDate() : null,
      isAvailable:  d['isAvailable'] as bool? ?? true,
      description:  d['description'] as String,
      referenceId:  d['referenceId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId':      userId,
    'type':        type.name,
    'amountCents': amountCents,
    'createdAt':   Timestamp.fromDate(createdAt),
    'availableAt': availableAt != null
        ? Timestamp.fromDate(availableAt!) : null,
    'isAvailable': isAvailable,
    'description': description,
    'referenceId': referenceId,
  };

  /// Display string: "+$2.00" or "-$10.00"
  String get formattedAmount {
    final abs     = amountCents.abs();
    final dollars = abs ~/ 100;
    final cents   = (abs % 100).toString().padLeft(2, '0');
    final sign    = amountCents >= 0 ? '+' : '-';
    return '$sign\$$dollars.$cents';
  }

  bool get isHeld => availableAt != null
      && availableAt!.isAfter(DateTime.now())
      && amountCents > 0;
}

/// Computed wallet state — derived from transaction list, never stored.
class RewardWallet {
  final int availableCents;
  final int pendingCents;
  final int lifetimeEarnedCents;
  final List<RewardTransaction> recentTransactions;

  const RewardWallet({
    required this.availableCents,
    required this.pendingCents,
    required this.lifetimeEarnedCents,
    required this.recentTransactions,
  });

  bool get canWithdraw =>
      availableCents >= AppConstants.walletMinWithdrawalCents;

  bool get showTaxWarning =>
      lifetimeEarnedCents >= AppConstants.walletTaxWarningCents;

  String get availableDisplay {
    final d = availableCents ~/ 100;
    final c = (availableCents % 100).toString().padLeft(2, '0');
    return '\$$d.$c';
  }

  static RewardWallet fromTransactions(List<RewardTransaction> txns) {
    final now      = DateTime.now();
    int available  = 0;
    int pending    = 0;
    int lifetime   = 0;

    for (final t in txns) {
      if (t.amountCents > 0) lifetime += t.amountCents;
      if (t.isHeld) {
        pending += t.amountCents;
      } else if (t.isAvailable) {
        available += t.amountCents;
      }
    }

    return RewardWallet(
      availableCents:      available.clamp(0, 999999999),
      pendingCents:        pending.clamp(0, 999999999),
      lifetimeEarnedCents: lifetime,
      recentTransactions:  txns.take(50).toList(),
    );
  }
}
```

---

## FILE 3: lib/core/models/sleep_challenge.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

enum ChallengeStatus { pending, active, completed, cancelled, disputed }

class ChallengeParticipant {
  final String  userId;
  final String  displayName;
  final bool    hasPaid;
  final bool    isDisqualified;
  final String? disqualifyReason;
  final double? finalScore;
  final int     stakeCents;

  const ChallengeParticipant({
    required this.userId,
    required this.displayName,
    this.hasPaid          = false,
    this.isDisqualified   = false,
    this.disqualifyReason,
    this.finalScore,
    required this.stakeCents,
  });

  factory ChallengeParticipant.fromMap(Map<String, dynamic> m) =>
      ChallengeParticipant(
        userId:           m['userId'] as String,
        displayName:      m['displayName'] as String,
        hasPaid:          m['hasPaid'] as bool? ?? false,
        isDisqualified:   m['isDisqualified'] as bool? ?? false,
        disqualifyReason: m['disqualifyReason'] as String?,
        finalScore:       (m['finalScore'] as num?)?.toDouble(),
        stakeCents:       m['stakeCents'] as int,
      );

  Map<String, dynamic> toMap() => {
    'userId':           userId,
    'displayName':      displayName,
    'hasPaid':          hasPaid,
    'isDisqualified':   isDisqualified,
    'disqualifyReason': disqualifyReason,
    'finalScore':       finalScore,
    'stakeCents':       stakeCents,
  };
}

class SleepChallenge {
  final String                     id;
  final String                     creatorId;
  final int                        durationDays;
  final int                        stakePerPersonCents;
  final DateTime                   startAt;
  final DateTime                   endsAt;
  final ChallengeStatus            status;
  final List<ChallengeParticipant> participants;
  final String?                    winnerUserId;
  final DateTime?                  payoutAt;

  const SleepChallenge({
    required this.id,
    required this.creatorId,
    required this.durationDays,
    required this.stakePerPersonCents,
    required this.startAt,
    required this.endsAt,
    required this.status,
    required this.participants,
    this.winnerUserId,
    this.payoutAt,
  });

  /// Total pool from non-disqualified, paid-up participants
  int get totalPoolCents => participants
      .where((p) => !p.isDisqualified && p.hasPaid)
      .fold(0, (s, p) => s + p.stakeCents);

  int get platformFeeCents =>
      (totalPoolCents * AppConstants.challengePlatformFee).round();

  int get winnerPayoutCents =>
      totalPoolCents - platformFeeCents;

  int get activePlayers =>
      participants.where((p) => !p.isDisqualified).length;

  factory SleepChallenge.fromFirestore(Map<String, dynamic> d, String id) =>
      SleepChallenge(
        id:                  id,
        creatorId:           d['creatorId'] as String,
        durationDays:        d['durationDays'] as int,
        stakePerPersonCents: d['stakePerPersonCents'] as int,
        startAt:             (d['startAt'] as Timestamp).toDate(),
        endsAt:              (d['endsAt'] as Timestamp).toDate(),
        status: ChallengeStatus.values.byName(d['status'] as String),
        participants: (d['participants'] as List)
            .map((e) => ChallengeParticipant.fromMap(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        winnerUserId: d['winnerUserId'] as String?,
        payoutAt:     d['payoutAt'] != null
            ? (d['payoutAt'] as Timestamp).toDate() : null,
      );

  Map<String, dynamic> toFirestore() => {
    'creatorId':           creatorId,
    'durationDays':        durationDays,
    'stakePerPersonCents': stakePerPersonCents,
    'startAt':             Timestamp.fromDate(startAt),
    'endsAt':              Timestamp.fromDate(endsAt),
    'status':              status.name,
    'participants':        participants.map((p) => p.toMap()).toList(),
    'winnerUserId':        winnerUserId,
    'payoutAt':            payoutAt != null
        ? Timestamp.fromDate(payoutAt!) : null,
  };
}
```

---

## FILE 4: lib/core/models/dream_entry.dart

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

part 'dream_entry.g.dart';

@HiveType(typeId: 8)
class DreamEntry extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String rawText;
  @HiveField(2) String? audioPath;
  @HiveField(3) DateTime recordedAt;
  @HiveField(4) List<String> tags;
  @HiveField(5) String? aiInterpretation;
  @HiveField(6) String faith;  // FaithOption.name
  @HiveField(7) bool interpretationRequested;
  @HiveField(8) String mood;   // 'positive'|'neutral'|'negative'|'unsettling'
  @HiveField(9) List<String> conversationHistory; // 'role:content' pairs

  DreamEntry({
    String? id,
    required this.rawText,
    this.audioPath,
    DateTime? recordedAt,
    this.tags                     = const [],
    this.aiInterpretation,
    this.faith                    = 'secular',
    this.interpretationRequested  = false,
    this.mood                     = 'neutral',
    this.conversationHistory      = const [],
  })  : id          = id ?? const Uuid().v4(),
        recordedAt  = recordedAt ?? DateTime.now();

  int get messagesUsed => conversationHistory.length ~/ 2;
}
```

---

## FILE 5: lib/core/models/referral_record.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ReferralStatus { pending, qualifying, confirmed, expired, fraudFlagged }

class ReferralRecord {
  final String         id;
  final String         referrerUserId;
  final String?        refereeUserId;
  final String         code;
  final ReferralStatus status;
  final DateTime       createdAt;
  final DateTime?      subscribedAt;
  final DateTime?      confirmedAt;
  final bool           earnerPaid;
  final bool           receiverPaid;
  final String?        tier;

  const ReferralRecord({
    required this.id,
    required this.referrerUserId,
    this.refereeUserId,
    required this.code,
    required this.status,
    required this.createdAt,
    this.subscribedAt,
    this.confirmedAt,
    this.earnerPaid  = false,
    this.receiverPaid = false,
    this.tier,
  });

  factory ReferralRecord.fromFirestore(Map<String, dynamic> d, String id) =>
      ReferralRecord(
        id:              id,
        referrerUserId:  d['referrerUserId'] as String,
        refereeUserId:   d['refereeUserId'] as String?,
        code:            d['code'] as String,
        status: ReferralStatus.values.byName(d['status'] as String),
        createdAt:  (d['createdAt'] as Timestamp).toDate(),
        subscribedAt: d['subscribedAt'] != null
            ? (d['subscribedAt'] as Timestamp).toDate() : null,
        confirmedAt:  d['confirmedAt'] != null
            ? (d['confirmedAt'] as Timestamp).toDate() : null,
        earnerPaid:   d['earnerPaid'] as bool? ?? false,
        receiverPaid: d['receiverPaid'] as bool? ?? false,
        tier:         d['tier'] as String?,
      );
}
```

---

## FILE 6: lib/core/services/economy_service.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../constants/app_constants.dart';
import '../models/reward_ledger.dart';
import '../models/sleep_session.dart';
import '../models/subscription_tier.dart';

class EconomyService {
  static final EconomyService _i = EconomyService._internal();
  factory EconomyService() => _i;
  EconomyService._internal();

  final _db        = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;

  // ── Wallet stream ─────────────────────────────────────────────────────────
  Stream<RewardWallet> walletStream(String userId) {
    return _db
        .collection('reward_transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final txns = snap.docs.map((d) =>
          RewardTransaction.fromFirestore(d.data(), d.id)).toList();
      return RewardWallet.fromTransactions(txns);
    });
  }

  // ── Sleep quality reward eligibility (local pre-check) ───────────────────
  Future<SqrStatus> checkSleepQualityRewardEligibility({
    required String             userId,
    required String             tierId,
    required List<SleepSession> sessions,
  }) async {
    if (!SubscriptionTier.fromId(tierId).sleepQualityRewardEligible) {
      return SqrStatus.tierNotEligible;
    }

    // Already claimed?
    final profile = await _db.collection('user_profiles').doc(userId).get();
    if (profile.data()?['sqrClaimed'] == true) return SqrStatus.alreadyClaimed;

    // Need 90 sessions in the last 90 days
    final cutoff = DateTime.now().subtract(
        Duration(days: AppConstants.sqrRequiredDays));
    final window = sessions
        .where((s) => s.createdAt.isAfter(cutoff))
        .toList();

    if (window.length < AppConstants.sqrRequiredDays) {
      return SqrStatus.insufficientDays;
    }

    final avg = window.map((s) => s.qualityScore.toDouble())
            .reduce((a, b) => a + b) / window.length;

    if (avg < AppConstants.sqrRequiredAvgScore) return SqrStatus.scoreTooLow;

    // Server-side final confirmation (prevents client manipulation)
    try {
      final r = await _functions
          .httpsCallable('verifySleepQualityReward')
          .call({'userId': userId});
      return (r.data['confirmed'] as bool? ?? false)
          ? SqrStatus.eligible
          : SqrStatus.serverRejected;
    } catch (_) {
      return SqrStatus.serverError;
    }
  }

  // ── Monthly health score (local computation for display) ─────────────────
  double computeMonthlyScore({
    required List<SleepSession> sessions,
    required int totalAlarmDays,
    required int noMaxSnoozeDays,
    required int nutritionLoggedDays,
    required int nutritionGoalHitDays,
    required List<WakeGameResult> games,
  }) {
    final recorded = sessions.length;
    double participation;
    if      (recorded >= 30) participation = 1.00;
    else if (recorded >= 25) participation = 0.90;
    else if (recorded >= 20) participation = 0.80;
    else                     return 0.0;

    double sleepQ = recorded > 0
        ? sessions.map((s) => s.qualityScore.toDouble())
              .reduce((a, b) => a + b) / recorded
        : 0.0;

    double gameScore = games.isNotEmpty
        ? games.where((g) => g.wrongAnswerCount == 0 && g.passed).length /
              games.length * 100
        : 0.0;

    double alarmC = totalAlarmDays > 0
        ? noMaxSnoozeDays / totalAlarmDays * 100
        : 0.0;

    double nutri = nutritionLoggedDays > 0
        ? nutritionGoalHitDays / nutritionLoggedDays * 100
        : 0.0;

    final raw = sleepQ   * AppConstants.lbWeightSleep
              + gameScore * AppConstants.lbWeightGame
              + alarmC   * AppConstants.lbWeightAlarm
              + nutri    * AppConstants.lbWeightNutrition;

    return (raw * participation).clamp(0, 100);
  }

  // ── Withdrawal request (server handles actual payment) ───────────────────
  Future<WithdrawalResult> requestWithdrawal({
    required String userId,
    required int    amountCents,
    required String method,     // 'paypal' | 'stripe'
    required String accountId,
  }) async {
    if (amountCents < AppConstants.walletMinWithdrawalCents) {
      return WithdrawalResult.tooSmall;
    }
    if (amountCents > AppConstants.walletMaxWithdrawalCents) {
      return WithdrawalResult.tooLarge;
    }
    try {
      await _functions.httpsCallable('processWithdrawal').call({
        'userId':      userId,
        'amountCents': amountCents,
        'method':      method,
        'accountId':   accountId,
      });
      return WithdrawalResult.success;
    } catch (_) {
      return WithdrawalResult.failed;
    }
  }
}

enum SqrStatus {
  eligible, tierNotEligible, alreadyClaimed,
  insufficientDays, scoreTooLow, serverRejected, serverError,
}

enum WithdrawalResult { success, tooSmall, tooLarge, failed }
```

---

## FILE 7: lib/core/services/referral_service.dart

```dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../constants/app_constants.dart';
import '../models/referral_record.dart';

class ReferralService {
  static final ReferralService _i = ReferralService._internal();
  factory ReferralService() => _i;
  ReferralService._internal();

  final _db        = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;

  // ── Generate code ─────────────────────────────────────────────────────────
  String generateCode(String userId) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I, O, 0, 1
    final rng   = Random.secure();
    final prefix = userId.substring(0, min(4, userId.length)).toUpperCase();
    final suffix = List.generate(
        6, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'RISE-$prefix-$suffix';
  }

  // ── Claim a referral code (all anti-fraud is server-side) ─────────────────
  Future<ReferralClaimResult> claimCode({
    required String code,
    required String newUserId,
    required String deviceFingerprint,
  }) async {
    try {
      final r = await _functions.httpsCallable('claimReferralCode').call({
        'code':              code,
        'newUserId':         newUserId,
        'deviceFingerprint': deviceFingerprint,
      });
      return ReferralClaimResult.values
          .byName(r.data['result'] as String? ?? 'error');
    } catch (_) {
      return ReferralClaimResult.error;
    }
  }

  // ── Stats for the user's referral dashboard ────────────────────────────────
  Future<ReferralStats> getStats(String userId) async {
    final snap = await _db
        .collection('referrals')
        .where('referrerUserId', isEqualTo: userId)
        .get();

    final records = snap.docs.map((d) =>
        ReferralRecord.fromFirestore(d.data(), d.id)).toList();

    final confirmed  = records.where((r) => r.status == ReferralStatus.confirmed);
    final qualifying = records.where((r) => r.status == ReferralStatus.qualifying);

    // Fetch or create the user's referral code
    final docSnap = await _db.collection('user_profiles').doc(userId).get();
    String? code  = docSnap.data()?['referralCode'] as String?;
    if (code == null) {
      code = generateCode(userId);
      await _db.collection('user_profiles').doc(userId)
          .update({'referralCode': code});
    }

    return ReferralStats(
      confirmed:        confirmed.length,
      qualifying:       qualifying.length,
      totalEarnedCents: confirmed.length * AppConstants.referralEarnerCents,
      code:             code,
      link:             'https://riseapp.io/r/$code',
    );
  }
}

class ReferralStats {
  final int    confirmed;
  final int    qualifying;
  final int    totalEarnedCents;
  final String code;
  final String link;
  const ReferralStats({
    required this.confirmed,
    required this.qualifying,
    required this.totalEarnedCents,
    required this.code,
    required this.link,
  });
}

enum ReferralClaimResult {
  success, alreadyUsed, selfReferral, expired, fraudFlagged, error,
}
```

---

## FILE 8: lib/core/services/dream_journal_service.dart

```dart
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/dream_entry.dart';
import '../models/subscription_tier.dart';

/// All supported faith traditions for dream interpretation.
/// The user selects one during onboarding (or can change in settings).
/// RISE NEVER makes religious judgments — it interprets within the
/// user's OWN stated worldview without adding or removing beliefs.
enum FaithOption {
  christian, catholic, islamic, jewish,
  hindu, buddhist, pentecostal, orthodox,
  secular,  // Jungian / psychological
  custom,
}

extension FaithExt on FaithOption {
  String get displayName => switch (this) {
    FaithOption.christian   => 'Christian',
    FaithOption.catholic    => 'Catholic',
    FaithOption.islamic     => 'Islamic',
    FaithOption.jewish      => 'Jewish',
    FaithOption.hindu       => 'Hindu',
    FaithOption.buddhist    => 'Buddhist',
    FaithOption.pentecostal => 'Pentecostal / Charismatic',
    FaithOption.orthodox    => 'Orthodox Christian',
    FaithOption.secular     => 'Secular / Psychological',
    FaithOption.custom      => 'My tradition',
  };

  String get systemContext => switch (this) {
    FaithOption.christian || FaithOption.catholic || FaithOption.orthodox =>
      'Interpret through a Christian lens: Biblical symbolism, imagery from '
      'Scripture (Joseph, Daniel, Acts 2), and the tradition of Christian '
      'dream interpretation. Be spiritually sensitive, non-prescriptive.',
    FaithOption.pentecostal =>
      'Interpret through a Pentecostal/Charismatic lens: prophetic gifting, '
      'the Holy Spirit speaking through dreams, Biblical imagery, and the '
      'tradition of testing dreams against Scripture.',
    FaithOption.islamic =>
      'Interpret through an Islamic lens. Reference relevant hadith on dreams '
      '(Sahih al-Bukhari on ru\'ya), common Islamic symbols, and the tradition '
      'of tabeer. Always acknowledge that only Allah knows the full meaning.',
    FaithOption.jewish =>
      'Interpret through a Jewish lens: Talmudic tradition (Tractate Berachot), '
      'Kabbalistic symbolism where relevant, and the Biblical prophetic tradition.',
    FaithOption.hindu =>
      'Interpret through a Hindu perspective: Swapna Shastra, Vedic symbolism, '
      'connections to dharma and the gunas.',
    FaithOption.buddhist =>
      'Interpret through a Buddhist perspective: the dreaming mind, the six '
      'realms, karmic themes, impermanence, and mindful reflection.',
    FaithOption.secular || FaithOption.custom =>
      'Interpret through a secular, psychological lens: Jungian archetypes, '
      'common dream symbols in modern psychology, emotional processing.',
  };
}

class DreamJournalService {
  static final DreamJournalService _i = DreamJournalService._internal();
  factory DreamJournalService() => _i;
  DreamJournalService._internal();

  // ── Save entry ────────────────────────────────────────────────────────────
  Future<DreamEntry> save({
    required String rawText,
    required FaithOption faith,
    required String mood,
    String? audioPath,
    List<String> tags = const [],
  }) async {
    final entry = DreamEntry(
      rawText:   rawText,
      faith:     faith.name,
      mood:      mood,
      audioPath: audioPath,
      tags:      tags,
    );
    await Hive.box<dynamic>(AppConstants.dreamsBoxName).put(entry.id, entry);
    return entry;
  }

  // ── Request first AI interpretation ───────────────────────────────────────
  Future<AiDreamResult> requestInterpretation({
    required String      dreamId,
    required String      tierId,
  }) async {
    final tier = SubscriptionTier.fromId(tierId);
    if (!tier.dreamJournalAi) {
      return AiDreamResult(
          success: false, text: null,
          error: 'Upgrade to Pro to unlock AI dream interpretation.');
    }

    if (await _remainingMessages(tierId) <= 0) {
      return AiDreamResult(
          success: false, text: null,
          error: 'You\'ve used all ${tier.aiChatMessagesPerDay} messages '
              'today. Come back tomorrow.');
    }

    final entry = Hive.box<dynamic>(AppConstants.dreamsBoxName)
        .get(dreamId) as DreamEntry?;
    if (entry == null) {
      return AiDreamResult(success: false, text: null, error: 'Dream not found.');
    }

    final faith = FaithOption.values.byName(entry.faith);

    final system = '''
You are RISE's Dream Companion — a warm, wise, non-prescriptive interpreter.
${faith.systemContext}
Guidelines:
- Acknowledge the dream's emotional tone before interpreting
- Offer 2–3 possible symbolic meanings (never one definitive answer)
- End with a gentle reflective question for the dreamer
- 150–250 words maximum
- If content is disturbing, respond with care and gently suggest a spiritual
  advisor or counsellor if the dreamer feels troubled
- Never make medical, psychological, or predictive claims
''';

    final text = await _callClaude(
      system:  system,
      history: [],
      message: 'Please interpret this dream: "${entry.rawText}"',
    );

    if (text == null) {
      return AiDreamResult(success: false, text: null, error: 'AI unavailable. Try again.');
    }

    entry.aiInterpretation        = text;
    entry.interpretationRequested = true;
    entry.conversationHistory     = [
      'user: ${entry.rawText}',
      'assistant: $text',
    ];
    await entry.save();
    await _useMessage(tierId);

    return AiDreamResult(success: true, text: text, error: null);
  }

  // ── Continue conversation (up to 5 messages per 24h) ──────────────────────
  Future<AiDreamResult> continueConversation({
    required String dreamId,
    required String userMessage,
    required String tierId,
  }) async {
    final tier = SubscriptionTier.fromId(tierId);
    if (!tier.dreamJournalAi) {
      return AiDreamResult(success: false, text: null,
          error: 'Upgrade to Pro to chat about your dreams.');
    }

    if (await _remainingMessages(tierId) <= 0) {
      return AiDreamResult(success: false, text: null,
          error: 'Daily limit reached. Come back tomorrow.');
    }

    final entry = Hive.box<dynamic>(AppConstants.dreamsBoxName)
        .get(dreamId) as DreamEntry?;
    if (entry == null || !entry.interpretationRequested) {
      return AiDreamResult(success: false, text: null,
          error: 'Request an interpretation first.');
    }

    final faith   = FaithOption.values.byName(entry.faith);
    final history = _parseHistory(entry.conversationHistory);

    final text = await _callClaude(
      system:  'You are RISE\'s Dream Companion. Continue this conversation '
               'warmly and consistently. ${faith.systemContext} '
               'Keep replies to 100–200 words.',
      history: history,
      message: userMessage,
    );

    if (text == null) {
      return AiDreamResult(success: false, text: null, error: 'AI unavailable.');
    }

    entry.conversationHistory = [
      ...entry.conversationHistory,
      'user: $userMessage',
      'assistant: $text',
    ];
    await entry.save();
    await _useMessage(tierId);

    return AiDreamResult(success: true, text: text, error: null);
  }

  // ── Claude API ─────────────────────────────────────────────────────────────
  Future<String?> _callClaude({
    required String system,
    required List<Map<String, String>> history,
    required String message,
  }) async {
    try {
      final messages = [
        ...history,
        {'role': 'user', 'content': message},
      ];
      final resp = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model':      'claude-sonnet-4-20250514',
          'max_tokens': 500,
          'system':     system,
          'messages':   messages,
        }),
      );
      if (resp.statusCode != 200) return null;
      final data    = jsonDecode(resp.body) as Map<String, dynamic>;
      final content = data['content'] as List?;
      if (content == null || content.isEmpty) return null;
      return (content.first as Map)['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Daily message quota (rolling 24h window) ───────────────────────────────
  Future<int> _remainingMessages(String tierId) async {
    final max = SubscriptionTier.fromId(tierId).aiChatMessagesPerDay;
    if (max == 0) return 0;
    final prefs  = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('ai_msg_ts') ?? [];
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final recent = stored
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .where((d) => d.isAfter(cutoff))
        .toList();
    await prefs.setStringList(
        'ai_msg_ts', recent.map((d) => d.toIso8601String()).toList());
    return (max - recent.length).clamp(0, max);
  }

  Future<void> _useMessage(String tierId) async {
    final prefs  = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('ai_msg_ts') ?? [];
    stored.add(DateTime.now().toIso8601String());
    await prefs.setStringList('ai_msg_ts', stored);
  }

  List<Map<String, String>> _parseHistory(List<String> raw) {
    return raw.map((line) {
      if (line.startsWith('user: ')) {
        return {'role': 'user', 'content': line.substring(6)};
      } else {
        return {'role': 'assistant', 'content': line.substring(11)};
      }
    }).toList();
  }
}

class AiDreamResult {
  final bool    success;
  final String? text;
  final String? error;
  const AiDreamResult({required this.success, required this.text, required this.error});
}
```

---

## FILE 9: lib/core/services/wake_game_engine.dart

```dart
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../models/subscription_tier.dart';
import '../models/wake_game_result.dart';

enum GameType { math, wordUnscramble, memoryGrid, barcodeScan, sequenceTap }
enum GameDifficulty { easy, medium, hard }

class GameSelection {
  final GameType       type;
  final GameDifficulty difficulty;
  final bool           accessibilityMode;
  const GameSelection({
    required this.type,
    required this.difficulty,
    this.accessibilityMode = false,
  });
}

class WakeGameEngine {
  static final WakeGameEngine _i = WakeGameEngine._internal();
  factory WakeGameEngine() => _i;
  WakeGameEngine._internal();

  GameSelection select({
    required int     sessionSnoozeCount,  // GLOBAL session count (EC-5.8)
    required String  tierId,
    required bool    tremorMode,          // EC-3.8
    required bool    cognitiveMode,       // EC-3.11
  }) {
    // EC-3.11: Cognitive disability → always sequence tap, easy, no timer
    if (cognitiveMode) {
      return const GameSelection(
          type: GameType.sequenceTap,
          difficulty: GameDifficulty.easy,
          accessibilityMode: true);
    }

    // Difficulty scales with GLOBAL snooze count across the whole session
    final difficulty = switch (sessionSnoozeCount) {
      <= AppConstants.gameEasyUntilSnoozes   => GameDifficulty.easy,
      <= AppConstants.gameMediumUntilSnoozes => GameDifficulty.medium,
      _                                      => GameDifficulty.hard,
    };

    // Starter: math only
    if (!SubscriptionTier.fromId(tierId).allWakeGames) {
      return GameSelection(type: GameType.math, difficulty: difficulty);
    }

    // Hard difficulty: always math (most reliable — no motion needed)
    if (difficulty == GameDifficulty.hard) {
      return const GameSelection(type: GameType.math, difficulty: GameDifficulty.hard);
    }

    // Build eligible game pool
    final hasBc = _hasStoredBarcode();
    final pool  = [
      GameType.math,
      GameType.wordUnscramble,
      GameType.memoryGrid,
      if (hasBc) GameType.barcodeScan,
    ];

    // Cycle through games to prevent habituation
    final count = Hive.box<dynamic>(AppConstants.gameResultsBoxName).length;
    final type  = pool[count % pool.length];

    return GameSelection(
      type:              type,
      difficulty:        difficulty,
      accessibilityMode: tremorMode,
    );
  }

  bool _hasStoredBarcode() {
    final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
    final bc  = box.get('barcode_scan_code') as String?;
    return bc != null && bc.isNotEmpty;
  }
}
```
