import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:s_liquid_pull_to_refresh/s_liquid_pull_to_refresh.dart';

void main() {
  group('SLiquidPullToRefresh', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SLiquidPullToRefresh(
              onRefresh: () async {},
              child: ListView(
                children: const [
                  ListTile(title: Text('Item 1')),
                  ListTile(title: Text('Item 2')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('should call onRefresh when programmatically triggered',
        (WidgetTester tester) async {
      bool refreshCalled = false;
      final key = GlobalKey<SLiquidPullToRefreshState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SLiquidPullToRefresh(
              key: key,
              springAnimationDurationInMilliseconds: 100,
              onRefresh: () async {
                refreshCalled = true;
                await Future.delayed(const Duration(milliseconds: 10));
              },
              child: ListView(
                children: const [
                  ListTile(title: Text('Item 1')),
                ],
              ),
            ),
          ),
        ),
      );

      // Trigger refresh programmatically
      key.currentState?.show();
      await tester.pump();

      // Wait for animations and refresh to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(refreshCalled, isTrue);
    });

    testWidgets('should accept custom colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SLiquidPullToRefresh(
              onRefresh: () async {},
              color: Colors.red,
              backgroundColor: Colors.blue,
              child: ListView(
                children: const [
                  ListTile(title: Text('Item 1')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SLiquidPullToRefresh), findsOneWidget);
    });

    testWidgets('should accept custom height and animation parameters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SLiquidPullToRefresh(
              onRefresh: () async {},
              height: 150,
              animSpeedFactor: 2.0,
              springAnimationDurationInMilliseconds: 800,
              borderWidth: 4.0,
              child: ListView(
                children: const [
                  ListTile(title: Text('Item 1')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SLiquidPullToRefresh), findsOneWidget);
    });

    testWidgets('should accept showChildOpacityTransition parameter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SLiquidPullToRefresh(
              onRefresh: () async {},
              showChildOpacityTransition: false,
              child: ListView(
                children: const [
                  ListTile(title: Text('Item 1')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SLiquidPullToRefresh), findsOneWidget);
    });

    testWidgets('should work with empty list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SLiquidPullToRefresh(
              onRefresh: () async {},
              child: ListView(
                children: const [],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SLiquidPullToRefresh), findsOneWidget);
    });

    testWidgets('should work with CustomScrollView',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SLiquidPullToRefresh(
              onRefresh: () async {},
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      const ListTile(title: Text('Item 1')),
                      const ListTile(title: Text('Item 2')),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('should complete refresh future', (WidgetTester tester) async {
      bool refreshCompleted = false;
      final key = GlobalKey<SLiquidPullToRefreshState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SLiquidPullToRefresh(
              key: key,
              springAnimationDurationInMilliseconds: 100,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 10));
              },
              child: ListView(
                children: const [
                  ListTile(title: Text('Item 1')),
                ],
              ),
            ),
          ),
        ),
      );

      // Trigger refresh and wait for completion
      key.currentState?.show()?.then((_) {
        refreshCompleted = true;
      });

      await tester.pump();

      // Wait for all animations and refresh to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(refreshCompleted, isTrue);
    });

    test('animSpeedFactor should assert >= 1.0', () {
      expect(
        () => SLiquidPullToRefresh(
          animSpeedFactor: 0.5,
          onRefresh: () async {},
          child: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('SRefreshCallback', () {
    test('should be a function type that returns Future<void>', () {
      Future<void> callback() async {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      expect(callback, isA<Future<void> Function()>());
    });
  });
}
