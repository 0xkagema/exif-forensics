import 'package:flutter/widgets.dart';
import 'package:toastification/toastification.dart';

extension ShowToast on BuildContext {
  void showErrorToast(String message, {String? title, Duration? duration}) {
    toastification.show(
      title: Text(title ?? 'Error'),
      description: Text(message),
      type: ToastificationType.error,
      animationDuration: duration,
    );
  }

  void showSuccessToast(String message, {String? title, Duration? duration}) {
    toastification.show(
      title: Text(title ?? 'Success'),
      description: Text(message),
      type: ToastificationType.success,
      animationDuration: duration,
    );
  }

  void showInfoToast(String message, {String? title, Duration? duration}) {
    toastification.show(
      title: Text(title ?? 'Info'),
      description: Text(message),
      type: ToastificationType.info,
      animationDuration: duration,
    );
  }

  void showWarningToast(String message, {String? title, Duration? duration}) {
    toastification.show(
      title: Text(title ?? 'Warning'),
      description: Text(message),
      type: ToastificationType.warning,
      animationDuration: duration,
    );
  }
}
