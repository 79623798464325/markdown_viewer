import 'package:dart_markdown/dart_markdown.dart' hide Text;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_viewer/markdown_viewer.dart';

void main() {
  group('SpoilerBlockSyntax', () {
    test('parses simple spoiler block', () {
      const markdown = '::: spoiler Click to reveal\nHidden content\n:::';
      final nodes = Markdown(
        enableHtmlBlock: false,
        enableRawHtml: false,
        extensions: [SpoilerBlockSyntax()],
      ).parse(markdown);

      expect(nodes.length, 1);
      final spoiler = nodes.first as BlockElement;
      expect(spoiler.type, 'spoiler');
      expect(spoiler.attributes['text'], 'Click to reveal');
    });

    test('parses spoiler with multiline content', () {
      const markdown = '::: spoiler Secret\nLine 1\nLine 2\nLine 3\n:::';
      final nodes = Markdown(
        enableHtmlBlock: false,
        enableRawHtml: false,
        extensions: [SpoilerBlockSyntax()],
      ).parse(markdown);

      expect(nodes.length, 1);
      final spoiler = nodes.first as BlockElement;
      expect(spoiler.type, 'spoiler');
      expect(spoiler.attributes['text'], 'Secret');
      // Content should be parsed as child blocks
      expect(spoiler.children.isNotEmpty, true);
    });

    test('parses spoiler with empty title', () {
      const markdown = '::: spoiler\nContent\n:::';
      final nodes = Markdown(
        enableHtmlBlock: false,
        enableRawHtml: false,
        extensions: [SpoilerBlockSyntax()],
      ).parse(markdown);

      expect(nodes.length, 1);
      final spoiler = nodes.first as BlockElement;
      expect(spoiler.type, 'spoiler');
      expect(spoiler.attributes['text'], '');
    });

    test('parses spoiler with image content', () {
      const markdown = '''::: spoiler spoiler
![](https://example.com/image.jpeg)

Edit: I oopsed.
:::''';
      final nodes = Markdown(
        enableHtmlBlock: false,
        enableRawHtml: false,
        extensions: [SpoilerBlockSyntax()],
      ).parse(markdown);

      expect(nodes.length, 1);
      final spoiler = nodes.first as BlockElement;
      expect(spoiler.type, 'spoiler');
      expect(spoiler.attributes['text'], 'spoiler');

      // Should have children (image paragraph and text paragraph)
      expect(spoiler.children.isNotEmpty, true);

      // Find the image element in children
      bool foundImage = false;
      for (final child in spoiler.children) {
        if (child is BlockElement && child.type == 'paragraph') {
          for (final grandchild in child.children) {
            if (grandchild is InlineElement && grandchild.type == 'image') {
              foundImage = true;
              expect(grandchild.attributes['destination'],
                  'https://example.com/image.jpeg');
              break;
            }
          }
        }
      }
      expect(foundImage, true,
          reason: 'Spoiler should contain an image element');
    });
  });

  group('SpoilerBuilder widget rendering', () {
    testWidgets('renders collapsed spoiler with indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownViewer(
              '::: spoiler Test Spoiler\nHidden text\n:::',
              syntaxExtensions: [SpoilerBlockSyntax()],
              elementBuilders: [
                SpoilerBuilder(isShowing: false),
              ],
            ),
          ),
        ),
      );

      // Find RichText widgets and check their content
      final richTexts = find.byType(RichText);
      expect(richTexts, findsWidgets);

      // Verify the indicator text is present (► Test Spoiler)
      bool foundIndicator = false;
      for (final element in richTexts.evaluate()) {
        final widget = element.widget as RichText;
        if (widget.text is TextSpan) {
          final span = widget.text as TextSpan;
          if (span.text?.contains('Test Spoiler') == true) {
            foundIndicator = true;
            expect(span.text, '► Test Spoiler');
            break;
          }
        }
      }
      expect(foundIndicator, true,
          reason: 'Should find collapsed indicator with title');
    });

    testWidgets('renders expanded spoiler with arrow up indicator',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownViewer(
              '::: spoiler Reveal Me\nVisible content\n:::',
              syntaxExtensions: [SpoilerBlockSyntax()],
              elementBuilders: [
                SpoilerBuilder(isShowing: true),
              ],
            ),
          ),
        ),
      );

      // Find RichText widgets and check their content
      final richTexts = find.byType(RichText);
      expect(richTexts, findsWidgets);

      // Verify the indicator text is present (▲ Reveal Me)
      bool foundIndicator = false;
      for (final element in richTexts.evaluate()) {
        final widget = element.widget as RichText;
        if (widget.text is TextSpan) {
          final span = widget.text as TextSpan;
          if (span.text?.contains('Reveal Me') == true) {
            foundIndicator = true;
            expect(span.text, '▲ Reveal Me');
            break;
          }
        }
      }
      expect(foundIndicator, true,
          reason: 'Should find expanded indicator with title');
    });

    testWidgets('calls onTap callback when spoiler is tapped', (tester) async {
      String? tappedTitle;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownViewer(
              '::: spoiler Click Me\nContent\n:::',
              syntaxExtensions: [SpoilerBlockSyntax()],
              elementBuilders: [
                SpoilerBuilder(
                  isShowing: false,
                  onTap: (_, title) {
                    tappedTitle = title;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Tap the GestureDetector wrapping the spoiler
      final gestureDetector = find.byType(GestureDetector);
      expect(gestureDetector, findsWidgets);
      await tester.tap(gestureDetector.first);
      await tester.pump();

      expect(tappedTitle, 'Click Me');
    });

    testWidgets('renders spoiler with image content - collapsed',
        (tester) async {
      // Use a custom image builder to avoid network requests in tests
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownViewer(
              '''::: spoiler spoiler
![](https://example.com/image.jpeg)

Edit: I oopsed.
:::''',
              syntaxExtensions: [SpoilerBlockSyntax()],
              elementBuilders: [
                SpoilerBuilder(isShowing: false),
              ],
              imageBuilder: (uri, info) => Container(
                key: const Key('test-image'),
                width: 100,
                height: 100,
                color: Colors.grey,
                child: const Text('Image placeholder'),
              ),
            ),
          ),
        ),
      );

      // Find the indicator (collapsed)
      final richTexts = find.byType(RichText);
      expect(richTexts, findsWidgets);

      bool foundIndicator = false;
      for (final element in richTexts.evaluate()) {
        final widget = element.widget as RichText;
        if (widget.text is TextSpan) {
          final span = widget.text as TextSpan;
          if (span.text?.contains('spoiler') == true &&
              span.text?.startsWith('►') == true) {
            foundIndicator = true;
            break;
          }
        }
      }
      expect(foundIndicator, true, reason: 'Should find collapsed indicator');

      // Verify the image placeholder DOES NOT exist (content is not built when hidden)
      final imagePlaceholder = find.byKey(const Key('test-image'));
      expect(imagePlaceholder, findsNothing,
          reason: 'Spoiler should NOT contain an image when collapsed');
    });

    testWidgets('renders spoiler with image content - expanded',
        (tester) async {
      // Use a custom image builder to avoid network requests in tests
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownViewer(
              '''::: spoiler spoiler
![](https://example.com/image.jpeg)

Edit: I oopsed.
:::''',
              syntaxExtensions: [SpoilerBlockSyntax()],
              elementBuilders: [
                SpoilerBuilder(isShowing: true),
              ],
              imageBuilder: (uri, info) => Container(
                key: const Key('test-image'),
                width: 100,
                height: 100,
                color: Colors.grey,
                child: const Text('Image placeholder'),
              ),
            ),
          ),
        ),
      );

      // Find the indicator (expanded)
      final richTexts = find.byType(RichText);
      expect(richTexts, findsWidgets);

      bool foundIndicator = false;
      for (final element in richTexts.evaluate()) {
        final widget = element.widget as RichText;
        if (widget.text is TextSpan) {
          final span = widget.text as TextSpan;
          if (span.text?.contains('spoiler') == true &&
              span.text?.startsWith('▲') == true) {
            foundIndicator = true;
            break;
          }
        }
      }
      expect(foundIndicator, true, reason: 'Should find expanded indicator');

      // Verify the image placeholder exists and is visible
      final imagePlaceholder = find.byKey(const Key('test-image'));
      expect(imagePlaceholder, findsOneWidget,
          reason: 'Spoiler should contain a visible image');
    });
  });
}
