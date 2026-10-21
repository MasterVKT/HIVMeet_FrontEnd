package com.hivmeet.hivmeet

import android.app.Activity
import android.content.Intent
import android.view.WindowManager
import androidx.annotation.NonNull
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {
    private val kycPrivacyChannel = "hivmeet/kyc_privacy"
    private val kycCaptureChannel = "hivmeet/kyc_capture"
    private var pendingKycScanResult: MethodChannel.Result? = null

    companion object {
        private const val kycScanRequestCode = 8714
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, kycPrivacyChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "setSecure") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val enabled = call.argument<Boolean>("enabled") ?: false
                if (enabled) {
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE,
                    )
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, kycCaptureChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanDocument" -> startKycDocumentScan(result)
                    // Android uses the ML Kit scanner before returning a file.
                    // iOS performs its local Vision rectangle check itself.
                    "assessDocument" -> result.success(true)
                    else -> result.notImplemented()
                }
            }
    }

    private fun startKycDocumentScan(result: MethodChannel.Result) {
        if (pendingKycScanResult != null) {
            result.error("scanner_busy", null, null)
            return
        }
        pendingKycScanResult = result
        val options = GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(false)
            .setPageLimit(1)
            .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
            .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
            .build()
        GmsDocumentScanning.getClient(options)
            .getStartScanIntent(this)
            .addOnSuccessListener { intentSender ->
                try {
                    startIntentSenderForResult(intentSender, kycScanRequestCode, null, 0, 0, 0)
                } catch (_: Exception) {
                    finishKycScanWithError("scanner_unavailable")
                }
            }
            .addOnFailureListener {
                finishKycScanWithError("scanner_unavailable")
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != kycScanRequestCode) return
        // Take and clear the callback before replying. Late native callbacks
        // are therefore harmless and cannot submit a second Flutter response.
        val result = takePendingKycScanResult() ?: return
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(mapOf("status" to "cancelled"))
            return
        }
        var target: File? = null
        try {
            val scanned = GmsDocumentScanningResult.fromActivityResultIntent(data)
            val imageUri = scanned?.pages?.firstOrNull()?.imageUri
            if (imageUri == null) {
                result.success(mapOf("status" to "cancelled"))
                return
            }
            val directory = File(cacheDir, "hivmeet_kyc_scan")
            directory.mkdirs()
            val outputFile = File.createTempFile("scan_", ".jpg", directory)
            target = outputFile
            contentResolver.openInputStream(imageUri).use { input ->
                if (input == null) throw IllegalStateException()
                FileOutputStream(outputFile).use { output -> input.copyTo(output) }
            }
            result.success(mapOf("status" to "captured", "path" to outputFile.absolutePath))
        } catch (_: Exception) {
            target?.delete()
            result.error("scanner_unavailable", null, null)
        }
    }

    private fun takePendingKycScanResult(): MethodChannel.Result? {
        val result = pendingKycScanResult
        pendingKycScanResult = null
        return result
    }

    private fun finishKycScanWithError(code: String) {
        takePendingKycScanResult()?.error(code, null, null)
    }

    override fun onDestroy() {
        // A configuration/process teardown before a scanner result must not
        // leave the Flutter method call pending. The helper guarantees the
        // callback is completed at most once.
        finishKycScanWithError("scanner_unavailable")
        super.onDestroy()
    }
}
