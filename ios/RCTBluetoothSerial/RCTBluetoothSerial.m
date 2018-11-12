/*
 
 Created by Nuttawut Malee on 10.11.18.
 Copyright © 2016 Nuttawut Malee. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "RCTBluetoothSerial.h"
#import "PrinterSDK.h"

@implementation RCTBluetoothSerial

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

/*----------------------------------------------------*/
#pragma mark - Lifecycle -
/*----------------------------------------------------*/

- (instancetype)init
{
    self = [super init];
    if (self) {
        _buffer = [[NSMutableString alloc] init];
        _delimiter = [[NSMutableString alloc] init];
        _doesHaveListeners = FALSE;
        
        _ble = [[BLE alloc] init];
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

/*----------------------------------------------------*/
#pragma mark - Getter/Setter -
/*----------------------------------------------------*/

- (BOOL)hasListeners
{
    return self.doesHaveListeners;
}

/*----------------------------------------------------*/
#pragma mark - React Native Methods Available in Javascript -
/*----------------------------------------------------*/


RCT_EXPORT_METHOD(requestEnable:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"%@", @"Request enable called");
    
    if (!self.ble.isCentralReady) {
        [self.ble centralManagerSetup];
    }
    
    resolve((id)kCFBooleanTrue);
}

RCT_EXPORT_METHOD(enable:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    // Apple does not support programmatically enabling central manager
    NSString *message = @"Enable bluetooth service; Apple does not support this function";
    NSError *error = [NSError errorWithDomain:@"no_support" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
    reject(@"", message, error);
    [self onError:message];
}

RCT_EXPORT_METHOD(disable:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    // Apple does not support programmatically disabling central manager
    NSString *message = @"Disable bluetooth service; Apple does not support this function";
    NSError *error = [NSError errorWithDomain:@"no_support" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
    reject(@"", message, error);
    [self onError:message];
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

RCT_EXPORT_METHOD(list:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"List peripherals");
    
    [self.ble scanForPeripheralsByInterval:(float)3.0 completion:^(NSMutableArray *peripherals) {
        NSMutableArray *result = [self getPeripheralList:peripherals];
        resolve(result);
    }];
}

RCT_EXPORT_METHOD(listUnpaired:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"List unpaired peripherals; This is basically the same with list function");
    
    [self.ble scanForPeripheralsByInterval:(float)3.0 completion:^(NSMutableArray *peripherals) {
        NSMutableArray *result = [self getPeripheralList:peripherals];
        resolve(result);
    }];
}

RCT_EXPORT_METHOD(isDiscovering:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Is discovering called");
    
    if (self.ble.isScanning) {
        resolve((id)kCFBooleanTrue);
    } else {
        resolve((id)kCFBooleanFalse);
    }
}

RCT_EXPORT_METHOD(cancelDiscovery:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Cancel discovery called");
    
    if (self.ble.isScanning) {
        [self.ble stopScanForPeripherals];
    }
    
    resolve((id)kCFBooleanTrue);
}

RCT_EXPORT_METHOD(pairDevice:(NSString *)uuid
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    // Apple does not support programmatically pairing.
    NSString *message = @"Pair to peripheral (UUID : %@); Apple does not support this function";
    NSError *error = [NSError errorWithDomain:@"no_support" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
    reject(@"", message, error);
    [self onError:message];
}

RCT_EXPORT_METHOD(unpairDevice:(NSString *)uuid
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    // Apple does not support programmatically unpairing.
    NSString *message = @"Unpair to peripheral (UUID : %@); Apple does not support this function";
    NSError *error = [NSError errorWithDomain:@"no_support" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
    reject(@"", message, error);
    [self onError:message];
}

RCT_EXPORT_METHOD(connect:(NSString *)uuid
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Connect to peripheral");
    
    // Disconnect from active peripherals
    if (self.ble.activePeripheral) {
        if (self.ble.activePeripheral.state == CBPeripheralStateConnected) {
            [self.ble disconnectToPeripheral:self.ble.activePeripheral];
        }
    }
    
    self.connectionResolver = resolve;
    self.connectionRejector = reject;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(findBLEPeripheralByUUID:completion:)
                                               object:nil];
    
    [self findBLEPeripheralByUUID:uuid completion:^(CBPeripheral *peripheral) {
        if (peripheral) {
            if (peripheral.identifier) {
                NSLog(@"Connecting to device (UUID : %@)", peripheral.identifier.UUIDString);
            } else {
                NSLog(@"Connecting to device (UUID : NULL)");
            }
            
            [self.ble connectToPeripheral:peripheral];
        } else {
            NSString *message = [NSString stringWithFormat:@"Could not find peripheral %@.", uuid];
            NSError *err = [NSError errorWithDomain:@"wrong_uuid" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
            self.connectionRejector(@"wrong_uuid", message, err);
            [self onError:message];
        }
    }];
}

RCT_EXPORT_METHOD(disconnect:(NSString *)uuid
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Disconnect from peripheral");
    
    // Disconnect active peripheral
    if (self.ble.activePeripheral) {
        if (self.ble.activePeripheral.state == CBPeripheralStateConnected) {
            [self.ble disconnectToPeripheral:self.ble.activePeripheral];
        }
    }
    
    resolve((id)kCFBooleanTrue);
}

RCT_EXPORT_METHOD(isConnected:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    if (self.ble.isConnected) {
        resolve((id)kCFBooleanTrue);
    } else {
        resolve((id)kCFBooleanFalse);
    }
}

RCT_EXPORT_METHOD(withDelimiter:(NSString *)delimiter
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Set delimiter to %@", delimiter);
    
    if (delimiter != (NSString *)[NSNull init]) {
        self.delimiter = [delimiter copy];
    }
    
    resolve((id)kCFBooleanTrue);
}

RCT_EXPORT_METHOD(clear:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    long end = [self.buffer length] - 1;
    NSRange truncate = NSMakeRange(0, end);
    [self.buffer deleteCharactersInRange:truncate];
    resolve((id)kCFBooleanTrue);
}

RCT_EXPORT_METHOD(available:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSNumber *bufferLength = [NSNumber numberWithInteger:[self.buffer length]];
    resolve(bufferLength);
}

RCT_EXPORT_METHOD(setAdapterName:(NSString *)name
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    // Apple does not support programmatically adapter name setter.
    NSString *message = @"Cannot set adapter name in iOS";
    NSError *error = [NSError errorWithDomain:@"no_support" code:500 userInfo:@{NSLocalizedDescriptionKey:message}];
    reject(@"", message, error);
    [self onError:message];
}

RCT_EXPORT_METHOD(writeToDevice:(NSString *)message
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Write to device : %@", message);
    
    if (message != (NSString *)[NSNull init]) {
        NSData *data = [[NSData alloc] initWithBase64EncodedString:message options:NSDataBase64DecodingIgnoreUnknownCharacters];
        [self.ble write:data];
    } else {
        NSLog(@"Data was null");
    }
    
    resolve((id)kCFBooleanTrue);
}

RCT_EXPORT_METHOD(writeBase64ImageToDevice:(NSString *)message
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Write base64 image to device : %@", message);
    
    if (message != (NSString *)[NSNull init]) {
        UIImage *image = [self base64StringToImage:message];
        NSData *data = [self POSPrintImage:image width:384];
        [self.ble write:data];
    } else {
        NSLog(@"Data was null");
    }
    
    resolve((id)kCFBooleanTrue);
}


RCT_EXPORT_METHOD(readFromDevice:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Read from active device");
    NSString *message = @"";
    
    if ([self.buffer length] > 0) {
        long end = [self.buffer length] - 1;
        message = [self.buffer substringToIndex:end];
        NSRange entireString = NSMakeRange(0, end);
        [self.buffer deleteCharactersInRange:entireString];
    }
    
    resolve(message);
}

RCT_EXPORT_METHOD(readUntilDelimiter:(NSString *)delimiter
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Read until delimiter : %@", self.delimiter);
    
    NSString *message = [self readUntil:delimiter];
    resolve(message);
}

/*----------------------------------------------------*/
#pragma mark - Private Methods -
/*----------------------------------------------------*/

- (void)findBLEPeripheralByUUID: (NSString *)uuid
                     completion:(RCTBluetoothSerialPeripheralCallback)callback
{
    NSLog(@"Scanning for BLE Peripherals: %@", uuid);
    
    // Scan for peripherals.
    // If the uuid is null or blank, scan and
    // connect to the first available device.
    [self.ble scanForPeripheralsByInterval:(float)3.0 completion:^(NSMutableArray *peripherals) {
        CBPeripheral *peripheral = nil;
        
        if ([peripherals count] < 1) {
            [self onError:@"Did not find any BLE peripherals"];
        } else {
            if ((uuid == (NSString *)[NSNull null]) | [uuid isEqualToString:@""]) {
                // First device found
                peripheral = [peripherals objectAtIndex:0];
            } else {
                // Device by UUID
                for (CBPeripheral *p in self.ble.peripherals) {
                    if ([uuid isEqualToString:p.identifier.UUIDString]) {
                        peripheral = p;
                        break;
                    }
                }
            }
        }
        
        if (callback) {
            callback(peripheral);
        }
    }];
}

- (NSMutableArray*)getPeripheralList:(NSMutableArray *)peripherals
{
    NSMutableArray *result = [NSMutableArray array];
    
    if ([peripherals count] > 0) {
        for (int i = 0; i < peripherals.count; i++) {
            CBPeripheral *peripheral = [self.ble.peripherals objectAtIndex:i];
            NSMutableDictionary *dict = [self.ble peripheralToDictionary:peripheral];
            [result addObject:dict];
        }
    }
    
    return result;
}

- (NSString *)readUntil:(NSString *)delimiter
{
    NSRange range = [self.buffer rangeOfString:delimiter];
    NSString *message = @"";
    
    if (range.location != NSNotFound) {
        long end = range.location + range.length;
        message = [self.buffer substringToIndex:end];
        NSRange truncate = NSMakeRange(0, end);
        [self.buffer deleteCharactersInRange:truncate];
    }
    
    return message;
}

- (void)onError:(NSString *)message
{
    NSLog(@"%@", message);
    [self sendEventWithName:@"error" body:@{@"message":message}];
}

- (NSString *)imageToBase64String:(UIImage *)image {
    return [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
}

- (UIImage *)base64StringToImage:(NSString *)base64 {
    NSData *data = [[NSData alloc]initWithBase64EncodedString:base64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [UIImage imageWithData:data];
}

- (NSData *)POSPrintImage:(UIImage *)image width:(NSUInteger)nWidth
{
    CGImageRef imageRef = [image CGImage];
    
    // Defind width and height
    NSUInteger width = (nWidth + 7) / 8 * 8;
    NSUInteger height = CGImageGetHeight(imageRef) * width / CGImageGetWidth(imageRef);
    
    height = (height + 7) / 8 * 8;
    
    // Craete grayscale color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // Get raw data
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:height * width * 4];
    unsigned char *rawData = data.mutableBytes;
    
    // Create context to draw image
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    CGColorSpaceRelease(colorSpace);
    
    // Draw image
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    CGContextRelease(context);
    
    NSData *newData = UIImageJPEGRepresentation([[UIImage alloc] initWithCGImage:imageRef], 1);
    
    return newData;
}
    
/*----------------------------------------------------*/
#pragma mark - Timers -
/*----------------------------------------------------*/

- (void)bluetoothPowerStateTimer:(NSTimer *)timer
{
    RCTPromiseResolveBlock resolve = [timer userInfo];
    
    if (self.ble.isCentralReady) {
        resolve((id)kCFBooleanTrue);
    } else {
        resolve((id)kCFBooleanFalse);
    }
}

/*----------------------------------------------------*/
#pragma mark - BLE Delegate -
/*----------------------------------------------------*/

- (void)didPowerOn
{
    [self sendEventWithName:@"bluetoothEnabled" body:nil];
}

- (void)didPowerOff
{
    [self sendEventWithName:@"bluetoothDisabled" body:nil];
}

- (void)didConnect:(CBPeripheral *)peripheral
{
    NSString *message;
    NSMutableDictionary *device = [self.ble peripheralToDictionary:peripheral];
    
    if (peripheral.identifier) {
        message = [NSString stringWithFormat:@"Connected to BLE peripheral (UUID : %@)", peripheral.identifier.UUIDString];
    } else {
        message = @"Connected to BLE peripheral (UUID : NULL)";
    }
    
    NSLog(@"%@", message);
    
    [self sendEventWithName:@"connectionSuccess" body:@{@"message":message, @"device":device}];
    
    if (self.connectionResolver) {
        self.connectionResolver(device);
    }
}

- (void)didFailToConnect:(CBPeripheral *)peripheral
{
    NSString *message;
    NSMutableDictionary *device = [self.ble peripheralToDictionary:peripheral];
    
    if (peripheral.identifier) {
        message = [NSString stringWithFormat:@"Unable to connect to BLE peripheral (UUID : %@)", peripheral.identifier.UUIDString];
    } else {
        message = @"Unable to connect to BLE peripheral (UUID : NULL)";
    }
    
    NSLog(@"%@", message);
    
    [self sendEventWithName:@"connectionFailed" body:@{@"message":message, @"device":device}];
    
    self.connectionResolver = nil;
    self.connectionRejector = nil;
}

- (void)didConnectionLost:(CBPeripheral *)peripheral
{
    NSString *message;
    NSMutableDictionary *device = [self.ble peripheralToDictionary:peripheral];
    
    if (peripheral.identifier) {
        message = [NSString stringWithFormat:@"BLE peripheral (UUID : %@) connection lost", peripheral.identifier.UUIDString];
    } else {
        message = @"BLE peripheral (UUID : NULL) connection lost";
    }
    
    NSLog(@"%@", message);
    
    [self sendEventWithName:@"connectionLost" body:@{@"message":message, @"device":device}];
    
    self.connectionResolver = nil;
    self.connectionRejector = nil;
}

- (void)didReceiveData:(unsigned char *)data length:(NSInteger)length
{
    NSLog(@"Received data from peripheral");
    
    NSData *d = [NSData dataWithBytes:data length:length];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    
    if (s) {
        NSLog(@"Received %@", s);
        
        [self.buffer appendString:s];
        NSLog(@"Read until delimiter : %@", self.delimiter);
        
        NSString *message = [self readUntil:self.delimiter];
        
        if ([message length] > 0) {
            [self sendEventWithName:@"read" body:@{@"data":message}];
            [self sendEventWithName:@"data" body:@{@"data":message}];
        }
    } else {
        [self onError:@"Error converting received data into a string"];
    }
}

- (void)didError:(NSError *)error
{
    NSString *message = [error localizedDescription];
    [self onError:message];
}

/*----------------------------------------------------*/
#pragma mark - RCT Event Emitter -
/*----------------------------------------------------*/

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"bluetoothEnabled", @"bluetoothDisabled", @"connectionSuccess", @"connectionFailed", @"connectionLost", @"read", @"data", @"error"];
}

- (void)startObserving
{
    self.doesHaveListeners = TRUE;
}

- (void)stopObserving
{
    self.doesHaveListeners = FALSE;
}

@end
