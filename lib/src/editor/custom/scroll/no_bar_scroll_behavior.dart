import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// ScrollConfiguration.of(context) = > MaterialScrollBehavior;
class NoBarScrollBehavior extends ScrollBehavior {
  const NoBarScrollBehavior();

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

// ScrollConfiguration.of(context) = > MaterialScrollBehavior;
// class NoBarScrollBehavior extends ScrollBehavior {
//   /// Creates a MaterialScrollBehavior that decorates [Scrollable]s with
//   /// [GlowingOverscrollIndicator]s and [Scrollbar]s based on the current
//   /// platform and provided [ScrollableDetails].
//   ///
//   /// [MaterialScrollBehavior.androidOverscrollIndicator] specifies the
//   /// overscroll indicator that is used on [TargetPlatform.android]. When null,
//   /// [ThemeData.androidOverscrollIndicator] is used. If also null, the default
//   /// overscroll indicator is the [GlowingOverscrollIndicator].
//   const NoBarScrollBehavior({
//     @Deprecated(
//         'Use ThemeData.useMaterial3 or override ScrollBehavior.buildOverscrollIndicator. '
//         'This feature was deprecated after v2.13.0-0.0.pre.')
//     super.androidOverscrollIndicator,
//   }) : _androidOverscrollIndicator = androidOverscrollIndicator;

//   final AndroidOverscrollIndicator? _androidOverscrollIndicator;

//   @override
//   TargetPlatform getPlatform(BuildContext context) =>
//       Theme.of(context).platform;

//   @override
//   Widget buildScrollbar(
//       BuildContext context, Widget child, ScrollableDetails details) {
//     // When modifying this function, consider modifying the implementation in
//     // the base class ScrollBehavior as well.
//     switch (axisDirectionToAxis(details.direction)) {
//       case Axis.horizontal:
//         return child;
//       case Axis.vertical:
//         switch (getPlatform(context)) {
//           case TargetPlatform.linux:
//           case TargetPlatform.macOS:
//           case TargetPlatform.windows:
//             assert(details.controller != null);
//             return Scrollbar(
//               thickness: 0,
//               interactive: false,
//               controller: details.controller,
//               child: child,
//             );
//           case TargetPlatform.android:
//           case TargetPlatform.fuchsia:
//           case TargetPlatform.iOS:
//             return child;
//         }
//     }
//   }

//   @override
//   Widget buildOverscrollIndicator(
//       BuildContext context, Widget child, ScrollableDetails details) {
//     // When modifying this function, consider modifying the implementation in
//     // the base class ScrollBehavior as well.
//     late final AndroidOverscrollIndicator indicator;
//     if (Theme.of(context).useMaterial3) {
//       indicator = AndroidOverscrollIndicator.stretch;
//     } else {
//       indicator = _androidOverscrollIndicator ??
//           Theme.of(context).androidOverscrollIndicator ??
//           androidOverscrollIndicator;
//     }
//     switch (getPlatform(context)) {
//       case TargetPlatform.iOS:
//       case TargetPlatform.linux:
//       case TargetPlatform.macOS:
//       case TargetPlatform.windows:
//         return child;
//       case TargetPlatform.android:
//         switch (indicator) {
//           case AndroidOverscrollIndicator.stretch:
//             return StretchingOverscrollIndicator(
//               axisDirection: details.direction,
//               clipBehavior: details.clipBehavior ?? Clip.hardEdge,
//               child: child,
//             );
//           case AndroidOverscrollIndicator.glow:
//             break;
//         }
//       case TargetPlatform.fuchsia:
//         break;
//     }
//     return GlowingOverscrollIndicator(
//       axisDirection: details.direction,
//       color: Theme.of(context).colorScheme.secondary,
//       child: child,
//     );
//   }
// }
