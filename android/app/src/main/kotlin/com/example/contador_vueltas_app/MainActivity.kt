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
                    Log.d("WearSync", "Token de inicio (Cold Start) encontrado en Data Layer")
                    notifyFlutter(accessToken, refreshToken)
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
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun sendTokenToWatch(accessToken: String, refreshToken: String, result: MethodChannel.Result) {
        Log.d("WearSync", "Iniciando envío de tokens. Path: $PATH_AUTH")
        
        // 1. DATA LAYER (State persistence)
        val putDataMapReq = PutDataMapRequest.create(PATH_AUTH)
        putDataMapReq.dataMap.putString("accessToken", accessToken)
        putDataMapReq.dataMap.putString("refreshToken", refreshToken)
        putDataMapReq.dataMap.putLong("timestamp", System.currentTimeMillis())
        val putDataReq = putDataMapReq.asPutDataRequest()
        putDataReq.setUrgent()

        Wearable.getDataClient(this).putDataItem(putDataReq)
            .addOnSuccessListener {
                Log.d("WearSync", "Data Layer: Item guardado exitosamente")
                
                // 2. MESSAGE CLIENT (Immediate signal)
            }
            .addOnFailureListener { e ->
                Log.e("WearSync", "Error en Data Layer: ${e.message}")
            }

        // 2. MessageClient (Instant signaling) with Base64 to avoid character issues
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            if (nodes.isEmpty()) {
                Log.w("WearSync", "No se encontraron relojes conectados")
            }
            for (node in nodes) {
                // Formato v7: "v7:base64(accessToken|refreshToken)"
                val rawData = "$accessToken|$refreshToken"
                val encodedData = android.util.Base64.encodeToString(rawData.toByteArray(), android.util.Base64.NO_WRAP)
                val message = "v7:$encodedData".toByteArray()
                
                Wearable.getMessageClient(this).sendMessage(node.id, PATH_AUTH, message)
                    .addOnSuccessListener { Log.d("WearSync", "Mensaje v7 enviado a nodo: ${node.displayName}") }
                    .addOnFailureListener { Log.e("WearSync", "Error enviando mensaje v7: ${it.message}") }
            }
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
                Log.d("WearSync", "Data Layer Changed: Token recibido")
                notifyFlutter(accessToken, refreshToken)
            }
        }
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        if (messageEvent.path == PATH_AUTH) {
            val rawMessage = String(messageEvent.data)
            Log.d("WearSync", "Mensaje recibido: $rawMessage")
            
            try {
                if (rawMessage.startsWith("v7:")) {
                    val encoded = rawMessage.substring(3)
                    val decoded = String(android.util.Base64.decode(encoded, android.util.Base64.DEFAULT))
                    val parts = decoded.split("|", limit = 2)
                    if (parts.size == 2) {
                        notifyFlutter(parts[0], parts[1])
                    }
                } else {
                    // Fallback para mensajes antiguos v6
                    val parts = rawMessage.split("|", limit = 2)
                    if (parts.size == 2) {
                        notifyFlutter(parts[0], parts[1])
                    }
                }
            } catch (e: Exception) {
                Log.e("WearSync", "Error decodificando mensaje v7: ${e.message}")
            }
        }
    }

    private fun notifyFlutter(accessToken: String?, refreshToken: String?) {
        if (accessToken == null || refreshToken == null) return
        
        runOnUiThread {
            Log.d("WearSync", "Notificando a Flutter (v7): accessToken=${accessToken.take(10)}...")
            methodChannel?.invokeMethod("onTokenReceived", mapOf(
                "accessToken" to accessToken,
                "refreshToken" to refreshToken,
                "timestamp" to System.currentTimeMillis()
            ))
        }
    }
}
