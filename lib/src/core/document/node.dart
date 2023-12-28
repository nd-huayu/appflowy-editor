import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:autosync/autosync.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/non_secure.dart';
part 'node_sync_mixin.dart';
part 'node_editing_mixin.dart';

abstract class NodeExternalValues {
  const NodeExternalValues();
}

/// [Node] represents a node in the document tree.
///
/// It contains three parts:
///   - [type]: The type of the node to determine which block component to render it.
///   - [data]: The data of the node to determine how to render it.
///   - [children]: The children of the node.
///
///
/// Json format:
/// ```
/// {
///   'type': String,
///   'data': Map<String, Object>
///   'children': List<Node>,
/// }
/// ```
///

final class Node extends ChangeNotifier
    with SyncNode, NodeSyncMixin, NodeEditingMixin {
  Node({
    required this.type,
    String? id,
    Node? parent,
    Attributes attributes = const {},
    Iterable<Node> children = const [],
  })  : _children = SyncRxList<Node>.empty(name: '_children')
          ..addAll(
            children.map(
              (e) => e..unlink(),
            ),
          ), // unlink the given children to avoid the error of "node has already a parent"
        _attributes = SyncRxMap<String, dynamic>.from(attributes),
        id = id ?? nanoid(6) {
    _parent = parent;
    for (final child in children) {
      child.parent = this;
      child.syncNodeParent = _children;
    }
    _children.syncNodeParent = this;
  }

  Node.fromSyncNode({
    required this.type,
    String? id,
    Node? parent,
    SyncRxMap<String, dynamic>? attributes,
    SyncRxList<Node>? children,
  }) : id = id ?? nanoid(6) {
    _parent = parent;
    children?.forEach((element) => element.unlink);
    _children = children ?? SyncRxList<Node>();
    _attributes = attributes ?? SyncRxMap<String, dynamic>();
    _children.syncNodeParent = this;
    _attributes.syncNodeParent = this;
    for (final child in _children) {
      child.parent = this;
      child.syncNodeParent = _children;
    }
  }

  /// Parses a [Map] into a [Node]
  ///
  factory Node.fromJson(Map<String, dynamic> json) {
    final astype = json['astype'] as String? ?? 'Node';
    final syncId = json['id'];
    final rev = json['rev'] ?? 0;

    final type = json['type'] as String;
    final children = getValue<SyncRxList<Node>?, Node>(json['children']);
    final attributes =
        SyncRxMap<String, dynamic>.from(json['attributes'] ?? {});
    final node = Node.fromSyncNode(
      type: type,
      attributes: attributes,
      children: children,
    )
      ..rev = rev
      ..syncNodeId = syncId;
    return node;
  }

  /// The type of the node.
  final String type;

  /// The id of the node.
  final String id;

  @Deprecated('Use type instead')
  String get subtype => type;

  // @Deprecated('Use type instead')
  // String get id => type;

  /// The parent of the node.
  Node? _parent;

  Node? get parent => _parent ?? getSafeParentNode();
  set parent(Node? parent) => _parent = parent;

  /// The children of the node.
  late final SyncRxList<Node> _children;
  SyncRxList<Node> get syncChildren => _children;
  List<Node> get children {
    return _children;
    // _cacheChildren ??= _children.toList(growable: false);
    // return _cacheChildren!;
  }

  // List<Node>? _cacheChildren;

  /// The attributes of the node.
  late SyncRxMap<String, dynamic> _attributes;
  Attributes get attributes => {..._attributes};

  /// The path of the node.
  Path get path => _computePath();

  NodeExternalValues? externalValues;

  // Render Part
  final key = GlobalKey();
  final layerLink = LayerLink();

  // 预设的属性值
  Attributes? toggleAttributes;

  void notify() {
    notifyListeners();
  }

  /// Update the attributes of the node.
  ///
  void updateAttributes(Attributes attributes) {
    this.attributes = composeAttributes(this.attributes, attributes) ?? {};
    notifyListeners();
  }

  /// Grabs the [Node] from this [Node]s children
  /// at a given index, if the index exists.
  ///
  Node? childAtIndexOrNull(int index) {
    if (children.length <= index || index < 0) {
      return null;
    }

    return children.elementAt(index);
  }

  Node? childAtPath(Path path) {
    if (path.isEmpty) {
      return this;
    }

    final index = path.first;
    final child = childAtIndexOrNull(index);
    return child?.childAtPath(path.sublist(1));
  }

  /// Inserts a [Node] at a given [index]
  ///
  /// If no [index] is supplied, inserts at the
  /// end of the [Node].
  ///
  void insert(Node entry, {int? index}) {
    final length = _children.length;
    index ??= length;

    Log.editor.debug('insert Node $entry at path ${path + [index]}}');

    entry._resetRelationshipIfNeeded();
    entry.parent = this;

    // _cacheChildren = null;

    if (_children.isEmpty) {
      _children.add(entry);
      notifyListeners();
      return;
    }

    // If index is out of range, insert at the end.
    // If index is negative, insert at the beginning.
    // If index is positive, insert at the index.
    if (index >= length) {
      _children.add(entry);
    } else if (index <= 0) {
      _children.insert(0, entry);
    } else {
      _children.insert(index, entry);
    }
    notifyListeners();
  }

  @override
  void insertAfter(Node entry) {
    entry.parent = parent;
    super.insertAfter(entry);

    // parent?._cacheChildren = null;

    // Notifies the new node.
    parent?.notifyListeners();
  }

  @override
  void insertBefore(Node entry) {
    entry.parent = parent;
    super.insertBefore(entry);

    // parent?._cacheChildren = null;

    // Notifies the new node.
    parent?.notifyListeners();
  }

  @override
  bool unlink() {
    if (parent == null) {
      return false;
    }
    Log.editor.debug('delete Node $this from path $path');
    super.unlink();

    // parent?._cacheChildren = null;

    parent?.notifyListeners();
    parent = null;
    return true;
  }

  // reset the relationship of the node before inserting it to another node
  //  to ensure it is not in the tree
  // otherwise, it will throw a state error
  //  'Bad state: LinkedNode is already in a LinkedList'
  void _resetRelationshipIfNeeded() {
    if (parent != null /*|| list != null*/) {
      unlink();
    }
  }

  @override
  String toString() {
    return '''Node(id: $id,
    type: $type,
    attributes: $attributes,
    children: $children,
    )''';
  }

  Delta? get delta {
    if (attributes['delta'] is List) {
      return Delta.fromJson(attributes['delta']);
    }
    return Delta();
  }

  Map<String, Object> toJson() {
    final map = <String, Object>{
      'type': type,
      'id': syncNodeId,
      'rev': rev,
      'astype': 'Node',
    };
    map['children'] = getIdOrValue(_children)!;
    if (_attributes.isNotEmpty) {
      // filter the null value
      // map['data'] = attributes..removeWhere((_, value) => value == null);
      map['attributes'] = getIdOrValue(_attributes)!;
    }
    return map;
  }

  Node copyWith({
    String? type,
    Iterable<Node>? children,
    Attributes? attributes,
  }) {
    final node = Node(
      type: type ?? this.type,
      id: nanoid(6),
      attributes: attributes ?? {...this.attributes},
      children: children ?? [],
    );
    if (children == null && _children.isNotEmpty) {
      for (final child in _children) {
        node._children.add(
          child.copyWith()..parent = node,
        );
      }
    }
    return node;
  }

  Path _computePath([Path previous = const []]) {
    final parent = getSafeParentNode();
    if (parent == null) {
      return previous;
    }
    final index = parent.children.indexOf(this);
    return parent._computePath([index, ...previous]);
  }

  /// check the integrity of the document (for DEBUG only)
  void checkDocumentIntegrity() {
    // skip the root node
    if (path.isNotEmpty) {
      // if node is rendered in the tree, its parent should not be null
      final errorMessage =
          '''Please submit an issue to https://github.com/AppFlowy-IO/appflowy-editor/issues if you see this error!
          node = ${toJson()}''';
      assert(
        parent != null,
        errorMessage,
      );
      // also, its parent should contain this node
      assert(
        parent!.children.where((element) => element.id == id).length == 1,
        errorMessage,
      );
    }

    for (final child in children) {
      child.checkDocumentIntegrity();
    }
  }

  bool isMediaType() => type ==  ImageBlockKeys.type || type == AudioBlockKeys.type || type == VideoBlockKeys.type;
}

@Deprecated('Use Paragraph instead')
final class TextNode extends Node {
  TextNode({
    required Delta delta,
    Iterable<Node>? children,
    Attributes? attributes,
  })  : _delta = delta,
        super(
          type: 'text',
          children: children?.toList() ?? [],
          attributes: attributes ?? {},
          id: '',
        );

  TextNode.empty({Attributes? attributes})
      : _delta = Delta(operations: [TextInsert('')]),
        super(
          type: 'text',
          attributes: attributes ?? {},
        );

  @override
  @Deprecated('Use type instead')
  String get subtype => '';

  Delta _delta;
  @override
  Delta get delta => _delta;
  set delta(Delta v) {
    _delta = v;
    notifyListeners();
  }

  @override
  Map<String, Object> toJson() {
    final map = super.toJson();
    map['delta'] = delta.toJson();
    return map;
  }

  @override
  TextNode copyWith({
    String? type = 'text',
    Iterable<Node>? children,
    Attributes? attributes,
    Delta? delta,
    String? id,
  }) {
    final textNode = TextNode(
      children: children ?? [],
      attributes: attributes ?? this.attributes,
      delta: delta ?? this.delta,
    );
    if (children == null && this.children.isNotEmpty) {
      for (final child in this.children) {
        textNode._children.add(
          child.copyWith()..parent = textNode,
        );
      }
    }
    return textNode;
  }

  String toPlainText() => _delta.toPlainText();
}

extension NodeEquality on Iterable<Node> {
  bool equals(Iterable<Node> other) {
    if (length != other.length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (!_nodeEquals(elementAt(i), other.elementAt(i))) {
        return false;
      }
    }
    return true;
  }

  bool _nodeEquals<T, U>(T base, U other) =>
      identical(this, other) ||
      base is Node &&
          other is Node &&
          other.type == base.type &&
          other.children.equals(base.children);
}
