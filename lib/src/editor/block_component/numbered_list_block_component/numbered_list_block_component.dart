import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/block_component/base_component/block_icon_builder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../base_component/text_align_mixin.dart';

class NumberedListBlockKeys {
  const NumberedListBlockKeys._();

  static const String type = 'numbered_list';

  static const String listType = 'numbered_list_type';

  static const String number = 'number';

  static const String delta = blockComponentDelta;

  static const String backgroundColor = blockComponentBackgroundColor;

  static const String textDirection = blockComponentTextDirection;
}

Node numberedListNode({
  Delta? delta,
  Attributes? attributes,
  int? number,
  String? textDirection,
  Iterable<Node>? children,
}) {
  attributes ??= {
    'delta': (delta ?? Delta()).toJson(),
    NumberedListBlockKeys.number: number,
  };
  return Node(
    type: NumberedListBlockKeys.type,
    attributes: {
      ...attributes,
      if (textDirection != null)
        NumberedListBlockKeys.textDirection: textDirection,
    },
    children: children ?? [],
  );
}

class NumberedListBlockComponentBuilder extends BlockComponentBuilder {
  NumberedListBlockComponentBuilder({
    super.configuration,
    this.iconBuilder,
  });

  final BlockIconBuilder? iconBuilder;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return NumberedListBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      iconBuilder: iconBuilder,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  bool validate(Node node) => node.delta != null;
}

class NumberedListBlockComponentWidget extends BlockComponentStatefulWidget {
  const NumberedListBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    this.iconBuilder,
  });

  final BlockIconBuilder? iconBuilder;

  @override
  State<NumberedListBlockComponentWidget> createState() =>
      _NumberedListBlockComponentWidgetState();
}

class _NumberedListBlockComponentWidgetState
    extends State<NumberedListBlockComponentWidget>
    with
        SelectableMixin,
        DefaultSelectableMixin,
        BlockComponentConfigurable,
        BlockComponentBackgroundColorMixin,
        NestedBlockComponentStatefulWidgetMixin,
        BlockComponentTextDirectionMixin,
        BlockComponentTextAlignMixin {
  @override
  final forwardKey = GlobalKey(debugLabel: 'flowy_rich_text');

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey = GlobalKey(
    debugLabel: NumberedListBlockKeys.type,
  );

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  @override
  Widget buildComponent(
    BuildContext context, {
    bool withBackgroundColor = true,
  }) {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );
    final textAlign = calculateTextAlign();

    Widget child = Container(
      color: withBackgroundColor ? backgroundColor : null,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: calculateRowMainAxisAlignment(textAlign),
        mainAxisSize: MainAxisSize.min,
        textDirection: textDirection,
        children: [
          widget.iconBuilder != null
              ? widget.iconBuilder!(context, node)
              : _NumberedListIcon(
                  node: node,
                  textStyle: textStyle,
                  direction: textDirection,
                ),
          Flexible(
            child: AppFlowyRichText(
              key: forwardKey,
              delegate: this,
              node: widget.node,
              editorState: editorState,
              placeholderText: placeholderText,
              textSpanDecorator: (textSpan) => textSpan.updateTextStyle(
                textStyle,
              ),
              placeholderTextSpanDecorator: (textSpan) =>
                  textSpan.updateTextStyle(
                placeholderTextStyle,
              ),
              textDirection: textDirection,
              textAlign: textAlign,
              cursorColor: editorState.editorStyle.cursorColor,
              selectionColor: editorState.editorStyle.selectionColor,
            ),
          ),
        ],
      ),
    );

    child = Padding(
      key: blockComponentKey,
      padding: padding,
      child: child,
    );

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [
        BlockSelectionType.block,
      ],
      child: child,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    return child;
  }
}

class _NumberedListIcon extends StatelessWidget {
  const _NumberedListIcon({
    required this.node,
    required this.textStyle,
    required this.direction,
  });

  final Node node;
  final TextStyle textStyle;
  final TextDirection direction;

  @override
  Widget build(BuildContext context) {
    final editorState = context.read<EditorState>();
    final text = editorState.editorStyle.textStyleConfiguration.text;
    final level = _NumberedListIconBuilder(node: node).level;
    Tuple2 fontSize = editorState.getCurNodeMaxFontSize(node);
    TextStyle style = text.combine(textStyle);
    TextStyle strutStyle = text.combine(textStyle);

    double lineHeight = 1.5;
    if (node.attributes.containsKey(blockComponentTextHeight)) {
      lineHeight = double.tryParse(
            (node.attributes[blockComponentTextHeight]!).toString(),
          ) ??
          1;
    }
    style = style.merge(
      TextStyle(
        height: lineHeight - 0.1,
        fontSize: fontSize.item1,
        fontFamily: defaultFontFamilyFallback.first,
        fontFamilyFallback: defaultFontFamilyFallback,
      ),
    );
    strutStyle = strutStyle.merge(
      TextStyle(
        height: lineHeight - 0.1,
        fontSize: fontSize.item2,
        fontFamily: defaultFontFamilyFallback.first,
        fontFamilyFallback: defaultFontFamilyFallback,
      ),
    );

    return Container(
      // color: Colors.red,
      padding: const EdgeInsets.only(right: 5.0),
      child: Text.rich(
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
        TextSpan(text: '$level.', style: style),
        textDirection: direction,
        style: style,
        strutStyle: StrutStyle.fromTextStyle(strutStyle),
      ),
    );
  }
}

class _NumberedListIconBuilder {
  _NumberedListIconBuilder({
    required this.node,
  });

  final Node node;

  int get level {
    int level = 1;
    Node? previous = node.previous;

    // if the previous one is not a numbered list, then it is the first one
    if (previous == null || previous.type != NumberedListBlockKeys.type) {
      return node.attributes[NumberedListBlockKeys.number] ?? level;
    }

    int? startNumber;
    while (previous != null && previous.type == NumberedListBlockKeys.type) {
      startNumber = previous.attributes[NumberedListBlockKeys.number] as int?;
      level++;
      previous = previous.previous;
    }
    if (startNumber != null) {
      return startNumber + level - 1;
    }
    return level;
  }
}
