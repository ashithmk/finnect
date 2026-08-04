import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State notifier tracking whether a modal bottom sheet is currently open.
class BottomSheetOpenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setOpen(bool isOpen) {
    state = isOpen;
  }
}

final isBottomSheetOpenProvider =
    NotifierProvider<BottomSheetOpenNotifier, bool>(BottomSheetOpenNotifier.new);

/// Helper function to show a modal bottom sheet and automatically hide the floating footer bar.
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required WidgetRef ref,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  Color? backgroundColor,
  ShapeBorder? shape,
}) async {
  ref.read(isBottomSheetOpenProvider.notifier).setOpen(true);
  try {
    return await showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor ?? Colors.transparent,
      shape: shape,
      builder: builder,
    );
  } finally {
    ref.read(isBottomSheetOpenProvider.notifier).setOpen(false);
  }
}
