const ReactNative = require("react-native");
const React = require("react");
const { Buffer } = require("buffer");

const { NativeModules, DeviceEventEmitter } = ReactNative;
const { BluetoothSerial } = NativeModules;

/**
 * High order component that will
 * attach native event emitter and
 * send it as a props named subscription
 *
 * It will create an emitter when component did mount
 * and remove all listeners when component will unmount
 *
 * @param  {Object}   [options]
 * @param  {String}   [options.subscriptionName=subscription]
 * @param  {Boolean}  [options.destroyOnWilUnmount=true]
 * @return {React.Component}
 */
export const withSubscription = (
  options = {
    subscriptionName: "subscription",
    destroyOnWilUnmount: true
  }
) => WrappedComponent => {
  const subscriptionName =
    typeof options.subscriptionName === "string"
      ? options.subscriptionName
      : "subscription";
  const destroyOnWilUnmount =
    typeof options.destroyOnWilUnmount === "boolean"
      ? options.destroyOnWilUnmount
      : true;

  let emitter = DeviceEventEmitter;
  emitter.on = DeviceEventEmitter.addListener;
  emitter.off = DeviceEventEmitter.removeListener;
  emitter.remove = DeviceEventEmitter.removeAllListeners;

  return class RTCBluetoothSerialComponent extends React.Component {
    componentWillUnmount() {
      const subscription = this.props[subscriptionName];

      if (destroyOnWilUnmount && subscription) {
        typeof subscription.remove === "function" && subscription.remove();

        typeof subscription.removeAllListeners === "functions" &&
          subscription.removeAllListeners();
      }
    }

    render() {
      return (
        <WrappedComponent {...this.props} {...{ [subscriptionName]: emitter }}>
          {this.props.children}
        </WrappedComponent>
      );
    }
  };
};

/**
 * Listen for available event once
 * @param  {String} eventName
 * @param  {Function} handler Event handler
 * @return {EmitterSubscription}
 */
BluetoothSerial.once = (eventName, handler) =>
  DeviceEventEmitter.once(eventName, handler);

/**
 * Listen for available events
 * @param  {String} eventName
 * @param  {Function} handler Event handler
 * @return {EmitterSubscription}
 */
BluetoothSerial.addListener = (eventName, handler) =>
  DeviceEventEmitter.addListener(eventName, handler);

/**
 * Listen for available events
 * @param  {String} eventName
 * @param  {Function} handler Event handler
 * @return {EmitterSubscription}
 */
BluetoothSerial.on = (eventName, handler) =>
  DeviceEventEmitter.addListener(eventName, handler);

/**
 * Remove subscription event
 * @param {EmitterSubscription} subscription
 */
BluetoothSerial.removeSubscription = subscription =>
  DeviceEventEmitter.removeSubscription(subscription);

/**
 * Stop listening for event
 * @param  {String} eventName
 * @param  {Function} handler Event handler
 */
BluetoothSerial.removeListener = (eventName, handler) =>
  DeviceEventEmitter.removeListener(eventName, handler);

/**
 * Stop listening for event
 * @param  {String} eventName
 * @param  {Function} handler Event handler
 */
BluetoothSerial.off = (eventName, handler) =>
  DeviceEventEmitter.removeListener(eventName, handler);

/**
 * Stop all listeners for event
 * @param  {String} eventName
 */
BluetoothSerial.removeAllListeners = eventName =>
  DeviceEventEmitter.removeAllListeners(eventName);

/**
 * Listen and read data from device
 * @param {Function} [callback=() => {}]
 * @param {String} [delimiter=""]
 */
BluetoothSerial.read = (callback = () => {}, delimiter = "") => {
  console.log(delimiter);
  BluetoothSerial.withDelimiter(delimiter).then(() => {
    const subscriptionId = BluetoothSerial.on("read", data => {
      callback(data, subscriptionId);
    });
  });
};

/**
 * Read data from device once
 * @param  {String} [delimiter=""]
 * @return {Promise<String>}
 */
BluetoothSerial.readOnce = (delimiter = "") =>
  typeof delimiter === "string"
    ? BluetoothSerial.readUntilDelimiter(delimiter)
    : BluetoothSerial.readFromDevice();

/**
 * Read data from device every n ms
 * @param {Function} [callback=() => {}]
 * @param {Number} [ms=1000]
 * @param {String} [delimiter=""]
 */
BluetoothSerial.readEvery = (
  callback = () => {},
  ms = 1000,
  delimiter = ""
) => {
  const intervalId = setInterval(() => {
    const data =
      typeof delimiter === "string"
        ? BluetoothSerial.readUntilDelimiter(delimiter)
        : BluetoothSerial.readFromDevice();

    callback(data, intervalId);
  }, ms);
};

/**
 * Write data to device, you can pass string or buffer,
 * We must convert to base64 in RN there is no way to pass buffer directly
 * @param  {Buffer|String} data
 * @return {Promise<Boolean>}
 */
BluetoothSerial.write = data => {
  if (typeof data === "string") {
    data = new Buffer(data);
  }
  return BluetoothSerial.writeToDevice(data.toString("base64"));
};

// Alias
BluetoothSerial.discoverUnpairedDevice = BluetoothSerial.listUnpaired;
BluetoothSerial.stopScanning = BluetoothSerial.cancelDiscovery;

export default BluetoothSerial;
