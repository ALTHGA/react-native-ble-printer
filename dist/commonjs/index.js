"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
var _exportNames = {};
exports.default = void 0;
var _reactNative = require("react-native");
var _blePrinterEvents = require("./enums/ble-printer-events");
var _align = require("./models/align.identify");
Object.keys(_align).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (Object.prototype.hasOwnProperty.call(_exportNames, key)) return;
  if (key in exports && exports[key] === _align[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _align[key];
    }
  });
});
var _device = require("./models/device.identify");
Object.keys(_device).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (Object.prototype.hasOwnProperty.call(_exportNames, key)) return;
  if (key in exports && exports[key] === _device[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _device[key];
    }
  });
});
const LINKING_ERROR = `The package 'react-native-ble-printer' doesn't seem to be linked. Make sure: \n\n` + _reactNative.Platform.select({
  ios: "- You have run 'pod install'\n",
  default: ''
}) + '- You rebuilt the app after installing the package\n' + '- You are not using Expo Go\n';
const BlePrinter = _reactNative.NativeModules.BlePrinter ? _reactNative.NativeModules.BlePrinter : new Proxy({}, {
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
  return _reactNative.DeviceEventEmitter.addListener(_blePrinterEvents.BLE_PRINTER_EVENTS.DEVICE_FOUND, device => callback(JSON.parse(device)));
}
function onDevicePaired(callback) {
  return _reactNative.DeviceEventEmitter.addListener(_blePrinterEvents.BLE_PRINTER_EVENTS.DEVICE_PAIRED, device => callback(JSON.parse(device)));
}
function onDiscoveryFinished(callback) {
  return _reactNative.DeviceEventEmitter.addListener(_blePrinterEvents.BLE_PRINTER_EVENTS.DISCOVER_DONE, callback);
}
var _default = exports.default = {
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