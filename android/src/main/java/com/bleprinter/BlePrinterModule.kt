package com.bleprinter

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext.RCTDeviceEventEmitter
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableArray
import org.json.JSONObject
import java.io.OutputStream
import java.util.Collections
import java.util.UUID

class BlePrinterModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String {
    return NAME
  }

  private val TAG = "BluetoothPrinter"
  private val EVENT_FOUND_DEVICES = "EVENT_FOUND_DEVICES"
  private val EVENT_PAIRED_DEVICES = "EVENT_PAIRED_DEVICES"
  private val EVENT_DISCOVERY_FINISHED = "EVENT_DISCOVERY_FINISHED"
  private var promiseScan: Promise? = null

  private val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

  var outputStream: OutputStream? = null
  private var socket: BluetoothSocket? = null

  private fun getStream(): OutputStream? {
    return outputStream ?: throw Exception("Device is not connected, please connect!")
  }

  private var devices: MutableList<BluetoothDevice> =
    Collections.synchronizedList(mutableListOf<BluetoothDevice>())

  private var receiverRegistered = false

  fun getAdapter(): BluetoothAdapter? {
    val bluetoothManager: BluetoothManager =
      reactApplicationContext.getSystemService(BluetoothManager::class.java)
    val bleAdapter: BluetoothAdapter = bluetoothManager.adapter
      ?: throw Exception("Devices doesn't support bluetooth")

    return bleAdapter
  }

  @ReactMethod
  fun bluetoothIsEnabled(promise: Promise) {
    val adapter = getAdapter()
    try {
        promise.resolve(adapter?.isEnabled)
    } catch (e: Exception) {
      promise.reject("PrintError", e.message)
    }
  }

  @SuppressLint("MissingPermission")
  @ReactMethod
  fun connect(address: String, promise: Promise) {
    val adapter = getAdapter()
    try {
      val device = adapter?.getRemoteDevice(address)
      if (device == null) {
        promise.reject("NOT_FOUND", "DEVICE NOT FOUND")
        return
      }


      socket = device.createRfcommSocketToServiceRecord(uuid)
      socket?.connect()
      outputStream = socket?.outputStream

      if (adapter != null && adapter.isDiscovering) {
        adapter.cancelDiscovery()
      }

      promise.resolve("CONNECT")
    } catch (e: Exception) {
      promise.reject("BlePrinter", e.message)
    }
  }

  @SuppressLint("MissingPermission")
  @ReactMethod
  fun disconnect(promise: Promise) {
    try {
      if (socket == null || outputStream == null) {
        promise.reject("NOT_FOUND", "DEVICE NOT FOUND")
        return
      }

      socket?.close()
      socket = null
      outputStream = null
      promise.resolve("Disconnected")
    } catch (e: Exception) {
      promise.reject("PrintError", e.message)
    }
  }

  @SuppressLint("MissingPermission")
  @RequiresApi(Build.VERSION_CODES.ECLAIR)
  @ReactMethod
  fun scanDevices(promise: Promise) {
    val checkBluetoothScanPermission = ActivityCompat.checkSelfPermission(
      reactApplicationContext,
      Manifest.permission.BLUETOOTH_SCAN
    )

    if (checkBluetoothScanPermission != PackageManager.PERMISSION_GRANTED) {
      requestPermissions(
        arrayOf(
          Manifest.permission.BLUETOOTH_SCAN,
          Manifest.permission.BLUETOOTH_CONNECT,
          Manifest.permission.ACCESS_COARSE_LOCATION
        )
      )
      promise.reject("PERMISSIONS", "Insufficient Permissions")
      return
    }

    val bleAdapter = getAdapter()
    try {
      stopScan()


      val pairedDevices = bleAdapter?.bondedDevices
      pairedDevices?.forEach {
        val pairedDevice = JSONObject()
        pairedDevice.put("name", it.name ?: "Unknown")
        pairedDevice.put("address", it.address)
        reactEmitEvent(EVENT_PAIRED_DEVICES, pairedDevice.toString())
      }

      devices.clear()
      bleAdapter?.startDiscovery()
      promiseScan = promise
    } catch (e: Exception) {
      promise.reject("SCAN", e.message)
    }
  }

  @RequiresApi(Build.VERSION_CODES.ECLAIR)
  @SuppressLint("MissingPermission")
  fun stopScan() {
    val bleAdapter = getAdapter()
    if (bleAdapter != null && bleAdapter.isDiscovering) {
      bleAdapter.cancelDiscovery()
      return
    }
  }

  @ReactMethod
  fun printText(
    text: String,
    bold: Boolean = false,
    align: String = "LEFT",
    size: Float = 24f,
    promise: Promise
  ) {

    val textBitmap = Utils().createTextBitmap(text, align, bold, size)
    val stream = getStream()
    try {
      stream?.write(textBitmap)
      promise.resolve("Printed Text")
    } catch (e: Exception) {
      promise.resolve(e.message)
    }
  }

  @ReactMethod
  fun printStroke(strokeHeight: Int = 20, strokeWidth: Float = 5f , strokeDash: ReadableArray? = null, promise: Promise) {
    val stream = getStream()
    try {
      val dash = if(strokeDash != null) FloatArray(strokeDash.size()) { strokeDash.getInt(it).toFloat() } else null
      stream?.write(Utils().createStyledStrokeBitmap(strokeHeight, strokeWidth, dash))
      promise.resolve("Print Underline")
    } catch (e: Exception) {
      promise.reject("PrintError", e.message)
    }
  }

  @ReactMethod
  fun resetPrinter(promise: Promise) {
    val stream = getStream()
    try {
      stream?.write(byteArrayOf(0x1B, 0x40))
      promise.resolve("Print reseted!")
    } catch (e: Exception) {
      promise.reject("PrintError", e.message)
    }
  }

  @ReactMethod
  fun printSpace(lines: Int, promise: Promise) {
    val stream = getStream()
    try {
      for (i in 0..lines) {
        stream?.write("\n".toByteArray())
      }

      promise.resolve("PRINTED LINES")
    } catch (e: Exception) {
      promise.reject("PrintError", e.message)
    }
  }

  @ReactMethod
  fun printTwoColumns(
    leftText: String,
    rightText: String,
    bold: Boolean = false,
    size: Float = 24f,
    promise: Promise
  ) {
    val text = Utils().twoColumnsBitmap(leftText, rightText, bold, size)
    val stream = getStream()
    try {
      stream?.write(text)
      promise.resolve("Printed Text")
    } catch (e: Exception) {
      promise.resolve(e.message)
    }
  }

  @ReactMethod
  fun printColumns(texts: ReadableArray, columnWidths: ReadableArray, alignments: ReadableArray, bold: Boolean = false, textSize: Float = 24f, promise: Promise) {
    val textList = Array(texts.size()) { texts.getString(it) ?: "" }
    val columnWidthList = Array(columnWidths.size()) { columnWidths.getInt(it) }
    val alignmentList = Array(alignments.size()) { alignments.getString(it) ?: "LEFT" }
    val columnBitmap = Utils().createColumnTextBitmap(textList, columnWidthList, alignmentList, bold, textSize)
    val stream = getStream()
    try {
      stream?.write(columnBitmap)
      promise.resolve("Printed Text")
    } catch (e: Exception) {
      promise.resolve(e.message)
    }
  }


  private val receiver = object : BroadcastReceiver() {

    @SuppressLint("MissingPermission")
    override fun onReceive(context: Context, intent: Intent) {
      val action: String = intent.action.toString()
      when (action) {
        BluetoothDevice.ACTION_FOUND -> {

          val bluetoothDevice: BluetoothDevice? =
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)

          bluetoothDevice?.let {
            val device = JSONObject()
            if (bluetoothDevice.bondState != BluetoothDevice.BOND_BONDED) {
              if (!deviceFounded(bluetoothDevice)) {
                devices.add(bluetoothDevice)
                device.put("name", bluetoothDevice.name ?: "Unknown")
                device.put("address", bluetoothDevice.address)
                reactEmitEvent(EVENT_FOUND_DEVICES, device.toString())
              }
            }
          }
        }

        BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
          promiseScan?.resolve("SCAN")
          reactEmitEvent(EVENT_DISCOVERY_FINISHED)
        }
      }
    }
  }

  fun reactEmitEvent(event: String, data: Any? = null) {
    reactApplicationContext
      .getJSModule(RCTDeviceEventEmitter::class.java)
      .emit(event, data)
  }

  fun deviceFounded(device: BluetoothDevice): Boolean {
    return devices.any { it.address == device.address }
  }

  @SuppressLint("MissingPermission")
  fun unregisterReceiver() {
    if (receiverRegistered) {
      val bleAdapter = getAdapter()

      if (bleAdapter != null && bleAdapter.isDiscovering) {
        bleAdapter.cancelDiscovery()
      }

      reactApplicationContext.unregisterReceiver(receiver)
      receiverRegistered = false
    }
  }

  private fun requestPermissions(permissions: Array<String>) {
    ActivityCompat.requestPermissions(reactApplicationContext.currentActivity!!, permissions, 1)
  }

  init {
    val filter = IntentFilter(BluetoothDevice.ACTION_FOUND)
    filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
    reactApplicationContext.registerReceiver(receiver, filter)
    receiverRegistered = true
  }

  companion object {
    const val NAME = "BlePrinter"
  }
}
