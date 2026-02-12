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
    this.textColor,
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

  /// Color for the spoiler toggle text.
  /// Falls back to indicatorColor, then theme text color, then textStyle color.
  final Color? textColor;

  /// Color for the expand/collapse indicator.
  /// Deprecated: Use textColor instead.
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

    // Use provided textColor, or indicatorColor for backwards compatibility,
    // or inherit from DefaultTextStyle (which inherits from consuming app), or use textStyle
    Color? resolvedColor;
    if (textColor != null) {
      resolvedColor = textColor;
    } else if (indicatorColor != null) {
      resolvedColor = indicatorColor;
    } else {
      resolvedColor = element.style?.color ??
          (context != null
              ? DefaultTextStyle.of(context!).style.color
              : null) ??
          textStyle?.color ??
          (context != null
              ? Theme.of(context!).textTheme.bodyMedium?.color
              : null);
    }

    if (resolvedColor == null) {
      return Text(
        'Error: Could not determine text color for spoiler',
        style: TextStyle(color: Colors.red),
      );
    }

    final effectiveTextColor = resolvedColor;

    // Create indicator widget with proper text styling (color AND font size)
    final indicator = RichText(
      text: TextSpan(
        text: indicatorText,
        style: textStyle?.copyWith(color: effectiveTextColor) ??
            TextStyle(color: effectiveTextColor),
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
