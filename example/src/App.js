import React, { Component } from "react";
import {
  Platform,
  ScrollView,
  Switch,
  Text,
  TouchableOpacity,
  SafeAreaView,
  View,
  ActivityIndicator
} from "react-native";

import Toast from "@remobile/react-native-toast";
import BluetoothSerial, {
  withSubscription
} from "react-native-bluetooth-serial-next";
import { Buffer } from "buffer";

import Button from "./components/Button";
import DeviceList from "./components/DeviceList";
import styles from "./styles";

global.Buffer = Buffer;

const iconv = require("iconv-lite");

class Example extends Component {
  events;

  constructor(props) {
    super(props);

    this.state = {
      isEnabled: false,
      device: null,
      devices: [],
      unpairedDevices: [],
      connected: false,
      connecting: false,
      scanning: false,
      section: 0
    };
  }

  async componentDidMount() {
    this.events = this.props.events;

    const [isEnabled, devices] = await Promise.all([
      BluetoothSerial.isEnabled(),
      BluetoothSerial.list()
    ]);

    this.setState({ isEnabled, devices });

    // Events

    // Bluetooth enable event
    this.events.on("bluetoothEnabled", () => {
      Toast.showShortBottom("Bluetooth enabled");
      this.setState({ isEnabled: true });
    });

    // Bluetooth disable event
    this.events.on("bluetoothDisabled", () => {
      Toast.showShortBottom("Bluetooth disabled");
      this.setState({ isEnabled: false });
    });

    // Error event
    this.events.on("error", err => console.log(`Error: ${err.message}`));

    // Connection success event
    this.events.on("connectionSuccess", device => {
      if (device) {
        Toast.showShortBottom(
          `Connection to device ${device.name} has been lost`
        );
      }
      this.setState({ connected: true, device });
    });

    // Connection lost event
    this.events.on("connectionLost", device => {
      if (device) {
        Toast.showShortBottom(
          `Connection to device ${device.name} has been lost`
        );
      }
      this.setState({ connected: false, device: null });
    });

    // Connection failed event
    this.events.on("connectionFailed", device => {
      if (device) {
        Toast.showShortBottom(`Connection to device ${device.name} has failed`);
      }
      this.setState({ connected: false, device: null });
    });

    // Read / Data
    // BluetoothSerial.on('data', () => {});
    // BluetoothSerial.on('read', () => {});
    BluetoothSerial.read((data, subscriptionId) => {
      console.log(`Data read from connected device : ${data}`);

      // To remove subscription, however if you use withSubscription HOC,
      // it will remove all listeners eventually

      // if (subscriptionId) {
      //   BluetoothSerial.removeSubscription(subscriptionId);
      // }
    }, "\r\n");
  }

  /**
   * [android]
   * [ios] throws an error
   * Request enable of bluetooth from user
   */
  requestEnable = async () => {
    try {
      await BluetoothSerial.requestEnable();
      this.setState({ isEnabled: true });
    } catch (err) {
      Toast.showShortBottom(err.message);
    }
  };

  /**
   * [android]
   * [ios] throws an error
   * Enable bluetooth on device
   */
  enable = async () => {
    try {
      await BluetoothSerial.enable();
    } catch (err) {
      Toast.showShortBottom(err.message);
    }
  };

  /**
   * [android]
   * [ios] throws an error
   * Disable bluetooth on device
   */
  disable = async () => {
    try {
      await BluetoothSerial.disable();
      this.setState({ isEnabled: false });
    } catch (err) {
      Toast.showShortBottom(err.message);
    }
  };

  /**
   * Toggle bluetooth adapter
   * @param {Boolean} value
   */
  toggleBluetooth = async value => {
    if (value === true) {
      await this.enable();
    } else {
      await this.disable();
    }
  };

  /**
   * [android]
   * [ios] it returns the same list as list() function
   * Discover unpaired devices
   */
  discoverUnpaired = async () => {
    if (!this.state.scanning) {
      this.setState({ scanning: true });
      try {
        // BluetoothSerial.discoverUnpairedDevices()
        const unpairedDevices = await BluetoothSerial.listUnpaired();
        this.setState({ unpairedDevices, scanning: false });
      } catch (err) {
        Toast.showShortBottom(err.message);
      }
    }
  };

  /**
   * Discover unpaired devices, works only in android
   */
  cancelDiscovery = async () => {
    if (this.state.scanning) {
      try {
        // await BluetoothSerial.stopScanning()
        await BluetoothSerial.cancelDiscovery();
        this.setState({ scanning: false });
      } catch (err) {
        Toast.showShortBottom(err.message);
      }
    }
  };

  /**
   * [android]
   * [ios] throws an error
   * Pair device
   * @param {Object} device
   */
  pairDevice = async device => {
    try {
      const paired = await BluetoothSerial.pairDevice(device.id);

      /**
       * Device object
       * [andriod]
       * -> id, name, address, class (optional)
       * [ios]
       * -> id, uuid, name, rssi (optional)
       */

      if (paired) {
        Toast.showShortBottom(`Device ${device.name} paired successfully`);

        this.setState(state => ({
          device,
          devices: [...devices, device],
          unpairedDevices: unpairedDevices.filter(v => v.id !== device.id)
        }));
      } else {
        Toast.showShortBottom(`Device ${device.name} pairing failed`);
      }
    } catch (err) {
      Toast.showShortBottom(err.message);
    }
  };

  /**
   * Connect to bluetooth device by id
   * @param {Object} device
   */
  connect = async device => {
    this.setState({ connecting: true });

    try {
      const connectedDevice = await BluetoothSerial.connect(device.id);

      Toast.showShortBottom(`Connected to device ${connectedDevice.name}`);

      this.setState({
        device: connectedDevice,
        connected: true,
        connecting: false
      });
    } catch (err) {
      Toast.showShortBottom(err.message);
    }
  };

  /**
   * Disconnect from current bluetooth device
   */
  disconnect = async () => {
    try {
      await BluetoothSerial.disconnect;
      this.setState({ connected: false });
    } catch (err) {
      Toast.showShortBottom(err.message);
    }
  };

  /**
   * Toggle connection when we have active device
   * @param {Boolean} value
   */
  toggleConnect = async value => {
    if (value === true && this.state.device) {
      await this.connect(this.state.device);
    } else {
      await this.disconnect();
    }
  };

  /**
   * Write message to device
   * @param {String} message
   */
  write = async message => {
    if (!this.state.connected) {
      Toast.showShortBottom("You must connect to device first");
      return;
    }

    try {
      await BluetoothSerial.write(message);
      Toast.showShortBottom("Successfuly wrote to device");
      this.setState({ connected: true });
    } catch (err) {
      Toast.showShortBottom(err.message);
    }
  };

  onDevicePress = async device => {
    if (this.state.section === 0) {
      await this.connect(device);
    } else {
      await this.pairDevice(device);
    }
  };

  writePackets = async (message, packetSize = 64) => {
    const toWrite = iconv.encode(message, "cp852");
    const writePromises = [];
    const packetCount = Math.ceil(toWrite.length / packetSize);

    for (var i = 0; i < packetCount; i++) {
      const packet = new Buffer(packetSize);
      packet.fill(" ");
      toWrite.copy(packet, 0, i * packetSize, (i + 1) * packetSize);
      writePromises.push(BluetoothSerial.write(packet));
    }

    Promise.all(writePromises).then(() => console.log("Writed packets"));
  };

  render() {
    return (
      <SafeAreaView style={{ flex: 1 }}>
        <View style={styles.topBar}>
          <Text style={styles.heading}>Bluetooth Serial Example</Text>
          <View style={styles.enableInfoWrapper}>
            <Text style={{ fontSize: 12, color: "#FFFFFF", paddingRight: 10 }}>
              {this.state.isEnabled ? "Enabled" : "Disable"}
            </Text>
            <Switch
              onValueChange={this.toggleBluetooth}
              value={this.state.isEnabled}
            />
          </View>
        </View>

        <View
          style={[
            styles.topBar,
            { justifyContent: "center", paddingHorizontal: 0 }
          ]}
        >
          <TouchableOpacity
            style={[
              styles.tab,
              this.state.section === 0 && styles.activeTabStyle
            ]}
            onPress={() => this.setState({ section: 0 })}
          >
            <Text style={{ fontSize: 14, color: "#FFFFFF" }}>
              PAIRED DEVICES
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[
              styles.tab,
              this.state.section === 1 && styles.activeTabStyle
            ]}
            onPress={() => this.setState({ section: 1 })}
          >
            <Text style={{ fontSize: 14, color: "#FFFFFF" }}>
              UNPAIRED DEVICES
            </Text>
          </TouchableOpacity>
        </View>
        {this.state.scanning && this.state.section === 1 ? (
          <View
            style={{ flex: 1, alignItems: "center", justifyContent: "center" }}
          >
            <ActivityIndicator
              style={{ marginBottom: 15 }}
              size={Platform.OS === "ios" ? 1 : 60}
            />
            <Button
              textStyle={{ color: "#FFFFFF" }}
              style={styles.buttonRaised}
              title="Cancel Discovery"
              onPress={() => this.cancelDiscovery()}
            />
          </View>
        ) : (
          <DeviceList
            showConnectedIcon={this.state.section === 0}
            connectedId={this.state.device && this.state.device.id}
            devices={
              this.state.section === 0
                ? this.state.devices
                : this.state.unpairedDevices
            }
            onDevicePress={device => this.onDevicePress(device)}
          />
        )}

        <View style={{ alignSelf: "flex-end", height: 52 }}>
          <ScrollView horizontal contentContainerStyle={styles.fixedFooter}>
            {this.state.isEnabled & this.state.connected ? (
              <Button
                title="Write message"
                onPress={() =>
                  this.write(
                    "This is the test message\r\nDoes it work?\r\nTell me it works!"
                  )
                }
              />
            ) : null}
            {this.state.isEnabled & this.state.connected ? (
              <Button
                title="Write base64"
                onPress={() => this.writeBase64Image(base64Image)}
              />
            ) : null}
            {!this.state.isEnabled ? (
              <Button
                title="Request enable"
                onPress={() => this.requestEnable()}
              />
            ) : null}
          </ScrollView>
        </View>
      </SafeAreaView>
    );
  }
}

export default withSubscription({ subscriptionName: "events" })(Example);
