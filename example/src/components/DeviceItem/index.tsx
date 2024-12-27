import { useState } from 'react';
import { Button, StyleSheet, Text, View } from 'react-native';
import BlePrinter, { type Device } from 'react-native-ble-printer';

interface DeviceItemProps {
  item: Device;
  isConnected: boolean;
  onConnectDevice(device: Device | null): void;
}

export const DeviceItem = ({
  item,
  isConnected,
  onConnectDevice,
}: DeviceItemProps) => {
  const [connectionLoading, setConnectionLoading] = useState(false);

  const handleConnectDevice = async (device: Device) => {
    setConnectionLoading(true);
    try {
      if (isConnected) {
        await BlePrinter.disconnect(); // Disconnect a device connected
        onConnectDevice(null);
      } else {
        await BlePrinter.connect(device.address);
        onConnectDevice(device);
      }
    } catch (error) {
      console.log(error);
    }
    setConnectionLoading(false);
  };

  return (
    <View style={styles.container}>
      <View>
        <Text style={styles.name}>{item.name}</Text>
        <Text style={styles.address}>{item.address}</Text>
      </View>

      <Button
        disabled={connectionLoading}
        onPress={() => handleConnectDevice(item)}
        color={isConnected ? 'gray' : undefined}
        title={isConnected ? 'Disconnect' : 'Connect'}
      />
    </View>
  );
};

export const styles = StyleSheet.create({
  container: {
    backgroundColor: '#FFFFFF',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 12,
  },
  name: {
    color: 'black',
    fontSize: 16,
  },
  address: {
    fontSize: 13,
  },
});
