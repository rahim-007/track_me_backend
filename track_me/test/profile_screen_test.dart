import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/core/theme/app_colors.dart';
import 'package:track_me/core/theme/app_theme.dart';
import 'package:track_me/features/profile/presentation/screens/profile_screen.dart';
import 'package:track_me/features/profile/providers/profile_provider.dart';

void main() {
  final testProfile = UserProfile(
    id: 'user_123',
    name: 'Rahim Ali',
    email: 'rahim@example.com',
    avatarUrl: null,
    currentStreak: 8,
    longestStreak: 14,
    totalCompletedHabits: 25,
    activeGoals: 3,
    createdAt: DateTime(2025, 1, 15),
    totalHabits: 6,
    goalsAchieved: 2,
  );

  const testStats = UserProfileStats(
    currentStreak: 8,
    longestStreak: 14,
    totalCompletedHabits: 25,
    activeGoals: 3,
    totalHabits: 6,
    totalGoals: 5,
    goalsAchieved: 2,
  );

  Widget buildTestableProfileScreen({
    UserProfile? profile,
    UserProfileStats? stats,
    bool isDarkMode = true,
  }) {
    AppColors.isDarkMode = isDarkMode;

    return ProviderScope(
      overrides: [
        profileProvider.overrideWith(
          (ref) => _FakeProfileNotifier(profile ?? testProfile),
        ),
        userProfileStatsProvider.overrideWithValue(stats ?? testStats),
        appVersionProvider.overrideWith(
          (ref) => Future.value('1.2.0'),
        ),
      ],
      child: MaterialApp(
        theme: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: const ProfileScreen(),
      ),
    );
  }

  testWidgets('renders all unified profile sections, hero card and metrics', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestableProfileScreen());
    await tester.pumpAndSettle();

    // 1. Header
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Account, statistics & app preferences'), findsOneWidget);

    // 2. Signature Hero Card
    expect(find.text('TRACK ME MEMBER'), findsOneWidget);
    expect(find.text('Rahim Ali'), findsOneWidget);
    expect(find.text('rahim@example.com'), findsOneWidget);
    expect(find.text('Member since Jan 2025'), findsOneWidget);

    // 3. Metrics Trio Row
    expect(find.text('Current Streak'), findsOneWidget);
    expect(find.text('Habits Done'), findsOneWidget);
    expect(find.text('Goals Active'), findsOneWidget);
    expect(find.text('8'), findsWidgets); // In metric item + badge
    expect(find.text('25'), findsWidgets);

    // 4. Promo Banner
    expect(find.text('Track Me Premium'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);

    // 5. Section Headers
    expect(find.text('ACHIEVEMENTS'), findsOneWidget);
    expect(find.text('LIFETIME STATISTICS'), findsOneWidget);
    expect(find.text('APP PREFERENCES'), findsOneWidget);
    expect(find.text('ACCOUNT & SECURITY'), findsOneWidget);
    expect(find.text('SUPPORT & ABOUT'), findsOneWidget);

    // 6. Settings & Danger Zone
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Notification Center'), findsOneWidget);
    expect(find.text('Edit Profile Information'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Log Out'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Log Out'), findsOneWidget);
  });

  testWidgets('renders properly in light theme mode without errors', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestableProfileScreen(isDarkMode: false));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Rahim Ali'), findsOneWidget);
    expect(find.text('Clean light theme enabled'), findsOneWidget);
  });

  testWidgets('tapping Edit button opens EditProfileDialog with all fields and closes cleanly', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestableProfileScreen());
    await tester.pumpAndSettle();

    // 1. Tap Hero Card Edit button
    final editBtn = find.text('Edit');
    expect(editBtn, findsOneWidget);
    await tester.tap(editBtn);
    await tester.pumpAndSettle();

    // 2. Dialog elements are visible
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Or Choose a Preset Avatar'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Save Profile Changes'), findsOneWidget);

    // 3. Close dialog via close icon
    final closeBtn = find.byIcon(Icons.close_rounded);
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    // 4. Dialog is dismissed
    expect(find.text('Edit Profile'), findsNothing);

    // 5. Test opening via Settings nav tile
    final settingsEditTile = find.text('Edit Profile Information');
    expect(settingsEditTile, findsOneWidget);
    await tester.tap(settingsEditTile);
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsOneWidget);
  });

  testWidgets('EditProfileDialog works safely even if user profile is initially null', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(
            (ref) => _FakeNullableProfileNotifier(),
          ),
          userProfileStatsProvider.overrideWithValue(testStats),
          appVersionProvider.overrideWith((ref) => Future.value('1.2.0')),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap header edit icon
    final editIcon = find.byIcon(Icons.edit_outlined);
    expect(editIcon, findsOneWidget);
    await tester.tap(editIcon);
    await tester.pumpAndSettle();

    // Dialog opens gracefully with empty fields
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Save Profile Changes'), findsOneWidget);
  });

  // ─── Delete Account Tests ─────────────────────────────────────────────────

  testWidgets('Delete Account tile appears in ACCOUNT & SECURITY section', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestableProfileScreen());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Delete Account'),
      400,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.text('Permanently delete your account and data'), findsOneWidget);
  });

  testWidgets('tapping Delete Account shows warning dialog with data list', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestableProfileScreen());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Delete Account'),
      400,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    // Warning dialog elements
    expect(find.text('Delete Account'), findsWidgets); // tile + dialog title
    expect(find.text('This action cannot be undone.'), findsOneWidget);
    expect(find.text('Your profile and personal information'), findsOneWidget);
    expect(find.text('All habits and completion history'), findsOneWidget);
    expect(find.text('All goals and progress records'), findsOneWidget);
    expect(find.text('Cash flow and financial records'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('tapping Continue in warning dialog opens final confirmation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestableProfileScreen());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Delete Account'),
      400,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Final confirmation dialog
    expect(find.text('Are you absolutely sure?'), findsOneWidget);
    expect(find.text('Permanently Delete My Account'), findsOneWidget);
  });
}

class _FakeNullableProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>>
    implements ProfileNotifier {
  _FakeNullableProfileNotifier() : super(const AsyncValue.data(null));

  @override
  Future<void> fetchProfile() async {}

  @override
  Future<void> updateProfile({required String name, String? avatarUrl}) async {}
}

class _FakeProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>>
    implements ProfileNotifier {
  _FakeProfileNotifier(UserProfile profile)
      : super(AsyncValue.data(profile));

  @override
  Future<void> fetchProfile() async {}

  @override
  Future<void> updateProfile({required String name, String? avatarUrl}) async {}
}
