import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct UrDayEntry: TimelineEntry {
    let date: Date
    let progressPercent: Int
    let progressRatio: String
    let streakCount: Int
    let dailyQuote: String
    let habits: [HabitWidgetItem]
    let lastUpdated: String
}

struct HabitWidgetItem: Identifiable, Decodable {
    let id: String
    let name: String
    let category: String?
    let emoji: String?
    let is_completed: Bool
    let streak: Int
}

// MARK: - Timeline Provider
struct UrDayTimelineProvider: TimelineProvider {
    let appGroupId = "group.com.trackme.app"

    func placeholder(in context: Context) -> UrDayEntry {
        UrDayEntry(
            date: Date(),
            progressPercent: 60,
            progressRatio: "3/5",
            streakCount: 14,
            dailyQuote: "Small healthy choices become a strong life.",
            habits: [
                HabitWidgetItem(id: "1", name: "Drink 2L Water", category: "Wellness", emoji: "💧", is_completed: true, streak: 14),
                HabitWidgetItem(id: "2", name: "Read 20 mins", category: "Mindset", emoji: "📚", is_completed: false, streak: 7)
            ],
            lastUpdated: "10:30 AM"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (UrDayEntry) -> Void) {
        completion(fetchCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UrDayEntry>) -> Void) {
        let entry = fetchCurrentEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchCurrentEntry() -> UrDayEntry {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        let percent = userDefaults?.integer(forKey: "progress_percent") ?? 0
        let ratio = userDefaults?.string(forKey: "progress_ratio") ?? "0/0"
        let streak = userDefaults?.integer(forKey: "streak_count") ?? 0
        let quote = userDefaults?.string(forKey: "daily_quote") ?? "Small healthy choices become a strong life."
        let updated = userDefaults?.string(forKey: "last_updated") ?? ""
        let habitsJson = userDefaults?.string(forKey: "habits_json") ?? "[]"

        var habits: [HabitWidgetItem] = []
        if let data = habitsJson.data(using: .utf8) {
            habits = (try? JSONDecoder().decode([HabitWidgetItem].self, from: data)) ?? []
        }

        return UrDayEntry(
            date: Date(),
            progressPercent: percent,
            progressRatio: ratio,
            streakCount: streak,
            dailyQuote: quote,
            habits: habits,
            lastUpdated: updated
        )
    }
}

// MARK: - Views

/// Circular UrDay Progress & Date Widget
struct UrDayProgressWidgetView: View {
    var entry: UrDayTimelineProvider.Entry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let isDark = colorScheme == .dark
        let circleBg = isDark ? Color(hex: "0D0E18") : Color(hex: "F7F7FA")
        let circleBorder = isDark ? Color(hex: "28283E") : Color(hex: "E2E2EA")
        let trackColor = isDark ? Color(hex: "1C1B30") : Color(hex: "ECECF2")
        let textPrimary = isDark ? Color(hex: "EDEDF4") : Color(hex: "171721")
        let textSecondary = isDark ? Color(hex: "9493A6") : Color(hex: "6B6B78")
        let purpleAccent = isDark ? Color(hex: "A78BFA") : Color(hex: "6E49E6")
        let glowColor = isDark ? Color(hex: "8B5CF6").opacity(0.3) : Color(hex: "7C3AED").opacity(0.15)

        HStack(spacing: -12) {
            // Main Progress Circle
            ZStack {
                // Background circle
                Circle()
                    .fill(circleBg)
                    .overlay(Circle().stroke(circleBorder, lineWidth: 1.2))

                // Progress Track
                Circle()
                    .stroke(trackColor, style: StrokeStyle(lineWidth: 9.5, lineCap: .round))
                    .padding(5)

                // Ambient Glow
                if entry.progressPercent > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(min(max(entry.progressPercent, 0), 100)) / 100.0)
                        .stroke(glowColor, style: StrokeStyle(lineWidth: 13, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(5)
                }

                // Dynamic Gradient Arc
                if entry.progressPercent > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(min(max(entry.progressPercent, 0), 100)) / 100.0)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: isDark ? [
                                    Color(hex: "7C3AED"),
                                    Color(hex: "8B5CF6"),
                                    Color(hex: "A78BFA")
                                ] : [
                                    Color(hex: "6D28D9"),
                                    Color(hex: "7C3AED"),
                                    Color(hex: "8B5CF6")
                                ]),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 9.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .padding(5)
                }

                // Content inside main circle (12-14% internal safe margin)
                VStack(spacing: 2) {
                    // Top branding
                    HStack(spacing: 3) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 8.5))
                            .foregroundColor(purpleAccent)
                        Text("UrDay")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(textPrimary)
                    }

                    // Center percentage & "Today"
                    Text("\(entry.progressPercent)%")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(textPrimary)
                    Text("Today")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(textSecondary)

                    // Bottom streak (single line)
                    HStack(spacing: 2) {
                        Text("🔥")
                            .font(.system(size: 9))
                        Text(entry.streakCount > 0 ? "+\(entry.streakCount) Streak" : "0 Streak")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(purpleAccent)
                    }
                    .padding(.top, 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .frame(width: 148, height: 148)
            .zIndex(1)

            // Secondary Date Circle (attached/overlapping)
            ZStack {
                Circle()
                    .fill(circleBg)
                    .overlay(Circle().stroke(circleBorder, lineWidth: 1.2))

                VStack(spacing: 2) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(purpleAccent)

                    Text(entry.date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(textSecondary)

                    Text(entry.date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(textPrimary)
                }
                .padding(10)
            }
            .frame(width: 96, height: 96)
            .zIndex(0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .widgetURL(URL(string: "urday://dashboard"))
    }
}

/// Medium (4x2) Today's Habits Widget
struct UrDayHabitsWidgetView: View {
    var entry: UrDayTimelineProvider.Entry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let isDark = colorScheme == .dark
        let cardBg = isDark ? Color(hex: "14141E") : Color(hex: "FFFFFF")
        let rowBg = isDark ? Color(hex: "1E1E2C") : Color(hex: "F2F2F7")
        let textPrimary = isDark ? Color(hex: "EDEDF4") : Color(hex: "171721")
        let textSecondary = isDark ? Color(hex: "9493A6") : Color(hex: "6B6B78")
        let dividerColor = isDark ? Color(hex: "2A2A3D") : Color(hex: "E5E5EB")
        let pillBg = isDark ? Color(hex: "282046") : Color(hex: "EDE9FE")
        let accentColor = isDark ? Color(hex: "8B6EF5") : Color(hex: "6E49E6")

        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentColor)
                    Text("UrDay • Today's Habits")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(textPrimary)
                }
                Spacer()
                Text("\(entry.progressRatio) (\(entry.progressPercent)%)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(pillBg)
                    .cornerRadius(10)

                Link(destination: URL(string: "urday://habits")!) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(textPrimary)
                        .frame(width: 22, height: 22)
                        .background(pillBg)
                        .clipShape(Circle())
                }
            }

            Divider()
                .background(dividerColor)

            // Habits rows (up to 4)
            if entry.habits.isEmpty {
                Spacer()
                Text("Open UrDay to schedule today's habits ✨")
                    .font(.system(size: 11))
                    .foregroundColor(textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ForEach(entry.habits.prefix(4)) { habit in
                    Link(destination: URL(string: "urday://habits?toggle=\(habit.id)")!) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(isDark ? Color(hex: "252538") : Color(hex: "E8E8F0"))
                                    .frame(width: 24, height: 24)
                                Text(habit.emoji ?? "⚡")
                                    .font(.system(size: 12))
                            }

                            Text(habit.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text("🔥 \(habit.streak)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "FFA500"))

                            Image(systemName: habit.is_completed ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16))
                                .foregroundColor(habit.is_completed ? Color(hex: "10B981") : (isDark ? Color(hex: "5A5A6E") : Color(hex: "C4C4D0")))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(rowBg)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(12)
        .background(cardBg)
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Cash Flow Timeline Entry
struct UrDayCashFlowEntry: TimelineEntry {
    let date: Date
    let netAmount: String
    let isPositive: Bool
    let income: String
    let outflow: String
    let bank: String
    let cash: String
    let card: String
    let hasData: Bool
}

// MARK: - Cash Flow Timeline Provider
struct UrDayCashFlowTimelineProvider: TimelineProvider {
    let appGroupId = "group.com.trackme.app"

    func placeholder(in context: Context) -> UrDayCashFlowEntry {
        UrDayCashFlowEntry(
            date: Date(),
            netAmount: "+₹24,500",
            isPositive: true,
            income: "₹48,000",
            outflow: "₹23,500",
            bank: "₹32,450",
            cash: "₹3,200",
            card: "₹12,800",
            hasData: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (UrDayCashFlowEntry) -> Void) {
        completion(fetchCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UrDayCashFlowEntry>) -> Void) {
        let entry = fetchCurrentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchCurrentEntry() -> UrDayCashFlowEntry {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        let net = userDefaults?.string(forKey: "cashflow_net") ?? "+₹0"
        let isPositive = userDefaults?.bool(forKey: "cashflow_is_positive") ?? true
        let income = userDefaults?.string(forKey: "cashflow_income") ?? "₹0"
        let outflow = userDefaults?.string(forKey: "cashflow_outflow") ?? "₹0"
        let bank = userDefaults?.string(forKey: "cashflow_bank") ?? "₹0"
        let cash = userDefaults?.string(forKey: "cashflow_cash") ?? "₹0"
        let card = userDefaults?.string(forKey: "cashflow_card") ?? "₹0"
        let hasData = userDefaults?.bool(forKey: "cashflow_has_data") ?? false

        return UrDayCashFlowEntry(
            date: Date(),
            netAmount: net,
            isPositive: isPositive,
            income: income,
            outflow: outflow,
            bank: bank,
            cash: cash,
            card: card,
            hasData: hasData
        )
    }
}

// MARK: - Cash Flow Widget View
struct UrDayCashFlowWidgetView: View {
    var entry: UrDayCashFlowTimelineProvider.Entry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let isDark = colorScheme == .dark
        let purpleGradient = LinearGradient(
            gradient: Gradient(colors: [Color(hex: "5848D6"), Color(hex: "4930D8")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        let safeIncome = (entry.income.hasPrefix("+") || entry.income.hasPrefix("↙")) ? entry.income : "+\(entry.income)"
        let safeOutflow = (entry.outflow.hasPrefix("-") || entry.outflow.hasPrefix("↗")) ? entry.outflow : "-\(entry.outflow)"

        VStack(alignment: .leading, spacing: 0) {
            // Header Row: Sparkle + NET CASH FLOW + Dynamic Status Pill
            HStack(spacing: 4) {
                Text("✨")
                    .font(.system(size: 10))
                Text("NET CASH FLOW")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(Color(hex: "E8E4FF"))
                    .tracking(0.8)
                Spacer()
                HStack(spacing: 3) {
                    Text(entry.isPositive ? "↗ Positive" : "↘ Deficit")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.20))
                .cornerRadius(12)
            }

            Spacer().frame(height: 6)

            // Main Net Amount
            Text(entry.netAmount)
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer().frame(height: 5)

            // Income / Outflow Chips
            HStack(spacing: 6) {
                // Income Chip (Mint)
                Link(destination: URL(string: "urday://cashflow?action=income")!) {
                    HStack(spacing: 3) {
                        Text("↙ \(safeIncome)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "34D399"))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3.5)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                }

                // Outflow Chip (Rose)
                Link(destination: URL(string: "urday://cashflow?action=outflow")!) {
                    HStack(spacing: 3) {
                        Text("↗ \(safeOutflow)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "F87171"))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3.5)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                }
            }

            Spacer().frame(height: 8)

            // Balance Breakdown in Translucent Rounded Box
            VStack(spacing: 4) {
                balanceRow(icon: "🏦", label: "Bank: ", amount: entry.bank)
                Divider().background(Color.white.opacity(0.18))
                balanceRow(icon: "💵", label: "Cash: ", amount: entry.cash)
                Divider().background(Color.white.opacity(0.18))
                balanceRow(icon: "💳", label: "Card: ", amount: entry.card)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.13))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.18), lineWidth: 0.8))
            .cornerRadius(12)
        }
        .padding(12)
        .background(purpleGradient)
        .widgetURL(URL(string: "urday://cashflow"))
    }

    private func balanceRow(icon: String, label: String, amount: String) -> some View {
        HStack(spacing: 3) {
            Text(icon)
                .font(.system(size: 8.5))
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: "E0D8FF"))
            Spacer()
            Text(amount)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Widget Bundle
@main
struct UrDayWidgetsBundle: WidgetBundle {
    var body: some Widget {
        UrDayProgressWidget()
        UrDayHabitsWidget()
        UrDayCashFlowWidget()
    }
}

struct UrDayProgressWidget: Widget {
    let kind: String = "UrDayProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UrDayTimelineProvider()) { entry in
            UrDayProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("UrDay Progress")
        .description("Track your daily habit completion and active streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct UrDayHabitsWidget: Widget {
    let kind: String = "UrDayHabitsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UrDayTimelineProvider()) { entry in
            UrDayHabitsWidgetView(entry: entry)
        }
        .configurationDisplayName("UrDay Habits")
        .description("View and toggle today's habits directly from the home screen.")
        .supportedFamilies([.systemMedium])
    }
}

struct UrDayCashFlowWidget: Widget {
    let kind: String = "UrDayCashFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UrDayCashFlowTimelineProvider()) { entry in
            UrDayCashFlowWidgetView(entry: entry)
        }
        .configurationDisplayName("UrDay Cash Flow")
        .description("Track your net cash flow, income, outflow, and pocket balances.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

