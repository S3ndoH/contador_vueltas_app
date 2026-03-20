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
        
        // Cold start: Check if there's already a token in the Data Layer
        checkPendingTokens()
    }

    private fun checkPendingTokens() {
        Wearable.getDataClient(this).dataItems.addOnSuccessListener { dataItems ->
            for (item in dataItems) {
                if (item.uri.path == PATH_AUTH) {
                    val dataMap = DataMapItem.fromDataItem(item).dataMap
                    val accessToken = dataMap.getString("accessToken")
                    val refreshToken = dataMap.getString("refreshToken")
                    val timestamp = dataMap.getLong("timestamp")
                    Log.d("WearSync", "Token de inicio (Cold Start) encontrado en Data Layer con ts $timestamp")
                    notifyFlutter(accessToken, refreshToken, timestamp)
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
                "openRemoteInput" -> {
                    val hint = call.argument<String>("hint") ?: "Escribir..."
                    val receiverName = call.argument<String>("receiverName") ?: "input"
                    openRemoteInput(hint, receiverName, result)
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
                    Log.d("WearSync", "Data Layer: Token limpiado (consumido)")
                }
            }
            result.success(true)
        }.addOnFailureListener {
            result.error("CLEAR_FAILED", it.message, null)
        }
    }

    private fun sendTokenToWatch(accessToken: String, refreshToken: String, result: MethodChannel.Result) {
        Log.d("WearSync", "Iniciando envío de tokens. Path: $PATH_AUTH")
        val timestamp = System.currentTimeMillis()
        
        // 1. DATA LAYER (State persistence)
        val putDataMapReq = PutDataMapRequest.create(PATH_AUTH)
        putDataMapReq.dataMap.putString("accessToken", accessToken)
        putDataMapReq.dataMap.putString("refreshToken", refreshToken)
        putDataMapReq.dataMap.putLong("timestamp", timestamp)
        val putDataReq = putDataMapReq.asPutDataRequest()
        putDataReq.setUrgent()

        Wearable.getDataClient(this).putDataItem(putDataReq)
            .addOnSuccessListener {
                Log.d("WearSync", "Data Layer: Item guardado exitosamente")
            }

        // 2. MessageClient (Instant signaling)
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            if (nodes.isEmpty()) {
                Log.w("WearSync", "No se encontraron nodos conectados.")
                result.success(false)
                return@addOnSuccessListener
            }

            var successCount = 0
            var completedCount = 0

            for (node in nodes) {
                val rawData = "$accessToken|$refreshToken"
                val encodedData = android.util.Base64.encodeToString(rawData.toByteArray(), android.util.Base64.NO_WRAP)
                val message = "v8:$timestamp:$encodedData".toByteArray()
                
                Wearable.getMessageClient(this).sendMessage(node.id, PATH_AUTH, message)
                    .addOnCompleteListener { task ->
                        completedCount++
                        if (task.isSuccessful) {
                            successCount++
                            Log.d("WearSync", "Mensaje v8 enviado exitosamente a: ${node.displayName}")
                        } else {
                            Log.e("WearSync", "Fallo al enviar mensaje a ${node.displayName}: ${task.exception?.message}")
                        }

                        if (completedCount == nodes.size) {
                            result.success(successCount > 0)
                        }
                    }
            }
        }.addOnFailureListener {
            Log.e("WearSync", "Error obteniendo nodos: ${it.message}")
            result.error("NODE_ERROR", it.message, null)
        }
    }

    private fun openRemoteInput(hint: String, receiverName: String, result: MethodChannel.Result) {
        result.success(null) 
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type == DataEvent.TYPE_CHANGED && event.dataItem.uri.path == PATH_AUTH) {
                val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                val accessToken = dataMap.getString("accessToken")
                val refreshToken = dataMap.getString("refreshToken")
                val timestamp = dataMap.getLong("timestamp")
                Log.d("WearSync", "Data Layer Changed: Token recibido con timestamp $timestamp")
                notifyFlutter(accessToken, refreshToken, timestamp)
            }
        }
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        if (messageEvent.path == PATH_AUTH) {
            val rawMessage = String(messageEvent.data)
            Log.d("WearSync", "Mensaje recibido: $rawMessage")
            
            try {
                if (rawMessage.startsWith("v8:")) {
                    val partsMsg = rawMessage.split(":", limit = 3)
                    if (partsMsg.size == 3) {
                        val timestamp = partsMsg[1].toLong()
                        val encoded = partsMsg[2]
                        val decoded = String(android.util.Base64.decode(encoded, android.util.Base64.DEFAULT))
                        val tokens = decoded.split("|", limit = 2)
                        if (tokens.size == 2) {
                            notifyFlutter(tokens[0], tokens[1], timestamp)
                        }
                    }
                } else if (rawMessage.startsWith("v7:")) {
                    val encoded = rawMessage.substring(3)
                    val decoded = String(android.util.Base64.decode(encoded, android.util.Base64.DEFAULT))
                    val tokens = decoded.split("|", limit = 2)
                    if (tokens.size == 2) {
                        notifyFlutter(tokens[0], tokens[1], System.currentTimeMillis())
                    }
                }
            } catch (e: Exception) {
                Log.e("WearSync", "Error decodificando mensaje v8: ${e.message}")
            }
        }
    }

    private fun notifyFlutter(accessToken: String?, refreshToken: String?, timestamp: Long) {
        if (accessToken == null || refreshToken == null) return
        
        runOnUiThread {
            Log.d("WearSync", "Notificando a Flutter (v8): ts=$timestamp")
            methodChannel?.invokeMethod("onTokenReceived", mapOf(
                "accessToken" to accessToken,
                "refreshToken" to refreshToken,
                "timestamp" to timestamp
            ))
        }
    }
}
