const ReactNative = require("react-native");
const React = require("react");
const { Buffer } = require("buffer");

const { NativeModules, DeviceEventEmitter } = ReactNative;
const { BluetoothSerial } = NativeModules;

/**
 * High order component that will
 * attach native event emitter and
 * send it as a props named subscription.
 *
 * It will create an emitter when component did mount
 * and remove all listeners when component will unmount.
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
 * Similar to addListener, except that the listener is removed after it is
 * invoked once.
 *
 * @param eventName - Name of the event to listen to
 * @param listener - Function to invoke only once when the
 *   specified event is emitted
 * @param context - Optional context object to use when invoking the
 *   listener
 */
BluetoothSerial.once = (eventName, handler, context) =>
  DeviceEventEmitter.once(eventName, handler, context);

/**
 * Attach listener to a certain event name.
 *
 * @param eventName - Name of the event to listen to
 * @param listener - Function to invoke only once when the
 *   specified event is emitted
 * @param context - Optional context object to use when invoking the
 *   listener
 */
BluetoothSerial.addListener = (eventName, handler, context) =>
  DeviceEventEmitter.addListener(eventName, handler, context);

/**
 * Attach listener to a certain event name.
 *
 * @param eventName - Name of the event to listen to
 * @param listener - Function to invoke only once when the
 *   specified event is emitted
 * @param context - Optional context object to use when invoking the
 *   listener
 */
BluetoothSerial.on = (eventName, handler, context) =>
  DeviceEventEmitter.addListener(eventName, handler, context);

/**
 * Removes a specific subscription. Called by the `remove()` method of the
 * subscription itself to ensure any necessary cleanup is performed.
 */
BluetoothSerial.removeSubscription = subscription =>
  DeviceEventEmitter.removeSubscription(subscription);

/**
 * Removes the given listener for event of specific type.
 *
 * @param eventName - Name of the event to emit
 * @param listener - Function to invoke when the specified event is
 *   emitted
 *
 * @example
 *   emitter.removeListener('someEvent', function(message) {
 *     console.log(message);
 *   }); // removes the listener if already registered
 *
 */
BluetoothSerial.removeListener = (eventName, handler, context) =>
  DeviceEventEmitter.removeListener(eventName, handler, context);

/**
 * Removes the given listener for event of specific type.
 *
 * @param eventName - Name of the event to emit
 * @param listener - Function to invoke when the specified event is
 *   emitted
 *
 * @example
 *   emitter.removeListener('someEvent', function(message) {
 *     console.log(message);
 *   }); // removes the listener if already registered
 *
 */
BluetoothSerial.off = (eventName, handler) =>
  DeviceEventEmitter.removeListener(eventName, handler);

/**
 * Removes all of the registered listeners, including those registered as
 * listener maps.
 *
 * @param eventName - Optional name of the event whose registered
 *   listeners to remove
 */
BluetoothSerial.removeAllListeners = eventName =>
  DeviceEventEmitter.removeAllListeners(eventName);

/**
 * Listen and read data from device.
 *
 * @param {Function} [callback=() => {}]
 * @param {String} [delimiter=""]
 */
BluetoothSerial.read = (callback = () => {}, delimiter = "") => {
  BluetoothSerial.withDelimiter(delimiter).then(() => {
    const subscription = BluetoothSerial.on("read", data => {
      callback(data, subscription);
    });
  });
};

/**
 * Read data from device once.
 *
 * @param  {String} [delimiter=""]
 * @return {Promise<String>}
 */
BluetoothSerial.readOnce = (delimiter = "") =>
  typeof delimiter === "string"
    ? BluetoothSerial.readUntilDelimiter(delimiter)
    : BluetoothSerial.readFromDevice();

/**
 * Read data from device every n ms.
 *
 * @param {Function} [callback=() => {}]
 * @param {Number} [ms=1000]
 * @param {String} [delimiter=""]
 */
BluetoothSerial.readEvery = (
  callback = () => {},
  ms = 1000,
  delimiter = ""
) => {
  const intervalId = setInterval(async () => {
    const data =
      typeof delimiter === "string"
        ? await BluetoothSerial.readUntilDelimiter(delimiter)
        : await BluetoothSerial.readFromDevice();

    callback(data, intervalId);
  }, ms);
};

/**
 * Write data to device, you can pass string or buffer,
 * We must convert to base64 in RN there is no way to pass buffer directly.
 *
 * @param  {Buffer|String} data
 * @return {Promise<Boolean>}
 */
BluetoothSerial.write = data => {
  if (typeof data === "string") {
    data = new Buffer(data);
  }
  return BluetoothSerial.writeToDevice(data.toString("base64"));
};

BluetoothSerial.discoverUnpairedDevice = BluetoothSerial.listUnpaired;
BluetoothSerial.stopScanning = BluetoothSerial.cancelDiscovery;

export default BluetoothSerial;
