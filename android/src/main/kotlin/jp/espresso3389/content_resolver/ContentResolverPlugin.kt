package jp.espresso3389.content_resolver

import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream
import java.nio.ByteBuffer

/** ContentResolverPlugin */
class ContentResolverPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

  private val ioScope = CoroutineScope(Dispatchers.IO)

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBinding = flutterPluginBinding
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "content_resolver")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    var address = 0L
    try {
      when (call.method) {
          "getContent" -> {
            val uri = Uri.parse(call.arguments as String)
            openInputStream(uri).use {
              val buffer = ByteArrayOutputStream()
              it.copyTo(buffer)
              val (bufAddress, byteBuffer) = allocBuffer(buffer.size())
              address = bufAddress
              byteBuffer.put(buffer.toByteArray())
              result.success(hashMapOf("address" to address, "length" to buffer.size(), "mimeType" to getMimeType(uri), "fileName" to getFileName(uri)))
            }
          }
          "writeContent" -> {
            openOutputStream(Uri.parse(call.argument<String>("uri") as String), call.argument<String>("mode") as String).use {
              it.write(call.argument<ByteArray>("bytes") as ByteArray)
            }
            result.success(0)
          }
          "releaseBuffer" -> {
            releaseBuffer(call.arguments as Long)
            result.success(0)
          }
          "saveContentToFile" -> {
            val uri = Uri.parse(call.argument<String>("uri") as String)
            val file = File(call.argument<String>("filePath") as String)
            openInputStream(uri).use { input ->
              FileOutputStream(file).use { output ->
                input.copyTo(output)
              }
            }
            result.success(hashMapOf("mimeType" to getMimeType(uri), "fileName" to getFileName(uri)))
          }
          "getContentMetadata" -> {
            val uri = Uri.parse(call.arguments as String)
            result.success(hashMapOf("mimeType" to getMimeType(uri), "fileName" to getFileName(uri)))
          }
          "streamContent" -> {
            streamContent(call, result)
          }
          else -> {
            result.notImplemented()
          }
      }
    } catch (e: Exception) {
      releaseBuffer(address)
      result.error("exception", "Internal error.", e)
    }
  }

  private fun openInputStream(uri: Uri): InputStream {
    val cr = flutterPluginBinding.applicationContext.contentResolver
    return cr.openInputStream(uri)!!
  }

  private fun getMimeType(uri: Uri): String? {
    val cr = flutterPluginBinding.applicationContext.contentResolver
    return cr.getType(uri)
  }

  private fun getFileName(uri: Uri): String? {
    val cr = flutterPluginBinding.applicationContext.contentResolver
    return cr.query(uri, null, null, null, null)?.use { cursor ->
      val nameColumnIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
      cursor.moveToFirst()
      return cursor.getString(nameColumnIndex)
    }
  }

  private fun openOutputStream(uri: Uri, mode: String): OutputStream {
    val cr = flutterPluginBinding.applicationContext.contentResolver
    return BufferedOutputStream(ParcelFileDescriptor.AutoCloseOutputStream(cr.openFileDescriptor(uri, mode)))
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    ioScope.cancel()
  }

  private fun allocBuffer(size: Int): Pair<Long, ByteBuffer> {
    val address = ByteBufferHelper.malloc(size.toLong())
    val bb = ByteBufferHelper.newDirectBuffer(address, size.toLong())
    return address to bb
  }

  private fun releaseBuffer(address: Long) {
    ByteBufferHelper.free(address)
  }

  private fun streamContent(call: MethodCall, result: Result) {
    val id = call.argument<Int>("id") as Int
    val uri = Uri.parse(call.argument<String>("uri") as String)
    val bufferSize = call.argument<Int>("bufferSize") as Int
    ioScope.launch {
      try {
        val buffer = ByteArray(bufferSize)
        var bytesReadSoFar = 0
        openInputStream(uri).use { input ->
          while (true) {
            val length = input.read(buffer)
            if (length < 0) {
              input.close()
              post("close", hashMapOf("id" to id, "totalSize" to bytesReadSoFar))
              return@launch
            } else if (length == 0) {
              continue
            }
            send(
              "data",
              hashMapOf(
                "id" to id,
                "offset" to bytesReadSoFar,
                "data" to buffer.sliceArray(0 until length)
              )
            )
            bytesReadSoFar += length
          }
        }
      } catch (e: Exception) {
        post("error", hashMapOf("id" to id, "errorMessage" to e.toString()))
      }
    }
    result.success(null)
  }

  private suspend fun post(method: String, arguments: Any?): Unit {
    withContext(Dispatchers.Main) {
      channel.invokeMethod(method, arguments)
    }
  }

  private suspend fun send(method: String, arguments: Any?): Any? {
    val deferred = CompletableDeferred<Any?>()
    withContext(Dispatchers.Main) {
      channel.invokeMethod(method, arguments,
        object : Result {
          override fun success(result: Any?) {
            deferred.complete(result)
          }

          override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            deferred.completeExceptionally(Exception("$errorCode: $errorMessage"))
          }

          override fun notImplemented() {
            deferred.completeExceptionally(NotImplementedError())
          }
        })
    }
    return deferred.await()
  }
}
