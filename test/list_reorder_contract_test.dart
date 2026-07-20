import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

void main() {
  testWidgets('MyList 向后移动仍传移除前插入下标', (tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    (int, int)? received;

    await tester.pumpWidget(
      MaterialApp(
        home: MyList<int>(
          items: const [1, 2, 3],
          itemBuilder: (_, index) => SizedBox(
            key: ValueKey(index),
            height: 40,
            child: Text('$index'),
          ),
          scrollController: scrollController,
          isDraggable: true,
          onCardReordered: (oldIndex, newIndex) {
            received = (oldIndex, newIndex);
          },
        ),
      ),
    );

    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorderItem!(0, 2);
    expect(received, (0, 3));
  });
}
