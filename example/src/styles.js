import { StyleSheet } from "react-native";

const styles = StyleSheet.create({
  container: {
    flex: 0.9,
    backgroundColor: "#F5FCFF"
  },
  topBar: {
    height: 56,
    paddingHorizontal: 16,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    elevation: 6,
    backgroundColor: "#7B1FA2"
  },
  heading: {
    fontWeight: "bold",
    fontSize: 16,
    alignSelf: "center",
    color: "#FFFFFF"
  },
  enableInfoWrapper: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center"
  },
  tab: {
    alignItems: "center",
    flex: 0.5,
    height: 56,
    justifyContent: "center",
    borderBottomWidth: 6,
    borderColor: "transparent"
  },
  connectionInfoWrapper: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingHorizontal: 25
  },
  connectionInfo: {
    fontWeight: "bold",
    alignSelf: "center",
    fontSize: 18,
    marginVertical: 10,
    color: "#238923"
  },
  listContainer: {
    borderColor: "#ccc",
    borderTopWidth: 0.5
  },
  listItem: {
    flex: 1,
    height: 48,
    paddingHorizontal: 16,
    borderColor: "#ccc",
    borderBottomWidth: 0.5,
    justifyContent: "center"
  },
  fixedFooter: {
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
    borderTopWidth: 1,
    borderTopColor: "#ddd"
  },
  button: {
    height: 36,
    margin: 5,
    paddingHorizontal: 16,
    alignItems: "center",
    justifyContent: "center"
  },
  buttonText: {
    color: "#7B1FA2",
    fontWeight: "bold",
    fontSize: 14
  },
  buttonRaised: {
    backgroundColor: "#7B1FA2",
    borderRadius: 2,
    elevation: 2
  },
  activeTabStyle: { borderBottomWidth: 6, borderColor: "#009688" }
});

export default styles;
