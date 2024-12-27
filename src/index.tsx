import {
  DeviceEventEmitter,
  type EmitterSubscription,
  NativeModules,
  Platform,
} from 'react-native';
import { BLE_PRINTER_EVENTS } from './enums/ble-printer-events';
import type { Device } from './models/device.identify';
import type { PrintOptions } from './models/print.identify';

export * from './models/align.identify';
export * from './models/device.identify';

const LINKING_ERROR =
  `The package 'react-native-ble-printer' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const BlePrinter = NativeModules.BlePrinter
  ? NativeModules.BlePrinter
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );
function bluetoothIsEnabled(): Promise<boolean> {
  return BlePrinter.bluetoothIsEnabled();
}

function scanDevices(): Promise<void> {
  return BlePrinter.scanDevices();
}

function printUnderline(): Promise<void> {
  return BlePrinter.printUnderline();
}

function printLines(lines: number): Promise<void> {
  return BlePrinter.printLines(lines);
}

function printText(text: string, options = {} as PrintOptions): Promise<void> {
  const { bold = false, size = 24, align = 'LEFT' } = options;
  return BlePrinter.printText(text, bold, align, size);
}

function printColumns(
  leftText: string,
  rightText: string,
  options = {} as Omit<PrintOptions, 'align'>
): Promise<void> {
  const { bold = false, size = 24 } = options;
  return BlePrinter.printColumns(leftText, rightText, bold, size);
}

function connect(address: string): Promise<void> {
  return BlePrinter.connect(address);
}

function disconnect(): Promise<void> {
  return BlePrinter.disconnect();
}

function onDeviceFound(
  callback: (device: Device) => void
): EmitterSubscription {
  return DeviceEventEmitter.addListener(
    BLE_PRINTER_EVENTS.DEVICE_FOUND,
    (device: string) => callback(JSON.parse(device))
  );
}

function onDevicePaired(
  callback: (device: Device) => void
): EmitterSubscription {
  return DeviceEventEmitter.addListener(
    BLE_PRINTER_EVENTS.DEVICE_PAIRED,
    (device: string) => callback(JSON.parse(device))
  );
}

function onDiscoveryFinished(
  callback: (listener: any) => void
): EmitterSubscription {
  return DeviceEventEmitter.addListener(
    BLE_PRINTER_EVENTS.DISCOVER_DONE,
    callback
  );
}

export default {
  connect,
  bluetoothIsEnabled,
  disconnect,
  scanDevices,
  printText,
  printLines,
  printUnderline,
  printColumns,
  onDeviceFound,
  onDiscoveryFinished,
  onDevicePaired,
};
