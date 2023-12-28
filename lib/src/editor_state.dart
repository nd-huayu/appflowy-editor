import 'dart:async';
import 'dart:math';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/scroll/auto_scroller.dart';
import 'package:appflowy_editor/src/history/undo_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import 'history/universal_undo_manager_2.dart';

class ApplyOptions {
  /// This flag indicates that
  /// whether the transaction should be recorded into
  /// the undo stack
  final bool recordUndo;
  final bool recordRedo;
  final bool fromUndoOpt;
  final bool fromRedoOpt;
  const ApplyOptions({
    this.recordUndo = true,
    this.recordRedo = false,
    this.fromUndoOpt = false,
    this.fromRedoOpt = false,
  });
}

@Deprecated('use SelectionUpdateReason instead')
enum CursorUpdateReason {
  uiEvent,
  others,
}

enum SelectionUpdateReason {
  uiEvent, // like mouse click, keyboard event
  transaction, // like insert, delete, format
  selectAll,
  searchHighlight, // Highlighting search results
}

enum SelectionType {
  inline,
  block,
}

enum TransactionTime {
  before,
  after,
}

/// 是否屏蔽部分功能
const bool isCoverAll = false;

typedef DirectoryClickCallback = void Function(Node node);

/// 点击抬起时回调
typedef TapUpCallback = void Function(TapUpDetails tapUpDetails);

/// 选区结束时回调
typedef PanEndCallback = void Function(DragEndDetails dragEndDetails);

/// 字体加载回调
typedef SupportDisplayFamily = List<String> Function(
  String? curFamily,
  String content,
  Node node,
);

/// The state of the editor.
///
/// The state includes:
/// - The document to render
/// - The state of the selection
///
/// [EditorState] also includes the services of the editor:
/// - Selection service
/// - Scroll service
/// - Keyboard service
/// - Input service
/// - Toolbar service
///
/// In consideration of collaborative editing,
/// all the mutations should be applied through [Transaction].
///
/// Mutating the document with document's API is not recommended.
class EditorState {
  EditorState({
    required this.document,
    this.minHistoryItemDuration = const Duration(milliseconds: 200),
  }) {
    undoManager.state = this;
  }

  @Deprecated('use EditorState.blank() instead')
  EditorState.empty()
      : this(
          document: Document.blank(),
        );

  EditorState.blank({
    bool withInitialText = true,
  }) : this(
          document: Document.blank(
            withInitialText: withInitialText,
          ),
        );

  final Document document;

  // the minimum duration for saving the history item.
  final Duration minHistoryItemDuration;
  // 获取协同控制接口
  IDocCooperativeApi? get cooperativeApi =>
      document.root.root?.firstChild as IDocCooperativeApi;

  /// Whether the editor is editable.
  bool editable = true;

  /// The style of the editor.
  late EditorStyle editorStyle;

  double curCanvasScale = 1.0;

  /// The selection notifier of the editor.
  PropertyValueNotifier<Selection?> selectionNotifier =
      PropertyValueNotifier<Selection?>(null);

  /// The selection of the editor.
  Selection? get selection => selectionNotifier.value;

  /// fyl：上一次的选中区域，用来修复文本内容好几页时，全选-更改字号会触发内容滚动问题
  Selection? preSelection;

  /// Sets the selection of the editor.
  set selection(Selection? value) {
    preSelection = selectionNotifier.value;
    selectionNotifier.value = value;
  }

  /// 标题变化通知器
  final PropertyValueNotifier<bool> headingNotifier =
      PropertyValueNotifier<bool>(false);

  set headingChange(bool isChange) {
    headingNotifier.value = isChange;
  }

  SelectionType? selectionType;

  SelectionUpdateReason _selectionUpdateReason = SelectionUpdateReason.uiEvent;
  SelectionUpdateReason get selectionUpdateReason => _selectionUpdateReason;

  Map? selectionExtraInfo;

  // Service reference.
  final service = EditorService();

  AppFlowyScrollService? get scrollService => service.scrollService;

  AppFlowySelectionService get selectionService => service.selectionService;
  BlockComponentRendererService get renderer => service.rendererService;
  set renderer(BlockComponentRendererService value) {
    service.rendererService = value;
  }

  /// store the auto scroller instance in here temporarily.
  AutoScroller? autoScroller;
  ScrollableState? scrollableState;

  /// Configures log output parameters,
  /// such as log level and log output callbacks,
  /// with this variable.
  LogConfiguration get logConfiguration => LogConfiguration();

  /// Stores the selection menu items.
  List<SelectionMenuItem> selectionMenuItems = [];

  /// Stores the toolbar items.
  @Deprecated('use floating toolbar or mobile toolbar instead')
  List<ToolbarItem> toolbarItems = [];

  /// listen to this stream to get notified when the transaction applies.
  Stream<(TransactionTime, Transaction)> get transactionStream =>
      _observer.stream;
  final StreamController<(TransactionTime, Transaction)> _observer =
      StreamController.broadcast(
    sync: true,
  );

  final UniversalUndoManager2 undoManager = UniversalUndoManager2(1000);

  Transaction get transaction {
    final transaction = Transaction(document: document);
    transaction.beforeSelection = selection;
    return transaction;
  }

  // TODO: only for testing.
  bool disableSealTimer = false;
  bool disableRules = false;

  @Deprecated('use editorState.selection instead')
  Selection? _cursorSelection;
  @Deprecated('use editorState.selection instead')
  Selection? get cursorSelection {
    return _cursorSelection;
  }

  RenderBox? get renderBox {
    final renderObject =
        service.scrollServiceKey.currentContext?.findRenderObject();
    if (renderObject != null && renderObject is RenderBox) {
      return renderObject;
    }
    return null;
  }

  Future<void> updateSelectionWithReason(
    Selection? selection, {
    SelectionUpdateReason reason = SelectionUpdateReason.transaction,
    Map? extraInfo,
  }) async {
    final completer = Completer<void>();

    if (reason == SelectionUpdateReason.uiEvent) {
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => completer.complete(),
      );
    }

    // broadcast to other users here
    _selectionUpdateReason = reason;
    this.selection = selection;

    return completer.future;
  }

  @Deprecated('use updateSelectionWithReason or editorState.selection instead')
  Future<void> updateCursorSelection(
    Selection? cursorSelection, [
    CursorUpdateReason reason = CursorUpdateReason.others,
  ]) {
    final completer = Completer<void>();

    // broadcast to other users here
    if (reason != CursorUpdateReason.uiEvent) {
      service.selectionService.updateSelection(cursorSelection);
    }
    _cursorSelection = cursorSelection;
    selection = cursorSelection;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      completer.complete();
    });
    return completer.future;
  }

  Timer? _debouncedSealHistoryItemTimer;
  final bool _enableCheckIntegrity = false;

  // the value of the notifier is meaningless, just for triggering the callbacks.
  final ValueNotifier<int> onDispose = ValueNotifier(0);

  void dispose() {
    _observer.close();
    _debouncedSealHistoryItemTimer?.cancel();
    onDispose.value += 1;
    onDispose.dispose();
  }

  /// Apply the transaction to the state.
  ///
  /// The options can be used to determine whether the editor
  /// should record the transaction in undo/redo stack.
  ///
  /// The maximumRuleApplyLoop is used to prevent infinite loop.
  ///
  /// The withUpdateSelection is used to determine whether the editor
  /// should update the selection after applying the transaction.
  Future<void> apply(
    Transaction transaction, {
    bool isRemote = false,
    ApplyOptions options = const ApplyOptions(recordUndo: true),
    bool withUpdateSelection = true,
  }) async {
    if (!editable) {
      return;
    }

    // it's a time consuming task, only enable it if necessary.
    if (_enableCheckIntegrity) {
      document.root.checkDocumentIntegrity();
    }

    final completer = Completer<void>();

    // broadcast to other users here, before applying the transaction
    _observer.add((TransactionTime.before, transaction));

    for (final operation in transaction.operations) {
      Log.editor.debug('apply op: ${operation.toJson()}');
      _applyOperation(operation);
    }

    // broadcast to other users here, after applying the transaction
    _observer.add((TransactionTime.after, transaction));

    _recordRedoOrUndo(options, transaction);

    if (withUpdateSelection) {
      _selectionUpdateReason = SelectionUpdateReason.transaction;
      selection = transaction.afterSelection;
      _selectionUpdateReason = SelectionUpdateReason.uiEvent;
    }

    // TODO: execute this line after the UI has been updated.
    completer.complete();
    _checkTransactionHeading(transaction);
    wordChange = true;

    return completer.future;
  }

  /// check current transcation heading
  void _checkTransactionHeading(Transaction transaction) {
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
  }

  /// Force rebuild the editor.
  void reload() {
    document.root.notify();
  }

  /// get nodes in selection
  ///
  /// if selection is backward, return nodes in order
  /// if selection is forward, return nodes in reverse order
  ///
  List<Node> getNodesInSelection(Selection selection) {
    // Normalize the selection.
    final normalized = selection.normalized;

    // Get the start and end nodes.
    final startNode = document.nodeAtPath(normalized.start.path);
    final endNode = document.nodeAtPath(normalized.end.path);

    // If we have both nodes, we can find the nodes in the selection.
    if (startNode != null && endNode != null) {
      final nodes = NodeIterator(
        document: document,
        startNode: startNode,
        endNode: endNode,
      ).toList();

      return selection.isForward ? nodes.reversed.toList() : nodes;
    }

    // If we don't have both nodes, we can't find the nodes in the selection.
    return [];
  }

  List<Node> getSelectedNodes({
    Selection? selection,
    bool withCopy = true,
  }) {
    List<Node> res = [];
    selection ??= this.selection;
    if (selection == null) {
      return res;
    }
    final nodes = getNodesInSelection(selection);
    for (final node in nodes) {
      if (res.any((element) => element.isParentOf(node))) {
        continue;
      }
      res.add(node);
    }

    if (withCopy) {
      res = res.map((e) => e.copyWith()).toList();
    }

    if (res.isNotEmpty) {
      var delta = res.first.delta;
      if (delta != null) {
        res.first.updateAttributes(
          {
            ...res.first.attributes,
            blockComponentDelta: delta
                .slice(
                  selection.startIndex,
                  selection.isSingle ? selection.endIndex : delta.length,
                )
                .toJson(),
          },
        );
      }

      var node = res.last;
      while (node.children.isNotEmpty) {
        node = node.children.last;
      }
      delta = node.delta;
      if (delta != null && !selection.isSingle) {
        if (node.parent != null) {
          node.insertBefore(
            node.copyWith(
              attributes: {
                ...node.attributes,
                blockComponentDelta: delta
                    .slice(
                      0,
                      selection.endIndex,
                    )
                    .toJson(),
              },
            ),
          );
          node.unlink();
        } else {
          node.updateAttributes(
            {
              ...node.attributes,
              blockComponentDelta: delta
                  .slice(
                    0,
                    selection.endIndex,
                  )
                  .toJson(),
            },
          );
        }
      }
    }

    return res;
  }

  Node? getNodeAtPath(Path path) {
    return document.nodeAtPath(path);
  }

  /// The current selection areas's rect in editor.
  List<Rect> selectionRects({Selection? targetSelection}) {
    Selection? selection = this.selection;

    if (targetSelection != null) {
      selection = targetSelection;
    }
    if (selection == null) {
      return [];
    }

    final nodes = getNodesInSelection(selection);
    final rects = <Rect>[];

    if (selection.isCollapsed && nodes.length == 1) {
      final selectable = nodes.first.selectable;
      if (selectable != null) {
        final rect = selectable.getCursorRectInPosition(
          selection.end,
          shiftWithBaseOffset: true,
        );
        if (rect != null) {
          rects.add(
            selectable.transformRectToGlobal(
              rect,
              shiftWithBaseOffset: true,
            ),
          );
        }
      }
    } else {
      for (final node in nodes) {
        final selectable = node.selectable;
        if (selectable == null) {
          continue;
        }
        final nodeRects = selectable.getRectsInSelection(
          selection,
          shiftWithBaseOffset: true,
        );
        if (nodeRects.isEmpty) {
          continue;
        }
        final renderBox = node.renderBox;
        if (renderBox == null) {
          continue;
        }
        for (final rect in nodeRects) {
          final globalOffset = renderBox.localToGlobal(rect.topLeft);
          rects.add(globalOffset & rect.size);
        }
      }
    }

    return rects;
  }

  void cancelSubscription() {
    _observer.close();
  }

  void updateAutoScroller(
    ScrollableState scrollableState,
  ) {
    if (this.scrollableState != scrollableState) {
      autoScroller?.stopAutoScroll();
      autoScroller = AutoScroller(
        scrollableState,
        velocityScalar: PlatformExtension.isDesktopOrWeb ? 50 : 100,
        onScrollViewScrolled: () {},
      );
      this.scrollableState = scrollableState;
    }
  }

  void _recordRedoOrUndo(ApplyOptions options, Transaction transaction) {
    if (options.recordUndo) {
      final undoItem = undoManager.getUndoHistoryItem(options.fromRedoOpt);
      undoItem.addAll(transaction.operations);
      if (undoItem.beforeSelection == null &&
          transaction.beforeSelection != null) {
        undoItem.beforeSelection = transaction.beforeSelection;
      }
      undoItem.afterSelection = transaction.afterSelection;
      if (options.fromUndoOpt) {
        if (undoManager.undoStack.isNonEmpty) {
          Log.editor.debug('Seal history item');
          final last = undoManager.undoStack.last;
          last.seal();
        }
      } else {
        _debouncedSealHistoryItem();
      }
    } else if (options.recordRedo) {
      final redoItem = HistoryItem();
      redoItem.addAll(transaction.operations);
      redoItem.beforeSelection = transaction.beforeSelection;
      redoItem.afterSelection = transaction.afterSelection;
      undoManager.redoStack.push(redoItem);
    }
  }

  void _debouncedSealHistoryItem() {
    if (disableSealTimer) {
      return;
    }
    _debouncedSealHistoryItemTimer?.cancel();
    _debouncedSealHistoryItemTimer = Timer(minHistoryItemDuration, () {
      if (undoManager.undoStack.isNonEmpty) {
        Log.editor.debug('Seal history item');
        final last = undoManager.undoStack.last;
        last.seal();
      }
    });
  }

  void _applyOperation(Operation op) {
    if (op is InsertOperation) {
      document.insert(op.path, op.nodes);
    } else if (op is UpdateOperation) {
      // ignore the update operation if the attributes are the same.
      if (!mapEquals(op.attributes, op.oldAttributes)) {
        document.update(op.path, op.attributes);
      }
    } else if (op is DeleteOperation) {
      document.delete(op.path, op.nodes.length);
    } else if (op is UpdateTextOperation) {
      document.updateText(op.path, op.delta);
    }
  }

  /// 获取标题Nodes
  List<Node> getAllHeadingNodes() {
    List<Node> headingNodes = [];
    for (var element in document.root.children) {
      if (element.type == HeadingBlockKeys.type) {
        headingNodes.add(element);
      }
    }
    return headingNodes;
  }

  /// 目录点击回调
  DirectoryClickCallback? onDirectoryClick;

  /// 获取当前node字体最大和最小值
  Tuple2<double, double> getCurNodeMaxFontSize(Node node) {
    double maxFontSize = 16;
    double minFontSize = 16;

    final textInserts = node.delta!.whereType<TextInsert>();
    int firstIndex = 0;
    for (final textInsert in textInserts) {
      final attributes = textInsert.attributes;
      if (firstIndex == 0) {
        if (attributes != null) {
          if (attributes.fontSize != null) {
            maxFontSize = attributes.fontSize!;
            minFontSize = attributes.fontSize!;
          }
        }
      } else {
        if (attributes != null) {
          if (attributes.fontSize != null) {
            maxFontSize = max(maxFontSize, attributes.fontSize!);
            minFontSize = min(minFontSize, attributes.fontSize!);
          }
        }
      }
      firstIndex++;
    }
    return Tuple2(minFontSize, maxFontSize);
  }

  /// 单击抬起回调
  TapUpCallback? onTapUpCallback;

  /// 选区结束回调
  PanEndCallback? onPanEndCallback;

  /// 是否支持当前字体
  SupportDisplayFamily? onSupportDisplayFamily;

  /// 字数变化通知器
  final PropertyValueNotifier<bool> wordNotifier =
      PropertyValueNotifier<bool>(false);

  set wordChange(bool isChange) {
    wordNotifier.value = isChange;
  }

  /// 文档字数
  int getDocumentWordLength() {
    int totalLength = 0;
    for (var node in document.root.children) {
      if (node.delta != null) {
        totalLength += node.delta!.toPlainText().replaceAll('\t', '').replaceAll(' ', '').length;
      }
    }
    return totalLength;
  }
}
