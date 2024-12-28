"use strict";

import { DeviceEventEmitter, NativeModules, Platform } from 'react-native';
import { BLE_PRINTER_EVENTS } from './enums/ble-printer-events';
export * from './models/align.identify';
export * from './models/device.identify';
const LINKING_ERROR = `The package 'react-native-ble-printer' doesn't seem to be linked. Make sure: \n\n` + Platform.select({
  ios: "- You have run 'pod install'\n",
  default: ''
}) + '- You rebuilt the app after installing the package\n' + '- You are not using Expo Go\n';
const BlePrinter = NativeModules.BlePrinter ? NativeModules.BlePrinter : new Proxy({}, {
  get() {
    throw new Error(LINKING_ERROR);
  }
});
function bluetoothIsEnabled() {
  return BlePrinter.bluetoothIsEnabled();
}
function scanDevices() {
  return BlePrinter.scanDevices();
}
function printStroke(strokeHeight = 20, strokeWidth = 5, strokeDash) {
  return BlePrinter.printStroke(strokeHeight, strokeWidth, strokeDash);
}
function printSpace(spacing) {
  return BlePrinter.printSpace(spacing);
}
function printText(text, options = {}) {
  const {
    bold = false,
    size = 24,
    align = 'LEFT'
  } = options;
  return BlePrinter.printText(text, bold, align, size);
}
function printTwoColumns(leftText, rightText, options = {}) {
  const {
    bold = false,
    size = 24
  } = options;
  return BlePrinter.printTwoColumns(leftText, rightText, bold, size);
}
function printColumns(texts, columnWidths, alignments, options = {}) {
  const {
    bold = false,
    size = 24
  } = options;
  return BlePrinter.printColumns(texts, columnWidths, alignments, bold, size);
}
function connect(address) {
  return BlePrinter.connect(address);
}
function disconnect() {
  return BlePrinter.disconnect();
}
function onDeviceFound(callback) {
  return DeviceEventEmitter.addListener(BLE_PRINTER_EVENTS.DEVICE_FOUND, device => callback(JSON.parse(device)));
}
function onDevicePaired(callback) {
  return DeviceEventEmitter.addListener(BLE_PRINTER_EVENTS.DEVICE_PAIRED, device => callback(JSON.parse(device)));
}
function onDiscoveryFinished(callback) {
  return DeviceEventEmitter.addListener(BLE_PRINTER_EVENTS.DISCOVER_DONE, callback);
}
export default {
  connect,
  bluetoothIsEnabled,
  disconnect,
  scanDevices,
  printText,
  printColumns,
  printSpace,
  printStroke,
  printTwoColumns,
  onDeviceFound,
  onDiscoveryFinished,
  onDevicePaired
};
//# sourceMappingURL=index.js.map