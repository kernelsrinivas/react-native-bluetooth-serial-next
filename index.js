const ReactNative = require("react-native");
const { Buffer } = require("buffer");
const { NativeModules, DeviceEventEmitter } = ReactNative;
const BluetoothSerial = NativeModules.BluetoothSerial;

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
BluetoothSerial.on = (eventName, handler) =>
  DeviceEventEmitter.addListener(eventName, handler);

/**
 * Listen for available events
 * @param  {String} eventName
 * @param  {Function} handler Event handler
 * @return {EmitterSubscription}
 */
BluetoothSerial.addListener = (eventName, handler) =>
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
BluetoothSerial.off = (eventName, handler) =>
  DeviceEventEmitter.removeListener(eventName, handler);

/**
 * Stop listening for event
 * @param  {String} eventName
 * @param  {Function} handler Event handler
 */
BluetoothSerial.removeListener = (eventName, handler) =>
  DeviceEventEmitter.removeListener(eventName, handler);

/**
 * Stop all listeners for event
 * @param  {String} eventName
 */
BluetoothSerial.removeAllListeners = eventName =>
  DeviceEventEmitter.removeAllListeners(eventName);

/**
 * Read data from device
 * @param  {String} [delimiter=""]
 * @return {Promise<String>}
 */
BluetoothSerial.readOnce = (delimiter = "") =>
  typeof delimiter === "string"
    ? BluetoothSerial.readUntilDelimiter(delimiter)
    : BluetoothSerial.readFromDevice();

/**
 * Read data from device every ms
 * @param {Function} [callback=() => {}]
 * @param {Number} [ms=1000]
 * @param {String} [delimiter=""]
 * @return {number} IntervalId
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

  return intervalId;
};
/**
 * Listen and read data from device
 * @param {Function} [callback=() => {}]
 * @param {String} [delimiter=""]
 */
BluetoothSerial.read = (callback = () => {}, delimiter = "") => {
  BluetoothSerial.withDelimiter(delimiter).then(() => {
    const timeoutId = BluetoothSerial.on("read", data => {
      callback(data, timeoutId);
    });
  });
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

/**
 * Write base64 image to device, you can pass string or buffer
 * We must convert to base64 in RN there is no way to pass buffer directly
 * @param  {Buffer|String} data
 * @return {Promise<Boolean>}
 */
BluetoothSerial.writeBase64Image = data => {
  if (typeof data === "string") {
    data = new Buffer(data);
  }
  return BluetoothSerial.writeBase64ImageToDevice(data.toString("base64"));
};

module.exports = BluetoothSerial;
