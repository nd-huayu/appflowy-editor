import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/document.dart';
import 'package:appflowy_editor/src/core/document/registerjson.dart';
import 'package:appflowy_editor/src/sync/IDocCooperativeApi.dart';
import 'package:appflowy_editor/src/sync/NdOnlineController.dart';
import 'package:autosync/autosync.dart';

class SyncNodeTreeController {
  static void initJson() {
    registerJson();
  }

  static late Document sleft;
  static late Document sright;
  static void connect(Document left, Document right) {
    sleft = left;
    sright = right;
    final leftRoot = SyncNodeRoot.get(left.hashCode.toString());
    final rightRoot = SyncNodeRoot.get(right.hashCode.toString());

    leftRoot.firstChild = left.root;
    rightRoot.firstChild = right.root;

    leftRoot.onDiffHandler = (diff) {
      final log = diff.toJson();
      print(log);
      // rightRoot.dispatchDiff([diff]);
    };

    // final connectBean = ConnectBean(
    //   'sssssssssxx',
    //   'mockweb',
    //   2012,
    //   '1',
    //   'Metting',
    //   '0',
    //   null,
    //   false,
    //   null,
    // );
    // initOnlineDocument(
    //   left,
    //   0,
    //   'https://gcdncs.101.com/v0.1/static/superboard/temp/download8.superboard',
    //   connectBean,
    // );
  }
}
