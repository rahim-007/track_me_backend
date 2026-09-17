import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/core/widgets/home_widget_service.dart';
import 'package:track_me/features/cashflow/data/models/cashflow_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final savedWidgetData = <String, dynamic>{};
  final updatedWidgets = <String>[];

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('track_me_cashflow_widget_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'saveWidgetData') {
          final args = methodCall.arguments as Map;
          savedWidgetData[args['id']] = args['data'];
          return true;
        } else if (methodCall.method == 'getWidgetData') {
          final args = methodCall.arguments as Map;
          return savedWidgetData[args['id']];
        } else if (methodCall.method == 'updateWidget') {
          final args = methodCall.arguments as Map;
          final name = args['name'] ?? args['android'] ?? args['ios'] ?? '';
          updatedWidgets.add(name.toString());
          return true;
        }
        return true;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async => null,
    );
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() {
    savedWidgetData.clear();
    updatedWidgets.clear();
  });

  group('Cash Flow Widget Synchronization Tests', () {
    test('Positive net cash flow syncs all required data matching reference design', () async {
      const period = CashFlowPeriodModel(
        id: 'period_09_2026',
        month: 9,
        year: 2026,
        openingBank: 30000,
        openingCash: 2000,
        openingCreditCard: 10000,
        openingDebt: 0,
        totalIncome: 48000,
        totalOutflow: 23500,
        netCashFlow: 24500,
        closingBank: 32450,
        closingCash: 3200,
        closingCreditCard: 12800,
        isCurrent: true,
      );

      await HomeWidgetService.instance.syncCashFlowData(period: period);

      expect(savedWidgetData['cashflow_net'], '+₹24,500');
      expect(savedWidgetData['cashflow_net_val'], 24500.0);
      expect(savedWidgetData['cashflow_is_positive'], true);
      expect(savedWidgetData['cashflow_income'], '₹48,000');
      expect(savedWidgetData['cashflow_outflow'], '₹23,500');
      expect(savedWidgetData['cashflow_bank'], '₹32,450');
      expect(savedWidgetData['cashflow_cash'], '₹3,200');
      expect(savedWidgetData['cashflow_card'], '₹12,800');
      expect(savedWidgetData['cashflow_has_data'], true);
      expect(savedWidgetData['cashflow_period_name'], 'September 2026');

      expect(updatedWidgets.contains(HomeWidgetService.androidCashFlowWidget), true);
    });

    test('Deficit net cash flow properly formats negative prefix and deficit flag', () async {
      const period = CashFlowPeriodModel(
        id: 'period_09_2026',
        month: 9,
        year: 2026,
        openingBank: 10000,
        openingCash: 1000,
        openingCreditCard: 5000,
        openingDebt: 0,
        totalIncome: 15000,
        totalOutflow: 20000,
        netCashFlow: -5000,
        closingBank: 6000,
        closingCash: 500,
        closingCreditCard: 6500,
        isCurrent: true,
      );

      await HomeWidgetService.instance.syncCashFlowData(period: period);

      expect(savedWidgetData['cashflow_net'], '-₹5,000');
      expect(savedWidgetData['cashflow_net_val'], -5000.0);
      expect(savedWidgetData['cashflow_is_positive'], false);
      expect(savedWidgetData['cashflow_income'], '₹15,000');
      expect(savedWidgetData['cashflow_outflow'], '₹20,000');
      expect(savedWidgetData['cashflow_bank'], '₹6,000');
      expect(savedWidgetData['cashflow_cash'], '₹500');
      expect(savedWidgetData['cashflow_card'], '₹6,500');
    });

    test('Zero net cash flow formats gracefully', () async {
      const period = CashFlowPeriodModel(
        id: 'period_09_2026',
        month: 9,
        year: 2026,
        openingBank: 0,
        openingCash: 0,
        openingCreditCard: 0,
        openingDebt: 0,
        totalIncome: 0,
        totalOutflow: 0,
        netCashFlow: 0,
        closingBank: 0,
        closingCash: 0,
        closingCreditCard: 0,
        isCurrent: true,
      );

      await HomeWidgetService.instance.syncCashFlowData(period: period);

      expect(savedWidgetData['cashflow_net'], '+₹0');
      expect(savedWidgetData['cashflow_is_positive'], true);
      expect(savedWidgetData['cashflow_income'], '₹0');
      expect(savedWidgetData['cashflow_outflow'], '₹0');
    });

    test('Theme change propagates to Cash Flow widget', () async {
      await HomeWidgetService.instance.syncTheme(isDarkMode: true);

      expect(savedWidgetData['app_is_dark_mode'], true);
      expect(updatedWidgets.contains(HomeWidgetService.androidCashFlowWidget), true);

      await HomeWidgetService.instance.syncTheme(isDarkMode: false);

      expect(savedWidgetData['app_is_dark_mode'], false);
      expect(updatedWidgets.contains(HomeWidgetService.androidCashFlowWidget), true);
    });

    test('Deep link URIs parse income and outflow actions correctly', () {
      final incomeUri = Uri.parse('urday://cashflow?action=income');
      final outflowUri = Uri.parse('urday://cashflow?action=outflow');
      final baseUri = Uri.parse('urday://cashflow');

      expect(incomeUri.host, 'cashflow');
      expect(incomeUri.queryParameters['action'], 'income');

      expect(outflowUri.host, 'cashflow');
      expect(outflowUri.queryParameters['action'], 'outflow');

      expect(baseUri.host, 'cashflow');
      expect(baseUri.queryParameters['action'], isNull);
    });
  });
}
