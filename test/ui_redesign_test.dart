import 'package:chibot/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('mobile settings returns to the preserved chat draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('帮我写作'));
    await tester.pumpAndSettle();
    final draft =
        tester.widget<TextField>(find.byType(TextField).first).controller!.text;
    expect(draft, contains('主题是'));
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('设置')),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('让想法，从这里开始'), findsOneWidget);

    // Reopening settings must also support the system back action.
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('设置')),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('让想法，从这里开始'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      draft,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop sidebar toggles without losing the chat draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('帮我写作'));
    await tester.pumpAndSettle();
    final draft =
        tester.widget<TextField>(find.byType(TextField).first).controller!.text;

    await tester.tap(find.byTooltip('收起侧边栏'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byTooltip('展开侧边栏'), findsOneWidget);
    expect(find.byTooltip('新建对话'), findsWidgets);
    await tester.tap(find.byTooltip('历史'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('聊天'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('展开侧边栏'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byTooltip('收起侧边栏'), findsOneWidget);
    expect(find.text('工作空间'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      draft,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop workspace and compact layout fit available space', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(1280, 800), const Size(320, 640)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('让想法，从这里开始'), findsOneWidget);
    }
  });
}
