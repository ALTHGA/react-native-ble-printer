#import "BlePrinter.h"
#import "Utils.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BlePrinter () <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *connectedPeripheral;
@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;
@property (nonatomic, strong) NSMutableDictionary *deviceMap;
@property (nonatomic, strong) RCTPromiseResolveBlock scanPromise;
@property (nonatomic, strong) NSMutableArray *pendingOperations;
@property (nonatomic, assign) BOOL isBluetoothPoweredOn;
@property (nonatomic, assign) BOOL isScanning;
@property (nonatomic, copy) RCTPromiseResolveBlock connectResolve;
@property (nonatomic, copy) RCTPromiseRejectBlock connectReject;
@end

@implementation BlePrinter

RCT_EXPORT_MODULE(BlePrinter);

- (NSArray<NSString *> *)supportedEvents {
    return @[@"EVENT_FOUND_DEVICES", @"EVENT_PAIRED_DEVICES", @"EVENT_DISCOVERY_FINISHED"];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.pendingOperations = [NSMutableArray array];
        self.isBluetoothPoweredOn = NO;
        self.isScanning = NO;
        self.deviceMap = [NSMutableDictionary dictionary];
    }
    return self;
}

// Inicializar CBCentralManager se ainda não estiver inicializado
- (void)ensureCentralManagerInitialized {
    if (!self.centralManager) {
        NSLog(@"Initializing CBCentralManager...");
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
}

// Verificar se o Bluetooth está ativado
RCT_EXPORT_METHOD(bluetoothIsEnabled:(RCTPromiseResolveBlock)resolve
                           rejecter:(RCTPromiseRejectBlock)reject) {
    [self ensureCentralManagerInitialized];
    if (self.isBluetoothPoweredOn) {
        NSLog(@"Bluetooth is enabled.");
        resolve(@YES);
    } else {
        NSLog(@"Bluetooth not yet powered on, adding to pending operations.");
        [self.pendingOperations addObject:@{@"resolve": resolve, @"reject": reject}];
    }
}

// Escanear dispositivos BLE
RCT_EXPORT_METHOD(scanDevices:(RCTPromiseResolveBlock)resolve
                     rejecter:(RCTPromiseRejectBlock)reject) {
    [self ensureCentralManagerInitialized];
    if (!self.isBluetoothPoweredOn) {
        NSLog(@"Bluetooth not powered on, adding scan to pending operations.");
        [self.pendingOperations addObject:@{@"resolve": resolve, @"reject": reject, @"operation": @"scan"}];
        return;
    }
    NSLog(@"Starting BLE scan...");
    [self.centralManager stopScan];
    [self.deviceMap removeAllObjects];
    self.isScanning = YES;
    
    // Enviar dispositivos pareados (simulação)
    NSDictionary *pairedDevices = [self getPairedDevices];
    for (NSString *deviceId in pairedDevices) {
        NSDictionary *deviceInfo = pairedDevices[deviceId];
        NSLog(@"Sending paired device: %@", deviceInfo);
        [self sendEventWithName:@"EVENT_PAIRED_DEVICES" body:deviceInfo];
    }
    
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    self.scanPromise = resolve;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (self.isScanning) {
            NSLog(@"Stopping BLE scan...");
            [self.centralManager stopScan];
            self.isScanning = NO;
            [self sendEventWithName:@"EVENT_DISCOVERY_FINISHED" body:nil];
            if (self.scanPromise) {
                self.scanPromise(@YES);
                self.scanPromise = nil;
            }
        }
    });
}

// Conectar a um dispositivo
RCT_EXPORT_METHOD(connect:(NSString *)address
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    [self ensureCentralManagerInitialized];
    if (!self.isBluetoothPoweredOn) {
        reject(@"BLUETOOTH_NOT_READY", @"Bluetooth is not powered on", nil);
        return;
    }

    CBPeripheral *peripheral = self.deviceMap[address];
    if (peripheral) {
        NSLog(@"Connecting to peripheral: %@", address);
        self.connectedPeripheral = peripheral;
        self.connectResolve = resolve;
        self.connectReject = reject;
        [self.centralManager connectPeripheral:peripheral options:nil];
    } else {
        reject(@"NOT_FOUND", @"DEVICE NOT FOUND", nil);
    }
}

// Desconectar
RCT_EXPORT_METHOD(disconnect:(RCTPromiseResolveBlock)resolve
                    rejecter:(RCTPromiseRejectBlock)reject) {
    if (self.connectedPeripheral) {
        NSLog(@"Disconnecting from peripheral...");
        [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
        self.connectedPeripheral = nil;
        self.writeCharacteristic = nil;
        resolve(@"Disconnected");
    } else {
        NSLog(@"No peripheral connected to disconnect.");
        reject(@"NOT_FOUND", @"DEVICE NOT FOUND", nil);
    }
}

// Imprimir texto
RCT_EXPORT_METHOD(printText:(NSString *)text
                      bold:(BOOL)bold
                     align:(NSString *)align
                      size:(float)size
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [self ensureCentralManagerInitialized];
    if (!self.isBluetoothPoweredOn) {
        NSLog(@"Bluetooth not powered on, rejecting printText.");
        reject(@"BLUETOOTH_NOT_READY", @"Bluetooth is not powered on", nil);
        return;
    }
    if (!self.connectedPeripheral || !self.writeCharacteristic) {
        NSLog(@"No connected peripheral or characteristic for printText.");
        reject(@"NOT_FOUND", @"No device connected or characteristic not found", nil);
        return;
    }
    NSLog(@"Printing text: %@", text);
    NSData *data = [Utils createTextBitmapWithText:text align:align bold:bold fontSize:size];
    [self.connectedPeripheral writeValue:data
                      forCharacteristic:self.writeCharacteristic
                                   type:CBCharacteristicWriteWithResponse];
    resolve(@"Printed Text");
}

// Imprimir linha estilizada
RCT_EXPORT_METHOD(printStroke:(int)strokeHeight
                 strokeWidth:(float)strokeWidth
                  strokeDash:(NSArray *)strokeDash
                    resolver:(RCTPromiseResolveBlock)resolve
                    rejecter:(RCTPromiseRejectBlock)reject) {
    [self ensureCentralManagerInitialized];
    if (!self.isBluetoothPoweredOn) {
        NSLog(@"Bluetooth not powered on, rejecting printStroke.");
        reject(@"BLUETOOTH_NOT_READY", @"Bluetooth is not powered on", nil);
        return;
    }
    if (!self.connectedPeripheral || !self.writeCharacteristic) {
        NSLog(@"No connected peripheral or characteristic for printStroke.");
        reject(@"NOT_FOUND", @"No device connected or characteristic not found", nil);
        return;
    }
    NSLog(@"Printing stroke with height: %d, width: %f", strokeHeight, strokeWidth);
    NSData *data = [Utils createStyledStrokeBitmapWithHeight:strokeHeight width:strokeWidth dash:strokeDash];
    [self.connectedPeripheral writeValue:data
                      forCharacteristic:self.writeCharacteristic
                                   type:CBCharacteristicWriteWithResponse];
    resolve(@"Print Underline");
}

// Resetar impressora
RCT_EXPORT_METHOD(resetPrinter:(RCTPromiseResolveBlock)resolve
                      rejecter:(RCTPromiseRejectBlock)reject) {
    [self ensureCentralManagerInitialized];
    if (!self.isBluetoothPoweredOn) {
        NSLog(@"Bluetooth not powered on, rejecting resetPrinter.");
        reject(@"BLUETOOTH_NOT_READY", @"Bluetooth is not powered on", nil);
        return;
    }
    if (!self.connectedPeripheral || !self.writeCharacteristic) {
        NSLog(@"No connected peripheral or characteristic for resetPrinter.");
        reject(@"NOT_FOUND", @"No device connected or characteristic not found", nil);
        return;
    }
    NSLog(@"Resetting printer...");
    const uint8_t reset[] = {0x1B, 0x40};
    NSData *data = [NSData dataWithBytes:reset length:2];
    [self.connectedPeripheral writeValue:data
                      forCharacteristic:self.writeCharacteristic
                                   type:CBCharacteristicWriteWithResponse];
    resolve(@"Print reseted!");
}

// Imprimir espaço
RCT_EXPORT_METHOD(printSpace:(int)lines
                   resolver:(RCTPromiseResolveBlock)resolve
                   rejecter:(RCTPromiseRejectBlock)reject) {
    [self ensureCentralManagerInitialized];
    if (!self.isBluetoothPoweredOn) {
        NSLog(@"Bluetooth not powered on, rejecting printSpace.");
        reject(@"BLUETOOTH_NOT_READY", @"Bluetooth is not powered on", nil);
        return;
    }
    if (!self.connectedPeripheral || !self.writeCharacteristic) {
        NSLog(@"No connected peripheral or characteristic for printSpace.");
        reject(@"NOT_FOUND", @"No device connected or characteristic not found", nil);
        return;
    }
    NSLog(@"Printing %d empty lines...", lines);
    NSMutableData *data = [NSMutableData data];
    for (int i = 0; i < lines; i++) {
        [data appendData:[@"\n" dataUsingEncoding:NSASCIIStringEncoding]];
    }
    [self.connectedPeripheral writeValue:data
                      forCharacteristic:self.writeCharacteristic
                                   type:CBCharacteristicWriteWithResponse];
    resolve(@"PRINTED LINES");
}

// Imprimir duas colunas
RCT_EXPORT_METHOD(printTwoColumns:(NSString *)leftText
                        rightText:(NSString *)rightText
                             bold:(BOOL)bold
                             size:(float)size
                         resolver:(RCTPromiseResolveBlock)resolve
                         rejecter:(RCTPromiseRejectBlock)reject) {
    [self ensureCentralManagerInitialized];
    if (!self.isBluetoothPoweredOn) {
        NSLog(@"Bluetooth not powered on, rejecting printTwoColumns.");
        reject(@"BLUETOOTH_NOT_READY", @"Bluetooth is not powered on", nil);
        return;
    }
    if (!self.connectedPeripheral || !self.writeCharacteristic) {
        NSLog(@"No connected peripheral or characteristic for printTwoColumns.");
        reject(@"NOT_FOUND", @"No device connected or characteristic not found", nil);
        return;
    }
    NSLog(@"Printing two columns: %@ | %@", leftText, rightText);
    NSData *data = [Utils twoColumnsBitmapWithLeftText:leftText rightText:rightText bold:bold size:size];
    [self.connectedPeripheral writeValue:data
                      forCharacteristic:self.writeCharacteristic
                                   type:CBCharacteristicWriteWithResponse];
    resolve(@"Printed Text");
}

// Imprimir colunas
RCT_EXPORT_METHOD(printColumns:(NSArray *)texts
                 columnWidths:(NSArray *)columnWidths
                  alignments:(NSArray *)alignments
                        bold:(BOOL)bold
                    textSize:(float)textSize
                    resolver:(RCTPromiseResolveBlock)resolve
                    rejecter:(RCTPromiseRejectBlock)reject) {
    [self ensureCentralManagerInitialized];
    if (!self.isBluetoothPoweredOn) {
        NSLog(@"Bluetooth not powered on, rejecting printColumns.");
        reject(@"BLUETOOTH_NOT_READY", @"Bluetooth is not powered on", nil);
        return;
    }
    if (!self.connectedPeripheral || !self.writeCharacteristic) {
        NSLog(@"No connected peripheral or characteristic for printColumns.");
        reject(@"NOT_FOUND", @"No device connected or characteristic not found", nil);
        return;
    }
    if (texts.count != columnWidths.count || texts.count != alignments.count) {
        NSLog(@"Invalid arguments for printColumns: texts, widths, and alignments must have the same size.");
        reject(@"INVALID_ARGS", @"texts, widths, and alignments must have the same size", nil);
        return;
    }
    NSLog(@"Printing columns: %@", texts);
    NSData *data = [Utils createColumnTextBitmapWithTexts:texts widths:columnWidths alignments:alignments bold:bold size:textSize];
    [self.connectedPeripheral writeValue:data
                      forCharacteristic:self.writeCharacteristic
                                   type:CBCharacteristicWriteWithResponse];
    resolve(@"Printed Text");
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSString *stateDescription;
    switch (central.state) {
        case CBManagerStatePoweredOn:
            stateDescription = @"Powered On";
            self.isBluetoothPoweredOn = YES;
            [self processPendingOperations];
            break;
        case CBManagerStatePoweredOff:
            stateDescription = @"Powered Off";
            self.isBluetoothPoweredOn = NO;
            self.isScanning = NO;
            [self rejectPendingOperationsWithCode:@"BLUETOOTH_OFF" message:@"Bluetooth is powered off"];
            break;
        case CBManagerStateUnauthorized:
            stateDescription = @"Unauthorized";
            self.isBluetoothPoweredOn = NO;
            self.isScanning = NO;
            [self rejectPendingOperationsWithCode:@"BLUETOOTH_UNAUTHORIZED" message:@"Bluetooth access not authorized"];
            break;
        case CBManagerStateUnsupported:
            stateDescription = @"Unsupported";
            self.isBluetoothPoweredOn = NO;
            self.isScanning = NO;
            [self rejectPendingOperationsWithCode:@"BLUETOOTH_UNSUPPORTED" message:@"Bluetooth is not supported on this device"];
            break;
        case CBManagerStateUnknown:
            stateDescription = @"Unknown";
            self.isBluetoothPoweredOn = NO;
            self.isScanning = NO;
            break;
        case CBManagerStateResetting:
            stateDescription = @"Resetting";
            self.isBluetoothPoweredOn = NO;
            self.isScanning = NO;
            break;
        default:
            stateDescription = @"Invalid";
            self.isBluetoothPoweredOn = NO;
            self.isScanning = NO;
            break;
    }
    NSLog(@"Bluetooth state changed: %@", stateDescription);
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    if (!self.isScanning) {
        NSLog(@"Ignoring discovered peripheral while not scanning: %@", peripheral.name ?: @"Unknown");
        return;
    }
    NSString *deviceId = peripheral.identifier.UUIDString;
    if (self.deviceMap[deviceId]) {
        NSLog(@"Skipping duplicate peripheral: %@", deviceId);
        return;
    }
    
    NSDictionary *deviceInfo = @{
        @"name": peripheral.name ?: @"Unknown",
        @"address": deviceId,
        @"rssi": RSSI
    };
    self.deviceMap[deviceId] = peripheral;
    NSLog(@"Discovered peripheral: %@", deviceInfo);
    [self sendEventWithName:@"EVENT_FOUND_DEVICES" body:deviceInfo];
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected to peripheral: %@", peripheral.identifier.UUIDString);
    peripheral.delegate = self;
    [peripheral discoverServices:nil];

    if (self.connectResolve) {
        self.connectResolve(@"CONNECTED");
        self.connectResolve = nil;
        self.connectReject = nil;
    }
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    NSLog(@"Failed to connect to peripheral: %@, error: %@", peripheral.identifier.UUIDString, error.localizedDescription);
    if (self.connectReject) {
        self.connectReject(@"CONNECTION_FAILED", @"Failed to connect", error);
        self.connectResolve = nil;
        self.connectReject = nil;
    }
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                     error:(NSError *)error {
    NSLog(@"Disconnected from peripheral: %@", peripheral.identifier.UUIDString);
    self.connectedPeripheral = nil;
    self.writeCharacteristic = nil;
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering services: %@", error.localizedDescription);
        return;
    }
    NSLog(@"Discovered services for peripheral: %@", peripheral.identifier.UUIDString);
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
                             error:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering characteristics: %@", error.localizedDescription);
        return;
    }
    NSLog(@"Discovered characteristics for service: %@", service.UUID.UUIDString);
    for (CBCharacteristic *characteristic in service.characteristics) {
        if (characteristic.properties & CBCharacteristicPropertyWrite ||
            characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
            self.writeCharacteristic = characteristic;
            NSLog(@"Found writable characteristic: %@", characteristic.UUID.UUIDString);
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
                             error:(NSError *)error {
    if (error) {
        NSLog(@"Error writing to characteristic: %@", error.localizedDescription);
    } else {
        NSLog(@"Successfully wrote to characteristic: %@", characteristic.UUID.UUIDString);
    }
}

// Obter dispositivos pareados (simulação, já que iOS não expõe dispositivos pareados diretamente)
- (NSDictionary *)getPairedDevices {
    NSLog(@"Returning paired devices (simulated, iOS does not expose paired devices).");
    return @{};
}

// Processar operações pendentes quando o Bluetooth estiver pronto
- (void)processPendingOperations {
    NSArray *operations = [self.pendingOperations copy];
    [self.pendingOperations removeAllObjects];
    
    NSLog(@"Processing %lu pending operations...", (unsigned long)operations.count);
    for (NSDictionary *op in operations) {
        RCTPromiseResolveBlock resolve = op[@"resolve"];
        RCTPromiseRejectBlock reject = op[@"reject"];
        NSString *operation = op[@"operation"];
        
        if ([operation isEqualToString:@"scan"]) {
            [self scanDevices:resolve rejecter:reject];
        } else {
            resolve(@YES);
        }
    }
}

// Rejeitar operações pendentes com erro
- (void)rejectPendingOperationsWithCode:(NSString *)code message:(NSString *)message {
    NSArray *operations = [self.pendingOperations copy];
    [self.pendingOperations removeAllObjects];
    
    NSLog(@"Rejecting %lu pending operations with code: %@, message: %@", (unsigned long)operations.count, code, message);
    for (NSDictionary *op in operations) {
        RCTPromiseRejectBlock reject = op[@"reject"];
        reject(code, message, nil);
    }
}

- (void)dealloc {
    NSLog(@"Deallocating BlePrinter, stopping scan...");
    [self.centralManager stopScan];
}

@end
