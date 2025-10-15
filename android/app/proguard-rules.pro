# Keep all TensorFlow Lite classes (Interpreter, Delegate, GPU, NNAPI, etc.)
-keep class org.tensorflow.** { *; }
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.experimental.** { *; }
-keep class org.tensorflow.lite.support.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep reflection used by TFLite
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
