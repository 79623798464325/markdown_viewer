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
    final spoilerTitle =
        element.attributes['text']?.replaceAll('\n', '') ?? 'Spoiler';

    // Get effective brightness for spoiler styling
    // Use provided brightness, or try to get from context, or default to light
    Brightness effectiveBrightness;
    if (brightness != null) {
      effectiveBrightness = brightness!;
    } else if (context != null) {
      effectiveBrightness = MediaQuery.platformBrightnessOf(context!);
    } else {
      effectiveBrightness = Brightness.light;
    }

    final spoilerColor =
        effectiveBrightness == Brightness.dark ? Colors.white : Colors.black;

    // Transform children to apply spoiler styling when hidden
    if (!isShowing) {
      _applySpoilerStyling(element.children, spoilerColor);
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

    if (isShowing) {
      // Add the rendered content when showing
      final baseWidget = super.buildWidget(element, parent);
      if (baseWidget != null) {
        contentWidgets.add(baseWidget);
      }
    } else {
      // Add hidden content (styled to be invisible)
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

  void _applySpoilerStyling(List<Widget> children, Color spoilerColor) {
    for (var i = 0; i < children.length; i++) {
      final child = children[i];

      if (child is Padding && child.child is Column) {
        _applySpoilerStyling((child.child! as Column).children, spoilerColor);
      } else if (child is Column) {
        _applySpoilerStyling(child.children, spoilerColor);
      } else if (child is RichText) {
        children[i] = _transformRichText(child, spoilerColor);
      }
    }
  }

  Widget _transformRichText(RichText richText, Color spoilerColor) {
    final textSpan = richText.text;
    if (textSpan is! TextSpan) return richText;

    final transformedSpan = _transformTextSpan(textSpan, spoilerColor);
    return RichText(
      text: transformedSpan,
      textAlign: richText.textAlign,
      selectionColor: richText.selectionColor,
      selectionRegistrar: richText.selectionRegistrar,
    );
  }

  TextSpan _transformTextSpan(TextSpan span, Color spoilerColor) {
    final baseStyle = span.style ?? const TextStyle();

    // When hidden: text color = background color (invisible text on matching bg)
    final spoilerStyle = TextStyle(
      color: spoilerColor,
      backgroundColor: spoilerColor,
      fontSize: baseStyle.fontSize,
      fontWeight: baseStyle.fontWeight,
      fontStyle: baseStyle.fontStyle,
      fontFamily: baseStyle.fontFamily,
      letterSpacing: baseStyle.letterSpacing,
      wordSpacing: baseStyle.wordSpacing,
      height: baseStyle.height,
      decoration: baseStyle.decoration,
      decorationColor: baseStyle.decorationColor,
      decorationStyle: baseStyle.decorationStyle,
      decorationThickness: baseStyle.decorationThickness,
      inherit: false,
    );

    return TextSpan(
      text: span.text,
      style: spoilerStyle,
      children: span.children
          ?.map((child) => child is TextSpan
              ? _transformTextSpan(child, spoilerColor)
              : child)
          .toList(),
    );
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
