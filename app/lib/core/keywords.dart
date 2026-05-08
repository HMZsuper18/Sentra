import 'package:flutter/material.dart';

const Map<String, List<String>> keywordMap = {
  'يمين': [
    'يمين','يميناً','اتجه يمين','دور يمين','لف يمين','خش يمين',
    'ناحية اليمين','جهة اليمين','اميل يمين','انعطف يمين','توجه يمين',
    'روّح يمين','حي اليمين','اتجه لليمين','دوار يمين','لف得太','خشّ يمين',
  ],
  'شمال': [
    'شمال','يسار','اتجه شمال','دور شمال','لف شمال','اتجه يساراً',
    'خش شمال','ناحية الشمال','جهة اليسار','اميل يسار','انعطف شمال',
    'توجه شمال','شمالاً','روّح شمال','حي للشمال','اتجه لليسار','دوار شمال',
  ],
  'قدام': [
    'قدام','امام','الأمام','تقدم','للأمام','امشي','تحرك','كمل','دغري',
    'على طول','اطلع قدام','توجه قدام','اماماً','روّح قدام','قدماً','امامي',
    'تقدم向前','امشي قدام',
  ],
  'ورا': [
    'ورا','الخلف','للخلف','تراجع','ارجع','ارجع ورا','لورا','عشيري',
    'ارجع تاني','تراجع للخلف','إرجع','رجع','رجع ورا','خلف','ورّ','إحيد',
  ],
  'وقف': [
    'وقف','توقف','قف','استنى','اوقف','بس','خلاص','اثبت','فرمل','هدئ',
    'كفاية','توق','توقّف','إوقف','ثبت','إنتظر','إنتظر.','إهدأ','تكفّى',
  ],
};

const Set<String> ignoredSpeechErrors = {
  'error_speech_timeout',
  'error_no_match',
  'error_client',
  'error_recognizer_busy',
};

String? extractKeyword(String text) {
  for (final entry in keywordMap.entries) {
    for (final phrase in entry.value) {
      if (text.contains(phrase)) return entry.key;
    }
  }
  return null;
}

Color wheelColor(String cmd) {
  switch (cmd) {
    case 'قدام': return const Color(0xFF22c55e);
    case 'ورا': return const Color(0xFFef4444);
    case 'يمين':
    case 'شمال': return const Color(0xFFf97316);
    default: return const Color(0xFF6b7280);
  }
}