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

class MainActivity : FlutterActivity(), DataClient.OnDataChangedListener {
    private val CHANNEL = "com.example.lapcounter/wear_sync"
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Wearable.getDataClient(this).addListener(this)
    }

    override fun onDestroy() {
        Wearable.getDataClient(this).removeListener(this)
        super.onDestroy()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendTokenToWatch" -> {
                    val token = call.argument<String>("token")
                    if (token != null) {
                        sendTokenToWatch(token, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Token is null", null)
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

    private fun sendTokenToWatch(token: String, result: MethodChannel.Result) {
        val putDataMapReq = PutDataMapRequest.create("/auth_token")
        putDataMapReq.dataMap.putString("token", token)
        putDataMapReq.dataMap.putLong("timestamp", System.currentTimeMillis())
        val putDataReq = putDataMapReq.asPutDataRequest()
        putDataReq.setUrgent()

        Wearable.getDataClient(this).putDataItem(putDataReq)
            .addOnSuccessListener {
                result.success(true)
            }
            .addOnFailureListener { e ->
                result.error("SYNC_FAILED", e.message, null)
            }
    }

    private fun openRemoteInput(hint: String, receiverName: String, result: MethodChannel.Result) {
        // En Wear OS, usamos el RemoteInput nativo. 
        // Nota: En Flutter, esto usualmente se maneja mostrando un diálogo que captura el resultado.
        // Dado que somos una FlutterActivity, podemos disparar un ActivityForResult o usar una librería de Wear OS.
        // Para simplificar esta iteración y asegurar compatibilidad, usaremos un enfoque de canal de retorno.
        
        // El verdadero RemoteInput a menudo requiere una notificación o un Action específico.
        // Sin embargo, en apps de Flutter para Wear OS, a menudo se usa un 'TextInputDialog' nativo.
        // Como no tenemos una librería de UI nativa de Wear cargada en este fragmento, 
        // marcaremos esto para mejora, pero por ahora el objetivo es la sincronización silenciosa.
        result.success(null) 
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type == DataEvent.TYPE_CHANGED && event.dataItem.uri.path == "/auth_token") {
                val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                val token = dataMap.getString("token")
                val timestamp = dataMap.getLong("timestamp")
                
                // Enviar el token a Flutter
                runOnUiThread {
                    methodChannel?.invokeMethod("onTokenReceived", mapOf(
                        "token" to token,
                        "timestamp" to timestamp
                    ))
                }
            }
        }
    }
}
