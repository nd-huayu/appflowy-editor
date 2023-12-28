import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

extension TextTransforms on EditorState {
  /// Inserts a new line at the given position.
  ///
  /// If the [Position] is not passed in, use the current selection.
  /// If there is no position, or if the selection is not collapsed, do nothing.
  ///
  /// Then it inserts a new paragraph node. After that, it sets the selection to be at the
  /// beginning of the new paragraph.
  Future<void> insertNewLine({
    Position? position,
    Node Function(Node node)? nodeBuilder,
  }) async {
    // If the position is not passed in, use the current selection.
    position ??= selection?.start;

    // If there is no position, or if the selection is not collapsed, do nothing.
    if (position == null || !(selection?.isCollapsed ?? false)) {
      return;
    }

    final node = getNodeAtPath(position.path);

    if (node == null) {
      return;
    }

    // Get the transaction and the path of the next node.
    final transaction = this.transaction;
    final next = position.path.next;
    final children = node.children;
    final delta = node.delta;

    if (delta != null && !node.isMediaType()) {
      // Delete the text after the cursor in the current node.
      transaction.deleteText(
        node,
        position.offset,
        delta.length - position.offset,
      );
    }

    // Delete the current node's children if it is not empty.
    if (children.isNotEmpty) {
      transaction.deleteNodes(children);
    }

    final slicedDelta = delta == null ? Delta() : delta.slice(position.offset);

    final Map<String, dynamic> attributes = {
      'delta': slicedDelta.toJson(),
    };

    // Copy the text direction from the current node.
    final textDirection =
        node.attributes[blockComponentTextDirection] as String?;
    if (textDirection != null) {
      attributes[blockComponentTextDirection] = textDirection;
    }

    final insertedNode = paragraphNode(
      attributes: node.isMediaType() ? null : attributes,
      children: children,
    );

    bool isNewHeading = false;
    nodeBuilder ??= (insertNode) {
      if (node.type == 'heading') {
        if (insertNode.delta?.toPlainText().isEmpty == true) {
          return insertNode.copyWith();
        }
        int level = node.attributes['level'] as int;
        Attributes srcAttributes = insertNode.attributes;
        srcAttributes['level'] = level;
        isNewHeading = true;
        return insertNode.copyWith(type: node.type, attributes: srcAttributes);
      }
      return insertNode.copyWith();
    };

    // Insert a new paragraph node.
    transaction.insertNode(
      next,
      nodeBuilder(insertedNode),
      deepCopy: true,
    );

    // Set the selection to be at the beginning of the new paragraph.
    transaction.afterSelection = Selection.collapsed(
      Position(
        path: next,
        offset: 0,
      ),
    );
    if (isNewHeading) {
      headingChange = true;
    }
    // Apply the transaction.
    return apply(transaction).then((value) {
      if(node.type != "heading" && delta != null && delta.operations.isNotEmpty){
        Attributes? last;
        try{
          //获取当前光标所在的操作对象
          last = getOffsetAtOperationIndex(position!.offset,delta.operations).attributes;
        }
        catch(e){
          last = delta.operations.last.attributes;
        }
       
        formatDelta(
          Selection.collapsed(
            Position(
              path: next,
              offset: 0,
            ),
          ),
          {
            ...?last,
          },
        );
      }
    });
  }

  TextInsert getOffsetAtOperationIndex(int index, List<TextOperation> ops) {
    int currentIndex = 0;

    for (var op in ops.map((e) => e as TextInsert)) {
      if (index >= currentIndex && index < currentIndex + op.text.length) {
        return op;
      }
      currentIndex += op.length;
    }

    throw RangeError('Index out of bounds');
  }

  /// Inserts text at the given position.
  /// If the [Position] is not passed in, use the current selection.
  /// If there is no position, or if the selection is not collapsed, do nothing.
  /// Then it inserts the text at the given position.

  Future<void> insertTextAtPosition(
    String text, {
    Position? position,
  }) async {
    // If the position is not passed in, use the current selection.
    position ??= selection?.start;

    // If there is no position, or if the selection is not collapsed, do nothing.
    if (position == null || !(selection?.isCollapsed ?? false)) {
      return;
    }

    final path = position.path;
    final node = getNodeAtPath(path);

    if (node == null) {
      return;
    }

    // Get the transaction and the path of the next node.
    final transaction = this.transaction;
    final delta = node.delta;
    if (delta == null) {
      return;
    }

    // Insert the text at the given position.
    transaction.insertText(node, position.offset, text);

    // Set the selection to be at the beginning of the new paragraph.
    transaction.afterSelection = Selection.collapsed(
      Position(
        path: path,
        offset: position.offset + text.length,
      ),
    );

    // Apply the transaction.
    return apply(transaction);
  }

  /// format the delta at the given selection.
  ///
  /// If the [Selection] is not passed in, use the current selection.
  Future<void> formatDelta(
    Selection? selection,
    Attributes attributes, [
    bool withUpdateSelection = true,
  ]) async {
    selection ??= this.selection;
    selection = selection?.normalized;

    if (selection == null || selection.isCollapsed) {
      if (selection != null) {
        final nodes = getNodesInSelection(selection);
        if (nodes.isEmpty) {
          return;
        }
        Node node = nodes.last;
        if (node.toggleAttributes == null) {
          node.toggleAttributes = {'position': selection, ...attributes};
        } else {
          node.toggleAttributes!.addAll({'position': selection});
          node.toggleAttributes!.addAll(attributes);
        }
        this.selection = selection;
      }
      return;
    }

    final nodes = getNodesInSelection(selection);
    if (nodes.isEmpty) {
      return;
    }

    final transaction = this.transaction;

    for (final node in nodes) {
      final delta = node.delta;
      if (delta == null || delta.isEmpty) {
        Selection emptySelection = Selection(
          start: Position(path: node.path),
          end: Position(path: node.path),
        );
        if (node.toggleAttributes == null) {
          node.toggleAttributes = {'position': emptySelection, ...attributes};
        } else {
          node.toggleAttributes!.addAll({'position': emptySelection});
          node.toggleAttributes!.addAll(attributes);
        }
        continue;
      }
      final startIndex = node == nodes.first ? selection.startIndex : 0;
      final endIndex = node == nodes.last ? selection.endIndex : delta.length;
      transaction
        ..formatText(
          node,
          startIndex,
          endIndex - startIndex,
          attributes,
        )
        ..afterSelection = transaction.beforeSelection;
    }

    return apply(
      transaction,
      withUpdateSelection: withUpdateSelection,
    );
  }

  /// Toggles the given attribute on or off for the selected text.
  ///
  /// If the [Selection] is not passed in, use the current selection.
  Future<void> toggleAttribute(
    String key, {
    Selection? selection,
  }) async {
    selection ??= this.selection;
    if (selection == null) {
      return;
    }
    final nodes = getNodesInSelection(selection);
    final isHighlight = nodes.allSatisfyInSelection(selection, (delta) {
      return delta.everyAttributes(
        (attributes) => attributes[key] == true,
      );
    });
    await formatDelta(
      selection,
      {
        key: !isHighlight,
      },
    );
  }

  /// format the node at the given selection.
  ///
  /// If the [Selection] is not passed in, use the current selection.
  Future<void> formatNode(
    Selection? selection,
    Node Function(
      Node node,
    ) nodeBuilder,
  ) async {
    selection ??= this.selection;
    selection = selection?.normalized;

    if (selection == null) {
      return;
    }

    final nodes = getNodesInSelection(selection);
    if (nodes.isEmpty) {
      return;
    }

    final transaction = this.transaction;

    for (final node in nodes) {
      transaction
        ..insertNode(
          node.path,
          nodeBuilder(node),
        )
        ..deleteNode(node)
        ..afterSelection = transaction.beforeSelection;
    }

    // 如果是标题增加或者移除，要通知外层
    for (var element in transaction.operations) {
      if (element is InsertOperation || element is DeleteOperation) {
        Iterable<Node> nodes;
        if (element is InsertOperation) {
          nodes = element.nodes;
        } else {
          nodes = (element as DeleteOperation).nodes;
        }
        bool isFind = false;
        for (final node in nodes) {
          if (node.type == HeadingBlockKeys.type) {
            headingChange = true;
            isFind = true;
            break;
          }
        }
        if (isFind) {
          break;
        }
      }
    }
    return apply(transaction);
  }

  /// 设置给的定范围对应的Node的整体属性，包含block属性和文本属性
  Future<void> formatSelectedNode(
    Selection? selection,
    Attributes attributes,
    Node Function(
      Node node,
    ) nodeBuilder, {
    bool isClearFormat = false,
  }) async {
    selection ??= this.selection;
    selection = selection?.normalized;

    if (selection == null) {
      return;
    }

    final nodes = getNodesInSelection(selection).where((element) => !element.isMediaType()).toList();
    if (nodes.isEmpty) {
      return;
    }

    final transaction = this.transaction;

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      Node newNode = nodeBuilder(node);

      transaction
        ..deleteNode(node)
        ..insertNode(
          node.path,
          newNode,
          transform: false,
        )
        ..afterSelection = transaction.beforeSelection;

      final delta = node.delta;
      newNode.path;
      if (delta == null) {
        continue;
      }
      if (!isClearFormat) {
        // transaction
        //   ..formatText(
        //     node,
        //     0,
        //     delta.length,
        //     attributes,
        //   )
        //   ..afterSelection = transaction.beforeSelection;
      } else {
        if (i == 0) {
          if (nodes.length == 1) {
            transaction
              ..customFormatText(
                newNode,
                selection.startIndex,
                selection.endIndex - selection.startIndex,
                attributes,
                node.path,
                transform: false,
              )
              ..afterSelection = transaction.beforeSelection;
          } else {
            transaction
              ..customFormatText(
                newNode,
                selection.startIndex,
                delta.length - selection.startIndex,
                attributes,
                node.path,
                transform: false,
              )
              ..afterSelection = transaction.beforeSelection;
          }
        } else if (i == nodes.length - 1) {
          transaction
            ..customFormatText(
              newNode,
              0,
              selection.endIndex,
              attributes,
              node.path,
              transform: false,
            )
            ..afterSelection = transaction.beforeSelection;
        } else {
          transaction
            ..customFormatText(
              newNode,
              0,
              delta.toPlainText().length,
              attributes,
              node.path,
              transform: false,
            )
            ..afterSelection = transaction.beforeSelection;
        }
      }
    }

    // 如果是标题增加或者移除，要通知外层
    for (var element in transaction.operations) {
      if (element is InsertOperation || element is DeleteOperation) {
        Iterable<Node> nodes;
        if (element is InsertOperation) {
          nodes = element.nodes;
        } else {
          nodes = (element as DeleteOperation).nodes;
        }
        bool isFind = false;
        for (final node in nodes) {
          if (node.type == HeadingBlockKeys.type) {
            headingChange = true;
            isFind = true;
            break;
          }
        }
        if (isFind) {
          break;
        }
      }
    }
    return apply(transaction);
  }

  /// update the node attributes at the given selection.
  ///
  /// If the [Selection] is not passed in, use the current selection.
  Future<void> updateNode(
    Selection? selection,
    Node Function(
      Node node,
    ) nodeBuilder,
  ) async {
    selection ??= this.selection;
    selection = selection?.normalized;

    if (selection == null) {
      return;
    }

    final nodes = getNodesInSelection(selection);
    if (nodes.isEmpty) {
      return;
    }

    final transaction = this.transaction;

    for (final node in nodes) {
      transaction
        ..updateNode(node, nodeBuilder(node).attributes)
        ..afterSelection = transaction.beforeSelection;
    }

    return apply(transaction);
  }

  /// Insert text at the given index of the given [Node] or the [Path].
  ///
  /// [Path] and [Node] are mutually exclusive.
  /// One of these two parameters must have a value.
  Future<void> insertText(
    int index,
    String text, {
    Path? path,
    Node? node,
  }) async {
    node ??= getNodeAtPath(path!);
    if (node == null) {
      assert(false, 'node is null');
      return;
    }
    return apply(
      transaction..insertText(node, index, text),
    );
  }

  Future<void> insertTextAtCurrentSelection(String text) async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    return insertText(
      selection.startIndex,
      text,
      path: selection.end.path,
    );
  }

  /// Get the text in the given selection.
  ///
  /// If the [Selection] is not passed in, use the current selection.
  ///
  List<String> getTextInSelection([
    Selection? selection,
  ]) {
    List<String> res = [];
    selection ??= this.selection;
    if (selection == null || selection.isCollapsed) {
      return res;
    }
    final nodes = getNodesInSelection(selection);
    for (final node in nodes) {
      final delta = node.delta;
      if (delta == null) {
        continue;
      }
      final startIndex = node == nodes.first ? selection.startIndex : 0;
      final endIndex = node == nodes.last ? selection.endIndex : delta.length;
      res.add(delta.slice(startIndex, endIndex).toPlainText());
    }
    return res;
  }

  /// Get the attributes in the given selection.
  ///
  /// If the [Selection] is not passed in, use the current selection.
  ///
  T? getDeltaAttributeValueInSelection<T>(
    String key, [
    Selection? selection,
  ]) {
    selection ??= this.selection;
    selection = selection?.normalized;
    if (selection == null || !selection.isSingle) {
      return null;
    }
    final node = getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (delta == null) {
      return null;
    }
    final ops = delta.whereType<TextInsert>();
    final startOffset = selection.start.offset;
    final endOffset = selection.end.offset;
    var start = 0;
    for (final op in ops) {
      if (start >= endOffset) {
        break;
      }
      final length = op.length;
      if (start < endOffset && start + length > startOffset) {
        final attributes = op.attributes;
        if (attributes != null &&
            attributes.containsKey(key) &&
            attributes[key] is T) {
          return attributes[key] as T;
        }
      }
      start += length;
    }
    return null;
  }
}
