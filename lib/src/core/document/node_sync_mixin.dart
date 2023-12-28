part of 'node.dart';

mixin NodeSyncMixin on SyncNode {
  static String typeName = 'Node';
  static void registerJson() {
    JsonSerialization().register<Node>(
      (Node object) {
        return object.toJson();
      },
      (Map<String, dynamic> params) {
        return Node.fromJson(params);
      },
      typename: typeName,
    );
  }

  Node get thiz => this as Node;

  @override
  Map<String, dynamic> nodeTree() {
    final map = <String, Object>{
      'type': thiz.type,
      'id': thiz.syncNodeId,
      'astype': 'Node',
      'rev': thiz.rev,
    };
    map['children'] = getIdOrValue(thiz._children)!;
    // if (thiz.children.isNotEmpty) {
    //   map['children'] = thiz.children
    //       .map(
    //         (node) => node.nodeTree(),
    //       )
    //       .toList(growable: false);
    // }
    if (thiz.attributes.isNotEmpty) {
      // filter the null value
      map['attributes'] = getIdOrValue(thiz._attributes)!;
    }
    return map;
  }

  @override
  void buildDependedField(Map<String, dynamic> params) {
    params = Map<String, dynamic>.from(params);
    if (params.containsKey("attributes")) {
      final newAttri = params.remove("attributes");
      thiz.trggerParentValueLstenerBefore(thiz, '_attributes', newAttri);
      thiz.attributes = newAttri;
    }
  }

  @override
  void applyDiff(Diff diff, bool useOldField) {
    buildDependedField(useOldField ? diff.olddata : diff.newdata);
  }

  @override
  SyncNode? findNode(List<int> path, int level) {
    return null;
  }

  set attributes(Map<String, dynamic> attributes) {
    final newAttri = SyncRxMap<String, dynamic>.fromJson(attributes);
    thiz.trggerParentValueLstenerBefore(thiz, '_attributes', newAttri);
    thiz._attributes.unmount();
    newAttri.mount(thiz);
    final old = thiz._attributes;
    thiz._attributes = newAttri;
    thiz.updateNode();
    thiz.updateVersion();
    if (thiz.mounted) {
      thiz.notifyDiff("attributes", newAttri, old);
    }
    thiz.trggerParentValueLstener(thiz, '_attributes', newAttri);
  }

  @override
  void updateNode() {
    thiz.notify();
  }

  @override
  void visitChildNode(NodeVisitor visitor) {
    visitor(thiz._children);
    thiz._children.visitChildNode(visitor);
  }

  ///////////////////////////////////////////////////////
  /// 双链表改成 list
  Node? getSafeParentNode() {
    if (thiz.syncNodeParent == null) {
      return null;
    }
    if (thiz.syncNodeParent is! Node && thiz.syncNodeParent is! SyncRxList) {
      return null;
    }
    final parentNode = thiz.syncNodeParent?.syncNodeParent as Node?;
    return parentNode;
  }

  List<Node>? getParentContainer() {
    if (thiz.syncNodeParent == null) {
      return null;
    }
    if (thiz.syncNodeParent is! Node && thiz.syncNodeParent is! SyncRxList) {
      return null;
    }
    final parentNode = thiz.syncNodeParent?.syncNodeParent as Node?;
    return thiz.parent?._children ?? parentNode?._children;
  }

  void insertAfter(Node entry) {
    final list = getParentContainer();
    assert(list != null);
    if (list == null) {
      return;
    }
    final index = list.indexOf(thiz);
    assert(index != -1);
    list.insert(index + 1, entry);
  }

  void insertBefore(Node entry) {
    final list = getParentContainer();
    assert(list != null);
    if (list == null) {
      return;
    }
    final index = list.indexOf(thiz);
    assert(index != -1);
    list.insert(index, entry);
  }

  void unlink() {
    getParentContainer()?.remove(this);
  }

  Node? get next {
    final list = getParentContainer();
    if (list == null) {
      return null;
    }
    final index = list.indexOf(thiz);
    if (index == -1) {
      return null;
    }
    if (index + 1 >= list.length) {
      return null;
    }
    return list[index + 1];
  }

  Node? get previous {
    final list = getParentContainer();
    if (list == null) {
      return null;
    }
    final index = list.indexOf(thiz);
    if (index <= 0) {
      return null;
    }
    if (list.length <= 1) {
      return null;
    }
    return list[index - 1];
  }
}
