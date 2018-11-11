//
//  RCTBluetoothSerial.m
//  RCTBluetoothSerial
//
//  Created by Nuttawut Malee on 10.11.18.
//  Copyright © 2018 Nuttawut Malee. All rights reserved.
//

#import "RCTBluetoothSerial.h"

@implementation RCTBluetoothSerial

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _ble = [[BLE alloc] init];
        _buffer = [[NSMutableString alloc] init];
        _hasListeners = false;
        
        [_ble setDelegate:self];
    }
    return self;
}

- (dispatch_queue_t)methodQueue
{
    // run all module methods in main thread
    // if we don't no timer callbacks got called
    return dispatch_get_main_queue();
}

#pragma mark - Methods available in Javascript

#pragma mark - Bluetooth related methods

RCT_EXPORT_METHOD(requestEnable:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    // Request user to enable bluetooth
}

RCT_EXPORT_METHOD(enable:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    // Enable bluetooth service
}

RCT_EXPORT_METHOD(disable:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    // Disable bluetooth service
}

RCT_EXPORT_METHOD(isEnabled:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    // Short delay so CBCentralManger can spin up bluetooth
    [NSTimer scheduledTimerWithTimeInterval:(float)0.2
                                     target:self
                                   selector:@selector(bluetoothPowerStateTimer:)
                                   userInfo:resolve
                                    repeats:NO];
}

#pragma mark - Connection related methods

RCT_EXPORT_METHOD(connect:(NSString *)uuid
                  bleUuid:(NSString *)bleUuid
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"connect");

    // if the uuid is null or blank, scan and
    // connect to the first available device

    if (uuid == (NSString *)[NSNull null]) {
        [self connectToFirstDevice];
    } else if ([uuid isEqualToString:@""]) {
        [self connectToFirstDevice];
    } else {
        [self connectToUUID:uuid];
    }

    _connectionResolver = resolve;
    _connectionRejector = reject;
}

RCT_EXPORT_METHOD(disconnect:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{

    NSLog(@"disconnect");

    _connectionResolver = nil;
    _connectionRejector = nil;
    
    if (_ble.activePeripheral) {
        if (_ble.activePeripheral.state == CBPeripheralStateConnected) {
            [[_ble CM] cancelPeripheralConnection:[_ble activePeripheral]];
        }
    }
    
    resolve((id)kCFBooleanTrue);
}

RCT_EXPORT_METHOD(isConnected:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    if ([_ble isConnected]) {
        resolve((id)kCFBooleanTrue);
    } else {
        resolve((id)kCFBooleanFalse);
    }
}

#pragma mark - Other methods

RCT_EXPORT_METHOD(withDelimiter:(NSString *)delimiter
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Set delimiter to %@", delimiter);
    
    if (delimiter != nil) {
        _delimiter = [delimiter copy];
    }
    
    resolve((id)kCFBooleanTrue);
}

RCT_EXPORT_METHOD(clear:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    long end = [_buffer length] - 1;
    NSRange truncate = NSMakeRange(0, end);
    [_buffer deleteCharactersInRange:truncate];
    resolve((id)kCFBooleanTrue);
}

RCT_EXPORT_METHOD(available:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSNumber *buffLen = [NSNumber numberWithInteger:[_buffer length]];
    resolve(buffLen);
}

RCT_EXPORT_METHOD(setAdapterName:(NSString *)name
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSError *err = [NSError errorWithDomain:@"" code:500 userInfo:nil];
    reject(@"E_SETTER", @"Cannot set adapter name in iOS", err);
}

RCT_EXPORT_METHOD(writeToDevice:(NSString *)message
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"write");
    if (message != nil) {
        NSData *data = [[NSData alloc] initWithBase64EncodedString:message options:NSDataBase64DecodingIgnoreUnknownCharacters];
        [_bleShield write:data];
        resolve((id)kCFBooleanTrue);
    } else {
        NSError *err = nil;
        reject(@"no_data", @"Data was null", err);
    }
}

RCT_EXPORT_METHOD(list:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    [self scanForBLEPeripherals:3];
    [NSTimer scheduledTimerWithTimeInterval:(float)3.0
                                     target:self
                                   selector:@selector(listPeripheralsTimer:)
                                   userInfo:resolve
                                    repeats:NO];
}

RCT_EXPORT_METHOD(read:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *message = @"";

    if ([_buffer length] > 0) {
        long end = [_buffer length] - 1;
        message = [_buffer substringToIndex:end];
        NSRange entireString = NSMakeRange(0, end);
        [_buffer deleteCharactersInRange:entireString];
    }

    resolve(message);
}

RCT_EXPORT_METHOD(readUntil:(NSString *)delimiter
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *message = [self readUntilDelimiter:delimiter];
    resolve(message);
}

#pragma mark - BLEDelegate

- (void)bleDidFindPeripherals:(NSMutableArray *)peripherals
{
    
}

- (void)bleDidReceiveData:(unsigned char *)data length:(int)length
{
    NSLog(@"bleDidReceiveData");

    // Append to the buffer
    NSData *d = [NSData dataWithBytes:data length:length];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    NSLog(@"Received %@", s);

    if (s) {
        [_buffer appendString:s];

        if (_subscribed) {
            [self sendDataToSubscriber]; // only sends if a delimiter is hit
        }

    } else {
        NSLog(@"Error converting received data into a String.");
    }

    // Always send raw data if someone is listening
    //if (_subscribeBytesCallbackId) {
    //    NSData* nsData = [NSData dataWithBytes:(const void *)data length:length];
    //}

}

- (void)bleDidChangedState:(bool)isEnabled
{
    NSLog(@"bleDidChangedState");
    NSString *eventName;
    if (isEnabled) {
        eventName = @"bluetoothEnabled";
    } else {
        eventName = @"bluetoothDisabled";
    }
    [self.bridge.eventDispatcher sendDeviceEventWithName:eventName body:nil];
}

- (void)bleDidConnect
{
    NSLog(@"bleDidConnect");
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"connectionSuccess" body:nil];
    //[self sendEventWithName:@"connectionSuccess" body:nil];

    if (_connectionResolver) {
        _connectionResolver((id)kCFBooleanTrue);
    }
}

- (void)bleDidDisconnect
{
    // TODO is there anyway to figure out why we disconnected?
    NSLog(@"bleDidDisconnect");
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"connectionLost" body:nil];
    //[self sendEventWithName:@"connectionLost" body:nil];

    _connectionResolver = nil;
}

#pragma mark - RCTEventEmitter

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"bluetoothEnabled",
             @"bluetoothDisabled",
             @"pairingSuccess",
             @"pairingFailed",
             @"unpairingSuccess",
             @"unpairingFailed",
             @"connectionSuccess",
             @"connectionFailed",
             @"connectionLost",
             @"read",
             @"data",
             @"error"];
}

- (void)startObserving
{
    _hasListeners = TRUE;
}

- (void)stopObserving
{
    _hasListeners = FALSE;
}

#pragma mark - Timers

-(void)listPeripheralsTimer:(NSTimer *)timer
{
    RCTPromiseResolveBlock resolve = [timer userInfo];
    NSMutableArray *peripherals = [self getPeripheralList];
    resolve(peripherals);
}

-(void)connectFirstDeviceTimer:(NSTimer *)timer
{
    if(_ble.peripherals.count > 0) {
        NSLog(@"Connecting");
        [_ble connectPeripheral:[_ble.peripherals objectAtIndex:0]];
    } else {
        NSString *message = @"Did not find any BLE peripherals";
        NSError *err = nil;
        NSLog(@"%@", message);
        _connectionRejector(@"no_peripherals", message, err);

    }
}

-(void)connectUuidTimer:(NSTimer *)timer
{
    NSString *uuid = [timer userInfo];
    CBPeripheral *peripheral = [self findPeripheralByUUID:uuid];

    if (peripheral) {
        [_ble connectPeripheral:peripheral];
    } else {
        NSString *message = [NSString stringWithFormat:@"Could not find peripheral %@.", uuid];
        NSError *err = nil;
        NSLog(@"%@", message);
        _connectionRejector(@"wrong_uuid", message, err);

    }
}

- (void)bluetoothPowerStateTimer:(NSTimer *)timer
{
    RCTPromiseResolveBlock resolve = [timer userInfo];
    
    if ([[_ble CM] state] == CBCentralManagerStatePoweredOn) {
        resolve((id)kCFBooleanTrue);
    } else {
        resolve((id)kCFBooleanFalse);
    }
}

#pragma mark - Internal methods implemetation

- (NSString*)readUntilDelimiter: (NSString*) delimiter
{

    NSRange range = [_buffer rangeOfString: delimiter];
    NSString *message = @"";

    if (range.location != NSNotFound) {

        long end = range.location + range.length;
        message = [_buffer substringToIndex:end];

        NSRange truncate = NSMakeRange(0, end);
        [_buffer deleteCharactersInRange:truncate];
    }
    return message;
}

- (NSMutableArray*) getPeripheralList
{

    NSMutableArray *peripherals = [NSMutableArray array];

    for (int i = 0; i < _bleShield.peripherals.count; i++) {
        NSMutableDictionary *peripheral = [NSMutableDictionary dictionary];
        CBPeripheral *p = [_bleShield.peripherals objectAtIndex:i];

        NSString *uuid = p.identifier.UUIDString;
        [peripheral setObject: uuid forKey: @"uuid"];
        [peripheral setObject: uuid forKey: @"id"];

        NSString *name = [p name];
        if (!name) {
            name = [peripheral objectForKey:@"uuid"];
        }
        [peripheral setObject: name forKey: @"name"];

        NSNumber *rssi = [p btsAdvertisementRSSI];
        if (rssi) { // BLEShield doesn't provide advertised RSSI
            [peripheral setObject: rssi forKey:@"rssi"];
        }

        [peripherals addObject:peripheral];
    }

    return peripherals;
}

// calls the JavaScript subscriber with data if we hit the _delimiter
- (void) sendDataToSubscriber {

    NSString *message = [self readUntilDelimiter:_delimiter];

    if ([message length] > 0) {
      [self.bridge.eventDispatcher sendDeviceEventWithName:@"data" body:@{@"data": message}];
    }

}

-(void)scanForBLEPeripherals:(NSString *)bleUuid
{
    NSLog(@"Scanning for BLE Peripherals: %@", bleUuid);
    
    // Disconnect from active peripherals
    if (_ble.activePeripheral) {
        if (_ble.activePeripheral.state == CBPeripheralStateConnected) {
            [[_ble centralManager] cancelPeripheralConnection:[_ble activePeripheral]];
        }
    }

    // Remove existing peripherals
    if (_ble.peripherals) {
        _ble.peripherals = nil;
    }
    
    [_ble findBLEPeripherals:bleUuid];
}

- (void)connectToFirstDevice
{
    

    [self scanForBLEPeripherals:@""];
    
    if(_ble.peripherals.count > 0) {
        NSLog(@"Connecting to first device");
        [_ble connectPeripheral:[_ble.peripherals objectAtIndex:0]];
    } else {
        NSLog(@"Did not find any BLE peripherals");
        _connectionRejector(@"no_peripherals", @"Did not find any BLE peripherals", nil);
        
    }

//    [NSTimer scheduledTimerWithTimeInterval:(float)3.0
//                                     target:self
//                                   selector:@selector(connectFirstDeviceTimer:)
//                                   userInfo:nil
//                                    repeats:NO];
}

- (void)connectToUUID:(NSString *)uuid
{
    if (_bleShield.peripherals.count < 1) {
        [self scanForBLEPeripherals];
    } else {
        CBPeripheral *peripheral = [self findPeripheralByUUID:uuid];
        
        if (peripheral) {
            [_bleShield connectPeripheral:peripheral];
        } else {
            NSString *message = [NSString stringWithFormat:@"Could not find peripheral %@.", uuid];
            NSError *err = nil;
            NSLog(@"%@", message);
            _connectionRejector(@"wrong_uuid", message, err);
        }
    }

//    [NSTimer scheduledTimerWithTimeInterval:interval
//                                     target:self
//                                   selector:@selector(connectUuidTimer:)
//                                   userInfo:uuid
//                                    repeats:NO];
}

- (CBPeripheral*)findPeripheralByUUID:(NSString*)uuid
{

    NSMutableArray *peripherals = [_bleShield peripherals];
    CBPeripheral *peripheral = nil;

    for (CBPeripheral *p in peripherals) {
        NSString *pid = p.identifier.UUIDString;

        if ([uuid isEqualToString:pid]) {
            peripheral = p;
            break;
        }
    }
    
    return peripheral;
}

@end
