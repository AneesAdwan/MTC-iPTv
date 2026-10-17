// No silent failure (plan §4 rule 7): every error becomes a clear message + technical details.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';

import 'tr.dart';

@immutable
class UiError {
  final Tr message;
  final String details;
  const UiError(this.message, this.details);
}

UiError describeError(Object e, [StackTrace? st]) {
  final details = '${e.runtimeType}: $e';
  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return UiError(const Tr('البريد أو كلمة المرور غير صحيحة.', 'Wrong email or password.'), details);
    }
    if (m.contains('invalid totp') || m.contains('invalid code') || e.code == 'mfa_verification_failed') {
      return UiError(const Tr('رمز التحقق غير صحيح أو انتهت صلاحيته. جرّب الرمز الجديد.', 'The code is wrong or expired. Try the new code.'), details);
    }
    if (m.contains('expired') || m.contains('refresh token')) {
      return UiError(const Tr('انتهت الجلسة. سجّل الدخول من جديد.', 'Your session expired. Please sign in again.'), details);
    }
    return UiError(const Tr('رفض الخادم طلب الدخول.', 'The server rejected the sign-in request.'), details);
  }
  if (e is PostgrestException) {
    if (e.code == '42501') {
      return UiError(
        const Tr('الخادم رفض العملية: ما عندك صلاحية أو الجلسة لم تعد صالحة.', 'The server refused: no permission or the session is no longer valid.'),
        details,
      );
    }
    return UiError(const Tr('الخادم رجّع خطأ.', 'The server returned an error.'), details);
  }
  if (e is SocketException || e is TimeoutException || e is HttpException) {
    return UiError(const Tr('تعذّر الاتصال بالخادم. تأكد من الإنترنت وأعد المحاولة.', 'Could not reach the server. Check the connection and retry.'), details);
  }
  return UiError(const Tr('صار خطأ غير متوقع.', 'Something unexpected went wrong.'), details);
}
