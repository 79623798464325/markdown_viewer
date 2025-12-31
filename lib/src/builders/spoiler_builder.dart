import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../ast.dart';
import '../definition.dart';
import '../models/markdown_tree_element.dart';
import 'builder.dart';

/// A builder for rendering spoiler blocks.
///
/// Spoilers are blocks that hide their content until tapped.
/// The format is:
/// ```
/// ::: spoiler Spoiler Title
/// Hidden content
/// :::
/// ```
class SpoilerBuilder extends MarkdownElementBuilder {
  SpoilerBuilder({
    super.context,
    super.textStyle,
    this.onTap,
    this.isShowing = false,
    this.brightness,
    this.revealedTextColor,
    this.indicatorColor,
    this.padding,
  });

  @override
  final matchTypes = ['spoiler'];

  /// Callback when the spoiler is tapped.
  /// The first parameter is the index, the second is the spoiler title.
  final MarkdownTapLinkCallback? onTap;

  /// Whether the spoiler content is currently showing.
  final bool isShowing;

  /// Brightness to use for determining spoiler colors.
  /// Falls back to platform brightness if not provided.
  final Brightness? brightness;

  /// Text color when the spoiler is revealed.
  /// Falls back to the original text color if not provided.
  final Color? revealedTextColor;

  /// Color for the expand/collapse indicator.
  final Color? indicatorColor;

  /// Padding around the spoiler block.
  final EdgeInsets? padding;

  @override
  bool replaceLineEndings(String type) => true;

  @override
  Widget? buildWidget(MarkdownTreeElement element, MarkdownTreeElement parent) {
    var spoilerTitle =
        element.attributes['text']?.replaceAll('\n', '').trim() ?? 'Spoiler';
    if (spoilerTitle.isEmpty) {
      spoilerTitle = 'Spoiler';
    }

    // Build the indicator
    final indicatorText = isShowing ? '▲ $spoilerTitle' : '► $spoilerTitle';

    // Use provided indicator color, or try to get from theme, or use default
    Color effectiveIndicatorColor;
    if (indicatorColor != null) {
      effectiveIndicatorColor = indicatorColor!;
    } else if (context != null) {
      effectiveIndicatorColor = Theme.of(context!).colorScheme.secondary;
    } else {
      effectiveIndicatorColor = const Color(0xff6200ee); // Default purple
    }

    // Create indicator widget
    final indicator = RichText(
      text: TextSpan(
        text: indicatorText,
        style: TextStyle(color: effectiveIndicatorColor),
      ),
    );

    // Build content column
    final contentWidgets = <Widget>[];
    contentWidgets.add(indicator);

    // Only add children if showing
    if (isShowing) {
      final baseWidget = super.buildWidget(element, parent);
      if (baseWidget != null) {
        contentWidgets.add(baseWidget);
      }
    }

    Widget result = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: contentWidgets,
    );

    // Apply padding if specified
    if (padding != null && padding != EdgeInsets.zero) {
      result = Padding(padding: padding!, child: result);
    }

    // Wrap with gesture detector if onTap is provided
    if (onTap != null) {
      result = GestureDetector(
        onTap: () => onTap!('0', spoilerTitle),
        behavior: HitTestBehavior.opaque,
        child: result,
      );
    }

    return result;
  }

  @override
  GestureRecognizer? gestureRecognizer(MarkdownElement element) {
    if (onTap == null) return null;

    return TapGestureRecognizer()
      ..onTap = () {
        onTap!(
          element.position.index.toString(),
          element.attributes['text'],
        );
      };
  }
}
