import 'dart:io';
import 'dart:math';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';

import 'base64_image.dart';

class ResizableImage extends StatefulWidget {
  const ResizableImage(
      {super.key,
      required this.alignment,
      required this.editable,
      required this.onResize,
      required this.width,
      required this.src,
      required this.listenable,
      required this.nodeBoardColor,
      this.height,
      this.degree,
      this.isShadow = false});

  final String src;
  final double width;
  final double? height;
  final double? degree;
  final Alignment alignment;
  final bool editable;
  final bool isShadow;
  final ValueListenable<bool> listenable;
  final Color nodeBoardColor;

  final void Function(double width) onResize;

  @override
  State<ResizableImage> createState() => _ResizableImageState();
}

const _kImageBlockComponentMinWidth = 30.0;

class _ResizableImageState extends State<ResizableImage> {
  late double imageWidth;

  double initialOffset = 0;
  double moveDistance = 0;

  Image? _cacheImage;

  @visibleForTesting
  bool onFocus = false;

  @override
  void initState() {
    super.initState();

    imageWidth = widget.width;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: SizedBox(
        width: max(_kImageBlockComponentMinWidth, imageWidth - moveDistance),
        height: widget.height,
        child: MouseRegion(
          onEnter: (event) => setState(() {
            onFocus = true;
          }),
          onExit: (event) => setState(() {
            onFocus = false;
          }),
          child: _buildResizableImage(context),
        ),
      ),
    );
  }

  Widget _buildResizableImage(BuildContext context) {
    Widget child;
    final src = widget.src;
    if (isBase64(src)) {
      // load base64 image (url is raw base64 from web)
      _cacheImage ??= Image.memory(
        dataFromBase64String(src),
      );
      child = _cacheImage!;
    } else if (isURL(src)) {
      // load network image
      _cacheImage ??= Image.network(
        widget.src,
        width: widget.width,
        gaplessPlayback: true,
        isAntiAlias: true,
        fit: BoxFit.fitWidth,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null ||
              loadingProgress.cumulativeBytesLoaded ==
                  loadingProgress.expectedTotalBytes) {
            return child;
          }
          return _buildLoading(context);
        },
        errorBuilder: (context, error, stackTrace) => _buildError(context),
      );
      child = _cacheImage!;
    } else {
      // load local file
      _cacheImage ??= Image.file(File(src));
      child = _cacheImage!;
    }
    return Stack(
      children: [
        Transform.rotate(
          angle: widget.degree ?? 0,
          child: widget.isShadow
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5), // 阴影颜色
                        spreadRadius: 5, // 阴影扩散程度
                        blurRadius: 7, // 阴影模糊程度
                        offset: const Offset(0, 3), // 阴影的偏移量
                      ),
                    ],
                  ),
                  child: child)
              : child,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: widget.listenable,
          builder: (context, value, c) {
            return value
                ? Positioned.fill(
                    child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                      color: widget.nodeBoardColor,
                      width: 2.0,
                    )),
                  ))
                : const SizedBox.shrink();
          },
          child: child,
        ),
        if (widget.editable) ...[
          _buildEdgeGesture(
            context,
            top: 0,
            left: 5,
            bottom: 0,
            width: 5,
            onUpdate: (distance) {
              setState(() {
                moveDistance = distance;
              });
            },
          ),
          _buildEdgeGesture(
            context,
            top: 0,
            right: 5,
            bottom: 0,
            width: 5,
            onUpdate: (distance) {
              setState(() {
                moveDistance = -distance;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.fromSize(
            size: const Size(18, 18),
            child: const CircularProgressIndicator(),
          ),
          SizedBox.fromSize(
            size: const Size(10, 10),
          ),
          Text(AppFlowyEditorLocalizations.current.loading),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      height: 100,
      width: imageWidth,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(width: 1, color: Colors.black),
      ),
      child: Text(AppFlowyEditorLocalizations.current.imageLoadFailed),
    );
  }

  Widget _buildEdgeGesture(
    BuildContext context, {
    double? top,
    double? left,
    double? right,
    double? bottom,
    double? width,
    void Function(double distance)? onUpdate,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      width: width,
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          initialOffset = details.globalPosition.dx;
        },
        onHorizontalDragUpdate: (details) {
          if (onUpdate != null) {
            var offset = (details.globalPosition.dx - initialOffset);
            if (widget.alignment == Alignment.center) {
              offset *= 2.0;
            }
            onUpdate(offset);
          }
        },
        onHorizontalDragEnd: (details) {
          imageWidth =
              max(_kImageBlockComponentMinWidth, imageWidth - moveDistance);
          initialOffset = 0;
          moveDistance = 0;

          widget.onResize(imageWidth);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: onFocus
              ? Center(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(5.0),
                      ),
                      border: Border.all(width: 1, color: Colors.white),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
