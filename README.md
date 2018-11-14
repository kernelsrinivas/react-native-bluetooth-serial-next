# React Native Bluetooth Serial Next

React Native version of [BluetoothSerial](https://github.com/don/BluetoothSerial) plugin for both Android and iOS. Pulled from [rusel1989/react-native-bluetooth-serial](https://github.com/rusel1989/react-native-bluetooth-serial) to fix some bugs.

- [Installation](#installation)
- [Manual Installation](#manual-installation)
  - [iOS](#ios)
  - [Android](#android)
- [Reading and Writing Concern](#reading-and-writing-concern)
- [Example Application](#example-application)
- [APIs](#apis)
  - [High Order Component](#high-order-component)
  - [Device Object](#device-object)
  - [Methods](#methods)
  - [Events](#events)
- [Todos](#todos)

## Installation

```bash
npm install react-native-bluetooth-serial-next
```

1. Link libraries with: `rnpm link` or `react-native link` for React Native >= 0.27
2. For android you also need to put the following code to `AndroidManifest.xml`

```
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## Manual Installation

#### iOS

1. `npm i react-native-bluetooth-serial-next`
2. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
3. Go to `node_modules` ➜ `react-native-bluetooth-serial-next` and add `RCTBluetoothSerial.xcodeproj`
4. In XCode, in the project navigator, select your project. Add `libRCTBluetoothSerial.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
5. Click `RCTBluetoothSerial.xcodeproj` in the project navigator and go the `Build Settings` tab. Make sure 'All' is toggled on (instead of 'Basic'). In the `Search Paths` section, look for `Header Search Paths` and make sure it contains both `$(SRCROOT)/../../react-native/React` and `$(SRCROOT)/../../../React` - mark both as `recursive`.
6. Run your project (`Cmd+R`)

#### Android

1. `npm i react-native-bluetooth-serial-next`
2. Open up `android/app/src/main/java/[...]/MainActivity.java` or `MainApplication.java` for React Native >= 0.29

- Add `import com.nuttawutmalee.RCTBluetoothSerial.*;` to the imports at the top of the file
- Add `new RCTBluetoothSerialPackage()` to the list returned by the `getPackages()` method

3. Append the following lines to `android/settings.gradle`:
   ```
   include ':react-native-bluetooth-serial-next'
   project(':react-native-bluetooth-serial-next').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-bluetooth-serial-next/android')
   ```
4. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
   ```
   compile project(':react-native-bluetooth-serial-next')
   ```

## Reading and Writing Concern

In Android after you connect to peripheral `write` and `read` methods should work for most of devices out of the box.
On iOS with BLE it is little bit complicated, you need to know correct serice and characteristics UUIDs. Currently
supported and preconfigured services are Red Bear lab, Adafruit BLE, Bluegiga, Laird Virtual Serial Port and Rongta.

## Example Application

1. Pull from this repository
2. `cd example`
3. `npm install && npm link ../`
4. `npm start`
5. `react-native run-ios` or `react-native run-android`

---

## APIs

### High Order Component

#### withSubscription(options)

This HOC will create an event listener and send it though as a prop. This will also remove all listeners when the wrapped component will unmount as well.

Available Options:

- `subscriptionName` : The event listener name that send through as a prop. (default is `subscription`.)
- `destroyOnWillUnmount` : Should all listeners function be removed on will unmount? (default is `true`.)

Example:

```js
class MyComponent extends React.Component {
    ...
}

export default withSubscription({
    subscriptionName: 'events',
    destroyOnWillUnmount: true,
})(MyComponent);
```

### Device Object

#### Android

```js
{
    "id": "111-111-111-111-111",
    "address": "111-111-111-111",
    "name": "My Printer",
    "class": "This field might not be in the object",
}
```

#### iOS

```js
{
    "id": "111-111-111-111",
    "uuid": "111-111-111-111",
    "name": "My Printer",
    "rssi": "This field might not be in the object",
}
```

### Methods

#### + requestEnable(): Promise\<Boolean>

**This will throws an error in iOS platform.**
Prompts user device to enable bluetooth adapter.

```js
await BluetoothSerial.requestEnable();
```

#### + enable(): Promise\<Boolean>

**This will throws an error in iOS platform.**
Enable bluetooth adapter service.

```js
await BluetoothSerial.enable();
```

#### + disable(): Promise\<Boolean>

**This will throws an error in iOS platform.**
Disable bluetooth adapter service.

```js
await BluetoothSerial.disable();
```

#### + isEnabled(): Promise\<Boolean>

**This will throws an error in iOS platform.**
Indicates bluetooth adapter service status.

```js
const isEnabled = await BluetoothSerial.isEnabled();
```

#### + pairDevice(id: String): Promise\<[Device](#device-object)>

**This will throws an error in iOS platform.**
Pair with a bluetooth device.

```js
const device = await BluetoothSerial.pairDevice(id);
```

#### + unpairDevice(id: String): Promise\<[Device](#device-object)>

**This will throws an error in iOS platform.**
Unpair with a bluetooth device.

```js
const device = await BluetoothSerial.unpairDevice(id);
```

#### + connect(id: String): Promise\<[Device](#device-object)>

Connect to a bluetooth device / peripheral.

```js
const device = await BluetoothSerial.connect(id);
```

#### + disconnect(): Promise\<Boolean>

Disconnect from connected bluetooth device / peripheral.

```js
await BluetoothSerial.disconnect();
```

#### + isConnected(): Promise\<Boolean>

Indicates if you are connected with active bluetooth device / peripheral or not.

```js
const isConnected = await BluetoothSerial.isConnected();
```

#### + list(): Promise\<[Device](#deviceObject)[]>

List all paired (android) / connected (ios) bluetooth devices.

```js
const devices = await BluetoothSerial.list();
```

#### + listUnpaired(): Promise\<[Device](#deviceObject)[]>

#### + discoverUnpairedDevices(): Promise\<[Device](#deviceObject)[]>

**This will throws an error in iOS platform.**
List all unpaired bluetooth devices.

```js
const devices = await BluetoothSerial.listUnpaired();
const devices = await BluetoothSerial.discoverUnpairedDevices();
```

#### + cancelDiscovery(): Promise\<Boolean></Boolean>

#### + stopScanning(): Promise\<Boolean></Boolean>

Cancel bluetooth device discovery.

```js
await BluetoothSerial.cancelDiscovery();
await BluetoothSerial.stopScanning();
```

#### + read(cb: Function, delimiter: String): void

Listen and read data from connected device.

```js
BluetoothSerial.read((data, subscription) => {
  console.log(data);

  if (this.imBoredNow) {
    BluetoothSerial.removeSubscription(subscription);
  }
}, "\r\n");
```

#### + readOnce(delimiter: String): Promise\<String>

Read data from connected device once.

```js
const data = await BluetoothSerial.readOnce("\r\n");
```

#### + readEvery(cb: Function, ms: Number, delimiter: String): void

Read data from connected device for every ... ms.

```js
BluetoothSerial.readEvery(
  (data, intervalId) => {
    console.log(data);

    if (this.imBoredNow && intervalId) {
      clearInterval(intervalId);
    }
  },
  1000,
  "\r\n"
);
```

#### + readFromDevice(): Promise\<String>

Read all buffer data from connected device.

```js
const data = await BluetoothSerial.readFromDevice();
```

#### + readUntilDelimiter(delimiter: String): Promise\<String>

Read all buffer data up to particular delimiter rom connected device.

```js
const data = await BluetoothSerial.readUntilDelimiter("\r\n");
```

#### + write(data: Buffer | String): Promise\<Boolean>

Write data to device, you can pass string or buffer,
We must convert to base64 in React Native
because there is no way to pass buffer directly.

```js
await BluetoothSerial.write("This is the test message");
```

#### + writeToDevice(data: String): Promise\<Boolean>

Write string to device.

```js
await BluetoothSerial.writeToDevice("This is the test message");
```

#### + clear(): Promise\<Boolean>

Clear all buffer data.

```js
await BluetoothSerial.clear();
```

#### + available(): Promise\<Number>

Get length of buffer data.

```js
const bufferLength = await BluetoothSerial.available();
```

#### + setAdapter(name: String): Promise\<String>

**This will throws an error in iOS platform.**
Set bluetooth adapter a new name.

```js
const newName = await BluetoothSerial.setAdapterName("New Adapter Name");
```

#### + withDelimiter(delimiter: String): Promise\<Boolean>

Set delimiter split the buffer data when you are reading from device.

```js
await BluetoothSerial.withDelimiter("\r\n");
```

### Events

#### Event Names

- `bluetoothEnabled`
  When bluetooth adapter is turned on.
- `bluetoothDisabled`
  When bluetooth adapter is turned off.
- `connectionSuccess`
  When device is connected. You get object of message and [device](#device-object).

  ```js
  {
      "message": ...,
      "device": {
          ...
      }
  }
  ```

- `connectionFailed`
  When you failed to connect to the device. You get object of message and [device](#device-object).

  ```js
  {
      "message": ...,
      "device": {
          ...
      }
  }
  ```

- `connectionLost`
  When the device connection is lost. You get object of message and [device](#device-object).

  ```js
  {
      "message": ...,
      "device": {
          ...
      }
  }
  ```

- `read` or `data`
  String of data from device. You get object of data.

  ```js
  {
      "data": ...
  }
  ```

- `error`
  Error message from native code.

  ```js
  {
      "message": ...
  }
  ```

#### Methods

##### + once(eventName, handler)

##### + on(eventName, handler)

##### + addListener(eventName, handler)

##### + off(eventName, handler);

##### + removeListener(eventName, handler)

##### + removeAllListeners(eventName?)

##### + removeSubscription(subscription)

## Events

You can listen to few event with `BluetoothSerial.on(eventName, callback)` or `BluetoothSerial.addListener(eventName, callback)`

Currently provided events are:

- `bluetoothEnabled` - when user enabled bluetooth
- `bluetoothDisabled` - when user disabled bluetooth
- `connectionSuccess` - when app connected to the device
- `connectionLost` - when app lost connection to the device (fired with `bluetoothDisabled`)

You can use `BluetoothSerial.off(eventName, callback)` or `BluetoothSerial.removeListener(eventName, callback)` to stop listening to an event

## Todos

- iOS Service declaration. We should be ab le to defice Array of Service UUID, Read Characteristic UUID, Write Characteristic UUID ourselves.
- Write base64 image.
- Multiple connection.
