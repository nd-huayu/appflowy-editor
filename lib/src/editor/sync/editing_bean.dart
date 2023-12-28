import 'dart:convert';

class EditingBean {
  int syncNodeId;
  bool lock;
  String? connectId;
  EditingBean({
    required this.syncNodeId,
    required this.lock,
    required this.connectId,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'syncNodeId': syncNodeId,
      'lock': lock,
      'connectId': connectId
    };
  }

  factory EditingBean.fromJson(Map<String, dynamic> params) {
    return EditingBean(
      syncNodeId: params['syncNodeId'],
      lock: params['lock'],
      connectId: params['connectId'],
    );
  }
}

String wrapEditingBeanMessage(EditingBean bean) {
  return jsonEncode(bean);
}
