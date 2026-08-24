// Visual-only patches to align Flutter UI with approved mockups.
const fs = require('fs');

function escapeRe(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function patch(file, pairs) {
  let src = fs.readFileSync(file, 'utf8');
  let dirty = false;
  for (const [name, oldS, newS] of pairs) {
    const re = new RegExp(escapeRe(oldS).replace(/\n/g, '\\r?\\n'));
    if (!re.test(src)) {
      console.log(`MISS [${file}] ${name}`);
      process.exitCode = 1;
      continue;
    }
    src = src.replace(re, () => newS);
    dirty = true;
    console.log(`OK   [${file}] ${name}`);
  }
  if (dirty) fs.writeFileSync(file, src);
}

const habitsScreen = 'lib/features/habits/presentation/screens/habits_screen.dart';
const habitRow = 'lib/features/habits/presentation/widgets/habit_grid_row.dart';
const mainShell = 'lib/core/shell/main_shell.dart';

// ---- Week selector: big pill -> per-day rounded cards (mockup .wday) ----
const oldWeek = `        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final date = startOfWeek.add(Duration(days: i));
              final isSelected = date.day == selectedDate.day &&
                  date.month == selectedDate.month &&
                  date.year == selectedDate.year;
              final isToday = date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;

              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      days[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : (isToday ? AppColors.primary.withOpacity(0.65) : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isToday ? AppColors.primaryContainer : Colors.transparent),
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                        border: isToday && !isSelected
                            ? Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '\${date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isToday ? AppColors.primary : AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),`;

const newWeek = `        Row(
          children: List.generate(7, (i) {
            final date = startOfWeek.add(Duration(days: i));
            final isSelected = date.day == selectedDate.day &&
                date.month == selectedDate.month &&
                date.year == selectedDate.year;
            final isToday = date.day == DateTime.now().day &&
                date.month == DateTime.now().month &&
                date.year == DateTime.now().year;

            return Expanded(
              child: GestureDetector(
                onTap: () => onDateSelected(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3.5),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isToday ? AppColors.primary.withOpacity(0.45) : AppColors.border),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.primary.withOpacity(AppColors.isDarkMode ? 0.40 : 0.30)
                            : (AppColors.isDarkMode
                                ? Colors.transparent
                                : Colors.black.withOpacity(0.03)),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        days[i].toUpperCase(),
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isSelected
                              ? Colors.white.withOpacity(0.75)
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '\${date.day}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? AppColors.primary : AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),`;

// ---- Habit row: inset rounded stripe ----
const oldStripe = `              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: 6,
                child: Container(color: categoryColor),
              ),`;
const newStripe = `              Positioned(
                top: 10,
                bottom: 10,
                left: 0,
                width: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),`;

// ---- Habit row: emoji circle -> rounded tile ----
const oldEmoji = `                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),`;
const newEmoji = `                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(AppColors.isDarkMode ? 0.14 : 0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),`;

// ---- Nav: active pill chip ----
const oldNav = `            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),`;
const newNav = `            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withOpacity(AppColors.isDarkMode ? 0.16 : 0.11)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),`;

patch(habitsScreen, [['week selector cards', oldWeek, newWeek]]);
patch(habitRow, [['inset stripe', oldStripe, newStripe], ['emoji tile', oldEmoji, newEmoji]]);
patch(mainShell, [['nav chip', oldNav, newNav]]);
