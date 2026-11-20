
import 'package:flutter/material.dart';

// Global application language
// ar = Arabic
// en = English

final ValueNotifier<String> appLang = ValueNotifier<String>('ar');

bool get isArabic => appLang.value == 'ar';

TextDirection get appDirection =>
    isArabic ? TextDirection.rtl : TextDirection.ltr;

// Change language
void changeAppLanguage(String language) {
  if (language != 'ar' && language != 'en') return;
  appLang.value = language;
}

// Toggle language
void toggleAppLanguage() {
  changeAppLanguage(isArabic ? 'en' : 'ar');
}

// Translate
String tr(String arabic, String english) {
  return isArabic ? arabic : english;
}

// Compatibility with main.dart and other screens
String translate(String arabic, String english) {
  return tr(arabic, english);
}
