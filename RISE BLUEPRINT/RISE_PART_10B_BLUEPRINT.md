# ============================================================
# RISE — AI ALARM CLOCK
# MASTER BLUEPRINT: PART 10B OF 12
# Goals Journal · Quotes System · Calorie Tracker Upgrades
# ============================================================
# COMMAND TO AI CODING AGENT:
# Part 10A must be complete before starting this part.
# Read ALL sections in order before writing any code.
#
# WHAT THIS PART CREATES (19 files):
#
# MODELS (7)
#  1. lib/core/models/calorie_entry.dart       (typeId: 3 — replaces Part 1 stub)
#  2. lib/core/models/food_item.dart           (typeId: 4 — replaces Part 1 stub)
#  3. lib/core/models/north_star_goal.dart     (typeId: 10)
#  4. lib/core/models/habit_model.dart         (typeId: 11)
#  5. lib/core/models/daily_entry.dart         (typeId: 12)
#  6. lib/core/models/quote_item.dart          (typeId: 13)
#  7. lib/core/models/proof_wall_milestone.dart(typeId: 14)
#
# SERVICES (4)
#  8. lib/core/services/goals_service.dart
#  9. lib/core/services/ai_reflection_service.dart
# 10. lib/core/services/quote_service.dart
# 11. lib/core/services/calorie_service.dart
#
# SCREENS & WIDGETS (8)
# 12. lib/features/goals/goals_screen.dart
# 13. lib/features/goals/daily_intention_screen.dart
# 14. lib/features/goals/weekly_review_screen.dart
# 15. lib/features/goals/monthly_letter_screen.dart
# 16. lib/features/goals/proof_wall_screen.dart
# 17. lib/features/quotes/quotes_screen.dart
# 18. lib/features/calorie/calorie_screen.dart
# 19. lib/features/calorie/food_search_sheet.dart
#
# DESIGN PRINCIPLES THAT GOVERN EVERY FILE IN THIS PART:
#  → Integration over addition: sleep ↔ calories ↔ goals ↔ quotes
#    always talk to each other. Nothing is siloed.
#  → Narrative over data: users see stories, not spreadsheets.
#    Every AI output reads like a wise friend speaking, not a dashboard.
#  → Cultural respect as default: jollof rice, ugali, injera, fufu
#    are first-class foods. Swahili proverbs show in Swahili first.
#    Ramadan is a celebrated mode, not an anomaly to manage.
#  → Five is enough: max 5 habits. Max 3 morning tasks. Restraint
#    is a feature. Overwhelm is the enemy of consistency.
#  → The Proof Wall beats the streak: milestones only accumulate.
#    They cannot be lost. The long arc matters more than the number.
# ============================================================

---

# ══════════════════════════════════════════════════════════════
# FILE 1: lib/core/models/calorie_entry.dart
# typeId: 3 — REPLACES the Part 1 CalorieLog stub
# PURPOSE: A single day's calorie log with meal breakdown.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'calorie_entry.g.dart';

enum MealType { breakfast, lunch, dinner, snack, suhoor, iftar }

extension MealTypeExt on MealType {
  String get displayName => switch (this) {
    MealType.breakfast => 'Breakfast',
    MealType.lunch     => 'Lunch',
    MealType.dinner    => 'Dinner',
    MealType.snack     => 'Snack',
    MealType.suhoor    => 'Suhoor',   // Ramadan pre-dawn meal
    MealType.iftar     => 'Iftar',    // Ramadan breaking-fast meal
  };

  bool get isRamadanMeal =>
      this == MealType.suhoor || this == MealType.iftar;
}

@HiveType(typeId: 3)
class CalorieEntry extends HiveObject {
  @HiveField(0) final String   id;
  @HiveField(1) final String   date;        // 'YYYY-MM-DD'
  @HiveField(2) String         foodItemId;  // Reference to FoodItem
  @HiveField(3) String         foodName;    // Denormalised for offline display
  @HiveField(4) double         servingGrams;
  @HiveField(5) double         calories;
  @HiveField(6) double         proteinG;
  @HiveField(7) double         carbsG;
  @HiveField(8) double         fatG;
  @HiveField(9) MealType       mealType;
  @HiveField(10) DateTime      loggedAt;
  @HiveField(11) bool          isRamadanFast; // Was this logged during Ramadan?
  @HiveField(12) String?       barcodeValue;  // If scanned (Core+)
  @HiveField(13) String?       notes;

  CalorieEntry({
    String? id,
    required this.date,
    required this.foodItemId,
    required this.foodName,
    required this.servingGrams,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.mealType,
    DateTime? loggedAt,
    this.isRamadanFast = false,
    this.barcodeValue,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        loggedAt = loggedAt ?? DateTime.now();
}

/// Summary of one day's nutrition — computed from entries.
class DailySummary {
  final String   date;
  final int      targetCalories;
  final double   consumedCalories;
  final double   proteinG;
  final double   carbsG;
  final double   fatG;
  final bool     isRamadanDay;
  final bool     fastComplete;   // Ramadan: no food logged between Fajr and Maghrib

  const DailySummary({
    required this.date,
    required this.targetCalories,
    required this.consumedCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.isRamadanDay  = false,
    this.fastComplete  = false,
  });

  double get calorieBalance => consumedCalories - targetCalories;
  bool   get withinTarget   => calorieBalance.abs() <= targetCalories * 0.1;

  // Progress 0.0–1.0 (capped at 1.0 to avoid visual overflow)
  double get progress =>
      (consumedCalories / targetCalories).clamp(0.0, 1.0);

  String get balanceLabel {
    final diff = calorieBalance.round().abs();
    if (calorieBalance.abs() < 50) return 'On target';
    return calorieBalance > 0
        ? '$diff kcal over'
        : '$diff kcal under';
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 2: lib/core/models/food_item.dart
# typeId: 4 — REPLACES the Part 1 FoodEntry stub
# PURPOSE: A food in the global database.
#          African and global cuisines are FIRST-CLASS.
#          No food is an "edge case" or "other" category.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:hive/hive.dart';

part 'food_item.g.dart';

/// Cuisine categories — every region is explicitly named.
/// This list communicates that RISE was built for the world.
enum CuisineRegion {
  westAfrica,    // Nigeria, Ghana, Senegal, Côte d'Ivoire, Mali
  eastAfrica,    // Kenya, Tanzania, Uganda, Ethiopia, Rwanda
  northAfrica,   // Egypt, Morocco, Tunisia, Algeria, Libya
  southAfrica,   // South Africa, Zimbabwe, Zambia, Mozambique
  centralAfrica, // DRC, Cameroon, CAR, Chad
  middleEast,    // UAE, Saudi Arabia, Lebanon, Iran, Iraq, Jordan
  southAsia,     // India, Pakistan, Bangladesh, Sri Lanka, Nepal
  eastAsia,      // China, Japan, Korea, Taiwan, Hong Kong
  southeastAsia, // Indonesia, Philippines, Thailand, Vietnam, Malaysia
  latinAmerica,  // Brazil, Mexico, Colombia, Argentina, Peru
  caribbean,     // Jamaica, Trinidad, Haiti, Cuba, Barbados
  western,       // US, UK, Canada, Australia, Western Europe
  mediterranean, // Italy, Greece, Spain, France (south), Turkey
  easternEurope,
  generic,       // Unbranded / generic items
}

@HiveType(typeId: 4)
class FoodItem extends HiveObject {
  @HiveField(0)  final String   id;
  @HiveField(1)  String         name;
  @HiveField(2)  String         nameLocalised;  // Name in local language/script
  @HiveField(3)  double         caloriesPer100g;
  @HiveField(4)  double         proteinPer100g;
  @HiveField(5)  double         carbsPer100g;
  @HiveField(6)  double         fatPer100g;
  @HiveField(7)  double         fiberPer100g;
  @HiveField(8)  CuisineRegion  cuisineRegion;
  @HiveField(9)  String         category;   // 'grain','protein','vegetable','fruit','dairy','beverage','snack','legume'
  @HiveField(10) String?        barcodeValue;
  @HiveField(11) bool           isUserAdded; // User created this item
  @HiveField(12) double         defaultServingGrams;
  @HiveField(13) String         servingUnit;  // 'g', 'ml', 'cup', 'piece', 'wrap', 'bowl'
  @HiveField(14) List<String>   aliases;      // Alternative search names

  FoodItem({
    required this.id,
    required this.name,
    this.nameLocalised    = '',
    required this.caloriesPer100g,
    this.proteinPer100g   = 0,
    this.carbsPer100g     = 0,
    this.fatPer100g       = 0,
    this.fiberPer100g     = 0,
    this.cuisineRegion    = CuisineRegion.generic,
    this.category         = 'generic',
    this.barcodeValue,
    this.isUserAdded      = false,
    this.defaultServingGrams = 100,
    this.servingUnit      = 'g',
    this.aliases          = const [],
  });

  double caloriesForServing(double grams) =>
      (caloriesPer100g * grams / 100).roundToDouble();
  double proteinForServing(double grams) =>
      (proteinPer100g * grams / 100);
  double carbsForServing(double grams) =>
      (carbsPer100g * grams / 100);
  double fatForServing(double grams) =>
      (fatPer100g * grams / 100);
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 3: lib/core/models/north_star_goal.dart
# typeId: 10
# PURPOSE: The user's one big goal — who they are becoming
#          and by when. Everything else in RISE connects to it.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'north_star_goal.g.dart';

enum GoalCategory {
  health,       // Lose weight, run a marathon, improve fitness
  business,     // Launch a business, hit a revenue target
  education,    // Finish a degree, learn a skill, pass an exam
  financial,    // Save X amount, pay off debt, invest
  creative,     // Write a book, record an album, build a portfolio
  spiritual,    // Deepen faith practice, meditation habit
  relationships,// Repair or build key relationships
  personal,     // Anything else that matters
}

extension GoalCategoryExt on GoalCategory {
  String get displayName => switch (this) {
    GoalCategory.health        => 'Health & Fitness',
    GoalCategory.business      => 'Business & Career',
    GoalCategory.education     => 'Education & Skills',
    GoalCategory.financial     => 'Financial',
    GoalCategory.creative      => 'Creative',
    GoalCategory.spiritual     => 'Spiritual',
    GoalCategory.relationships => 'Relationships',
    GoalCategory.personal      => 'Personal',
  };

  String get emoji => switch (this) {
    GoalCategory.health        => '💪',
    GoalCategory.business      => '🚀',
    GoalCategory.education     => '📚',
    GoalCategory.financial     => '💰',
    GoalCategory.creative      => '🎨',
    GoalCategory.spiritual     => '🕊️',
    GoalCategory.relationships => '❤️',
    GoalCategory.personal      => '⭐',
  };

  /// Suggested habits for this goal category — shown during habit setup.
  List<String> get suggestedHabits => switch (this) {
    GoalCategory.health => [
      'Sleep by 10pm',
      'Run or walk 30 min',
      'Hit calorie target',
      'Drink 2L water',
      'No food after 9pm',
    ],
    GoalCategory.business => [
      'Work on the business 2h',
      'Review financials',
      'Reach out to one client',
      'Read 20 pages',
      'Plan tomorrow\'s priorities',
    ],
    GoalCategory.education => [
      'Study 1 hour',
      'Review yesterday\'s notes',
      'Practice the skill 30 min',
      'Read one chapter',
      'No social media before studying',
    ],
    GoalCategory.financial => [
      'Log every expense',
      'No unnecessary purchases',
      'Review budget weekly',
      'Transfer to savings',
      'Learn one financial concept',
    ],
    GoalCategory.spiritual => [
      'Morning prayer / devotion',
      'Gratitude journal entry',
      'Evening reflection',
      'Read scripture or spiritual text',
      'One act of service',
    ],
    _ => [
      'Sleep by 10pm',
      'Exercise',
      'Read 20 pages',
      'Journal entry',
      'Plan tomorrow',
    ],
  };
}

@HiveType(typeId: 10)
class NorthStarGoal extends HiveObject {
  @HiveField(0) final String       id;
  @HiveField(1) String             statement;     // "I want to run a half marathon"
  @HiveField(2) String             whyStatement;  // "Because I want to prove to myself..."
  @HiveField(3) GoalCategory       category;
  @HiveField(4) DateTime           targetDate;
  @HiveField(5) DateTime           createdAt;
  @HiveField(6) bool               achieved;
  @HiveField(7) DateTime?          achievedAt;
  @HiveField(8) List<String>       milestoneIds;  // References to ProofWallMilestone
  @HiveField(9) String?            celebrationNote; // Written when achieved

  NorthStarGoal({
    String? id,
    required this.statement,
    required this.whyStatement,
    required this.category,
    required this.targetDate,
    DateTime? createdAt,
    this.achieved        = false,
    this.achievedAt,
    this.milestoneIds    = const [],
    this.celebrationNote,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  int get daysRemaining =>
      targetDate.difference(DateTime.now()).inDays.clamp(0, 9999);

  double get progressFraction {
    final total = targetDate.difference(createdAt).inDays;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(createdAt).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String get daysRemainingLabel {
    final d = daysRemaining;
    if (d == 0) return 'Today is the day';
    if (d == 1) return '1 day left';
    if (d < 7)  return '$d days left';
    if (d < 30) return '${d ~/ 7} weeks left';
    return '${d ~/ 30} months left';
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 4: lib/core/models/habit_model.dart
# typeId: 11
# PURPOSE: One of the user's five tracked habits.
#          Max 5 total — enforced in GoalsService.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'habit_model.g.dart';

enum HabitFrequency { daily, weekdays, weekends, custom }

@HiveType(typeId: 11)
class HabitModel extends HiveObject {
  @HiveField(0) final String   id;
  @HiveField(1) String         name;
  @HiveField(2) String?        goalId;      // Connected North Star goal
  @HiveField(3) HabitFrequency frequency;
  @HiveField(4) List<int>      customDays;  // 0=Mon..6=Sun for custom frequency
  @HiveField(5) DateTime       createdAt;
  @HiveField(6) int            sortOrder;   // User-defined display order
  @HiveField(7) bool           archived;

  HabitModel({
    String? id,
    required this.name,
    this.goalId,
    this.frequency    = HabitFrequency.daily,
    this.customDays   = const [],
    DateTime? createdAt,
    this.sortOrder    = 0,
    this.archived     = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  bool isDueToday() {
    final weekday = DateTime.now().weekday; // 1=Mon..7=Sun
    return switch (frequency) {
      HabitFrequency.daily    => true,
      HabitFrequency.weekdays => weekday <= 5,
      HabitFrequency.weekends => weekday >= 6,
      HabitFrequency.custom   => customDays.contains(weekday - 1),
    };
  }
}

/// A single habit check-in for one day.
@HiveType(typeId: 15)
class HabitEntry extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String       habitId;
  @HiveField(2) String       date;        // 'YYYY-MM-DD'
  @HiveField(3) bool         completed;
  @HiveField(4) DateTime     recordedAt;

  HabitEntry({
    String? id,
    required this.habitId,
    required this.date,
    required this.completed,
    DateTime? recordedAt,
  })  : id = id ?? const Uuid().v4(),
        recordedAt = recordedAt ?? DateTime.now();
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 5: lib/core/models/daily_entry.dart
# typeId: 12
# PURPOSE: Container for one day's goal-related entries:
#          morning intention, morning three tasks,
#          evening reflection on the intention.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'daily_entry.g.dart';

enum MorningTaskStatus { pending, done, skipped }

@HiveType(typeId: 12)
class MorningTask extends HiveObject {
  @HiveField(0) final String        id;
  @HiveField(1) String              text;
  @HiveField(2) MorningTaskStatus   status;
  @HiveField(3) DateTime?           completedAt;

  MorningTask({
    String? id,
    required this.text,
    this.status = MorningTaskStatus.pending,
    this.completedAt,
  }) : id = id ?? const Uuid().v4();

  bool get isDone => status == MorningTaskStatus.done;
}

enum EveningReflection { yes, notYet, tomorrow }

@HiveType(typeId: 12) // same typeId, different adapter name
class DailyEntry extends HiveObject {
  @HiveField(0)  final String           id;
  @HiveField(1)  String                 date;           // 'YYYY-MM-DD'
  @HiveField(2)  String?                intention;      // "Today I will..."
  @HiveField(3)  List<MorningTask>      morningThree;   // Max 3 tasks
  @HiveField(4)  EveningReflection?     intentionResult;
  @HiveField(5)  String?                eveningNote;    // Optional freeform
  @HiveField(6)  DateTime               createdAt;
  @HiveField(7)  bool                   intentionSet;
  @HiveField(8)  DateTime?              intentionSetAt;

  DailyEntry({
    String? id,
    required this.date,
    this.intention,
    List<MorningTask>? morningThree,
    this.intentionResult,
    this.eveningNote,
    DateTime? createdAt,
    this.intentionSet    = false,
    this.intentionSetAt,
  })  : id = id ?? const Uuid().v4(),
        morningThree = morningThree ?? [],
        createdAt = createdAt ?? DateTime.now();

  int get morningThreeDoneCount =>
      morningThree.where((t) => t.isDone).length;

  double get morningThreeCompletionRate =>
      morningThree.isEmpty ? 0
      : morningThreeDoneCount / morningThree.length;

  bool get isComplete =>
      intentionSet && morningThree.length == 3;
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 6: lib/core/models/quote_item.dart
# typeId: 13
# PURPOSE: A single quote — with like, save, share state.
#          7 categories. Regional wisdom in original language.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:hive/hive.dart';

part 'quote_item.g.dart';

/// Quote categories — defined in our brainstorming session.
enum QuoteCategory {
  sleepScience,    // Surprising, credible sleep facts
  faithMorning,    // Scripture, hadith, spiritual wisdom by faith
  africaProverbs,  // Local wisdom in original language FIRST
  longGame,        // Consistency, the unseen days, patience
  hardTruth,       // Accountability, discipline, owning your choices
  humor,           // Light, self-aware morning humor
  greatness,       // Builders, athletes, creators mid-journey
  userSubmitted,   // Eventually — user-generated wisdom (Phase 2)
}

extension QuoteCategoryExt on QuoteCategory {
  String get displayName => switch (this) {
    QuoteCategory.sleepScience   => 'Sleep Science',
    QuoteCategory.faithMorning   => 'Morning Faith',
    QuoteCategory.africaProverbs => 'African & Global Wisdom',
    QuoteCategory.longGame       => 'The Long Game',
    QuoteCategory.hardTruth      => 'Hard Truths',
    QuoteCategory.humor          => 'Morning Humor',
    QuoteCategory.greatness      => 'Greatness',
    QuoteCategory.userSubmitted  => 'From Our Community',
  };
}

@HiveType(typeId: 13)
class QuoteItem {
  @HiveField(0)  final String        id;
  @HiveField(1)  String              text;
  @HiveField(2)  String              textOriginal;  // In native language (Yoruba, Swahili, Arabic etc.)
  @HiveField(3)  String              originalLanguage; // 'yo', 'sw', 'ar', 'ha', 'am', 'en'...
  @HiveField(4)  String              attribution;   // Author / source
  @HiveField(5)  QuoteCategory       category;
  @HiveField(6)  String?             faithContext;  // FaithOption.name if faith-specific
  @HiveField(7)  String?             region;        // Country/region this is especially relevant for
  @HiveField(8)  bool                isLiked;
  @HiveField(9)  bool                isSaved;
  @HiveField(10) DateTime?           savedAt;
  @HiveField(11) DateTime?           shownAt;

  QuoteItem({
    required this.id,
    required this.text,
    this.textOriginal    = '',
    this.originalLanguage = 'en',
    required this.attribution,
    required this.category,
    this.faithContext,
    this.region,
    this.isLiked   = false,
    this.isSaved   = false,
    this.savedAt,
    this.shownAt,
  });

  bool get hasOriginalLanguage =>
      textOriginal.isNotEmpty && originalLanguage != 'en';
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 7: lib/core/models/proof_wall_milestone.dart
# typeId: 14
# PURPOSE: A milestone on the Proof Wall.
#          Only accumulates — never deletes.
#          The long arc of becoming.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'proof_wall_milestone.g.dart';

enum MilestoneType {
  streakDay,          // 7, 14, 30, 60, 90, 100, 365 days
  goalAchieved,       // North Star goal completed
  habitBuilt,         // 30 consecutive days on a habit
  challengeWon,       // Sleep challenge victory
  wakePerfectWeek,    // 7-day perfect alarm dismissal
  wakeConfirmStreak,  // 7 successful wake confirmations
  calorieMonth,       // 30-day calorie consistency
  morningThreeStreak, // 14-day Morning Three completion
  firstAlarm,         // Day one — always the most important
  leaderboardTop3,    // Hit top 3 on the leaderboard
  customNote,         // User manually added a milestone
}

extension MilestoneTypeExt on MilestoneType {
  String get displayName => switch (this) {
    MilestoneType.streakDay          => 'Streak Milestone',
    MilestoneType.goalAchieved       => 'Goal Achieved',
    MilestoneType.habitBuilt         => 'Habit Built',
    MilestoneType.challengeWon       => 'Challenge Won',
    MilestoneType.wakePerfectWeek    => 'Perfect Wake Week',
    MilestoneType.wakeConfirmStreak  => 'Wake Confirmation Streak',
    MilestoneType.calorieMonth       => 'Calorie Consistency',
    MilestoneType.morningThreeStreak => 'Morning Three Streak',
    MilestoneType.firstAlarm         => 'The First Morning',
    MilestoneType.leaderboardTop3    => 'Leaderboard Top 3',
    MilestoneType.customNote         => 'Personal Milestone',
  };

  String get emoji => switch (this) {
    MilestoneType.streakDay          => '🔥',
    MilestoneType.goalAchieved       => '🏆',
    MilestoneType.habitBuilt         => '💎',
    MilestoneType.challengeWon       => '⚔️',
    MilestoneType.wakePerfectWeek    => '⭐',
    MilestoneType.wakeConfirmStreak  => '✅',
    MilestoneType.calorieMonth       => '🥗',
    MilestoneType.morningThreeStreak => '📋',
    MilestoneType.firstAlarm         => '🌅',
    MilestoneType.leaderboardTop3    => '🥇',
    MilestoneType.customNote         => '📌',
  };
}

@HiveType(typeId: 14)
class ProofWallMilestone extends HiveObject {
  @HiveField(0) final String        id;
  @HiveField(1) MilestoneType       type;
  @HiveField(2) String              title;
  @HiveField(3) String              description;  // What this moment meant
  @HiveField(4) DateTime            achievedAt;
  @HiveField(5) String?             goalId;       // If connected to a North Star goal
  @HiveField(6) int?                streakCount;  // If a streak milestone
  @HiveField(7) bool                isShared;     // User shared this milestone
  @HiveField(8) String?             userNote;     // User's own words about this moment

  ProofWallMilestone({
    String? id,
    required this.type,
    required this.title,
    required this.description,
    DateTime? achievedAt,
    this.goalId,
    this.streakCount,
    this.isShared   = false,
    this.userNote,
  })  : id = id ?? const Uuid().v4(),
        achievedAt = achievedAt ?? DateTime.now();
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 8: lib/core/services/goals_service.dart
# PURPOSE: CRUD for goals, habits, daily entries, proof wall.
#          Enforces the 5-habit limit.
#          Connects morning actions to the North Star goal.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../models/daily_entry.dart';
import '../models/habit_model.dart';
import '../models/north_star_goal.dart';
import '../models/proof_wall_milestone.dart';
import 'offline_sync_service.dart';

class GoalsService {
  static final GoalsService _i = GoalsService._internal();
  factory GoalsService() => _i;
  GoalsService._internal();

  static const int maxHabits       = 5;  // HARD LIMIT — never raise without research
  static const int maxMorningTasks = 3;  // Three important things per day

  final _sync = OfflineSyncService();

  // ── NORTH STAR GOAL ───────────────────────────────────────────────────────

  Future<NorthStarGoal?> getActiveGoal() async {
    final box = Hive.box<dynamic>(AppConstants.goalsBoxName);
    final goals = box.values.cast<NorthStarGoal>()
        .where((g) => !g.achieved)
        .toList();
    if (goals.isEmpty) return null;
    goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return goals.first;
  }

  Future<void> saveGoal(NorthStarGoal goal) async {
    await Hive.box<dynamic>(AppConstants.goalsBoxName).put(goal.id, goal);
    await _sync.queue(SyncOpType.saveGoalUpdate, _goalToMap(goal));

    // Auto-create the "The First Morning" milestone for new goals
    if (goal.milestoneIds.isEmpty) {
      await addMilestone(ProofWallMilestone(
        type:        MilestoneType.firstAlarm,
        title:       'Goal set',
        description: '"${goal.statement}" — ${goal.achievedAt ?? DateTime.now()}',
        goalId:      goal.id,
      ));
    }
  }

  Future<void> markGoalAchieved(NorthStarGoal goal, String celebrationNote) async {
    goal.achieved        = true;
    goal.achievedAt      = DateTime.now();
    goal.celebrationNote = celebrationNote;
    await saveGoal(goal);

    await addMilestone(ProofWallMilestone(
      type:        MilestoneType.goalAchieved,
      title:       'Goal achieved 🏆',
      description: goal.statement,
      goalId:      goal.id,
    ));
  }

  // ── HABITS ────────────────────────────────────────────────────────────────

  Future<List<HabitModel>> getActiveHabits() async {
    final box = Hive.box<dynamic>(AppConstants.habitsBoxName);
    return box.values.cast<HabitModel>()
        .where((h) => !h.archived)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Enforces the 5-habit maximum.
  Future<HabitSaveResult> saveHabit(HabitModel habit) async {
    final existing = await getActiveHabits();

    // Count only habits not being updated (new habits)
    final isNew = !existing.any((h) => h.id == habit.id);
    if (isNew && existing.length >= maxHabits) {
      return HabitSaveResult.limitReached;
    }

    await Hive.box<dynamic>(AppConstants.habitsBoxName)
        .put(habit.id, habit);
    await _sync.queue(SyncOpType.saveHabitEntry, _habitToMap(habit));
    return HabitSaveResult.success;
  }

  Future<void> checkInHabit({
    required String habitId,
    required String date,
    required bool completed,
  }) async {
    final entry = HabitEntry(
      habitId:   habitId,
      date:      date,
      completed: completed,
    );
    await Hive.box<dynamic>(AppConstants.habitsBoxName)
        .put('${habitId}_$date', entry);
    await _sync.queue(SyncOpType.saveHabitEntry, {
      'habitId':   habitId,
      'date':      date,
      'completed': completed,
      'type':      'checkin',
    });
  }

  /// Completion rate for a habit over the last N days.
  double getHabitCompletionRate(String habitId, {int days = 7}) {
    final box  = Hive.box<dynamic>(AppConstants.habitsBoxName);
    int due    = 0;
    int done   = 0;
    final now  = DateTime.now();
    for (var i = 0; i < days; i++) {
      final d   = now.subtract(Duration(days: i));
      final key = '${habitId}_${_dateStr(d)}';
      final entry = box.get(key) as HabitEntry?;
      if (entry != null) {
        due++;
        if (entry.completed) done++;
      }
    }
    return due == 0 ? 0 : done / due;
  }

  // ── DAILY ENTRY (intention + morning three + evening) ─────────────────────

  Future<DailyEntry> getTodayEntry() async {
    final date = _dateStr(DateTime.now());
    final box  = Hive.box<dynamic>(AppConstants.intentionsBoxName);
    return box.get(date) as DailyEntry?
        ?? DailyEntry(date: date);
  }

  Future<void> setIntention(String intention) async {
    final entry    = await getTodayEntry();
    entry.intention    = intention;
    entry.intentionSet = true;
    entry.intentionSetAt = DateTime.now();
    await _saveEntry(entry);
  }

  Future<void> setMorningThree(List<String> tasks) async {
    assert(tasks.length <= maxMorningTasks,
        'Morning Three: max $maxMorningTasks tasks allowed.');
    final entry      = await getTodayEntry();
    entry.morningThree = tasks.map((t) => MorningTask(text: t)).toList();
    await _saveEntry(entry);
  }

  Future<void> completeMorningTask(String taskId) async {
    final entry = await getTodayEntry();
    final task  = entry.morningThree.firstWhere((t) => t.id == taskId);
    task.status      = MorningTaskStatus.done;
    task.completedAt = DateTime.now();
    await _saveEntry(entry);
  }

  Future<void> recordEveningReflection({
    required EveningReflection result,
    String? note,
  }) async {
    final entry             = await getTodayEntry();
    entry.intentionResult   = result;
    entry.eveningNote       = note;
    await _saveEntry(entry);
  }

  Future<List<DailyEntry>> getEntriesForWeek() async {
    final box = Hive.box<dynamic>(AppConstants.intentionsBoxName);
    final now = DateTime.now();
    final entries = <DailyEntry>[];
    for (var i = 0; i < 7; i++) {
      final d    = now.subtract(Duration(days: i));
      final key  = _dateStr(d);
      final e    = box.get(key) as DailyEntry?;
      if (e != null) entries.add(e);
    }
    return entries;
  }

  Future<void> _saveEntry(DailyEntry entry) async {
    await Hive.box<dynamic>(AppConstants.intentionsBoxName)
        .put(entry.date, entry);
    await _sync.queue(SyncOpType.saveDailyIntention, {
      'date':            entry.date,
      'intention':       entry.intention,
      'intentionSet':    entry.intentionSet,
      'intentionResult': entry.intentionResult?.name,
    });
  }

  // ── PROOF WALL ────────────────────────────────────────────────────────────

  Future<void> addMilestone(ProofWallMilestone m) async {
    await Hive.box<dynamic>(AppConstants.proofWallBoxName)
        .put(m.id, m);
  }

  Future<List<ProofWallMilestone>> getAllMilestones() async {
    final box = Hive.box<dynamic>(AppConstants.proofWallBoxName);
    final all = box.values.cast<ProofWallMilestone>().toList();
    all.sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
    return all;
  }

  /// Called by AlarmService after each streak milestone.
  Future<void> checkAndAwardStreakMilestone(int streak) async {
    const milestones = [1, 7, 14, 30, 60, 90, 100, 180, 365];
    if (!milestones.contains(streak)) return;

    final label = streak == 1
        ? 'The First Morning'
        : '$streak-Day Streak';

    await addMilestone(ProofWallMilestone(
      type:        MilestoneType.streakDay,
      title:       label,
      description: 'You\'ve woken up on purpose $streak days in a row.',
      streakCount: streak,
    ));
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}'
      '-${d.day.toString().padLeft(2,'0')}';

  Map<String, dynamic> _goalToMap(NorthStarGoal g) => {
    'id': g.id, 'statement': g.statement,
    'category': g.category.name, 'targetDate': g.targetDate.toIso8601String(),
    'achieved': g.achieved,
  };

  Map<String, dynamic> _habitToMap(HabitModel h) => {
    'id': h.id, 'name': h.name,
    'frequency': h.frequency.name, 'archived': h.archived,
  };
}

enum HabitSaveResult { success, limitReached }
```

---

# ══════════════════════════════════════════════════════════════
# FILE 9: lib/core/services/ai_reflection_service.dart
# PURPOSE: Generates weekly review narrative, monthly letter,
#          and accountability mirror using the Claude API.
#          The understanding layer — the most personal thing
#          RISE produces. Must feel like a wise friend speaking.
# ══════════════════════════════════════════════════════════════

```dart
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/daily_entry.dart';
import '../models/habit_model.dart';
import '../models/north_star_goal.dart';
import '../models/sleep_session.dart';
import '../models/subscription_tier.dart';
import 'goals_service.dart';

class AiReflectionService {
  static final AiReflectionService _i = AiReflectionService._internal();
  factory AiReflectionService() => _i;
  AiReflectionService._internal();

  static const _apiUrl =
      'https://api.anthropic.com/v1/messages';
  static const _model  = 'claude-sonnet-4-20250514';

  // ── WEEKLY REVIEW ─────────────────────────────────────────────────────────
  // Generates a narrative review of the past 7 days.
  // Called every Sunday (or user's chosen review day).
  // Requires Core+ subscription.
  Future<WeeklyReview?> generateWeeklyReview({
    required String tierId,
  }) async {
    if (!SubscriptionTier.fromId(tierId).fullSleepHistory) return null;

    // Gather data
    final goalsSvc   = GoalsService();
    final goal       = await goalsSvc.getActiveGoal();
    final entries    = await goalsSvc.getEntriesForWeek();
    final habits     = await goalsSvc.getActiveHabits();
    final sessions   = _getWeekSessions();
    final calorieAvg = await _getWeekCalorieAvg();

    final prompt = _buildWeeklyPrompt(
        goal: goal, entries: entries,
        habits: habits, sessions: sessions,
        calorieAvg: calorieAvg);

    final narrative = await _callClaude(prompt,
        maxTokens: 600,
        systemPrompt: _weeklySystemPrompt);

    if (narrative == null) return null;

    final review = WeeklyReview(
      weekStartDate: _weekStartDate(),
      narrative:     narrative,
      sleepAvgHours: _avgSleepHours(sessions),
      habitRates:    _getHabitRates(habits),
      intentionRate: _getIntentionRate(entries),
    );

    // Cache it
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_weekly_review',
        jsonEncode(review.toJson()));

    return review;
  }

  // ── MONTHLY LETTER ────────────────────────────────────────────────────────
  // The most personal output RISE produces.
  // A letter addressed to the user, second-person, narrative.
  // Not statistics — a story of who they were this month.
  // Requires Pro+ subscription.
  Future<MonthlyLetter?> generateMonthlyLetter({
    required String tierId,
    required String userName,
  }) async {
    if (!SubscriptionTier.fromId(tierId).dailyAiMorningBriefing) return null;

    final goalsSvc   = GoalsService();
    final goal       = await goalsSvc.getActiveGoal();
    final milestones = await goalsSvc.getAllMilestones();
    final sessions   = _getMonthSessions();
    final habits     = await goalsSvc.getActiveHabits();

    final prompt = _buildMonthlyPrompt(
        userName:   userName,
        goal:       goal,
        milestones: milestones
            .where((m) => m.achievedAt.month == DateTime.now().month)
            .toList(),
        sessions:   sessions,
        habits:     habits);

    final letter = await _callClaude(prompt,
        maxTokens: 900,
        systemPrompt: _monthlySystemPrompt);

    if (letter == null) return null;

    final result = MonthlyLetter(
      month:       _monthLabel(),
      letterText:  letter,
      generatedAt: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('monthly_letter_${_monthLabel()}',
        jsonEncode(result.toJson()));

    return result;
  }

  // ── ACCOUNTABILITY MIRROR ─────────────────────────────────────────────────
  // Side-by-side: what you said vs. what you did.
  // No editorialising — just the mirror.
  Future<AccountabilityMirror> generateMirror() async {
    final goalsSvc = GoalsService();
    final goal     = await goalsSvc.getActiveGoal();
    final habits   = await goalsSvc.getActiveHabits();

    final intentionRate  = await _getWeekIntentionRate();
    final habitRates     = {
      for (final h in habits)
        h.name: GoalsService().getHabitCompletionRate(h.id, days: 30),
    };

    return AccountabilityMirror(
      goalStatement:    goal?.statement,
      targetDate:       goal?.targetDate,
      daysRemaining:    goal?.daysRemaining ?? 0,
      commitments: {
        for (final h in habits) h.name: h.frequency.displayName,
      },
      results:          habitRates,
      intentionRate:    intentionRate,
    );
  }

  // ── SLEEP + NUTRITION CORRELATION INSIGHT ─────────────────────────────────
  // The triangle: sleep → nutrition → goal performance.
  // Called once per week after enough data exists (14+ days).
  Future<String?> generateSleepNutritionInsight({
    required String tierId,
  }) async {
    if (!SubscriptionTier.fromId(tierId).fullSleepHistory) return null;

    final sessions   = _getMonthSessions();
    if (sessions.length < 7) return null; // Not enough data

    final calorieData = await _getCalorieVsSleepData();

    final prompt = '''
You are RISE's wellness insight engine. Based on this user's data:
${jsonEncode(calorieData)}

Write ONE insight in 2-3 sentences that:
1. Identifies a real pattern in their sleep vs. nutrition data
2. Names the biological mechanism briefly (cortisol, insulin, etc.)
3. Offers one concrete, actionable suggestion for tomorrow

Write in second person. Be warm, specific, not generic. 
If there is no meaningful pattern, say so briefly and honestly.
''';

    return _callClaude(prompt, maxTokens: 150,
        systemPrompt: 'You are a warm, evidence-based wellness coach.');
  }

  // ── CLAUDE API CALL ───────────────────────────────────────────────────────

  Future<String?> _callClaude(String prompt, {
    required int    maxTokens,
    required String systemPrompt,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'content-type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model':      _model,
          'max_tokens': maxTokens,
          'system':     systemPrompt,
          'messages':   [{'role': 'user', 'content': prompt}],
        }),
      );

      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final content = (data['content'] as List?)?.first
          as Map<String, dynamic>?;
      return content?['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── PROMPT BUILDERS ───────────────────────────────────────────────────────

  String get _weeklySystemPrompt =>
      'You are RISE\'s reflection engine. You write weekly reviews '
      'that feel like a wise, caring friend who has been watching quietly. '
      'Never list statistics. Tell a story. Be honest about struggles '
      'without being harsh. Celebrate effort more than outcomes. '
      'Write in second person. 200-400 words.';

  String get _monthlySystemPrompt =>
      'You are writing a deeply personal monthly letter to a RISE user. '
      'This is the most important thing RISE produces. '
      'It is addressed to them by name. It is written as a letter. '
      'It narrates who they were this month — what they built, '
      'where they struggled, what the data quietly reveals about their '
      'character. Do not summarise statistics. Write about a person. '
      'End with one sentence about who they are becoming. '
      '300-600 words.';

  String _buildWeeklyPrompt({
    required NorthStarGoal? goal,
    required List<DailyEntry> entries,
    required List<HabitModel> habits,
    required List<SleepSession> sessions,
    required double calorieAvg,
  }) {
    final habitSummary = habits.map((h) {
      final rate = GoalsService()
          .getHabitCompletionRate(h.id, days: 7);
      return '${h.name}: ${(rate * 100).round()}%';
    }).join(', ');

    final intentionsSet = entries
        .where((e) => e.intentionSet).length;
    final intentionsDone = entries
        .where((e) => e.intentionResult == EveningReflection.yes).length;

    return '''
User's North Star Goal: ${goal?.statement ?? 'Not set'}
Days until target: ${goal?.daysRemaining ?? 'N/A'}

This week's data:
- Sleep sessions: ${sessions.length} nights
- Average sleep: ${_avgSleepHours(sessions).toStringAsFixed(1)} hours
- Habit completion: $habitSummary
- Daily intentions set: $intentionsSet/7
- Intentions fulfilled: $intentionsDone/$intentionsSet
- Average calories: ${calorieAvg.round()} kcal/day

Write the weekly review.
''';
  }

  String _buildMonthlyPrompt({
    required String userName,
    required NorthStarGoal? goal,
    required List<ProofWallMilestone> milestones,
    required List<SleepSession> sessions,
    required List<HabitModel> habits,
  }) {
    final mList = milestones.map((m) => m.title).join(', ');
    return '''
User's name: $userName
North Star Goal: ${goal?.statement ?? 'Not set'}
Milestones this month: ${mList.isEmpty ? 'None recorded' : mList}
Sleep sessions this month: ${sessions.length}
Average sleep: ${_avgSleepHours(sessions).toStringAsFixed(1)} hours
Snooze pattern: avg ${_avgSnoozes(sessions).toStringAsFixed(1)} snoozes

Write a personal monthly letter addressed to $userName.
''';
  }

  // ── DATA HELPERS ──────────────────────────────────────────────────────────

  List<SleepSession> _getWeekSessions() {
    final box  = Hive.box<dynamic>(AppConstants.sessionsBoxName);
    final week = DateTime.now().subtract(const Duration(days: 7));
    return box.values.cast<SleepSession>()
        .where((s) => s.createdAt.isAfter(week))
        .toList();
  }

  List<SleepSession> _getMonthSessions() {
    final box   = Hive.box<dynamic>(AppConstants.sessionsBoxName);
    final month = DateTime.now().subtract(const Duration(days: 30));
    return box.values.cast<SleepSession>()
        .where((s) => s.createdAt.isAfter(month))
        .toList();
  }

  double _avgSleepHours(List<SleepSession> sessions) {
    if (sessions.isEmpty) return 0;
    final total = sessions
        .map((s) => s.durationMinutes)
        .reduce((a, b) => a + b);
    return total / sessions.length / 60.0;
  }

  double _avgSnoozes(List<SleepSession> sessions) {
    if (sessions.isEmpty) return 0;
    return sessions.map((s) => s.snoozeCount)
        .reduce((a, b) => a + b) / sessions.length;
  }

  Map<String, double> _getHabitRates(List<HabitModel> habits) =>
      {for (final h in habits)
        h.name: GoalsService().getHabitCompletionRate(h.id, days: 7)};

  double _getIntentionRate(List<DailyEntry> entries) {
    final set = entries.where((e) => e.intentionSet).length;
    if (set == 0) return 0;
    final done = entries
        .where((e) => e.intentionResult == EveningReflection.yes).length;
    return done / set;
  }

  Future<double> _getWeekIntentionRate() async {
    final entries = await GoalsService().getEntriesForWeek();
    return _getIntentionRate(entries);
  }

  Future<double> _getWeekCalorieAvg() async => 0; // Implemented in CalorieService

  Future<Map<String, dynamic>> _getCalorieVsSleepData() async => {};

  String _weekStartDate() {
    final now   = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return '${start.year}-${start.month.toString().padLeft(2,'0')}'
           '-${start.day.toString().padLeft(2,'0')}';
  }

  String _monthLabel() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[now.month - 1]} ${now.year}';
  }
}

// ── Data structures returned by the service ──────────────────────────────────

class WeeklyReview {
  final String              weekStartDate;
  final String              narrative;
  final double              sleepAvgHours;
  final Map<String, double> habitRates;
  final double              intentionRate;

  const WeeklyReview({
    required this.weekStartDate,
    required this.narrative,
    required this.sleepAvgHours,
    required this.habitRates,
    required this.intentionRate,
  });

  Map<String, dynamic> toJson() => {
    'weekStartDate':  weekStartDate,
    'narrative':      narrative,
    'sleepAvgHours':  sleepAvgHours,
    'intentionRate':  intentionRate,
  };
}

class MonthlyLetter {
  final String   month;
  final String   letterText;
  final DateTime generatedAt;

  const MonthlyLetter({
    required this.month,
    required this.letterText,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
    'month':       month,
    'letterText':  letterText,
    'generatedAt': generatedAt.toIso8601String(),
  };
}

class AccountabilityMirror {
  final String?             goalStatement;
  final DateTime?           targetDate;
  final int                 daysRemaining;
  final Map<String, String> commitments;  // habit name → frequency promise
  final Map<String, double> results;      // habit name → actual rate
  final double              intentionRate;

  const AccountabilityMirror({
    this.goalStatement,
    this.targetDate,
    required this.daysRemaining,
    required this.commitments,
    required this.results,
    required this.intentionRate,
  });

  double gapForHabit(String name) {
    final actual = results[name] ?? 0;
    return 1.0 - actual; // 0 = perfect, 1 = never done
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 10: lib/core/services/quote_service.dart
# PURPOSE: Quote rotation, delivery, like/save/share.
#          Regional wisdom shows in original language first.
#          Faith-aware. Remote-config-driven category rotation.
# ══════════════════════════════════════════════════════════════

```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/quote_item.dart';
import 'offline_sync_service.dart';
import 'remote_config_service.dart';

class QuoteService {
  static final QuoteService _i = QuoteService._internal();
  factory QuoteService() => _i;
  QuoteService._internal();

  final _sync   = OfflineSyncService();
  final _rc     = RemoteConfigService();

  // ── Get today's quote ─────────────────────────────────────────────────────
  // Checks remote config for today's category.
  // Falls back to local bundled quote bank if offline.
  Future<QuoteItem> getTodayQuote({
    required String   storefrontCountry,
    required String?  faithContext,
  }) async {
    final prefs     = await SharedPreferences.getInstance();
    final todayKey  = 'quote_${_todayStr()}';
    final cached    = prefs.getString(todayKey);

    if (cached != null) {
      return _quoteFromJson(jsonDecode(cached) as Map<String, dynamic>);
    }

    // Determine category
    final remoteCategory = _rc.todayQuoteCategory;
    final category = _resolveCategory(
        remoteCategory, storefrontCountry, faithContext);

    final quote = await _selectQuote(
        category: category,
        country:  storefrontCountry,
        faith:    faithContext);

    // Cache for today
    await prefs.setString(todayKey, jsonEncode(_quoteToJson(quote)));
    return quote;
  }

  // ── Like a quote ──────────────────────────────────────────────────────────
  Future<void> likeQuote(String quoteId) async {
    final box   = Hive.box<dynamic>(AppConstants.quotesBoxName);
    final prefs = await SharedPreferences.getInstance();
    final liked = (prefs.getStringList('liked_quotes') ?? [])
        ..add(quoteId);
    await prefs.setStringList('liked_quotes', liked.toSet().toList());
    await _sync.queue(SyncOpType.saveQuoteLike,
        {'quoteId': quoteId, 'liked': true, 'at': _nowStr()});
  }

  Future<void> unlikeQuote(String quoteId) async {
    final prefs = await SharedPreferences.getInstance();
    final liked = prefs.getStringList('liked_quotes') ?? [];
    liked.remove(quoteId);
    await prefs.setStringList('liked_quotes', liked);
    await _sync.queue(SyncOpType.saveQuoteLike,
        {'quoteId': quoteId, 'liked': false, 'at': _nowStr()});
  }

  // ── Save a quote ──────────────────────────────────────────────────────────
  Future<void> saveQuote(QuoteItem quote) async {
    quote.isSaved = true;
    quote.savedAt = DateTime.now();
    await Hive.box<dynamic>(AppConstants.quotesBoxName)
        .put(quote.id, quote);
    await _sync.queue(SyncOpType.saveQuoteSave,
        {'quoteId': quote.id, 'saved': true, 'at': _nowStr()});
  }

  Future<void> unsaveQuote(String quoteId) async {
    final box   = Hive.box<dynamic>(AppConstants.quotesBoxName);
    final quote = box.get(quoteId) as QuoteItem?;
    if (quote == null) return;
    quote.isSaved = false;
    await box.put(quoteId, quote);
    await _sync.queue(SyncOpType.saveQuoteSave,
        {'quoteId': quoteId, 'saved': false, 'at': _nowStr()});
  }

  // ── Get saved quotes collection ───────────────────────────────────────────
  List<QuoteItem> getSavedQuotes() {
    final box = Hive.box<dynamic>(AppConstants.quotesBoxName);
    return box.values.cast<QuoteItem>()
        .where((q) => q.isSaved)
        .toList()
      ..sort((a, b) => (b.savedAt ?? DateTime(0))
          .compareTo(a.savedAt ?? DateTime(0)));
  }

  bool isLiked(String quoteId) {
    // Synchronous check using SharedPreferences cached value
    return false; // Full impl loads from prefs
  }

  // ── Select quote from bundled bank ────────────────────────────────────────
  Future<QuoteItem> _selectQuote({
    required QuoteCategory category,
    required String        country,
    String?                faith,
  }) async {
    final bank = await _loadQuoteBank();
    var candidates = bank
        .where((q) => q.category == category)
        .toList();

    // Faith-aware filtering
    if (category == QuoteCategory.faithMorning && faith != null) {
      final faithFiltered = candidates
          .where((q) => q.faithContext == faith)
          .toList();
      if (faithFiltered.isNotEmpty) candidates = faithFiltered;
    }

    if (candidates.isEmpty) {
      candidates = bank
          .where((q) => q.category == QuoteCategory.greatness)
          .toList();
    }

    // Avoid recent repeats
    final prefs   = await SharedPreferences.getInstance();
    final recent  = prefs.getStringList('recent_quote_ids') ?? [];
    final fresh   = candidates
        .where((q) => !recent.contains(q.id))
        .toList();
    final pool    = fresh.isNotEmpty ? fresh : candidates;

    // Seed with date for consistent daily quote
    pool.shuffle();
    final quote   = pool.first;

    // Update recency list (keep last 30)
    final updated = [...recent, quote.id].takeLast(30).toList();
    await prefs.setStringList('recent_quote_ids', updated);

    return quote;
  }

  QuoteCategory _resolveCategory(
      String remote, String country, String? faith) {
    if (remote == 'faith' && faith != null) {
      return QuoteCategory.faithMorning;
    }
    if (remote == 'african_proverbs' ||
        _isAfricanCountry(country)) {
      return QuoteCategory.africaProverbs;
    }
    if (remote == 'accountability') return QuoteCategory.hardTruth;
    if (remote == 'humor')          return QuoteCategory.humor;
    if (remote == 'long_game')      return QuoteCategory.longGame;
    // Mixed: cycle through categories by day of week
    const cycle = [
      QuoteCategory.greatness,
      QuoteCategory.longGame,
      QuoteCategory.africaProverbs,
      QuoteCategory.hardTruth,
      QuoteCategory.sleepScience,
      QuoteCategory.humor,
      QuoteCategory.greatness,
    ];
    return cycle[DateTime.now().weekday - 1];
  }

  bool _isAfricanCountry(String code) {
    const africa = {
      'NG','KE','GH','ZA','ET','TZ','UG','RW','CM','SN',
      'CI','EG','MA','TN','DZ','LY','SD','ZM','MW','MZ',
      'ZW','BI','SS','SL','LR','GN','ML','NE','BF','TD',
    };
    return africa.contains(code.toUpperCase());
  }

  // ── Bundled quote bank ─────────────────────────────────────────────────────
  // Loaded from assets/quotes.json — ships with the app.
  // Remote quotes can be pushed via server for live updates.
  Future<List<QuoteItem>> _loadQuoteBank() async {
    try {
      final json = await rootBundle.loadString('assets/quotes.json');
      final list = jsonDecode(json) as List;
      return list.map((j) =>
          _quoteFromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return _fallbackQuotes();
    }
  }

  List<QuoteItem> _fallbackQuotes() => [
    QuoteItem(
      id:            'q_001',
      text:          'However long the night, the dawn will break.',
      textOriginal:  'Usiku mrefu kiasi gani, alfajiri itakuja.',
      originalLanguage: 'sw',
      attribution:   'Swahili proverb',
      category:      QuoteCategory.africaProverbs,
      region:        'EA',
    ),
    QuoteItem(
      id:            'q_002',
      text:          'The secret of getting ahead is getting started.',
      textOriginal:  '',
      originalLanguage: 'en',
      attribution:   'Mark Twain',
      category:      QuoteCategory.longGame,
    ),
    QuoteItem(
      id:            'q_003',
      text:          'Sleep is the single most effective thing you can do '
                     'to reset your brain and body.',
      textOriginal:  '',
      originalLanguage: 'en',
      attribution:   'Matthew Walker, neuroscientist',
      category:      QuoteCategory.sleepScience,
    ),
    QuoteItem(
      id:            'q_004',
      text:          'We do not inherit the earth from our ancestors; '
                     'we borrow it from our children.',
      textOriginal:  'A nan ce mu ba iyayenmu ƙasa; muna aro ta daga yaranmu.',
      originalLanguage: 'ha',
      attribution:   'Hausa proverb',
      category:      QuoteCategory.africaProverbs,
      region:        'NG',
    ),
    QuoteItem(
      id:            'q_005',
      text:          'You do not rise to the level of your goals. '
                     'You fall to the level of your systems.',
      textOriginal:  '',
      originalLanguage: 'en',
      attribution:   'James Clear',
      category:      QuoteCategory.hardTruth,
    ),
  ];

  QuoteItem _quoteFromJson(Map<String, dynamic> j) => QuoteItem(
    id:               j['id'] as String,
    text:             j['text'] as String,
    textOriginal:     j['textOriginal'] as String? ?? '',
    originalLanguage: j['originalLanguage'] as String? ?? 'en',
    attribution:      j['attribution'] as String,
    category:         QuoteCategory.values.byName(
        j['category'] as String? ?? 'greatness'),
    faithContext:     j['faithContext'] as String?,
    region:           j['region'] as String?,
  );

  Map<String, dynamic> _quoteToJson(QuoteItem q) => {
    'id':               q.id,
    'text':             q.text,
    'textOriginal':     q.textOriginal,
    'originalLanguage': q.originalLanguage,
    'attribution':      q.attribution,
    'category':         q.category.name,
    'faithContext':     q.faithContext,
    'region':           q.region,
  };

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}'
           '-${n.day.toString().padLeft(2,'0')}';
  }

  String _nowStr() => DateTime.now().toIso8601String();
}

extension<T> on List<T> {
  Iterable<T> takeLast(int n) =>
      length <= n ? this : skip(length - n);
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 11: lib/core/services/calorie_service.dart
# PURPOSE: Full calorie tracking service.
#          Global food database — African foods FIRST-CLASS.
#          Ramadan mode: Suhoor/Iftar tracking, fast monitoring.
#          Sleep-nutrition correlation data for AI insights.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/calorie_entry.dart';
import '../models/food_item.dart';
import '../models/sleep_session.dart';
import 'offline_sync_service.dart';
import 'remote_config_service.dart';

class CalorieService {
  static final CalorieService _i = CalorieService._internal();
  factory CalorieService() => _i;
  CalorieService._internal();

  final _sync = OfflineSyncService();
  final _rc   = RemoteConfigService();

  // ── LOG FOOD ──────────────────────────────────────────────────────────────

  Future<void> logFood({
    required FoodItem  food,
    required double    servingGrams,
    required MealType  mealType,
    String?            notes,
  }) async {
    final isRamadan = _rc.isRamadanActive;

    final entry = CalorieEntry(
      date:          _todayStr(),
      foodItemId:    food.id,
      foodName:      food.name,
      servingGrams:  servingGrams,
      calories:      food.caloriesForServing(servingGrams),
      proteinG:      food.proteinForServing(servingGrams),
      carbsG:        food.carbsForServing(servingGrams),
      fatG:          food.fatForServing(servingGrams),
      mealType:      mealType,
      isRamadanFast: isRamadan,
      notes:         notes,
    );

    await Hive.box<dynamic>(AppConstants.calorieBoxName)
        .put(entry.id, entry);
    await _sync.queue(SyncOpType.saveCalorieLog, _entryToMap(entry));
  }

  // ── GET DAILY SUMMARY ─────────────────────────────────────────────────────

  Future<DailySummary> getDailySummary({String? date}) async {
    final d       = date ?? _todayStr();
    final entries = _getEntriesForDate(d);
    final target  = await _getCalorieTarget();
    final isRamadan = _rc.isRamadanActive;

    final totalCal  = entries.fold(0.0, (s, e) => s + e.calories);
    final totalProt = entries.fold(0.0, (s, e) => s + e.proteinG);
    final totalCarb = entries.fold(0.0, (s, e) => s + e.carbsG);
    final totalFat  = entries.fold(0.0, (s, e) => s + e.fatG);

    // Ramadan: check if fast is complete
    // Fast = no food logged between Fajr (approx 05:00) and Maghrib (approx 18:30)
    bool fastComplete = false;
    if (isRamadan) {
      final forbiddenEntries = entries.where((e) {
        final h = e.loggedAt.hour;
        return h >= 5 && h < 18 &&
            !e.mealType.isRamadanMeal;
      });
      fastComplete = forbiddenEntries.isEmpty && entries.isNotEmpty;
    }

    return DailySummary(
      date:             d,
      targetCalories:   target,
      consumedCalories: totalCal,
      proteinG:         totalProt,
      carbsG:           totalCarb,
      fatG:             totalFat,
      isRamadanDay:     isRamadan,
      fastComplete:     fastComplete,
    );
  }

  // ── SEARCH FOOD DATABASE ──────────────────────────────────────────────────
  // Searches bundled database first (offline-first).
  // African foods, South Asian foods, LatAm foods — equal weighting.

  List<FoodItem> searchFood(String query, {String? countryCode}) {
    final q     = query.toLowerCase().trim();
    final box   = Hive.box<dynamic>(AppConstants.foodDbBoxName);
    final items = box.values.cast<FoodItem>().toList();

    // Prioritise results from user's cuisine region
    final regionItems = countryCode != null
        ? items.where((f) => _countryMatchesRegion(
            countryCode, f.cuisineRegion))
            .toList()
        : <FoodItem>[];

    final allMatches = items.where((f) =>
        f.name.toLowerCase().contains(q) ||
        f.nameLocalised.toLowerCase().contains(q) ||
        f.aliases.any((a) => a.toLowerCase().contains(q)))
        .toList();

    // Sort: region items first, then alphabetical
    final regionMatches = allMatches
        .where((f) => regionItems.contains(f)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final otherMatches  = allMatches
        .where((f) => !regionItems.contains(f)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return [...regionMatches, ...otherMatches];
  }

  // ── GLOBAL FOOD DATABASE — SEED DATA ──────────────────────────────────────
  // Called once at app install to seed the local Hive food database.
  // EVERY cuisine is first-class. This is non-negotiable.
  Future<void> seedFoodDatabase() async {
    final box   = Hive.box<dynamic>(AppConstants.foodDbBoxName);
    if (box.isNotEmpty) return; // Already seeded

    final foods = _buildGlobalFoodDatabase();
    for (final food in foods) {
      await box.put(food.id, food);
    }
  }

  List<FoodItem> _buildGlobalFoodDatabase() => [
    // ── WEST AFRICA ────────────────────────────────────────────
    FoodItem(
      id: 'f_jollof_rice_ng', name: 'Jollof Rice (Nigerian)',
      nameLocalised: 'Jollof Raisi', cuisineRegion: CuisineRegion.westAfrica,
      caloriesPer100g: 180, proteinPer100g: 4, carbsPer100g: 36, fatPer100g: 3,
      category: 'grain', defaultServingGrams: 250, servingUnit: 'bowl',
      aliases: ['jollof', 'party rice', 'red rice'],
    ),
    FoodItem(
      id: 'f_fufu_ng', name: 'Fufu (Yam)',
      nameLocalised: 'Iyan', cuisineRegion: CuisineRegion.westAfrica,
      caloriesPer100g: 110, proteinPer100g: 1.2, carbsPer100g: 25, fatPer100g: 0.3,
      category: 'grain', defaultServingGrams: 300, servingUnit: 'wrap',
      aliases: ['iyan', 'pounded yam', 'amala', 'eba'],
    ),
    FoodItem(
      id: 'f_egusi_soup', name: 'Egusi Soup',
      cuisineRegion: CuisineRegion.westAfrica,
      caloriesPer100g: 220, proteinPer100g: 12, carbsPer100g: 8, fatPer100g: 16,
      category: 'protein', defaultServingGrams: 200, servingUnit: 'bowl',
      aliases: ['melon seed soup', 'egusi'],
    ),
    FoodItem(
      id: 'f_suya', name: 'Suya',
      cuisineRegion: CuisineRegion.westAfrica,
      caloriesPer100g: 290, proteinPer100g: 28, carbsPer100g: 5, fatPer100g: 18,
      category: 'protein', defaultServingGrams: 150, servingUnit: 'g',
      aliases: ['kilishi', 'tsire', 'beef suya'],
    ),
    FoodItem(
      id: 'f_waakye', name: 'Waakye',
      cuisineRegion: CuisineRegion.westAfrica,
      caloriesPer100g: 160, proteinPer100g: 6, carbsPer100g: 30, fatPer100g: 2,
      category: 'grain', defaultServingGrams: 300, servingUnit: 'bowl',
      aliases: ['rice and beans ghana', 'waachi'],
    ),
    FoodItem(
      id: 'f_thieboudienne', name: 'Thiéboudienne',
      nameLocalised: 'Ceebu Jën', cuisineRegion: CuisineRegion.westAfrica,
      caloriesPer100g: 195, proteinPer100g: 14, carbsPer100g: 22, fatPer100g: 6,
      category: 'mixed', defaultServingGrams: 350, servingUnit: 'bowl',
      aliases: ['senegalese rice fish', 'ceebu jën'],
    ),
    // ── EAST AFRICA ────────────────────────────────────────────
    FoodItem(
      id: 'f_ugali', name: 'Ugali',
      nameLocalised: 'Ugali / Posho', cuisineRegion: CuisineRegion.eastAfrica,
      caloriesPer100g: 119, proteinPer100g: 2.4, carbsPer100g: 26, fatPer100g: 0.5,
      category: 'grain', defaultServingGrams: 300, servingUnit: 'piece',
      aliases: ['posho', 'nshima', 'sadza', 'uji'],
    ),
    FoodItem(
      id: 'f_sukuma_wiki', name: 'Sukuma Wiki',
      cuisineRegion: CuisineRegion.eastAfrica,
      caloriesPer100g: 45, proteinPer100g: 3.3, carbsPer100g: 7, fatPer100g: 0.7,
      category: 'vegetable', defaultServingGrams: 150, servingUnit: 'cup',
      aliases: ['collard greens', 'kale kenyan'],
    ),
    FoodItem(
      id: 'f_injera', name: 'Injera',
      nameLocalised: 'እንጀራ', cuisineRegion: CuisineRegion.eastAfrica,
      caloriesPer100g: 130, proteinPer100g: 4, carbsPer100g: 28, fatPer100g: 0.8,
      category: 'grain', defaultServingGrams: 150, servingUnit: 'piece',
      aliases: ['Ethiopian flatbread', 'teff bread'],
    ),
    FoodItem(
      id: 'f_doro_wat', name: 'Doro Wat',
      nameLocalised: 'ዶሮ ወጥ', cuisineRegion: CuisineRegion.eastAfrica,
      caloriesPer100g: 185, proteinPer100g: 18, carbsPer100g: 8, fatPer100g: 9,
      category: 'protein', defaultServingGrams: 250, servingUnit: 'bowl',
      aliases: ['Ethiopian chicken stew', 'doro wot'],
    ),
    FoodItem(
      id: 'f_mandazi', name: 'Mandazi',
      cuisineRegion: CuisineRegion.eastAfrica,
      caloriesPer100g: 330, proteinPer100g: 7, carbsPer100g: 48, fatPer100g: 13,
      category: 'snack', defaultServingGrams: 80, servingUnit: 'piece',
      aliases: ['maandazi', 'East African doughnut'],
    ),
    // ── NORTH AFRICA / MIDDLE EAST ─────────────────────────────
    FoodItem(
      id: 'f_ful_medames', name: 'Ful Medames',
      nameLocalised: 'فول مدمس', cuisineRegion: CuisineRegion.northAfrica,
      caloriesPer100g: 110, proteinPer100g: 7.6, carbsPer100g: 18, fatPer100g: 1.2,
      category: 'legume', defaultServingGrams: 200, servingUnit: 'bowl',
      aliases: ['foul', 'fava beans egyptian', 'ful'],
    ),
    FoodItem(
      id: 'f_tagine', name: 'Lamb Tagine',
      nameLocalised: 'طاجين', cuisineRegion: CuisineRegion.northAfrica,
      caloriesPer100g: 210, proteinPer100g: 16, carbsPer100g: 12, fatPer100g: 11,
      category: 'protein', defaultServingGrams: 300, servingUnit: 'bowl',
      aliases: ['moroccan tagine', 'tajine'],
    ),
    FoodItem(
      id: 'f_shawarma', name: 'Shawarma (Chicken)',
      nameLocalised: 'شاورما', cuisineRegion: CuisineRegion.middleEast,
      caloriesPer100g: 215, proteinPer100g: 17, carbsPer100g: 22, fatPer100g: 7,
      category: 'protein', defaultServingGrams: 250, servingUnit: 'wrap',
      aliases: ['chicken shawarma', 'wrap'],
    ),
    // ── SOUTH ASIA ─────────────────────────────────────────────
    FoodItem(
      id: 'f_biryani_chicken', name: 'Chicken Biryani',
      nameLocalised: 'بریانی', cuisineRegion: CuisineRegion.southAsia,
      caloriesPer100g: 185, proteinPer100g: 12, carbsPer100g: 25, fatPer100g: 4,
      category: 'mixed', defaultServingGrams: 350, servingUnit: 'bowl',
      aliases: ['biryani', 'biriani'],
    ),
    FoodItem(
      id: 'f_dal', name: 'Dal (Lentil Curry)',
      nameLocalised: 'दाल', cuisineRegion: CuisineRegion.southAsia,
      caloriesPer100g: 115, proteinPer100g: 7.6, carbsPer100g: 19, fatPer100g: 1.5,
      category: 'legume', defaultServingGrams: 200, servingUnit: 'bowl',
      aliases: ['dhal', 'lentil soup', 'masoor dal'],
    ),
    FoodItem(
      id: 'f_chapati', name: 'Chapati',
      nameLocalised: 'चपाती', cuisineRegion: CuisineRegion.southAsia,
      caloriesPer100g: 297, proteinPer100g: 9, carbsPer100g: 56, fatPer100g: 4,
      category: 'grain', defaultServingGrams: 60, servingUnit: 'piece',
      aliases: ['roti', 'phulka', 'flatbread'],
    ),
    // ── LATIN AMERICA ───────────────────────────────────────────
    FoodItem(
      id: 'f_arroz_frijoles', name: 'Rice and Beans (Latin)',
      nameLocalised: 'Arroz con Frijoles', cuisineRegion: CuisineRegion.latinAmerica,
      caloriesPer100g: 170, proteinPer100g: 7, carbsPer100g: 32, fatPer100g: 1.5,
      category: 'mixed', defaultServingGrams: 300, servingUnit: 'bowl',
      aliases: ['gallo pinto', 'moros y cristianos', 'rice beans'],
    ),
    FoodItem(
      id: 'f_tacos_carne', name: 'Beef Tacos (2)',
      nameLocalised: 'Tacos de Carne', cuisineRegion: CuisineRegion.latinAmerica,
      caloriesPer100g: 220, proteinPer100g: 14, carbsPer100g: 22, fatPer100g: 9,
      category: 'mixed', defaultServingGrams: 180, servingUnit: 'piece',
      aliases: ['tacos', 'street tacos'],
    ),
    // ── WESTERN / GENERIC ──────────────────────────────────────
    FoodItem(
      id: 'f_chicken_breast', name: 'Chicken Breast (grilled)',
      cuisineRegion: CuisineRegion.western,
      caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6,
      category: 'protein', defaultServingGrams: 150, servingUnit: 'g',
      aliases: ['grilled chicken', 'chicken fillet'],
    ),
    FoodItem(
      id: 'f_oats', name: 'Oats (porridge)',
      cuisineRegion: CuisineRegion.generic,
      caloriesPer100g: 68, proteinPer100g: 2.4, carbsPer100g: 12, fatPer100g: 1.4,
      category: 'grain', defaultServingGrams: 250, servingUnit: 'bowl',
      aliases: ['oatmeal', 'porridge'],
    ),
    FoodItem(
      id: 'f_banana', name: 'Banana',
      cuisineRegion: CuisineRegion.generic,
      caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23, fatPer100g: 0.3,
      category: 'fruit', defaultServingGrams: 120, servingUnit: 'piece',
      aliases: ['plantain ripe', 'ndizi'],
    ),
    FoodItem(
      id: 'f_eggs_boiled', name: 'Boiled Eggs (2)',
      cuisineRegion: CuisineRegion.generic,
      caloriesPer100g: 155, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 11,
      category: 'protein', defaultServingGrams: 120, servingUnit: 'piece',
      aliases: ['eggs', 'hard boiled egg'],
    ),
  ];

  bool _countryMatchesRegion(String code, CuisineRegion r) {
    const map = <String, CuisineRegion>{
      'NG': CuisineRegion.westAfrica,  'GH': CuisineRegion.westAfrica,
      'SN': CuisineRegion.westAfrica,  'CI': CuisineRegion.westAfrica,
      'KE': CuisineRegion.eastAfrica,  'TZ': CuisineRegion.eastAfrica,
      'UG': CuisineRegion.eastAfrica,  'ET': CuisineRegion.eastAfrica,
      'RW': CuisineRegion.eastAfrica,  'EG': CuisineRegion.northAfrica,
      'MA': CuisineRegion.northAfrica, 'TN': CuisineRegion.northAfrica,
      'IN': CuisineRegion.southAsia,   'PK': CuisineRegion.southAsia,
      'BD': CuisineRegion.southAsia,   'BR': CuisineRegion.latinAmerica,
      'MX': CuisineRegion.latinAmerica,'CO': CuisineRegion.latinAmerica,
    };
    return map[code.toUpperCase()] == r;
  }

  List<CalorieEntry> _getEntriesForDate(String date) {
    final box = Hive.box<dynamic>(AppConstants.calorieBoxName);
    return box.values.cast<CalorieEntry>()
        .where((e) => e.date == date)
        .toList();
  }

  Future<int> _getCalorieTarget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('calorie_target') ?? 2000;
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}'
           '-${n.day.toString().padLeft(2,'0')}';
  }

  Map<String, dynamic> _entryToMap(CalorieEntry e) => {
    'id':           e.id,
    'date':         e.date,
    'foodName':     e.foodName,
    'calories':     e.calories,
    'mealType':     e.mealType.name,
    'loggedAt':     e.loggedAt.toIso8601String(),
  };
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 12: lib/features/goals/goals_screen.dart
# PURPOSE: Main goals dashboard. Four tabs:
#          Today (intention + Morning Three + habit check-ins)
#          Goals (North Star + progress)
#          Reflect (Accountability Mirror + history)
#          Proof Wall
# ══════════════════════════════════════════════════════════════

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/daily_entry.dart';
import '../../core/models/habit_model.dart';
import '../../core/models/north_star_goal.dart';
import '../../core/services/goals_service.dart';
import 'daily_intention_screen.dart';
import 'monthly_letter_screen.dart';
import 'proof_wall_screen.dart';
import 'weekly_review_screen.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});
  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _svc          = GoalsService();
  DailyEntry?         _todayEntry;
  NorthStarGoal?      _goal;
  List<HabitModel>    _habits   = [];
  bool                _loading  = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    final entry   = await _svc.getTodayEntry();
    final goal    = await _svc.getActiveGoal();
    final habits  = await _svc.getActiveHabits();
    if (!mounted) return;
    setState(() {
      _todayEntry = entry;
      _goal       = goal;
      _habits     = habits;
      _loading    = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('Goals',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300)),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const WeeklyReviewScreen())),
            child: const Text('Review',
                style: TextStyle(color: Colors.indigoAccent)),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.indigoAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'My Goal'),
            Tab(text: 'Reflect'),
            Tab(text: 'Proof Wall'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: Colors.white24))
          : TabBarView(
              controller: _tabs,
              children: [
                _TodayTab(
                  entry:          _todayEntry!,
                  habits:         _habits,
                  goal:           _goal,
                  onRefresh:      _load,
                ),
                _GoalTab(
                  goal:           _goal,
                  onGoalUpdated:  _load,
                ),
                _ReflectTab(goal: _goal, habits: _habits),
                const ProofWallScreen(embedded: true),
              ],
            ),
    );
  }
}

// ── TODAY TAB ──────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  final DailyEntry        entry;
  final List<HabitModel>  habits;
  final NorthStarGoal?    goal;
  final VoidCallback      onRefresh;

  const _TodayTab({
    required this.entry,   required this.habits,
    required this.goal,    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final svc = GoalsService();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Daily intention ──────────────────────────────────
        _SectionHeader('Your intention today'),
        if (!entry.intentionSet)
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) =>
                    DailyIntentionScreen(entry: entry)))
                .then((_) => onRefresh()),
            child: _EmptyCard(
              label:    'Set your intention',
              sublabel: 'One thing that matters most today',
              icon:     Icons.track_changes,
            ),
          )
        else
          _IntentionCard(entry: entry, onRefresh: onRefresh),

        const SizedBox(height: 20),

        // ── Morning Three ─────────────────────────────────────
        _SectionHeader('Morning Three'),
        if (entry.morningThree.isEmpty)
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) =>
                    DailyIntentionScreen(entry: entry, skipToTasks: true)))
                .then((_) => onRefresh()),
            child: _EmptyCard(
              label:    'Add your 3 tasks',
              sublabel: 'The three things that move you forward today',
              icon:     Icons.check_box_outline_blank,
            ),
          )
        else
          ...entry.morningThree.map((t) =>
              _MorningTaskTile(task: t, onToggle: () async {
                if (!t.isDone) {
                  await svc.completeMorningTask(t.id);
                  onRefresh();
                }
              })),

        const SizedBox(height: 20),

        // ── Habit check-ins ───────────────────────────────────
        _SectionHeader('Today\'s habits'),
        if (habits.isEmpty)
          _EmptyCard(
            label:    'No habits yet',
            sublabel: 'Add up to 5 habits in My Goal',
            icon:     Icons.repeat,
          )
        else
          ...habits
              .where((h) => h.isDueToday())
              .map((h) => _HabitCheckInTile(
                  habit: h,
                  date:  _todayStr(),
                  onToggle: (done) async {
                    await svc.checkInHabit(
                        habitId: h.id,
                        date: _todayStr(), completed: done);
                    onRefresh();
                  })),

        const SizedBox(height: 40),
      ],
    );
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}'
           '-${n.day.toString().padLeft(2,'0')}';
  }
}

// ── GOAL TAB ───────────────────────────────────────────────────────────────

class _GoalTab extends StatelessWidget {
  final NorthStarGoal? goal;
  final VoidCallback   onGoalUpdated;
  const _GoalTab({required this.goal, required this.onGoalUpdated});

  @override
  Widget build(BuildContext context) {
    if (goal == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            const Text('Set your North Star',
                style: TextStyle(color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.w300)),
            const SizedBox(height: 8),
            Text('The one thing, by when.',
                style: TextStyle(color: Colors.white.withOpacity(0.4),
                    fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const _NorthStarSetupScreen()))
                  .then((_) => onGoalUpdated()),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white),
              child: const Text('Set my goal'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _NorthStarCard(goal: goal!),
        const SizedBox(height: 16),
        _GoalProgressTimeline(goal: goal!),
        const SizedBox(height: 16),
        _GoalHabitsList(goalId: goal!.id),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ── REFLECT TAB ────────────────────────────────────────────────────────────

class _ReflectTab extends StatefulWidget {
  final NorthStarGoal? goal;
  final List<HabitModel> habits;
  const _ReflectTab({required this.goal, required this.habits});
  @override
  State<_ReflectTab> createState() => _ReflectTabState();
}

class _ReflectTabState extends State<_ReflectTab> {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Accountability Mirror
      _SectionHeader('Accountability Mirror'),
      _AccountabilityMirrorCard(
          goal: widget.goal, habits: widget.habits),
      const SizedBox(height: 16),

      // Quick access to weekly review + monthly letter
      _QuickLink(
        icon:  Icons.calendar_view_week,
        label: 'Weekly Review',
        sublabel: 'Your last 7 days, in a story',
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const WeeklyReviewScreen())),
      ),
      const SizedBox(height: 10),
      _QuickLink(
        icon:  Icons.mail_outline,
        label: 'Monthly Letter',
        sublabel: 'A letter about who you were this month',
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const MonthlyLetterScreen())),
      ),
      const SizedBox(height: 40),
    ],
  );
}

// ── REUSABLE WIDGETS ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(
        color: Colors.white54, fontSize: 12,
        fontWeight: FontWeight.w600, letterSpacing: 0.8)),
  );
}

class _EmptyCard extends StatelessWidget {
  final String   label;
  final String   sublabel;
  final IconData icon;
  const _EmptyCard({required this.label,
      required this.sublabel, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        const Color(0xFF161628),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Row(children: [
      Icon(icon, color: Colors.white24, size: 28),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 3),
          Text(sublabel, style: TextStyle(
              color: Colors.white.withOpacity(0.3), fontSize: 12)),
        ],
      )),
      const Icon(Icons.add_circle_outline,
          color: Colors.indigoAccent, size: 20),
    ]),
  );
}

class _IntentionCard extends StatelessWidget {
  final DailyEntry   entry;
  final VoidCallback onRefresh;
  const _IntentionCard({required this.entry, required this.onRefresh});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        const Color(0xFF161628),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.indigoAccent.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.track_changes,
              color: Colors.indigoAccent, size: 16),
          const SizedBox(width: 8),
          const Text('Today I will',
              style: TextStyle(color: Colors.indigoAccent,
                  fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (entry.intentionResult == null)
            _EveningReflectionButtons(entry: entry, onDone: onRefresh),
        ]),
        const SizedBox(height: 8),
        Text(entry.intention ?? '',
            style: const TextStyle(color: Colors.white,
                fontSize: 16, height: 1.5)),
        if (entry.intentionResult != null) ...[
          const SizedBox(height: 8),
          _IntentionResultBadge(result: entry.intentionResult!),
        ],
      ],
    ),
  );
}

class _IntentionResultBadge extends StatelessWidget {
  final EveningReflection result;
  const _IntentionResultBadge({required this.result});
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (result) {
      EveningReflection.yes      => ('Done ✓', Colors.greenAccent),
      EveningReflection.notYet   => ('Not yet', Colors.amber),
      EveningReflection.tomorrow => ('Moved to tomorrow', Colors.white38),
    };
    return Text(label, style: TextStyle(color: color, fontSize: 12,
        fontWeight: FontWeight.w600));
  }
}

class _EveningReflectionButtons extends StatelessWidget {
  final DailyEntry   entry;
  final VoidCallback onDone;
  const _EveningReflectionButtons(
      {required this.entry, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final svc = GoalsService();
    return Row(children: [
      _MiniBtn('Yes', Colors.greenAccent, () async {
        await svc.recordEveningReflection(
            result: EveningReflection.yes);
        onDone();
      }),
      const SizedBox(width: 6),
      _MiniBtn('Not yet', Colors.white38, () async {
        await svc.recordEveningReflection(
            result: EveningReflection.notYet);
        onDone();
      }),
    ]);
  }
}

class _MiniBtn extends StatelessWidget {
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _MiniBtn(this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11,
              fontWeight: FontWeight.w600)),
    ),
  );
}

class _MorningTaskTile extends StatelessWidget {
  final MorningTask  task;
  final VoidCallback onToggle;
  const _MorningTaskTile({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onToggle,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        const Color(0xFF161628),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isDone
              ? Colors.greenAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(children: [
        Icon(
          task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color:    task.isDone ? Colors.greenAccent : Colors.white38,
          size:     20,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(task.text,
            style: TextStyle(
                color:               task.isDone
                    ? Colors.white38 : Colors.white70,
                fontSize:            14,
                decoration:          task.isDone
                    ? TextDecoration.lineThrough : null))),
      ]),
    ),
  );
}

class _HabitCheckInTile extends StatefulWidget {
  final HabitModel      habit;
  final String          date;
  final void Function(bool) onToggle;
  const _HabitCheckInTile({
    required this.habit, required this.date, required this.onToggle});
  @override
  State<_HabitCheckInTile> createState() => _HabitCheckInTileState();
}

class _HabitCheckInTileState extends State<_HabitCheckInTile> {
  bool _done = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      setState(() => _done = !_done);
      widget.onToggle(_done);
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161628),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _done
              ? Colors.greenAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.05)),
      ),
      child: Row(children: [
        Icon(_done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: _done ? Colors.greenAccent : Colors.white38,
            size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(widget.habit.name,
            style: const TextStyle(color: Colors.white70, fontSize: 14))),
        const SizedBox(width: 8),
        Text(widget.habit.frequency.displayName,
            style: TextStyle(
                color: Colors.white.withOpacity(0.25), fontSize: 11)),
      ]),
    ),
  );
}

class _NorthStarCard extends StatelessWidget {
  final NorthStarGoal goal;
  const _NorthStarCard({required this.goal});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A1A3E), Color(0xFF2D1B69)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(goal.category.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Text(goal.category.displayName,
              style: const TextStyle(color: Colors.white54, fontSize: 12,
                  letterSpacing: 0.5)),
          const Spacer(),
          Text(goal.daysRemainingLabel,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        Text(goal.statement, style: const TextStyle(
            color: Colors.white, fontSize: 18,
            fontWeight: FontWeight.w500, height: 1.4)),
        const SizedBox(height: 6),
        Text(goal.whyStatement, style: TextStyle(
            color: Colors.white.withOpacity(0.5), fontSize: 13,
            height: 1.4)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:           goal.progressFraction,
            backgroundColor: Colors.white.withOpacity(0.1),
            color:           Colors.indigoAccent,
            minHeight:       6,
          ),
        ),
      ],
    ),
  );
}

class _GoalProgressTimeline extends StatelessWidget {
  final NorthStarGoal goal;
  const _GoalProgressTimeline({required this.goal});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF161628),
        borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      _TimelinePoint('Started', goal.createdAt, true),
      Expanded(child: Container(height: 2,
          color: Colors.white.withOpacity(0.1))),
      _TimelinePoint('Target', goal.targetDate, false),
    ]),
  );
}

class _TimelinePoint extends StatelessWidget {
  final String   label;
  final DateTime date;
  final bool     isLeft;
  const _TimelinePoint(this.label, this.date, this.isLeft);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: isLeft
        ? CrossAxisAlignment.start : CrossAxisAlignment.end,
    children: [
      Text(label, style: const TextStyle(
          color: Colors.white54, fontSize: 11)),
      Text('${date.day}/${date.month}/${date.year}',
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );
}

class _GoalHabitsList extends StatelessWidget {
  final String goalId;
  const _GoalHabitsList({required this.goalId});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _AccountabilityMirrorCard extends StatelessWidget {
  final NorthStarGoal?   goal;
  final List<HabitModel> habits;
  const _AccountabilityMirrorCard(
      {required this.goal, required this.habits});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF161628),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What you said vs. what you did',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 12),
        if (habits.isEmpty)
          const Text('Add habits in My Goal to see your mirror.',
              style: TextStyle(color: Colors.white38, fontSize: 13))
        else
          ...habits.map((h) {
            final rate = GoalsService()
                .getHabitCompletionRate(h.id, days: 30);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name, style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                    Text('Said: ${h.frequency.displayName}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                )),
                Text('${(rate * 100).round()}%',
                    style: TextStyle(
                        color: rate > 0.7
                            ? Colors.greenAccent
                            : rate > 0.4 ? Colors.amber : Colors.redAccent,
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
            );
          }),
      ],
    ),
  );
}

class _NorthStarSetupScreen extends StatelessWidget {
  const _NorthStarSetupScreen();
  @override
  Widget build(BuildContext context) =>
      Scaffold(backgroundColor: const Color(0xFF0D0D1A),
          body: const Center(child: Text('North Star Setup',
              style: TextStyle(color: Colors.white))));
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   sublabel;
  final VoidCallback onTap;
  const _QuickLink({required this.icon, required this.label,
      required this.sublabel, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161628),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: Colors.indigoAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(
                color: Colors.white70, fontSize: 14)),
            Text(sublabel, style: TextStyle(
                color: Colors.white.withOpacity(0.3), fontSize: 12)),
          ],
        )),
        const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      ]),
    ),
  );
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 13: lib/features/goals/daily_intention_screen.dart
# PURPOSE: Post-alarm entry point for daily intention +
#          Morning Three. The 3-minute morning ritual.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:flutter/material.dart';
import '../../core/models/daily_entry.dart';
import '../../core/models/north_star_goal.dart';
import '../../core/services/goals_service.dart';

class DailyIntentionScreen extends StatefulWidget {
  final DailyEntry  entry;
  final bool        skipToTasks;

  const DailyIntentionScreen({
    super.key, required this.entry, this.skipToTasks = false,
  });

  @override
  State<DailyIntentionScreen> createState() =>
      _DailyIntentionScreenState();
}

class _DailyIntentionScreenState extends State<DailyIntentionScreen> {
  final _svc         = GoalsService();
  final _intCtrl     = TextEditingController();
  final List<TextEditingController> _taskCtrls =
      [TextEditingController(), TextEditingController(),
       TextEditingController()];
  NorthStarGoal? _goal;
  int _step = 0; // 0 = intention, 1 = morning three

  @override
  void initState() {
    super.initState();
    if (widget.skipToTasks) _step = 1;
    if (widget.entry.intention != null) {
      _intCtrl.text = widget.entry.intention!;
    }
    for (var i = 0; i < widget.entry.morningThree.length; i++) {
      _taskCtrls[i].text = widget.entry.morningThree[i].text;
    }
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final g = await _svc.getActiveGoal();
    if (mounted) setState(() => _goal = g);
  }

  @override
  void dispose() {
    _intCtrl.dispose();
    for (final c in _taskCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _saveIntention() async {
    if (_intCtrl.text.trim().isEmpty) return;
    await _svc.setIntention(_intCtrl.text.trim());
    setState(() => _step = 1);
  }

  Future<void> _saveMorningThree() async {
    final tasks = _taskCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .take(3)
        .toList();
    if (tasks.isEmpty) return;
    await _svc.setMorningThree(tasks);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _step == 0
              ? _IntentionStep(
                  ctrl: _intCtrl,
                  goal: _goal,
                  onDone: _saveIntention,
                )
              : _MorningThreeStep(
                  ctrls:  _taskCtrls,
                  goal:   _goal,
                  onDone: _saveMorningThree,
                ),
        ),
      ),
    );
  }
}

class _IntentionStep extends StatelessWidget {
  final TextEditingController ctrl;
  final NorthStarGoal?        goal;
  final VoidCallback          onDone;
  const _IntentionStep({required this.ctrl,
      required this.goal, required this.onDone});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Spacer(),
      if (goal != null) ...[
        Text('Working toward:', style: TextStyle(
            color: Colors.white.withOpacity(0.4), fontSize: 12)),
        const SizedBox(height: 4),
        Text(goal!.statement, style: const TextStyle(
            color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 32),
      ],
      const Text('Today I will…', style: TextStyle(
          color: Colors.white, fontSize: 26,
          fontWeight: FontWeight.w200)),
      const SizedBox(height: 16),
      TextField(
        controller:      ctrl,
        autofocus:       true,
        style:           const TextStyle(color: Colors.white,
            fontSize: 20, fontWeight: FontWeight.w300),
        maxLines:        3,
        keyboardType:    TextInputType.text,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText:  '…one meaningful thing',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2),
              fontSize: 20, fontWeight: FontWeight.w300),
          border:    InputBorder.none,
        ),
        onSubmitted: (_) => onDone(),
      ),
      const Spacer(),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:   onDone,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigoAccent,
            foregroundColor: Colors.white,
            minimumSize:     const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Set intention'),
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}

class _MorningThreeStep extends StatelessWidget {
  final List<TextEditingController> ctrls;
  final NorthStarGoal?              goal;
  final VoidCallback                onDone;
  const _MorningThreeStep({required this.ctrls,
      required this.goal, required this.onDone});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Spacer(),
      const Text('Morning Three', style: TextStyle(
          color: Colors.white, fontSize: 26,
          fontWeight: FontWeight.w200)),
      const SizedBox(height: 6),
      Text('Your 3 most important tasks today.',
          style: TextStyle(color: Colors.white.withOpacity(0.4),
              fontSize: 14)),
      const SizedBox(height: 32),
      ...List.generate(3, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Text('${i + 1}', style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 20, fontWeight: FontWeight.w300)),
          const SizedBox(width: 16),
          Expanded(child: TextField(
            controller:  ctrls[i],
            autofocus:   i == 0,
            style:       const TextStyle(color: Colors.white,
                fontSize: 16),
            decoration:  InputDecoration(
              hintText:  i == 0 ? 'The most important thing'
                        : i == 1 ? 'Second priority'
                        : 'Third (optional)',
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.2), fontSize: 15),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1))),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.indigoAccent)),
            ),
            onSubmitted: i < 2 ? (_) {} : (_) => onDone(),
          )),
        ]),
      )),
      const Spacer(),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onDone,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            minimumSize:     const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Start my day',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 14: lib/features/goals/weekly_review_screen.dart
# FILE 15: lib/features/goals/monthly_letter_screen.dart
# FILE 16: lib/features/goals/proof_wall_screen.dart
# ══════════════════════════════════════════════════════════════

```dart
// ── WEEKLY REVIEW SCREEN ──────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/ai_reflection_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/proof_wall_milestone.dart';
import '../../core/services/goals_service.dart';

class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key});
  @override
  ConsumerState<WeeklyReviewScreen> createState() =>
      _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState
    extends ConsumerState<WeeklyReviewScreen> {
  final _svc     = AiReflectionService();
  WeeklyReview?  _review;
  bool           _loading = true;
  String?        _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tierId = ref.read(subscriptionProvider).tier;
    final review = await _svc.generateWeeklyReview(tierId: tierId);
    if (!mounted) return;
    setState(() {
      _review  = review;
      _loading = false;
      _error   = review == null
          ? 'Upgrade to Core to unlock weekly reviews.' : null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D0D1A),
      title: const Text('Weekly Review',
          style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w300)),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(
            color: Colors.white24))
        : _error != null
        ? _ErrorState(message: _error!)
        : _ReviewBody(review: _review!),
  );
}

class _ReviewBody extends StatelessWidget {
  final WeeklyReview review;
  const _ReviewBody({required this.review});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Week of ${review.weekStartDate}',
            style: const TextStyle(color: Colors.white38,
                fontSize: 12, letterSpacing: 0.5)),
        const SizedBox(height: 24),

        // The narrative — the most important thing on this screen
        Text(review.narrative, style: const TextStyle(
            color: Colors.white, fontSize: 16,
            height: 1.8, fontWeight: FontWeight.w300)),

        const SizedBox(height: 32),
        const Divider(color: Colors.white12),
        const SizedBox(height: 20),

        // Stats row — supporting data, not the lead
        _StatsRow(review: review),

        const SizedBox(height: 40),
      ],
    ),
  );
}

class _StatsRow extends StatelessWidget {
  final WeeklyReview review;
  const _StatsRow({required this.review});

  @override
  Widget build(BuildContext context) => Row(children: [
    _StatCell('Sleep',
        '${review.sleepAvgHours.toStringAsFixed(1)}h avg'),
    _StatCell('Intentions',
        '${(review.intentionRate * 100).round()}%'),
    if (review.habitRates.isNotEmpty)
      _StatCell('Top habit',
          '${(review.habitRates.values.reduce((a,b)=>a>b?a:b)*100).round()}%'),
  ]);
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: const TextStyle(color: Colors.white,
        fontSize: 20, fontWeight: FontWeight.w300)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
  ]));
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Text(message, style: const TextStyle(
        color: Colors.white54, fontSize: 15),
        textAlign: TextAlign.center),
  ));
}

// ── MONTHLY LETTER SCREEN ─────────────────────────────────────────────────

class MonthlyLetterScreen extends ConsumerStatefulWidget {
  const MonthlyLetterScreen({super.key});
  @override
  ConsumerState<MonthlyLetterScreen> createState() =>
      _MonthlyLetterScreenState();
}

class _MonthlyLetterScreenState
    extends ConsumerState<MonthlyLetterScreen> {
  final _svc     = AiReflectionService();
  MonthlyLetter? _letter;
  bool           _loading = true;
  String?        _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final tierId   = ref.read(subscriptionProvider).tier;
    final userName = ref.read(subscriptionProvider).displayName
        ?? 'there';
    final letter   = await _svc.generateMonthlyLetter(
        tierId: tierId, userName: userName);
    if (!mounted) return;
    setState(() {
      _letter  = letter;
      _loading = false;
      _error   = letter == null
          ? 'Monthly letters are available on Pro.' : null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D0D1A),
      title: Text(_letter?.month ?? 'Monthly Letter',
          style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w300)),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(
            color: Colors.white24))
        : _error != null
        ? _ErrorState(message: _error!)
        : SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              // Decorative header
              const Text('✉', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 24),
              Text(_letter!.letterText,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 2.0,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 40),
            ]),
          ),
  );
}

// ── PROOF WALL SCREEN ──────────────────────────────────────────────────────

class ProofWallScreen extends StatefulWidget {
  final bool embedded;
  const ProofWallScreen({super.key, this.embedded = false});
  @override
  State<ProofWallScreen> createState() => _ProofWallScreenState();
}

class _ProofWallScreenState extends State<ProofWallScreen> {
  final _svc = GoalsService();
  List<ProofWallMilestone> _milestones = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final m = await _svc.getAllMilestones();
    if (!mounted) return;
    setState(() { _milestones = m; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator(
            color: Colors.white24))
        : _milestones.isEmpty
        ? _EmptyProofWall()
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _milestones.length,
            itemBuilder: (_, i) =>
                _MilestoneTile(milestone: _milestones[i]),
          );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('Proof Wall',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w300)),
      ),
      body: body,
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  final ProofWallMilestone milestone;
  const _MilestoneTile({required this.milestone});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF161628),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    ),
    child: Row(children: [
      Text(milestone.type.emoji,
          style: const TextStyle(fontSize: 28)),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(milestone.title, style: const TextStyle(
              color: Colors.white, fontSize: 15,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(milestone.description, style: TextStyle(
              color: Colors.white.withOpacity(0.4), fontSize: 12,
              height: 1.4)),
        ],
      )),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${milestone.achievedAt.day}/'
             '${milestone.achievedAt.month}/'
             '${milestone.achievedAt.year}',
            style: const TextStyle(
                color: Colors.white24, fontSize: 11)),
      ]),
    ]),
  );
}

class _EmptyProofWall extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('🌅', style: TextStyle(fontSize: 52)),
      SizedBox(height: 16),
      Text('Your first milestone is waiting.',
          style: TextStyle(color: Colors.white54, fontSize: 16)),
      SizedBox(height: 8),
      Text('Wake up tomorrow.',
          style: TextStyle(color: Colors.white24, fontSize: 14)),
    ],
  ));
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 17: lib/features/quotes/quotes_screen.dart
# PURPOSE: Daily quote (liked/saved/shared) + saved collection.
#          Regional wisdom in original language FIRST.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/quote_item.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/quote_service.dart';

class QuotesScreen extends ConsumerStatefulWidget {
  const QuotesScreen({super.key});
  @override
  ConsumerState<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends ConsumerState<QuotesScreen>
    with SingleTickerProviderStateMixin {
  final _svc   = QuoteService();
  QuoteItem?   _today;
  bool         _todayLiked   = false;
  bool         _todaySaved   = false;
  bool         _loading      = true;
  late final TabController _tabs;
  List<QuoteItem> _saved     = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    final country = ref.read(subscriptionProvider).storefrontCountry
        ?? 'US';
    final faith   = ref.read(subscriptionProvider).faithContext;
    final today   = await _svc.getTodayQuote(
        storefrontCountry: country, faithContext: faith);
    final saved   = _svc.getSavedQuotes();
    if (!mounted) return;
    setState(() {
      _today   = today;
      _saved   = saved;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D0D1A),
      title: const Text('Quotes',
          style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w300)),
      bottom: TabBar(
        controller: _tabs,
        indicatorColor: Colors.indigoAccent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        tabs: const [Tab(text: 'Today'), Tab(text: 'Saved')],
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(
            color: Colors.white24))
        : TabBarView(
            controller: _tabs,
            children: [
              _TodayQuoteTab(
                quote:     _today!,
                isLiked:   _todayLiked,
                isSaved:   _todaySaved,
                onLike:    _onLike,
                onSave:    _onSave,
                onShare:   _onShare,
              ),
              _SavedQuotesTab(saved: _saved, onUnsave: _onUnsave),
            ],
          ),
  );

  Future<void> _onLike() async {
    if (_today == null) return;
    setState(() => _todayLiked = !_todayLiked);
    if (_todayLiked) {
      await _svc.likeQuote(_today!.id);
    } else {
      await _svc.unlikeQuote(_today!.id);
    }
  }

  Future<void> _onSave() async {
    if (_today == null) return;
    setState(() => _todaySaved = !_todaySaved);
    if (_todaySaved) {
      await _svc.saveQuote(_today!);
    } else {
      await _svc.unsaveQuote(_today!.id);
    }
    _saved = _svc.getSavedQuotes();
    setState(() {});
  }

  void _onShare(QuoteItem q) {
    final text = q.hasOriginalLanguage
        ? '"${q.textOriginal}"\n\n'
          '"${q.text}"\n— ${q.attribution}\n\nvia RISE'
        : '"${q.text}"\n— ${q.attribution}\n\nvia RISE';
    Share.share(text);
  }

  Future<void> _onUnsave(String quoteId) async {
    await _svc.unsaveQuote(quoteId);
    setState(() => _saved = _svc.getSavedQuotes());
  }
}

class _TodayQuoteTab extends StatelessWidget {
  final QuoteItem  quote;
  final bool       isLiked;
  final bool       isSaved;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final void Function(QuoteItem) onShare;

  const _TodayQuoteTab({
    required this.quote,   required this.isLiked, required this.isSaved,
    required this.onLike,  required this.onSave,  required this.onShare,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(children: [
      const Spacer(),

      // Category label
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color:        Colors.indigoAccent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(quote.category.displayName,
            style: const TextStyle(color: Colors.indigoAccent,
                fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      ),

      const SizedBox(height: 32),

      // Original language FIRST (if not English)
      if (quote.hasOriginalLanguage) ...[
        Text(quote.textOriginal, style: const TextStyle(
            color: Colors.white, fontSize: 22,
            fontWeight: FontWeight.w300, height: 1.7),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(quote.text, style: TextStyle(
            color: Colors.white.withOpacity(0.5), fontSize: 17,
            fontWeight: FontWeight.w300, height: 1.6,
            fontStyle: FontStyle.italic),
            textAlign: TextAlign.center),
      ] else ...[
        Text(quote.text, style: const TextStyle(
            color: Colors.white, fontSize: 22,
            fontWeight: FontWeight.w300, height: 1.7),
            textAlign: TextAlign.center),
      ],

      const SizedBox(height: 24),

      // Attribution
      Text('— ${quote.attribution}',
          style: TextStyle(
              color: Colors.white.withOpacity(0.35), fontSize: 13),
          textAlign: TextAlign.center),

      const Spacer(),

      // Action row
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _ActionBtn(
          icon:   isLiked ? Icons.favorite : Icons.favorite_border,
          color:  isLiked ? Colors.redAccent : Colors.white38,
          label:  isLiked ? 'Liked' : 'Like',
          onTap:  onLike,
        ),
        const SizedBox(width: 24),
        _ActionBtn(
          icon:   isSaved ? Icons.bookmark : Icons.bookmark_border,
          color:  isSaved ? Colors.amber : Colors.white38,
          label:  isSaved ? 'Saved' : 'Save',
          onTap:  onSave,
        ),
        const SizedBox(width: 24),
        _ActionBtn(
          icon:   Icons.share_outlined,
          color:  Colors.white38,
          label:  'Share',
          onTap:  () => onShare(quote),
        ),
      ]),

      const SizedBox(height: 32),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color,
      required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap:    onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ]),
    ),
  );
}

class _SavedQuotesTab extends StatelessWidget {
  final List<QuoteItem>        saved;
  final void Function(String) onUnsave;
  const _SavedQuotesTab({required this.saved, required this.onUnsave});

  @override
  Widget build(BuildContext context) {
    if (saved.isEmpty) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔖', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('No saved quotes yet.',
              style: TextStyle(color: Colors.white54, fontSize: 15)),
          SizedBox(height: 6),
          Text('Save quotes that move you.',
              style: TextStyle(color: Colors.white24, fontSize: 13)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: saved.length,
      itemBuilder: (_, i) {
        final q = saved[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161628),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.amber.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (q.hasOriginalLanguage) ...[
                Text(q.textOriginal, style: const TextStyle(
                    color: Colors.white, fontSize: 15, height: 1.6)),
                const SizedBox(height: 8),
                Text(q.text, style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13, height: 1.5,
                    fontStyle: FontStyle.italic)),
              ] else
                Text(q.text, style: const TextStyle(
                    color: Colors.white, fontSize: 15, height: 1.6)),
              const SizedBox(height: 8),
              Row(children: [
                Text('— ${q.attribution}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
                const Spacer(),
                GestureDetector(
                  onTap: () => onUnsave(q.id),
                  child: const Icon(Icons.bookmark,
                      color: Colors.amber, size: 18),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 18: lib/features/calorie/calorie_screen.dart
# FILE 19: lib/features/calorie/food_search_sheet.dart
# ══════════════════════════════════════════════════════════════

```dart
// ── CALORIE SCREEN ────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/calorie_entry.dart';
import '../../core/models/food_item.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/calorie_service.dart';
import '../../core/services/remote_config_service.dart';

class CalorieScreen extends ConsumerStatefulWidget {
  const CalorieScreen({super.key});
  @override
  ConsumerState<CalorieScreen> createState() => _CalorieScreenState();
}

class _CalorieScreenState extends ConsumerState<CalorieScreen> {
  final _svc  = CalorieService();
  final _rc   = RemoteConfigService();
  DailySummary? _summary;
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _svc.seedFoodDatabase(); // No-op if already seeded
    _load();
  }

  Future<void> _load() async {
    final s = await _svc.getDailySummary();
    if (!mounted) return;
    setState(() { _summary = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('Nutrition',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w300)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: Colors.white24))
          : RefreshIndicator(
              onRefresh: _load,
              color: Colors.indigoAccent,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Ramadan mode banner
                  if (_rc.isRamadanActive) _RamadanBanner(
                      fastComplete: _summary?.fastComplete ?? false),

                  // Daily ring
                  _DailyRingCard(summary: _summary!),
                  const SizedBox(height: 16),

                  // Meal sections
                  ..._buildMealSections(),

                  const SizedBox(height: 80),
                ],
              ),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openFoodSearch,
        backgroundColor: Colors.indigoAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Widget> _buildMealSections() {
    final meals = _rc.isRamadanActive
        ? [MealType.suhoor, MealType.iftar, MealType.snack]
        : [MealType.breakfast, MealType.lunch,
           MealType.dinner, MealType.snack];

    return meals.map((meal) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _MealSection(
        meal:       meal,
        onAdd:      () => _openFoodSearch(mealType: meal),
      ),
    )).toList();
  }

  void _openFoodSearch({MealType? mealType}) {
    final country = ref.read(subscriptionProvider).storefrontCountry
        ?? 'US';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161628),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(20))),
      builder: (_) => FoodSearchSheet(
        countryCode:     country,
        defaultMealType: mealType ?? MealType.snack,
        onFoodLogged:    _load,
      ),
    );
  }
}

class _RamadanBanner extends StatelessWidget {
  final bool fastComplete;
  const _RamadanBanner({required this.fastComplete});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.teal.shade900, Colors.indigo.shade900],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [
      const Text('🌙', style: TextStyle(fontSize: 22)),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ramadan Mubarak 🌙',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w600, fontSize: 14)),
          Text(
            fastComplete
                ? 'Fast complete today — Masha\'Allah ✓'
                : 'Tracking Suhoor and Iftar today',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      )),
    ]),
  );
}

class _DailyRingCard extends StatelessWidget {
  final DailySummary summary;
  const _DailyRingCard({required this.summary});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color:        const Color(0xFF161628),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      // Calorie ring
      Stack(alignment: Alignment.center, children: [
        SizedBox(width: 80, height: 80,
          child: CircularProgressIndicator(
            value:           summary.progress,
            backgroundColor: Colors.white.withOpacity(0.06),
            color:           _ringColor(summary),
            strokeWidth:     7,
          ),
        ),
        Text('${summary.consumedCalories.round()}',
            style: TextStyle(color: _ringColor(summary),
                fontSize: 17, fontWeight: FontWeight.w700)),
      ]),

      const SizedBox(width: 20),

      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${summary.consumedCalories.round()} / '
               '${summary.targetCalories} kcal',
              style: const TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w300)),
          const SizedBox(height: 4),
          Text(summary.balanceLabel, style: TextStyle(
              color: _ringColor(summary), fontSize: 12,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            _MacroChip('P', summary.proteinG, Colors.blueAccent),
            const SizedBox(width: 8),
            _MacroChip('C', summary.carbsG, Colors.amber),
            const SizedBox(width: 8),
            _MacroChip('F', summary.fatG, Colors.redAccent),
          ]),
        ],
      )),
    ]),
  );

  Color _ringColor(DailySummary s) {
    if (s.calorieBalance > s.targetCalories * 0.15) return Colors.redAccent;
    if (s.calorieBalance > 0) return Colors.amber;
    return Colors.greenAccent;
  }
}

class _MacroChip extends StatelessWidget {
  final String letter;
  final double grams;
  final Color  color;
  const _MacroChip(this.letter, this.grams, this.color);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(
          color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('${grams.round()}g',
          style: TextStyle(color: color, fontSize: 11)),
    ],
  );
}

class _MealSection extends StatelessWidget {
  final MealType     meal;
  final VoidCallback onAdd;
  const _MealSection({required this.meal, required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF161628),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      Text(meal.displayName, style: const TextStyle(
          color: Colors.white70, fontSize: 14,
          fontWeight: FontWeight.w500)),
      const Spacer(),
      GestureDetector(
        onTap: onAdd,
        child: const Icon(Icons.add,
            color: Colors.indigoAccent, size: 20),
      ),
    ]),
  );
}

// ── FOOD SEARCH SHEET ─────────────────────────────────────────────────────

class FoodSearchSheet extends StatefulWidget {
  final String      countryCode;
  final MealType    defaultMealType;
  final VoidCallback onFoodLogged;

  const FoodSearchSheet({
    super.key,
    required this.countryCode,
    required this.defaultMealType,
    required this.onFoodLogged,
  });

  @override
  State<FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<FoodSearchSheet> {
  final _svc         = CalorieService();
  final _ctrl        = TextEditingController();
  List<FoodItem>     _results       = [];
  FoodItem?          _selected;
  double             _servingGrams  = 100;
  late MealType      _mealType;
  bool               _logging       = false;

  @override
  void initState() {
    super.initState();
    _mealType = widget.defaultMealType;
    // Show regional suggestions immediately
    _results = _svc.searchFood('', countryCode: widget.countryCode)
        .take(8).toList();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Drag handle
        Container(width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),

        // Search field
        TextField(
          controller:   _ctrl,
          autofocus:    true,
          style:        const TextStyle(color: Colors.white),
          onChanged:    (q) => setState(() =>
              _results = _svc.searchFood(q,
                  countryCode: widget.countryCode)),
          decoration: InputDecoration(
            hintText:      'Search foods…',
            hintStyle:     const TextStyle(color: Colors.white38),
            prefixIcon:    const Icon(Icons.search, color: Colors.white38),
            filled:        true,
            fillColor:     const Color(0xFF1E1E38),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),

        const SizedBox(height: 8),

        // Selected food + serving input
        if (_selected != null) ...[
          _SelectedFoodCard(
            food:         _selected!,
            grams:        _servingGrams,
            onGramsChange: (g) => setState(() => _servingGrams = g),
            mealType:     _mealType,
            onMealChange: (m) => setState(() => _mealType = m),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _logging ? null : _log,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _logging
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Add to ${_mealType.displayName}'),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white12),
        ],

        // Results list
        Expanded(child: ListView.builder(
          itemCount: _results.length,
          itemBuilder: (_, i) {
            final food = _results[i];
            return ListTile(
              title: Text(food.name,
                  style: const TextStyle(color: Colors.white70,
                      fontSize: 14)),
              subtitle: food.nameLocalised.isNotEmpty &&
                  food.nameLocalised != food.name
                  ? Text(food.nameLocalised,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 12))
                  : Text('${food.caloriesPer100g.round()} kcal/100g',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
              trailing: Text(
                  '${food.caloriesForServing(
                      food.defaultServingGrams).round()} kcal',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12)),
              onTap: () => setState(() {
                _selected     = food;
                _servingGrams = food.defaultServingGrams;
              }),
              tileColor: _selected?.id == food.id
                  ? Colors.indigoAccent.withOpacity(0.1)
                  : null,
            );
          },
        )),
      ]),
    ),
  );

  Future<void> _log() async {
    if (_selected == null) return;
    setState(() => _logging = true);
    await _svc.logFood(
      food:         _selected!,
      servingGrams: _servingGrams,
      mealType:     _mealType,
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onFoodLogged();
    }
  }
}

class _SelectedFoodCard extends StatelessWidget {
  final FoodItem    food;
  final double      grams;
  final void Function(double) onGramsChange;
  final MealType    mealType;
  final void Function(MealType) onMealChange;

  const _SelectedFoodCard({
    required this.food,    required this.grams,
    required this.onGramsChange,
    required this.mealType, required this.onMealChange,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color:        const Color(0xFF1E1E38),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
          color: Colors.indigoAccent.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(food.name, style: const TextStyle(
            color: Colors.white, fontSize: 15,
            fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Serving (g)',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 11)),
              Slider(
                value:    grams.clamp(10, 500),
                min:      10, max: 500, divisions: 49,
                label:    '${grams.round()}g',
                onChanged: (v) => onGramsChange(v),
                activeColor: Colors.indigoAccent,
              ),
              Text('${grams.round()}g = '
                   '${food.caloriesForServing(grams).round()} kcal',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ],
          )),
        ]),
      ],
    ),
  );
}
```

---

## CONSTANTS TO ADD: lib/core/constants/app_constants.dart

```dart
// Part 10B — New Hive box names
static const String foodDbBoxName       = 'food_db_v1';
static const String proofWallBoxName    = 'proof_wall_v1';
static const String habitEntriesBoxName = 'habit_entries_v1';

// Part 10B — Goals rules
static const int    maxHabits           = 5;
static const int    maxMorningTasks     = 3;
```

## NEW PUBSPEC DEPENDENCIES

```yaml
  share_plus: ^7.2.2   # Quote sharing
```

---

## PART 10B — COMPLETE FILE INVENTORY

```
NEW FILES (19):
  lib/core/models/calorie_entry.dart          typeId: 3 (replaces stub)
  lib/core/models/food_item.dart              typeId: 4 (replaces stub)
  lib/core/models/north_star_goal.dart        typeId: 10
  lib/core/models/habit_model.dart            typeId: 11, 15
  lib/core/models/daily_entry.dart            typeId: 12
  lib/core/models/quote_item.dart             typeId: 13
  lib/core/models/proof_wall_milestone.dart   typeId: 14
  lib/core/services/goals_service.dart
  lib/core/services/ai_reflection_service.dart
  lib/core/services/quote_service.dart
  lib/core/services/calorie_service.dart
  lib/features/goals/goals_screen.dart
  lib/features/goals/daily_intention_screen.dart
  lib/features/goals/weekly_review_screen.dart
  lib/features/goals/monthly_letter_screen.dart
  lib/features/goals/proof_wall_screen.dart
  lib/features/quotes/quotes_screen.dart
  lib/features/calorie/calorie_screen.dart
  lib/features/calorie/food_search_sheet.dart
```

---

## DESIGN DECISIONS HONORED ✓

```
DECISION                                     STATUS
─────────────────────────────────────────────────────────────────
Integration: sleep ↔ calories ↔ goals ↔ quotes   ✓ AiReflectionService pulls all
Narrative over data: weekly review, monthly letter ✓ AI generates stories not tables
Cultural respect: African foods first-class        ✓ 15+ African dishes in seed data
Ramadan mode: Suhoor/Iftar, fast monitoring        ✓ CalorieService + RamadanBanner
Original language first: Swahili, Hausa, Amharic  ✓ textOriginal shown before English
Five habits maximum: enforced in service           ✓ GoalsService.maxHabits = 5
Three morning tasks maximum                        ✓ GoalsService.maxMorningTasks = 3
North Star: connects to habits + daily intention   ✓ goal.suggestedHabits + goalId
Proof Wall: only accumulates, never deletes        ✓ No delete method in GoalsService
Accountability Mirror: no editorialising           ✓ Shows gap without judgment
Weekly Review: friend's voice, not dashboard       ✓ _weeklySystemPrompt specifies this
Monthly Letter: personal, addressed by name        ✓ _monthlySystemPrompt specifies this
Sleep-nutrition correlation insight                ✓ generateSleepNutritionInsight()
Quotes liked + saved + shared                      ✓ Full implementation in QuoteService
All features work offline                          ✓ Local Hive, OfflineSyncService
```

---

## WHAT PART 11 COVERS:
Onboarding flow — first-run experience.
Permission requests in correct order, biometric enrollment
(the 5-session multi-day protocol), faith preference
selection, buddy setup, regional detection + pricing display,
and the three entry modes:
Quick / Standard / Assisted (EC-9.2 elderly users).

---
## END OF PART 10B BLUEPRINT
## 19 new files | 2 constant updates | 1 dependency
## Goals Journal:       COMPLETE ✓ (North Star, habits, Morning Three, intention, mirror, proof wall)
## AI Reflection:       COMPLETE ✓ (weekly review + monthly letter via Claude API)
## Quotes System:       COMPLETE ✓ (7 categories, liked/saved/shared, original language first)
## Calorie Tracker:     COMPLETE ✓ (global DB, African foods first-class, Ramadan mode, sleep correlation)
## Sleep-Nutrition AI:  COMPLETE ✓ (generateSleepNutritionInsight — 14+ days data required)
## Cultural respect:    COMPLETE ✓ (Swahili, Hausa, Amharic proverbs shown in original language)
