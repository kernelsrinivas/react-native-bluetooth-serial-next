import React from "react";
import {
  ScrollView,
  Text,
  TouchableHighlight,
  View,
  Image
} from "react-native";
import styles from "../../styles";

const DeviceList = ({
  devices,
  connectedId,
  showConnectedIcon,
  onDevicePress
}) => (
  <ScrollView style={styles.container}>
    <View style={styles.listContainer}>
      {devices.map((device, i) => {
        return (
          <TouchableHighlight
            underlayColor="#DDDDDD"
            key={`${device.id}_${i}`}
            style={styles.listItem}
            onPress={() => onDevicePress(device)}
          >
            <View style={{ flexDirection: "row" }}>
              {showConnectedIcon ? (
                <View style={{ width: 48, height: 48, opacity: 0.4 }}>
                  {connectedId === device.id ? (
                    <Image
                      style={{
                        resizeMode: "contain",
                        width: 24,
                        height: 24,
                        flex: 1
                      }}
                      source={require("./img/ic_done_black_24dp.png")}
                    />
                  ) : null}
                </View>
              ) : null}
              <View
                style={{
                  justifyContent: "space-between",
                  flexDirection: "row",
                  alignItems: "center"
                }}
              >
                <Text style={{ fontWeight: "bold" }}>{device.name}</Text>
                <Text>{`<${device.id}>`}</Text>
              </View>
            </View>
          </TouchableHighlight>
        );
      })}
    </View>
  </ScrollView>
);

export default DeviceList;
