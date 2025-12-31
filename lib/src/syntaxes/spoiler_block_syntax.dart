import 'package:dart_markdown/dart_markdown.dart';

/// A block syntax for parsing spoiler blocks.
///
/// The format is:
/// ```
/// ::: spoiler Spoiler Title
/// Spoiler content goes here
/// :::
/// ```
class SpoilerBlockSyntax extends BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^::: ?spoiler ?(.*)$');

  /// Pattern to match the closing `:::` tag.
  static final _endPattern = RegExp(r'^:::$');

  @override
  BlockElement parse(BlockParser parser) {
    // Use Line's firstMatch method for proper matching
    final match = parser.current.firstMatch(pattern);
    final spoilerTitle = match?.group(1)?.trim() ?? '';

    final startLine = parser.current;
    final childLines = <Line>[];

    parser.advance();

    // Consume lines until we find the closing :::
    while (!parser.isDone) {
      final lineText = parser.current.text.trim();
      if (_endPattern.hasMatch(lineText)) {
        parser.advance();
        break;
      }
      childLines.add(parser.current);
      parser.advance();
    }

    final endLine = parser.isDone
        ? (childLines.isNotEmpty ? childLines.last : startLine)
        : startLine;

    // Parse child content as blocks if there are any
    List<Node> children = [];
    if (childLines.isNotEmpty) {
      final childParser = BlockParser(childLines, parser.document);
      children = childParser.parseLines();
    }

    return BlockElement(
      'spoiler',
      children: children,
      start: startLine.start,
      end: endLine.end,
      attributes: {'text': spoilerTitle},
    );
  }
}
