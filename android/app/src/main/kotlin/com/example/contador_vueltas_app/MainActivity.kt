package com.example.contador_vueltas_app

import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.wearable.*
import com.google.android.gms.tasks.Tasks
import android.util.Log
import android.content.Intent
import android.content.Context

class MainActivity : FlutterActivity(), DataClient.OnDataChangedListener, MessageClient.OnMessageReceivedListener {
    private val CHANNEL = "com.example.lapcounter/wear_sync"
    private val PATH_AUTH = "/auth_token"
    private val PATH_SYNC_SIGNAL = "/sync_signal"
    
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Wearable.getDataClient(this).addListener(this)
        Wearable.getMessageClient(this).addListener(this)
        
        // v13: REMOVED checkPendingTokens() from here.
    }

    private fun checkPendingTokens() {
        Wearable.getDataClient(this).dataItems.addOnSuccessListener { dataItems ->
            for (item in dataItems) {
                if (item.uri.path == PATH_AUTH) {
                    val dataMap = DataMapItem.fromDataItem(item).dataMap
                    val accessToken = dataMap.getString("accessToken")
                    val refreshToken = dataMap.getString("refreshToken")
                    val mirrorPayload = dataMap.getString("mirror_payload")
                    val timestamp = dataMap.getLong("timestamp")
                    
                    if (mirrorPayload != null) {
                        notifyFlutter(null, null, timestamp, mirrorPayload)
                    } else if (accessToken != null && refreshToken != null) {
                        notifyFlutter(accessToken, refreshToken, timestamp)
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        Wearable.getDataClient(this).removeListener(this)
        Wearable.getMessageClient(this).removeListener(this)
        super.onDestroy()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendTokenToWatch" -> {
                    val accessToken = call.argument<String>("accessToken")
                    val refreshToken = call.argument<String>("refreshToken")
                    if (accessToken != null && refreshToken != null) {
                        sendTokenToWatch(accessToken, refreshToken, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Tokens are null", null)
                    }
                }
                "sendMirrorToken" -> {
                    val payload = call.argument<String>("payload")
                    if (payload != null) {
                        sendMirrorToken(payload, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Payload is null", null)
                    }
                }
                "isWatch" -> {
                    val uiMode = resources.configuration.uiMode
                    val isWatch = (uiMode and android.content.res.Configuration.UI_MODE_TYPE_MASK) == android.content.res.Configuration.UI_MODE_TYPE_WATCH
                    result.success(isWatch)
                }
                "clearAuthData" -> {
                    clearAuthData(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun clearAuthData(result: MethodChannel.Result) {
        Wearable.getDataClient(this).dataItems.addOnSuccessListener { dataItems ->
            for (item in dataItems) {
                if (item.uri.path == PATH_AUTH) {
                    Wearable.getDataClient(this).deleteDataItems(item.uri)
                    Log.d("WearSync", "Data Layer: Token limpiado")
                }
            }
            result.success(true)
        }.addOnFailureListener {
            result.error("CLEAR_FAILED", it.message, null)
        }
    }

    private fun sendTokenToWatch(accessToken: String, refreshToken: String, result: MethodChannel.Result) {
        val timestamp = System.currentTimeMillis()
        val putDataMapReq = PutDataMapRequest.create(PATH_AUTH)
        putDataMapReq.dataMap.putString("accessToken", accessToken)
        putDataMapReq.dataMap.putString("refreshToken", refreshToken)
        putDataMapReq.dataMap.putLong("timestamp", timestamp)
        val putDataReq = putDataMapReq.asPutDataRequest()
        putDataReq.setUrgent()

        Wearable.getDataClient(this).putDataItem(putDataReq)

        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            if (nodes.isEmpty()) {
                result.success(false)
                return@addOnSuccessListener
            }
            var completedCount = 0
            for (node in nodes) {
                val rawData = "$accessToken|$refreshToken"
                val encodedData = android.util.Base64.encodeToString(rawData.toByteArray(), android.util.Base64.NO_WRAP)
                val message = "v8:$timestamp:$encodedData".toByteArray()
                Wearable.getMessageClient(this).sendMessage(node.id, PATH_AUTH, message)
                    .addOnCompleteListener {
                        completedCount++
                        if (completedCount == nodes.size) result.success(true)
                    }
            }
        }
    }

    private fun sendMirrorToken(payload: String, result: MethodChannel.Result) {
        val timestamp = System.currentTimeMillis()
        val putDataMapReq = PutDataMapRequest.create(PATH_AUTH)
        putDataMapReq.dataMap.putString("mirror_payload", payload)
        putDataMapReq.dataMap.putLong("timestamp", timestamp)
        val putDataReq = putDataMapReq.asPutDataRequest()
        putDataReq.setUrgent()
        Wearable.getDataClient(this).putDataItem(putDataReq)

        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            if (nodes.isEmpty()) { result.success(false); return@addOnSuccessListener }
            var completedCount = 0
            for (node in nodes) {
                val message = payload.toByteArray()
                Wearable.getMessageClient(this).sendMessage(node.id, PATH_AUTH, message)
                    .addOnCompleteListener {
                        completedCount++
                        if (completedCount == nodes.size) result.success(true)
                    }
            }
        }
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type == DataEvent.TYPE_CHANGED && event.dataItem.uri.path == PATH_AUTH) {
                val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                val accessToken = dataMap.getString("accessToken")
                val refreshToken = dataMap.getString("refreshToken")
                val mirrorPayload = dataMap.getString("mirror_payload")
                val timestamp = dataMap.getLong("timestamp")
                
                if (mirrorPayload != null) {
                    notifyFlutter(null, null, timestamp, mirrorPayload)
                } else if (accessToken != null && refreshToken != null) {
                    notifyFlutter(accessToken, refreshToken, timestamp)
                }
            }
        }
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        if (messageEvent.path == PATH_AUTH) {
            val rawMessage = String(messageEvent.data)
            if (rawMessage.startsWith("v14:")) {
                notifyFlutter(null, null, System.currentTimeMillis(), rawMessage)
            } else if (rawMessage.startsWith("v8:")) {
                // ... handle v8 ...
                try {
                    val partsMsg = rawMessage.split(":", limit = 3)
                    if (partsMsg.size == 3) {
                        val timestamp = partsMsg[1].toLong()
                        val encoded = partsMsg[2]
                        val decoded = String(android.util.Base64.decode(encoded, android.util.Base64.DEFAULT))
                        val tokens = decoded.split("|", limit = 2)
                        if (tokens.size == 2) notifyFlutter(tokens[0], tokens[1], timestamp)
                    }
                } catch (e: Exception) {}
            }
        }
    }

    private fun notifyFlutter(accessToken: String?, refreshToken: String?, timestamp: Long, mirrorPayload: String? = null) {
        runOnUiThread {
            val args = mutableMapOf<String, Any>("timestamp" to timestamp)
            if (mirrorPayload != null) args["mirrorPayload"] = mirrorPayload
            if (accessToken != null) args["accessToken"] = accessToken
            if (refreshToken != null) args["refreshToken"] = refreshToken
            
            methodChannel?.invokeMethod("onTokenReceived", args)
        }
    }
}
