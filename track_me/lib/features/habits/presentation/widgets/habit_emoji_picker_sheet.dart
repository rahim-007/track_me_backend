import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'emoji_data.dart';

/// Modal bottom sheet that lets the user pick any standard emoji.
///
/// The selected emoji is returned via [Navigator.pop] as a `String?`, or
/// `null` if the sheet is dismissed without a selection.
class HabitEmojiPickerSheet extends StatefulWidget {
  const HabitEmojiPickerSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HabitEmojiPickerSheet(),
    );
  }

  @override
  State<HabitEmojiPickerSheet> createState() => _HabitEmojiPickerSheetState();
}

class _HabitEmojiPickerSheetState extends State<HabitEmojiPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  int _selectedCategory = 0;

  // Flattened view of every emoji plus lowercase search terms for fast
  // name/subgroup filtering.
  late final List<HabitEmoji> _allEmojis = [
    for (final category in habitEmojiCategories) ...category.emojis,
  ];
  late final List<String> _searchTerms = [
    for (final category in habitEmojiCategories)
      for (final emoji in category.emojis) emoji.name.toLowerCase(),
  ];

  List<HabitEmoji> get _visibleEmojis {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return habitEmojiCategories[_selectedCategory].emojis;
    final matches = <HabitEmoji>[];
    for (var i = 0; i < _allEmojis.length; i++) {
      if (_searchTerms[i].contains(query)) matches.add(_allEmojis[i]);
    }
    return matches;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // Keep the sheet comfortably above the keyboard while searching and sized
    // to the available space on every screen.
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final sheetHeight = (availableHeight * 0.8).clamp(320.0, 640.0);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Choose an Emoji',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                key: const ValueKey('emoji_search_field'),
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search emoji',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          color: AppColors.textSecondary,
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Category chips (hidden while searching — results span all groups)
            if (_query.isEmpty)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: habitEmojiCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final selected = i == _selectedCategory;
                    return ChoiceChip(
                      label: Text(habitEmojiCategories[i].label),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedCategory = i),
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.onPrimaryContainer
                            : AppColors.textSecondary,
                      ),
                      selectedColor: AppColors.primaryContainer,
                      backgroundColor: AppColors.surfaceVariant,
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              )
            else
              const SizedBox(height: 12),

            // Emoji grid
            Expanded(
              child: _visibleEmojis.isEmpty
                  ? Center(
                      child: Text(
                        'No emoji found for "$_query"',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: _visibleEmojis.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemBuilder: (context, index) {
                        final emoji = _visibleEmojis[index].emoji;
                        return InkWell(
                          key: ValueKey('emoji_option_$emoji'),
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Navigator.pop(context, emoji),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
