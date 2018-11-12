
/*

 Edited by Nuttawut Malee on 10.11.18
 Copyright (c) 2013 RedBearLab

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

#import "BLE.h"
#import "BLEDefines.h"

@implementation BLE

static int rssi = 0;
static const int MAX_BUFFER_LENGTH = 100;

// TODO should have a configurable list of services

/**
 * Available services
 */
CBUUID *redBearLabsServiceUUID;
CBUUID *adafruitServiceUUID;
CBUUID *lairdServiceUUID;
CBUUID *blueGigaServiceUUID;
CBUUID *rongtaSerivceUUID;
CBUUID *posnetSerivceUUID;

/**
 * Available read/write characteristic
 */
CBUUID *serialServiceUUID;
CBUUID *readCharacteristicUUID;
CBUUID *writeCharacteristicUUID;

/*----------------------------------------------------*/
#pragma mark - Lifecycle -
/*----------------------------------------------------*/

- (instancetype)init
{
    self = [super init];
    if (self) {
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _scannedPeripherals = [NSMutableArray new];
        _peripheralsCountToStop = NSUIntegerMax;
    }
    return self;
}

/*----------------------------------------------------*/
#pragma mark - Getter/Setter -
/*----------------------------------------------------*/

- (BOOL)isConnected
{
    return self.connected;
}

- (BOOL)isCentralReady
{
    return (self.manager.state == CBCentralManagerStatePoweredOn);;
}

- (NSArray *)peripherals
{
    // Sorting peripherals by RSSI values
    NSArray *sortedArray = [_scannedPeripherals sortedArrayUsingComparator:^NSComparisonResult(CBPeripheral *a, CBPeripheral *b) {
        return a.RSSI < b.RSSI;
    }];
    return sortedArray;
}

/*----------------------------------------------------*/
#pragma mark - KVO -
/*----------------------------------------------------*/


+ (NSSet *)keyPathsForValuesAffectingCentralReady
{
    return [NSSet setWithObject:@"cbCentralManagerState"];
}

+ (NSSet *)keyPathsForValuesAffectingCentralNotReadyReason
{
    return [NSSet setWithObject:@"cbCentralManagerState"];
}

/*----------------------------------------------------*/
#pragma mark - Public Methods -
/*----------------------------------------------------*/

- (NSDictionary *)peripheralToDictionary:(CBPeripheral *)peripheral
{
    return @{@"name":peripheral.name, @"id":peripheral.identifier.UUIDString, @"btsAdvertisementRSSI":peripheral.btsAdvertisementRSSI, @"btsAdvertising":peripheral.btsAdvertising};
}

- (void)readActivePeripheralRSSI
{
    [self.activePeripheral readRSSI];
}

- (void)enableReadNotification:(CBPeripheral *)peripheral
{
    CBService *service = [self findServiceFromUUID:serialServiceUUID peripheral:peripheral];
    
    if (!service) {
        NSString *message = [NSString stringWithFormat:@"Could not find service with UUID %@ on peripheral with UUID %@",
                             [self CBUUIDToString:serialServiceUUID],
                             peripheral.identifier.UUIDString];
        NSError *error = [NSError errorWithDomain:@"no_service" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
        NSLog(@"%@", message);
        [[self delegate] didError:error];
        
        return;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:readCharacteristicUUID service:service];
    
    if (!characteristic) {
        NSString *message = [NSString stringWithFormat:
                             @"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
                             [self CBUUIDToString:readCharacteristicUUID],
                             [self CBUUIDToString:serialServiceUUID],
                             peripheral.identifier.UUIDString];
        NSError *error = [NSError errorWithDomain:@"no_characteristic" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
        NSLog(@"%@", message);
        [[self delegate] didError:error];

        return;
    }
    
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
}

- (void)read
{
    CBService *service = [self findServiceFromUUID:serialServiceUUID peripheral:self.activePeripheral];

    if (!service) {
        NSString *message = [NSString stringWithFormat:
                             @"Could not find service with UUID %@ on peripheral with UUID %@",
                             [self CBUUIDToString:serialServiceUUID],
                             self.activePeripheral.identifier.UUIDString];
        NSError *error = [NSError errorWithDomain:@"no_service" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
        
        NSLog(@"%@", message);
        [[self delegate] didError:error];
        
        return;
    }

    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:readCharacteristicUUID service:service];

    if (!characteristic) {
        NSString *message = [NSString stringWithFormat:
                             @"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
                             [self CBUUIDToString:readCharacteristicUUID],
                             [self CBUUIDToString:serialServiceUUID],
                             self.activePeripheral.identifier.UUIDString];
        NSError *error = [NSError errorWithDomain:@"no_characteristic" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
        NSLog(@"%@", message);
        [[self delegate] didError:error];

        return;
    }
    
    [self.activePeripheral readValueForCharacteristic:characteristic];
}

- (void)write:(NSData *)data
{
    NSLog(@"Write in ble.m\n");
    
    NSInteger dataLength = data.length;
    NSData *buffer;

    for(int i = 0; i < dataLength; i += MAX_BUFFER_LENGTH) {
        NSInteger remainLength = dataLength - i;
        NSInteger bufferLength = (remainLength > MAX_BUFFER_LENGTH) ? MAX_BUFFER_LENGTH : remainLength;
        buffer = [data subdataWithRange:NSMakeRange(i, bufferLength)];
        
        NSLog(@"Buffer data %li %i %@", (long)remainLength, i, [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding]);
        
        [self writeValue:serialServiceUUID characteristicUUID:writeCharacteristicUUID peripheral:self.activePeripheral data:buffer];
    }
}

- (void)scanForPeripheralsByInterval:(NSUInteger)interval completion:(CentralManagerDiscoverPeripheralsCallback)callback
{
    if (!self.isCentralReady) {
        NSString *message = [NSString stringWithFormat:
                             @"CoreBluetooth not correctly initialized! State = %ld (%@)",
                             (long)self.manager.state,
                             [self centralManagerStateToString:self.manager.state]];
        NSError *error = [NSError errorWithDomain:@"no_bluetooth_initialized" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
        NSLog(@"%@", message);
        [[self delegate] didError:error];
        
        return;
    }
    
    self.scanBlock = callback;
    
    [self scanForPeripheralsByServices];

    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(stopScanForPeripherals)
                                               object:nil];

    [self performSelector:@selector(stopScanForPeripherals)
               withObject:nil
               afterDelay:interval];
}

- (void)stopScanForPeripherals
{
    [self.manager stopScan];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(stopScanForPeripherals)
                                               object:nil];
    
    NSLog(@"Stopped Scanning");
    NSLog(@"Known peripherals : %lu", (unsigned long)[self.peripherals count]);
    [self printKnownPeripherals];

    if (self.scanBlock) {
        // Return peripherals to completion block
        self.scanBlock(self.scannedPeripherals);
    }
    
    self.scanBlock = nil;
}

- (void)connectToPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connecting to peripheral with UUID : %@", peripheral.identifier.UUIDString);

    self.activePeripheral = peripheral;
    self.activePeripheral.delegate = self;

    [self.manager connectPeripheral:self.activePeripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

- (void)disconnectToPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Disconnecting peripheral with UUID : %@", peripheral.identifier.UUIDString);
    
    [self.manager cancelPeripheralConnection:peripheral];
}

/*----------------------------------------------------*/
#pragma mark - Private Methods -
/*----------------------------------------------------*/

-(void)scanForPeripheralsByServices
{
    // Clear all peripherals
    [self.scannedPeripherals removeAllObjects];

    // TODO - Allow customized service UUIDs / Read - Write Characteristics UUIDs
#if TARGET_OS_IPHONE
    redBearLabsServiceUUID = [CBUUID UUIDWithString:@RBL_SERVICE_UUID];
    adafruitServiceUUID = [CBUUID UUIDWithString:@ADAFRUIT_SERVICE_UUID];
    lairdServiceUUID = [CBUUID UUIDWithString:@LAIRD_SERVICE_UUID];
    blueGigaServiceUUID = [CBUUID UUIDWithString:@BLUEGIGA_SERVICE_UUID];
    rongtaSerivceUUID = [CBUUID UUIDWithString:@RONGTA_SERVICE_UUID];
    posnetSerivceUUID = [CBUUID UUIDWithString:@POSNET_SERVICE_UUID];
    
    NSArray *services = @[redBearLabsServiceUUID, adafruitServiceUUID, lairdServiceUUID, blueGigaServiceUUID, rongtaSerivceUUID, posnetSerivceUUID];
    
    [self.manager scanForPeripheralsWithServices:services options:nil];
#else
    [self.manager scanForPeripheralsWithServices:nil options:nil];
#endif
    
    NSLog(@"Scan for peripherals with services");
}

- (NSString *)centralManagerStateToString:(int)state
{
    switch(state) {
        case CBCentralManagerStateUnknown:
            return @"State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return @"State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return @"State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return @"State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            return @"State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            return @"State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return @"State unknown";
    }
    
    return @"Unknown state";
}

- (void)writeValue:(CBUUID *)serviceUUID
characteristicUUID:(CBUUID *)characteristicUUID
        peripheral:(CBPeripheral *)peripheral
              data:(NSData *)data
{
    CBService *service = [self findServiceFromUUID:serviceUUID peripheral:peripheral];
    
    if (!service) {
        NSString *message = [NSString stringWithFormat:@"Could not find service with UUID %@ on peripheral with UUID %@",
                             [self CBUUIDToString:serviceUUID],
                             peripheral.identifier.UUIDString];
        
        NSError *error = [NSError errorWithDomain:@"no_service" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
        
        NSLog(@"%@", message);
        [[self delegate] didError:error];
        
        return;
    }
    
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
    
    if (!characteristic) {
        NSString *message = [NSString stringWithFormat:
                             @"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
                             [self CBUUIDToString:characteristicUUID],
                             [self CBUUIDToString:serviceUUID],
                             peripheral.identifier.UUIDString];
        
        NSError *error = [NSError errorWithDomain:@"no_characteristic" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
        
        NSLog(@"%@", message);
        [[self delegate] didError:error];
        
        return;
    }
    
    NSLog(@"Write value in ble.m\n");
    NSLog(@"Buffer data %li", data.length);
    
    if ((characteristic.properties & CBCharacteristicPropertyWrite) == CBCharacteristicPropertyWrite) {
        [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    } else if ((characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) == CBCharacteristicPropertyWriteWithoutResponse) {
        [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

- (CBCharacteristic *)findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
    for (int i = 0; i < service.characteristics.count; i++) {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        
        if ([self compareCBUUID:c.UUID UUID2:UUID]) {
            return c;
        }
    }
    
    return nil;
}

- (CBService *)findServiceFromUUID:(CBUUID *)UUID peripheral:(CBPeripheral *)peripheral
{
    for (int i = 0; i < peripheral.services.count; i++) {
        CBService *s = [peripheral.services objectAtIndex:i];
        
        if ([self compareCBUUID:s.UUID UUID2:UUID]) {
            return s;
        }
    }
    
    return nil;
}

- (UInt16)swap:(UInt16)s
{
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

- (NSString *)CBUUIDToString:(CBUUID *)UUID
{
    NSData *data = UUID.data;
    
    if ([data length] == 2) {
        const unsigned char *tokenBytes = [data bytes];
        return [NSString stringWithFormat:@"%02x%02x", tokenBytes[0], tokenBytes[1]];
    } else if ([data length] == 16) {
        NSUUID* nsuuid = [[NSUUID alloc] initWithUUIDBytes:[data bytes]];
        return [nsuuid UUIDString];
    }
    
    return [UUID description];
}

- (UInt16)CBUUIDToInt:(CBUUID *)UUID
{
    char b[16];
    [UUID.data getBytes:b length:UUID.data.length];
    return ((b[0] << 8) | b[1]);
}

- (int)compareCBUUID:(CBUUID *)UUID1 UUID2:(CBUUID *)UUID2
{
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1 length:UUID1.data.length];
    [UUID2.data getBytes:b2 length:UUID2.data.length];
    
    if (memcmp(b1, b2, UUID1.data.length) == 0) {
        return 1;
    } else {
        return 0;
    }
}

- (int)compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2
{
    char b1[16];
    [UUID1.data getBytes:b1 length:UUID1.data.length];
    
    UInt16 b2 = [self swap:UUID2];
    
    if (memcmp(b1, (char *)&b2, 2) == 0) {
        return 1;
    } else {
        return 0;
    }
}

- (BOOL)UUIDSAreEqual:(NSUUID *)UUID1 UUID2:(NSUUID *)UUID2
{
    if ([UUID1.UUIDString isEqualToString:UUID2.UUIDString]) {
        return TRUE;
    } else {
        return FALSE;
    }
}

-(CBUUID *)IntToCBUUID:(UInt16)UUID
{
    char t[16];
    t[0] = ((UUID >> 8) & 0xff); t[1] = (UUID & 0xff);
    NSData *data = [[NSData alloc] initWithBytes:t length:16];
    return [CBUUID UUIDWithData:data];
}

#if TARGET_OS_IPHONE
//-- no need for iOS
#else
- (BOOL)isLECapableHardware
{
    NSString *state = @"";
    
    switch ([self.manager state]) {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
    }
    
    NSLog(@"Central manager state: %@", state);
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:state];
    [alert addButtonWithTitle:@"OK"];
    [alert setIcon:[[NSImage alloc] initWithContentsOfFile:@"AppIcon"]];
    [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:nil contextInfo:nil];
    
    return FALSE;
}
#endif

- (void)printKnownPeripherals
{
    NSLog(@"List of currently known peripherals :");
    
    for (int i = 0; i < self.peripherals.count; i++) {
        CBPeripheral *peripheral = [self.peripherals objectAtIndex:i];
        
        if (peripheral.identifier != NULL) {
            NSLog(@"%d  |  %@", i, peripheral.identifier.UUIDString);
        } else {
            NSLog(@"%d  |  NULL", i);
        }
        
        [self printPeripheralInfo:peripheral];
    }
}

- (void)printPeripheralInfo:(CBPeripheral*)peripheral
{
    NSLog(@"------------------------------------");
    NSLog(@"Peripheral Info :");
    
    if (peripheral.identifier != NULL) {
        NSLog(@"UUID : %@", peripheral.identifier.UUIDString);
    } else {
        NSLog(@"UUID : NULL");
    }

    NSLog(@"Name : %@", peripheral.name);
    NSLog(@"-------------------------------------");
}

/*----------------------------------------------------*/
#pragma mark - Central Manager Delegate -
/*----------------------------------------------------*/

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    self.cbCentralManagerState = (CBCentralManagerState)central.state;
    
#if TARGET_OS_IPHONE
    NSString *state = [self centralManagerStateToString:central.state];
    NSLog(@"Status of CoreBluetooth central manager changed %ld (%@)", (long)central.state, state);
    
    if (self.isCentralReady) {
        [[self delegate] didPowerOn];
    } else {
        [[self delegate] didPowerOff];
        
        if (self.isConnected) {
            [[self delegate] didConnectionLost:self.activePeripheral];
            self.connected = FALSE;
        }
    }
#else
    [self isLECapableHardware];
#endif
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if (peripheral.identifier != NULL) {
        NSLog(@"Connected to %@ successful", peripheral.identifier.UUIDString);
    } else {
        NSLog(@"Connected to NULL successful");
    }
    
    self.activePeripheral = peripheral;
    [self.activePeripheral discoverServices:nil];
    
    [[self delegate] didPairSuccessful:peripheral];
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    if (peripheral.identifier != NULL) {
        NSLog(@"Failed to connect to %@", peripheral.identifier.UUIDString);
    } else {
        NSLog(@"Failed to connect to NULL");
    }
    
    if (error) {
        NSString *message = [error localizedDescription];
        NSLog(@"%@", message);
        [[self delegate] didError:error];
    }

    [[self delegate] didPairUnsuccessful:peripheral];
    [[self delegate] didFailToConnect:peripheral];
}

-(void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                error:(NSError *)error
{
    if ([self UUIDSAreEqual:self.activePeripheral.identifier UUID2:peripheral.identifier]) {
        self.activePeripheral = nil;
        self.activePeripheral.delegate = nil;
    }
    
    if (peripheral.identifier != NULL) {
        NSLog(@"Disconnected to %@ successful", peripheral.identifier.UUIDString);
    } else {
        NSLog(@"Disconnected to NULL successful");
    }
    
    if (error) {
        NSString *message = [error localizedDescription];
        NSLog(@"%@", message);
        [[self delegate] didError:error];
        [[self delegate] didUnpairUnsuccessful:peripheral];
    } else {
        [[self delegate] didUnpairSuccessful:peripheral];
    }
    
    self.connected = FALSE;
}

-(void)centralManager:(CBCentralManager *)central
didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary *)advertisementData
                 RSSI:(NSNumber *)RSSI
{
    if (!self.scannedPeripherals) {
        // Initiate peripherals with a new peripheral
        self.scannedPeripherals = [[NSMutableArray alloc] initWithObjects:peripheral, nil];
    } else {
        // Replace a duplicate peripheral
        for (int i = 0; i < self.scannedPeripherals.count; i++) {
            CBPeripheral *p = [self.scannedPeripherals objectAtIndex:i];
            [p bts_setAdvertisementData:advertisementData RSSI:RSSI];
            
            if ((p.identifier == NULL) || (peripheral.identifier) == NULL) {
                continue;
            }
            
            if ([self UUIDSAreEqual:p.identifier UUID2:peripheral.identifier]) {
                [self.scannedPeripherals replaceObjectAtIndex:i withObject:peripheral];
                NSLog(@"Updating duplicate UUID (%@) peripheral", peripheral.identifier.UUIDString);
                return;
            }
        }
        
        // Add a new peripheral
        [self.scannedPeripherals addObject:peripheral];
        NSLog(@"Adding new UUID (%@) peripheral", peripheral.identifier.UUIDString);
    }
    
    NSLog(@"didDiscoverPeripheral");
    
    if ([self.scannedPeripherals count] >= self.peripheralsCountToStop) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(stopScanForPeripherals)
                                                   object:nil];
        [self stopScanForPeripherals];
    }
}

/*----------------------------------------------------*/
#pragma mark - Peripheral Delegate -
/*----------------------------------------------------*/

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (error) {
        NSString *message = @"Characteristic discovery unsuccessful!";
        NSLog(@"%@", message);
        NSError *error = [NSError errorWithDomain:@"no_characteristic_discovery" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
        [[self delegate] didError:error];
    } else {
        NSLog(@"Characteristics of service with UUID : %@ found\n", [self CBUUIDToString:service.UUID]);
        
        int i = 0;
        for (; i < service.characteristics.count; i++) {
            CBCharacteristic *characteristic = [service.characteristics objectAtIndex:i];
            NSLog(@"Found characteristic %@\n", [self CBUUIDToString:characteristic.UUID]);
            
            CBService *s = [peripheral.services objectAtIndex:(peripheral.services.count - 1)];

            if ([service.UUID isEqual:s.UUID] & self.isCentralReady & !self.connected) {
                [self enableReadNotification:self.activePeripheral];
                [[self delegate] didConnect:peripheral];
                self.connected = TRUE;
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) {
        NSString *message = @"Update value for characteristic unsuccessful!";
        NSLog(@"%@", message);
        NSError *error = [NSError errorWithDomain:@"no_characteristic_update" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
        [[self delegate] didError:error];
    } else {
        static unsigned char buffer[512];
        NSInteger dataLength;
        
        if ([characteristic.UUID isEqual:readCharacteristicUUID]) {
            dataLength = characteristic.value.length;
            [characteristic.value getBytes:buffer length:dataLength];
            [[self delegate] didReceiveData:buffer length:dataLength];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSString *message = @"Service discovery unsuccessful!";
        NSLog(@"%@", message);
        NSError *error = [NSError errorWithDomain:@"no_service_discovery" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
        [[self delegate] didError:error];
    } else {
        // TODO - Allow customized read/write characteristic
        // Determine if we're connected to Red Bear Labs, Adafruit or Laird hardware
        for (CBService *service in peripheral.services) {
            if ([service.UUID isEqual:redBearLabsServiceUUID]) {
                NSLog(@"RedBearLabs Bluetooth");
                serialServiceUUID = redBearLabsServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@RBL_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@RBL_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:adafruitServiceUUID]) {
                NSLog(@"Adafruit Bluefruit LE");
                serialServiceUUID = adafruitServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@ADAFRUIT_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@ADAFRUIT_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:lairdServiceUUID]) {
                NSLog(@"Laird BL600");
                serialServiceUUID = lairdServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@LAIRD_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@LAIRD_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:blueGigaServiceUUID]) {
                NSLog(@"BlueGiga Bluetooth");
                serialServiceUUID = blueGigaServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@BLUEGIGA_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@BLUEGIGA_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:rongtaSerivceUUID]) {
                NSLog(@"Rongta");
                serialServiceUUID = rongtaSerivceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@RONGTA_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@RONGTA_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:posnetSerivceUUID]) {
                NSLog(@"Posnet");
                serialServiceUUID = posnetSerivceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@POSNET_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@POSNET_CHAR_RX_UUID];
                break;
            } else {
                // Ignore unknown services
            }
        }
        
        // TODO - Future versions should just get characteristics we care about
        // [peripheral discoverCharacteristics:characteristics forService:service];
        for (int i = 0; i< peripheral.services.count; i++) {
            CBService *s = [peripheral.services objectAtIndex:i];
            [peripheral discoverCharacteristics:nil forService:s];
        }
    }
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (!self.isConnected) {
        return;
    }
    
    if (rssi != peripheral.RSSI.intValue) {
        rssi = peripheral.RSSI.intValue;
        [[self delegate] didUpdateRSSI:self.activePeripheral.RSSI];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
       didReadRSSI:(NSNumber *)RSSI
             error:(NSError *)error
{
    if (!self.isConnected) {
        return;
    }

    if (rssi != peripheral.RSSI.intValue) {
        rssi = peripheral.RSSI.intValue;
        [[self delegate] didUpdateRSSI:self.activePeripheral.RSSI];
    }
    
}

@end
