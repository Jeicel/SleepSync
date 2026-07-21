package com.example.sleep_tracker

import android.app.Activity
import android.content.Intent
import android.content.Context
import android.content.ComponentName
import android.content.SharedPreferences
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val CHANNEL = "sleep_tracker/ringtone_picker"
  private val RINGTONE_REQUEST_CODE = 1001
  private var pendingResult: MethodChannel.Result? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "pickRingtone" -> {
            val isAlarm = call.argument<Boolean>("isAlarm") ?: false
            val currentUri = call.argument<String>("currentUri")
            pendingResult = result
            val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER)
              .putExtra(
                RingtoneManager.EXTRA_RINGTONE_TYPE,
                if (isAlarm) RingtoneManager.TYPE_ALARM else RingtoneManager.TYPE_NOTIFICATION
              )
              .putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
              .putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, true)
            if (!currentUri.isNullOrEmpty()) {
              intent.putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(currentUri))
            }
            startActivityForResult(intent, RINGTONE_REQUEST_CODE)
          }
          "getRingtoneTitle" -> {
            val uri = call.argument<String>("uri")
            if (uri.isNullOrEmpty()) {
              result.success(null)
            } else {
              try {
                val ringtone = RingtoneManager.getRingtone(this, Uri.parse(uri))
                result.success(ringtone?.getTitle(this))
              } catch (e: Exception) {
                result.success(null)
              }
            }
          }
          else -> result.notImplemented()
        }
      }

    // Widget update channel: accepts a map and stores widget data into
    // SharedPreferences, then sends a broadcast to update app widgets.
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sleep_tracker/widget")
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "updateWidget" -> {
            android.util.Log.d("WidgetDebug", "updateWidget called with args=${call.arguments}")
            val args = call.arguments as? Map<String, Any?>
            if (args == null) {
              android.util.Log.d("WidgetDebug", "args is null / wrong type")
              result.error("NO_ARGS", "No arguments provided", null)
              return@setMethodCallHandler
            }
            val prefs = getSharedPreferences("sleep_tracker_widget_prefs", Context.MODE_PRIVATE)
            val editor = prefs.edit()
            val type = args["type"] as? String
            val data = args["data"] as? Map<String, Any?>
            android.util.Log.d("WidgetDebug", "type=$type data=$data")
            if (type != null && data != null) {
              // write all entries as strings with prefix
              for ((k, v) in data) {
                editor.putString("${type}_$k", v?.toString())
              }
              editor.apply()
              android.util.Log.d("WidgetDebug", "prefs written, sending broadcast")

              // notify widgets to refresh
              val updateIntent = Intent()
              updateIntent.action = "com.example.sleep_tracker.ACTION_UPDATE_WIDGET"
              updateIntent.setPackage(packageName)
              sendBroadcast(updateIntent)
              android.util.Log.d("WidgetDebug", "broadcast sent")
              result.success(true)
            } else {
              android.util.Log.d("WidgetDebug", "type or data null: type=$type data=$data")
              result.error("BAD_ARGS", "Missing type or data", null)
            }
          }
          else -> result.notImplemented()
        }
      }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    if (requestCode == RINGTONE_REQUEST_CODE) {
      val r = pendingResult
      pendingResult = null
      if (r == null) return
      if (resultCode != Activity.RESULT_OK) {
        r.success(null)
        return
      }
      val uri = data?.getParcelableExtra<Uri>(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
      val title = if (uri != null) RingtoneManager.getRingtone(this, uri)?.getTitle(this) else null
      r.success(mapOf("uri" to uri?.toString(), "title" to title))
    }
  }
}