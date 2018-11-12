/*
 
 Edited by Nuttawut Malee on 10.11.18
 Copyright (c) 2013 RedBearLab
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

#import "CBPeripheral+BTSExtensions.h"

typedef void (^CentralManagerDiscoverPeripheralsCallback) (NSMutableArray *peripherals);

/*!
 * BLE delegate event to send data
 * to delegate class.
 */
@protocol BLEDelegate
@required
/*!
 *  @method didPowerOn
 *
 *  @discussion Delegate bluetooth enabled.
 *
 */
- (void)didPowerOn;

/*!
 *  @method didPowerOff
 *
 *  @discussion Delegate bluetooth disabled.
 *
 */
- (void)didPowerOff;

/*!
 *  @method didError
 *
 *  @param error The error that will be delegated to delegate class.
 *
 */
- (void)didError:(NSError *)error;

/*!
 *  @method didConnect
 *
 *  @param peripheral   The connected peripheral.
 *
 */
- (void)didConnect:(CBPeripheral *) peripheral;

/*!
 *  @method didFailToConnect
 *
 *  @param peripheral   The connected peripheral.
 *
 */
- (void)didFailToConnect:(CBPeripheral *) peripheral;

/*!
 *  @method didConnectionLost
 *
 *  @param peripheral   The connected peripheral.
 *
 */
- (void)didConnectionLost:(CBPeripheral *) peripheral;

/*!
 *  @method didReceiveData:length:
 *
 *  @param data     The received data from peripheral buffer.
 *  @param length   The length of received data.
 *
 */
- (void)didReceiveData:(unsigned char *) data length:(NSInteger) length;

@optional

/*!
 *  @method didUpdateRSSI
 *
 *  @param rssi The updated RSSI number.
 *
 */
- (void)didUpdateRSSI:(NSNumber *)rssi;

@end

/*!
 * BLE wrapper class that implement
 * common central manager and peripheral instance.
 */
@interface BLE : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

/*!
 * The delegate object that will receive BLE central events.
 */
@property (nonatomic, assign) id<BLEDelegate> delegate;

/*!
 * Core bluetooth's Central manager, for implementing central role.
 */
@property (strong, nonatomic) CBCentralManager *manager;

/*!
 * Peripherals that are nearby (sorted descending by RSSI values)
 */
@property (weak, nonatomic, readonly) NSArray *peripherals;

/*!
 * List of scanned peripherals
 */
@property (strong, nonatomic) NSMutableArray *scannedPeripherals;

/*!
 * The active peripheral that has been paired and connected.
 */
@property (strong, nonatomic) CBPeripheral *activePeripheral;

/*!
 * CBCentralManager's state updated by centralManagerDidUpdateState:
 */
@property(nonatomic) CBCentralManagerState cbCentralManagerState;

/*!
 * Threshould to stop scanning for peripherals.
 * When the number of discovered peripherals exceeds this value, scanning will be
 * stopped even before the scan-interval.
 */
@property (assign, nonatomic) NSUInteger peripheralsCountToStop;

/*!
 * Indicates if active peripheral is connected.
 */
@property (assign, nonatomic, getter = isConnected) BOOL connected;

/**
 * Indicates if CBCentralManager is scanning for peripherals
 */
@property (nonatomic, getter = isScanning) BOOL scanning;

/*!
 * Indicates if central manager is ready for core bluetooth tasks. KVO observable.
 */
@property (assign, nonatomic, readonly, getter = isCentralReady) BOOL centralReady;

/*!
 * Completion block for peripheral scanning.
 */
@property (copy, nonatomic) CentralManagerDiscoverPeripheralsCallback scanBlock;

/*!
 * KVO for centralReady and centralNotReadyReason
 */
+ (NSSet *)keyPathsForValuesAffectingCentralReady;

+ (NSSet *)keyPathsForValuesAffectingCentralNotReadyReason;

/*!
 *  @method peripheralToDictionary
 *
 *  @param peripheral CBPeripheral
 *
 *  @discussion Get NSMutableDictionary info of a peripheral.
 *
 */
- (NSMutableDictionary *)peripheralToDictionary:(CBPeripheral *)peripheral;

/*!
 *  @method readActivePeripheralRSSI
 *
 *  @discussion Retrieves and delegate current RSSI of current
 *              active peripheral that connected to central manager.
 *
 */
- (void)readActivePeripheralRSSI;

/*!
 *  @method enableReadNotification
 *
 *  @param peripheral
 *
 *  @discussion Notify peripheral read for a certain characteristic.
 */
- (void)enableReadNotification:(CBPeripheral *)peripheral;

/*!
 *  @method read
 *
 *  @discussion Read value from active peripheral
 *              for a certain characteristic.
 */
- (void)read;

/*!
 *  @method write
 *
 *  @param data Data to be written to an active peripheral.
 *
 *  @discussion Write value to active peripheral
 *              for a certain characteristic.
 *
 */
- (void)write:(NSData *)data;

/*!
 *  @method scanForPeripheralsByInterval
 *
 *  @param interval Interval by which scan will be stopped.
 *  @param callback Completion block will be called after
 *                  <i>interval</i> with nearby peripherals.
 *
 *  @discussion Scans for nearby peripherals
 *              and fills the - NSArray *peripherals.
 *              Scan will be stoped after input interaval.
 *
 */
- (void)scanForPeripheralsByInterval:(NSUInteger)interval
                          completion:(CentralManagerDiscoverPeripheralsCallback)callback;

/*!
 *  @method stopScanForPeripheral
 *
 *  @discussion Stops ongoing scan proccess
 *
 */
- (void)stopScanForPeripherals;

/*!
 *  @method connectToPeripheral
 *
 *  @param peripheral
 *
 *  @discussion Connect to certain peripheral
 *              and assign activePeripheral to it.
 *
 */
- (void)connectToPeripheral:(CBPeripheral *)peripheral;

/*!
 *  @method disconnectToPeripheral
 *
 *  @param peripheral
 *
 *  @discussion Cancel connect of a certain peripheral.
 *
 */

- (void)disconnectToPeripheral:(CBPeripheral *)peripheral;

/*!
 *  @method centralManagerSetup
 *
 *  @discussion Request bluetooth enable settings.
 *
 */
- (void)centralManagerSetup;

@end
