import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_viewer/src/ast.dart';
import 'package:markdown_viewer/src/builders/spoiler_builder.dart';
import 'package:markdown_viewer/src/models/markdown_tree_element.dart';

// Concrete implementation of MarkdownTreeElement for testing
class TestTreeElement extends MarkdownTreeElement {
  TestTreeElement({
    required MarkdownElement element,
    TextStyle? style,
  }) : super(element: element, style: style);
}

void main() {
  testWidgets(
      'SpoilerBuilder returns error widget when color cannot be resolved',
      (tester) async {
    // 1. Instantiate SpoilerBuilder with NO context and NO style
    final builder = SpoilerBuilder();

    // 2. Create a dummy MarkdownTreeElement with NO style and NO context available
    final element = TestTreeElement(
      element: MarkdownElement(
        'spoiler',
        SiblingPosition(index: 0, total: 1),
        isBlock: true,
        attributes: {'text': 'Spoiler'},
      ),
      style: null, // Critical: No style here
    );

    // Parent element
    final parent = TestTreeElement(
      element: MarkdownElement(
        'root',
        SiblingPosition(index: 0, total: 1),
        isBlock: true,
      ),
      style: null,
    );

    // 3. Call buildWidget directly
    final widget = builder.buildWidget(element, parent);

    // 4. Verify the result is the Error Text widget
    expect(widget, isA<Text>());
    final textWidget = widget as Text;
    expect(textWidget.data, contains('Error: Could not determine text color'));
    expect(textWidget.style?.color, Colors.red);
  });
}
