import {
  NativeEventEmitter,
  NativeModules,
  Platform,
  type EmitterSubscription,
} from 'react-native';
import { BLE_PRINTER_EVENTS } from './enums/ble-printer-events';
import type { Align } from './models/align.identify';
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

const eventEmitter = new NativeEventEmitter(BlePrinter);

function bluetoothIsEnabled(): Promise<boolean> {
  return BlePrinter.bluetoothIsEnabled();
}

function scanDevices(): Promise<void> {
  return BlePrinter.scanDevices();
}

function printStroke(
  strokeHeight: number = 20,
  strokeWidth: number = 5,
  strokeDash?: number[]
): Promise<void> {
  return BlePrinter.printStroke(strokeHeight, strokeWidth, strokeDash);
}

function printSpace(spacing: number): Promise<void> {
  return BlePrinter.printSpace(spacing);
}

function printText(text: string, options = {} as PrintOptions): Promise<void> {
  const { bold = false, size = 24, align = 'LEFT' } = options;
  return BlePrinter.printText(text, bold, align, size);
}

function printTwoColumns(
  leftText: string,
  rightText: string,
  options = {} as Omit<PrintOptions, 'align'>
): Promise<void> {
  const { bold = false, size = 24 } = options;
  return BlePrinter.printTwoColumns(leftText, rightText, bold, size);
}

function printColumns(
  texts: string[],
  columnWidths: number[],
  alignments: Align[],
  options = {} as Omit<PrintOptions, 'align'>
) {
  const { bold = false, size = 24 } = options;
  return BlePrinter.printColumns(texts, columnWidths, alignments, bold, size);
}

function connect(address: string): Promise<void> {
  return BlePrinter.connect(address);
}

function disconnect(): Promise<void> {
  return BlePrinter.disconnect();
}

const normalizeDevice = (data: string): Device => {
  let device;
  try {
    if (typeof data === 'string') {
      device = JSON.parse(data);
    } else {
      device = data;
    }
  } catch (error) {
    console.error('Failed to normalize device data:', error, data);
    throw error;
  }
  return {
    name: device.name || 'Unknown',
    address: Platform.OS === 'ios' ? device.address : device.address,
  };
};

function onDeviceFound(
  callback: (device: Device) => void
): EmitterSubscription {
  return eventEmitter.addListener(
    BLE_PRINTER_EVENTS.DEVICE_FOUND,
    (device: string) => {
      const normalizedData = normalizeDevice(device);
      if (normalizedData) {
        callback(normalizedData);
      } else {
        console.warn(
          `Invalid device data received for event ${BLE_PRINTER_EVENTS.DEVICE_FOUND}:`,
          device
        );
      }
    }
  );
}

function onDevicePaired(
  callback: (device: Device) => void
): EmitterSubscription {
  return eventEmitter.addListener(
    BLE_PRINTER_EVENTS.DEVICE_PAIRED,
    (device: string) => {
      const normalizedData = normalizeDevice(device);
      if (normalizedData) {
        callback(normalizedData);
      } else {
        console.warn(
          `Invalid device data received for event ${BLE_PRINTER_EVENTS.DEVICE_PAIRED}:`,
          device
        );
      }
    }
  );
}

function onDiscoveryFinished(
  callback: (listener: any) => void
): EmitterSubscription {
  return eventEmitter.addListener(BLE_PRINTER_EVENTS.DISCOVER_DONE, callback);
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
  onDevicePaired,
};
