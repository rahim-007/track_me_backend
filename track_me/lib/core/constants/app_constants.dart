class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Track Me';
  static const String appVersion = '1.0.0';
  static const String bundleId = 'com.trackme.app';

  // Isar Box Names
  static const String onboardingBox = 'onboarding_box';
  static const String authBox = 'auth_box';
  static const String settingsBox = 'settings_box';
  static const String habitsBox = 'habits_box';
  static const String goalsBox = 'goals_box';
  static const String cacheBox = 'cache_box';

  // Secure Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  // Isar Keys
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // API Timeouts (milliseconds)
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Pagination
  static const int defaultPageSize = 20;

  // Habit Config
  static const int maxHabitsPerDay = 20;
  static const List<String> weekDays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  // Notification IDs
  static const int habitNotificationBaseId = 1000;
  static const int goalNotificationBaseId = 2000;
  static const int weeklyReportNotificationId = 3000;
  static const int motivationNotificationId = 3001;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration pageAnimation = Duration(milliseconds: 300);

  // Motivational Quotes — Dashboard
  static const List<String> motivationalQuotes = [
    'Small habits build extraordinary lives.',
    'Consistency beats motivation every single day.',
    'One percent better every day.',
    'The secret of getting ahead is getting started.',
    'You don\'t rise to the level of your goals, you fall to the level of your systems.',
    'Every action you take is a vote for the person you want to become.',
    'Make it easy to do right and hard to do wrong.',
    'Success is the product of daily habits, not once-in-a-lifetime transformations.',
    'The chains of habit are too light to be felt until they are too heavy to be broken.',
    'We are what we repeatedly do.',
  ];

  // Goal Quotes
  static const List<String> goalQuotes = [
    'A goal without a plan is just a wish.',
    'Goals are dreams with deadlines.',
    'Setting goals is the first step in turning the invisible into the visible.',
    'The trouble with not having a goal is that you can spend your life running up and down the field and never score.',
    'What you get by achieving your goals is not as important as what you become.',
  ];

  // Habit Categories
  static const List<String> habitCategories = [
    'Health',
    'Fitness',
    'Learning',
    'Mindfulness',
    'Productivity',
    'Social',
    'Finance',
    'Other',
  ];

  // Goal Categories
  static const List<String> goalCategories = [
    'Personal',
    'Career',
    'Fitness',
    'Education',
    'Finance',
    'Health',
    'Relationships',
    'Other',
  ];

  // Skip Reasons
  static const List<String> skipReasons = [
    'Feeling Sick',
    'Too Busy',
    'Traveling',
    'Forgot',
    'No Motivation',
    'Other',
  ];

  // Habit Emojis
  static const List<String> habitEmojis = [
    '💧', '🏃', '📚', '🧘', '💪', '🥗', '😴', '✍️',
    '🎯', '🧹', '🎵', '🌿', '💊', '🚴', '🧠', '❤️',
    '🛁', '☀️', '🌙', '📝', '🎨', '🍎', '🧘‍♀️', '🏋️',
  ];

  // Habit Colors (hex)
  static const List<String> habitColors = [
    '#7C3AED', '#6366F1', '#3B82F6', '#06B6D4',
    '#10B981', '#F59E0B', '#EF4444', '#EC4899',
    '#8B5CF6', '#059669', '#0EA5E9', '#14B8A6',
  ];
}
