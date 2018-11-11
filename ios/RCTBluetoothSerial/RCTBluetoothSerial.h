//
//  RCTBluetoothSerial.h
//  RCTBluetoothSerial
//
//  Created by Nuttawut Malee on 10.11.18.
//  Copyright © 2016 Nuttawut Malee. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import "BLE.h"

/**
 * RCTBluetoothSerial is an abstract base class to be used for module that connect,
 * read and write data from active peripheral.
 */
@interface RCTBluetoothSerial : RCTEventEmitter <RCTBridgeModule, BLEDelegate> {
    BLE *_ble;
    BOOL _hasListeners;
    RCTPromiseResolveBlock _connectionResolver;
    RCTPromiseRejectBlock _connectionRejector;
    NSString *_subscribeCallbackId;
    NSString *_subscribeBytesCallbackId;
    NSString *_rssiCallbackId;
    NSMutableString *_buffer;
    NSString *_delimiter;
}

/**
 * Read buffer from beginning character to the first delimiter found
 * and return the message
 */
- (NSString *)readUntilDelimiter:(NSString *)delimiter;
- (NSMutableArray *)getPeripheralList;
- (void)sendDataToSubscriber;
- (CBPeripheral *)findPeripheralByUUID:(NSString *)uuid;

#pragma mark - Connection methods

- (void)connectToFirstDevice;
- (void)connectToUUID:(NSString *)uuid;

#pragma mark - Timer methods

- (void)listPeripheralsTimer:(NSTimer *)timer;
- (void)connectFirstDeviceTimer:(NSTimer *)timer;
- (void)connectUuidTimer:(NSTimer *)timer;

/**
 * Check if bluetooth is powered on or off
 */
- (void)bluetoothPowerStateTimer:(NSTimer *)timer;

@end
