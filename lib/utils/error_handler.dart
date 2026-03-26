import 'package:firebase_auth/firebase_auth.dart';

class FirebaseErrorHandler {
  static String getErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'المستخدم غير موجود. يرجى التحقق من البريد الإلكتروني.';
        case 'wrong-password':
          return 'كلمة المرور غير صحيحة.';
        case 'email-already-in-use':
          return 'هذا البريد الإلكتروني مستخدم بالفعل.';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صحيح.';
        case 'weak-password':
          return 'كلمة المرور ضعيفة جداً.';
        case 'operation-not-allowed':
          return 'هذه العملية غير مسموح بها حالياً.';
        case 'user-disabled':
          return 'تم تعطيل هذا الحساب.';
        case 'too-many-requests':
          return 'محاولات كثيرة جداً. يرجى المحاولة لاحقاً.';
        case 'network-request-failed':
          return 'فشل الاتصال بالشبكة. يرجى التحقق من الإنترنت.';
        case 'invalid-credential':
          return 'بيانات الاعتماد غير صالحة أو منتهية الصلاحية.';
        default:
          return 'حدث خطأ: ${e.message ?? e.code}';
      }
    }
    return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
  }
}
