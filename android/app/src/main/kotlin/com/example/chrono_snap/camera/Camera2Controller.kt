package com.example.chrono_snap.camera

import android.annotation.SuppressLint
import android.content.Context
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraMetadata
import android.hardware.camera2.CaptureRequest
import android.util.Range
import android.view.Surface
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Camera2 API 控制器
 * 提供手动对焦、曝光补偿、白平衡锁定等高级功能
 */
class Camera2Controller(private val context: Context) {

    private var cameraManager: CameraManager =
        context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

    private var cameraDevice: android.hardware.camera2.CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var previewSurface: Surface? = null

    private var currentFocusDistance: Float = 0f
    private var currentExposureCompensation: Int = 0
    private var isWhiteBalanceLocked: Boolean = false

    // 曝光补偿范围缓存
    private var exposureCompensationRange: IntRange? = null

    /**
     * 打开相机
     */
    suspend fun openCamera(cameraId: String) = suspendCancellableCoroutine { continuation ->
        try {
            cameraManager.openCamera(cameraId, object : android.hardware.camera2.CameraDevice.StateCallback() {
                override fun onOpened(camera: android.hardware.camera2.CameraDevice) {
                    cameraDevice = camera
                    continuation.resume(Unit)
                }

                override fun onDisconnected(camera: android.hardware.camera2.CameraDevice) {
                    camera.close()
                    cameraDevice = null
                    continuation.resumeWithException(Exception("Camera disconnected"))
                }

                override fun onError(camera: android.hardware.camera2.CameraDevice, error: Int) {
                    camera.close()
                    cameraDevice = null
                    continuation.resumeWithException(Exception("Camera error: $error"))
                }
            }, null)
        } catch (e: Exception) {
            continuation.resumeWithException(e)
        }
    }

    /**
     * 设置预览 Surface
     */
    suspend fun setPreviewSurface(surface: Surface) = suspendCancellableCoroutine { continuation ->
        previewSurface = surface
        cameraDevice?.createCaptureSession(
            listOf(surface),
            object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    captureSession = session
                    continuation.resume(Unit)
                }

                override fun onConfigureFailed(session: CameraCaptureSession) {
                    continuation.resumeWithException(Exception("Failed to configure session"))
                }
            },
            null
        )
    }

    /**
     * 锁定对焦到指定距离
     * @param focusDistance 对焦距离，范围通常是 0.0 ~ 10.0（微距到无穷远）
     */
    fun lockFocus(focusDistance: Float): Boolean {
        if (captureSession == null) return false

        try {
            val builder = captureSession!!.device.createCaptureRequest(
                android.hardware.camera2.CameraDevice.TEMPLATE_PREVIEW
            )
            builder.addTarget(previewSurface!!)

            // 设置手动对焦模式
            builder.set(
                CaptureRequest.CONTROL_AF_MODE,
                CameraMetadata.CONTROL_AF_MODE_OFF
            )

            // 设置对焦距离
            // Camera2 使用 lensFocusDistance，单位是焦距的倒数
            // 0 表示无穷远，值越大越近
            val clampedDistance = focusDistance.coerceIn(0f, 10f)
            builder.set(CaptureRequest.LENS_FOCUS_DISTANCE, clampedDistance)

            captureSession!!.setRepeatingRequest(builder.build(), null, null)
            currentFocusDistance = clampedDistance
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    /**
     * 锁定曝光并设置曝光补偿
     * @param exposureCompensation 曝光补偿值，范围取决于设备
     */
    fun lockExposure(exposureCompensation: Int): Boolean {
        if (captureSession == null) return false

        try {
            val builder = captureSession!!.device.createCaptureRequest(
                android.hardware.camera2.CameraDevice.TEMPLATE_PREVIEW
            )
            builder.addTarget(previewSurface!!)

            // 设置曝光模式为手动
            builder.set(
                CaptureRequest.CONTROL_AE_MODE,
                CameraMetadata.CONTROL_AE_MODE_OFF
            )

            // 设置曝光补偿
            val range = getExposureCompensationRange()
            val clamped = exposureCompensation.coerceIn(range.first, range.second)
            builder.set(CaptureRequest.CONTROL_AE_EXPOSURE_COMPENSATION, clamped)

            captureSession!!.setRepeatingRequest(builder.build(), null, null)
            currentExposureCompensation = clamped
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    /**
     * 解锁曝光（回到自动曝光）
     */
    fun unlockExposure(): Boolean {
        if (captureSession == null) return false

        try {
            val builder = captureSession!!.device.createCaptureRequest(
                android.hardware.camera2.CameraDevice.TEMPLATE_PREVIEW
            )
            builder.addTarget(previewSurface!!)

            // 设置自动曝光模式
            builder.set(
                CaptureRequest.CONTROL_AE_MODE,
                CameraMetadata.CONTROL_AE_MODE_ON
            )

            captureSession!!.setRepeatingRequest(builder.build(), null, null)
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    /**
     * 锁定白平衡
     */
    fun lockWhiteBalance(): Boolean {
        if (captureSession == null) return false

        try {
            val builder = captureSession!!.device.createCaptureRequest(
                android.hardware.camera2.CameraDevice.TEMPLATE_PREVIEW
            )
            builder.addTarget(previewSurface!!)

            // 设置白平衡模式为锁定
            builder.set(
                CaptureRequest.CONTROL_AWB_MODE,
                CameraMetadata.CONTROL_AWB_MODE_OFF
            )

            captureSession!!.setRepeatingRequest(builder.build(), null, null)
            isWhiteBalanceLocked = true
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    /**
     * 解锁白平衡（回到自动白平衡）
     */
    fun unlockWhiteBalance(): Boolean {
        if (captureSession == null) return false

        try {
            val builder = captureSession!!.device.createCaptureRequest(
                android.hardware.camera2.CameraDevice.TEMPLATE_PREVIEW
            )
            builder.addTarget(previewSurface!!)

            // 设置自动白平衡模式
            builder.set(
                CaptureRequest.CONTROL_AWB_MODE,
                CameraMetadata.CONTROL_AWB_MODE_ON
            )

            captureSession!!.setRepeatingRequest(builder.build(), null, null)
            isWhiteBalanceLocked = false
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    /**
     * 获取曝光补偿范围
     */
    private fun getExposureCompensationRange(): IntRange {
        exposureCompensationRange?.let { return it }

        try {
            val cameraId = cameraManager.cameraIdList.firstOrNull() ?: return 0..0
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val range = characteristics.get(
                CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE
            ) as Range<Int>?

            if (range != null) {
                exposureCompensationRange = range.lower..range.upper
                return exposureCompensationRange!!
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return 0..0
    }

    /**
     * 获取最大曝光补偿值
     */
    fun getMaxExposureCompensation(): Int {
        return getExposureCompensationRange().last
    }

    /**
     * 获取最小曝光补偿值
     */
    fun getMinExposureCompensation(): Int {
        return getExposureCompensationRange().first
    }

    /**
     * 关闭相机
     */
    fun close() {
        try {
            captureSession?.close()
            captureSession = null
            cameraDevice?.close()
            cameraDevice = null
            previewSurface = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    companion object {
        private const val CHANNEL_NAME = "com.chrono_snap/camera2"
    }
}
