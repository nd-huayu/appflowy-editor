import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'audio_control_widget.dart';

class AudioBlockKeys {
  const AudioBlockKeys._();

  static const String type = 'audio';

  static const String url = 'url';
  static const String width = 'width';
  static const String height = 'height';
  static const String autoPlay = 'autoplay';
  static const String isLoop = 'isloop';
}

Node audioNode({
  required String url,
  double? height,
  double? width,
  bool? autoPlay,
  bool? isLoop,
}) {
  return Node(
    type: AudioBlockKeys.type,
    attributes: {
      AudioBlockKeys.url: url,
      AudioBlockKeys.height: height,
      AudioBlockKeys.width: width,
      AudioBlockKeys.autoPlay: autoPlay,
      AudioBlockKeys.isLoop: isLoop,
    },
  );
}

class AudioBlockComponentBuilder extends BlockComponentBuilder {
  AudioBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return AudioBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
    );
  }

  @override
  bool validate(Node node) => node.attributes[AudioBlockKeys.url] != null;
}

class AudioBlockComponentWidget extends BlockComponentStatefulWidget {
  const AudioBlockComponentWidget({
    super.key,
    required super.node,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<AudioBlockComponentWidget> createState() =>
      AudioBlockComponentWidgetState();
}

class AudioBlockComponentWidgetState extends State<AudioBlockComponentWidget>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  final audioKey = GlobalKey();

  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  late final editorState = Provider.of<EditorState>(context, listen: false);

  final showActionsNotifier = ValueNotifier<bool>(false);
  final showBoarderNotifier = ValueNotifier<bool>(false);

  late final player = Player();
  late final controller = VideoController(player);

  @override
  void initState() {
    MediaKit.ensureInitialized();
    editorState.selectionNotifier.addListener(_inSelectNode);
    final url = node.attributes[AudioBlockKeys.url];
    bool autoPlay = node.attributes[AudioBlockKeys.autoPlay] ?? false;
    bool isLoop = node.attributes[AudioBlockKeys.isLoop] ?? false;
    player.setPlaylistMode(isLoop ? PlaylistMode.loop : PlaylistMode.none);
    player.open(Media(url), play: autoPlay);

    super.initState();
  }

  @override
  void dispose() {
    editorState.selectionNotifier.removeListener(_inSelectNode);
    player.dispose();
    super.dispose();
  }

  void _inSelectNode() {
    final selection = editorState.selectionNotifier.value?.normalized;
    final path = widget.node.path;
    showBoarderNotifier.value = path.inSelection(selection);
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final attributes = node.attributes;
    final width = attributes[AudioBlockKeys.width]?.toDouble() ??
        MediaQuery.of(context).size.width;

    //seekBarContainerHeight + buttonBarHeight + seekBarMargin.top
    final height = attributes[AudioBlockKeys.height]?.toDouble() ?? 53;

    Widget child = SizedBox(
      width: width,
      height: height,
      child: Video(
        controller: controller,
        fill: Colors.transparent,
        controls: (state) {
          return DefaultDesktopAudioControls(state);
        },
      ),
    );

    child = Stack(children: [
      child,
      Positioned.fill(
          child: ValueListenableBuilder<bool>(
              valueListenable: showBoarderNotifier,
              builder: (context, value, c) {
                return value ? c! : const SizedBox.shrink();
              },
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(44.0),
                      border: Border.all(
                    color: editorState.editorStyle.cursorColor,
                    width: 2.0,
                  )),
                ),
              )))
    ]);

    child = Padding(
      key: audioKey,
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

    return child;
  }

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({
    bool shiftWithBaseOffset = false,
  }) {
    final imageBox = audioKey.currentContext?.findRenderObject();
    if (imageBox is RenderBox) {
      return Offset.zero & imageBox.size;
    }
    return Rect.zero;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) {
      return null;
    }
    final size = _renderBox!.size;
    return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
  }

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) {
      return [];
    }
    final parentBox = context.findRenderObject();
    final imageBox = audioKey.currentContext?.findRenderObject();
    if (parentBox is RenderBox && imageBox is RenderBox) {
      return [
        imageBox.localToGlobal(Offset.zero, ancestor: parentBox) &
            imageBox.size,
      ];
    }
    return [Offset.zero & _renderBox!.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
        path: widget.node.path,
        startOffset: 0,
        endOffset: 1,
      );

  @override
  Offset localToGlobal(
    Offset offset, {
    bool shiftWithBaseOffset = false,
  }) =>
      _renderBox!.localToGlobal(offset);
}
