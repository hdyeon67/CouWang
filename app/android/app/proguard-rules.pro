-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions

# flutter_local_notifications + Gson
# 릴리스(R8) 빌드에서 Gson 제네릭 타입 정보가 제거되면 알림 예약/취소 호출이
# "Missing type parameter." RuntimeException으로 터진다. 아래 룰로 플러그인과
# Gson의 타입 정보를 보존해 알림 기능이 릴리스에서도 정상 동작하도록 한다.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod
-keep class com.google.gson.** { *; }
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
