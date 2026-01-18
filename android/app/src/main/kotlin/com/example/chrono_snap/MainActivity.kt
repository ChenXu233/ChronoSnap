package com.example.chrono_snap

import android.annotation.SuppressLint
import android.content.Context
import android.hardware.camera2.CameraManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.chrono_snap.camera.Camera2Controller
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var camera2Controller: Camera2Controller? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        )

        channel.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
    }

    @SuppressLint("ObsoleteSdkInt")
    private fun handleMethodCall(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getAvailableCameras" -> {
                getAvailableCameras(result)
            }
            "openCamera" -> {
                val cameraId = call.argument<String>("cameraId")
                if (cameraId != null) {
                    openCamera(cameraId, result)
                } else {
                    result.error("INVALID_ARGUMENT", "cameraId is required", null)
                }
            }
            "setPreviewSurface" -> {
                // 需要 SurfaceView 的处理，这里简化
                result.success(true)
            }
            "lockFocus" -> {
                val focusDistance = call.argument<Double>("focusDistance") ?: 0.0
                val success = camera2Controller?.lockFocus(focusDistance.toFloat()) ?: false
                result.success(success)
            }
            "lockExposure" -> {
                val compensation = call.argument<Int>("exposureCompensation") ?: 0
                val success = camera2Controller?.lockExposure(compensation) ?: false
                result.success(success)
            }
            "unlockExposure" -> {
                val success = camera2Controller?.unlockExposure() ?: false
                result.success(success)
            }
            "lockWhiteBalance" -> {
                val success = camera2Controller?.lockWhiteBalance() ?: false
                result.success(success)
            }
            "unlockWhiteBalance" -> {
                val success = camera2Controller?.unlockWhiteBalance() ?: false
                result.success(success)
            }
            "getExposureCompensationRange" -> {
                val min = camera2Controller?.getMinExposureCompensation() ?: 0
                val max = camera2Controller?.getMaxExposureCompensation() ?: 0
                result.success(mapOf("min" to min, "max" to max))
            }
            "closeCamera" -> {
                camera2Controller?.close()
                camera2Controller = null
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getAvailableCameras(result: MethodChannel.Result) {
        try {
            val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameras = mutableListOf<Map<String, Any>>()

            for (id in cameraManager.cameraIdList) {
                val characteristics = cameraManager.getCameraCharacteristics(id)
                val lensDirection = when (characteristics.get(CameraCharacteristics.LENS_FACING)) {
                    CameraCharacteristics.LENS_FACING_BACK -> "back"
                    CameraCharacteristics.LENS_FACING_FRONT -> "front"
                    else -> "external"
                }

                cameras.add(mapOf(
                    "id" to id,
                    "name" to "Camera $id",
                    "lensDirection" to lensDirection
                ))
            }

            result.success(cameras)
        } catch (e: Exception) {
            result.error("CAMERA_ERROR", e.message, null)
        }
    }

    private fun openCamera(cameraId: String, result: MethodChannel.Result) {
        scope.launch {
            try {
                // 初始化控制器
                camera2Controller = Camera2Controller(this@MainActivity)

                // 打开相机
                camera2Controller?.openCamera(cameraId)

                result.success(true)
            } catch (e: Exception) {
                result.error("OPEN_CAMERA_ERROR", e.message, null)
            }
        }
    }

    companion object {
        private const val CHANNEL_NAME = "com.chrono_snap/camera2"
    }
}
