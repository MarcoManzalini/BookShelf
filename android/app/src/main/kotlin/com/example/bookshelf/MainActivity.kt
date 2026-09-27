package com.example.bookshelf

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Reads the text of a photographed page, for saving quotes.
        // Returns the recognized lines in reading order.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "bookshelf/text_recognition",
        ).setMethodCallHandler { call, result ->
            if (call.method != "recognize") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            if (path == null) {
                result.error("bad_args", "Missing image path", null)
                return@setMethodCallHandler
            }
            val image = try {
                InputImage.fromFilePath(this, Uri.fromFile(File(path)))
            } catch (e: Exception) {
                result.error("bad_image", e.message, null)
                return@setMethodCallHandler
            }
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            recognizer.process(image)
                .addOnSuccessListener { text ->
                    result.success(text.textBlocks.flatMap { block -> block.lines.map { it.text } })
                }
                .addOnFailureListener { e -> result.error("failed", e.message, null) }
                .addOnCompleteListener { recognizer.close() }
        }
    }
}
