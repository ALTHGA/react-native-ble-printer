import { useEffect, useState } from 'react';
import {
  Alert,
  Button,
  ScrollView,
  StyleSheet,
  Text,
  View,
  type EmitterSubscription,
} from 'react-native';
import BlePrinter, { type Device } from 'react-native-ble-printer';
import { DeviceItem } from './components/DeviceItem';
import { printReceipt } from './services/printReceipt';

export default function App() {
  const [connectedDevice, setConnectedDevice] = useState<Device | null>(null);
  const [pairedDevices, setPairedDevices] = useState<Device[]>([]);
  const [foundDevices, setFoundDevices] = useState<Device[]>([]);
  const [isScanning, setScanning] = useState<boolean>(false);

  async function handlePrintReceipt() {
    try {
      await printReceipt();
    } catch (error) {
      console.log(error);
    }
  }

  async function handleScanDevices() {
    const isEnabled = await BlePrinter.bluetoothIsEnabled();

    if (!isEnabled) {
      Alert.alert('Oops!', 'Enable bluetooth');
      return;
    }

    setScanning(true);

    try {
      setFoundDevices([]);
      setPairedDevices([]);
      await BlePrinter.scanDevices();
    } catch (error) {
      console.log(error);
    }
    setScanning(false);
  }

  const handleDeviceFounds = (device: Device) => {
    console.log('Devices', device);
    setFoundDevices((oldDevices) => [...oldDevices, device]);
  };

  const handleDevicePaired = (device: Device) => {
    setPairedDevices((oldDevices) => [...oldDevices, device]);
  };

  useEffect(() => {
    var listeners: EmitterSubscription[] = [];

    listeners.push(BlePrinter.onDeviceFound(handleDeviceFounds));
    listeners.push(BlePrinter.onDevicePaired(handleDevicePaired));

    return () => {
      for (var listener of listeners) {
        listener.remove();
      }
    };
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>BLEPrinter</Text>
        <View style={styles.headerActions}>
          <Button
            title="Scan Devices"
            onPress={handleScanDevices}
            disabled={isScanning}
          />
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.body}>
        {/* Options */}

        {/* Paired devices */}
        <Text>Dispositivos pareados:</Text>
        {pairedDevices.map((device, i) => (
          <DeviceItem
            isConnected={device.address === connectedDevice?.address}
            item={device}
            key={i}
            onConnectDevice={setConnectedDevice}
          />
        ))}

        {/* Found devices */}
        <Text>Dispositivos encontrados:</Text>
        {foundDevices.map((device, i) => (
          <DeviceItem
            item={device}
            isConnected={false}
            key={i}
            onConnectDevice={setConnectedDevice}
          />
        ))}
      </ScrollView>

      {connectedDevice && (
        <Button title="Print Receipt" onPress={handlePrintReceipt} />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#eee',
  },
  header: {
    paddingTop: 54,
    paddingBottom: 20,
    paddingHorizontal: 20,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'white',
    elevation: 5,
    shadowColor: 'rgba(0,0,0,0.8)',
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    gap: 10,
    flex: 1,
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: 'bold',
  },
  body: {
    paddingHorizontal: 10,
    gap: 10,
    paddingTop: 10,
    paddingBottom: 100,
  },
});
