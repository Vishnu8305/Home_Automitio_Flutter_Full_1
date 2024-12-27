#include <WiFi.h>
#include <PubSubClient.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>
#include "esp_bt.h"
#include "esp_bt_main.h"
#include "esp_bt_device.h"
/////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////

// Pin Definitions
#define LED_PIN_1 2 // GPIO for LED 1
#define LED_PIN_2 0 // GPIO for LED 2
#define LED_PIN_3 4 // GPIO for LED 1
#define LED_PIN_4 16 // GPIO for LED 2
/////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////

// BLE UUIDs
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CONFIG_CHARACTERISTIC_UUID "abcdefab-cdef-1234-5678-1234567890ab"
#define STATUS_CHARACTERISTIC_UUID "fedcba98-7654-3210-9876-543210fedcba"

// MQTT Configuration
WiFiClient espClient;
PubSubClient mqttClient(espClient);
String mqttBroker;
String bluetoothMacAddress;
String mqttTopic1;
String mqttTopic2;
String mqttTopic3;
String mqttTopic4;
bool credentialsReceived = false;

// BLE Characteristics
BLECharacteristic *configCharacteristic;
BLECharacteristic *statusCharacteristic;

// Wi-Fi Configuration
String wifiSSID;
String wifiPassword;
bool wifiConnectedFlag = false;
bool mqttConnectedFlag = false;

// Notify App
void sendStatusToApp(const String &status) {
    if (statusCharacteristic) {
        StaticJsonDocument<128> jsonDoc;
        jsonDoc["type"] = "status";
        jsonDoc["message"] = status;
        jsonDoc["timestamp"] = millis();

        String jsonString;
        serializeJson(jsonDoc, jsonString);

        statusCharacteristic->setValue(jsonString.c_str());
        statusCharacteristic->notify();
        Serial.println("Status sent to app: " + jsonString);
    }
}

void monitorWiFiStatus() {
    static bool lastConnectionState = false;

    bool currentConnectionState = (WiFi.status() == WL_CONNECTED);
    if (currentConnectionState != lastConnectionState) {
        lastConnectionState = currentConnectionState;

        if (currentConnectionState) {
            sendStatusToApp("Wi-Fi Connected");
        } else {
            sendStatusToApp("Wi-Fi Disconnected");
        }
    }
}

// Connect to Wi-Fi
void connectToWiFi() {
    wifiSSID.trim();
    wifiPassword.trim();

    Serial.println("\nConnecting to Wi-Fi...");
    WiFi.disconnect(true);
    delay(1000);
    WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());

    int timeout = 30;
    while (WiFi.status() != WL_CONNECTED && timeout > 0) {
        delay(1000);
        Serial.print(".");
        timeout--;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nConnected to Wi-Fi!");
        Serial.print("SSID: ");
        Serial.println(wifiSSID);
        Serial.print("IP Address: ");
        Serial.println(WiFi.localIP());
        wifiConnectedFlag = true;
        sendStatusToApp("Wi-Fi Connected");
    } else {
        Serial.println("\nWi-Fi Connection Failed");
        sendStatusToApp("Wi-Fi Failed");
        restartBLE();
    }
}
void restartBLE() {
  BLEDevice::getAdvertising()->start();
  Serial.println("BLE restarted for new configuration");
}

String getBluetoothMacAddress() {
    if (esp_bluedroid_get_status() == ESP_BLUEDROID_STATUS_ENABLED) {
        const uint8_t* mac = esp_bt_dev_get_address();
        char macStr[18];
        snprintf(macStr, sizeof(macStr), "%02X:%02X:%02X:%02X:%02X:%02X",
                 mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
        return String(macStr);
    } else {
        return "Bluetooth not initialized";
    }
}

// Connect to MQTT
void connectToMQTT() {
    if (!wifiConnectedFlag) {
        Serial.println("Wi-Fi not connected. Cannot connect to MQTT.");
        return;
    }

    mqttClient.setServer(mqttBroker.c_str(), 1883);

    while (!mqttClient.connected()) {
        Serial.println("Attempting to connect to MQTT...");
        Serial.print("Broker: ");
        Serial.println(mqttBroker);
/////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////
        if (mqttClient.connect("ESP32Client")) {
            Serial.println("Connected to MQTT!");

            mqttClient.subscribe(mqttTopic1.c_str());
            Serial.print("Subscribed to topic: ");
            Serial.println(mqttTopic1);

            mqttClient.subscribe(mqttTopic2.c_str());
            Serial.print("Subscribed to topic: ");
            Serial.println(mqttTopic2);

            mqttClient.subscribe(mqttTopic3.c_str());
            Serial.print("Subscribed to topic: ");
            Serial.println(mqttTopic3);

            mqttClient.subscribe(mqttTopic4.c_str());
            Serial.print("Subscribed to topic: ");
            Serial.println(mqttTopic4);


            mqttConnectedFlag = true;
            sendStatusToApp("MQTT Connected");
        } else {
            Serial.print("Failed to connect to MQTT, rc=");
            Serial.println(mqttClient.state());
            delay(5000);
        }
    }
}
/////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////

// MQTT Callback
void mqttCallback(char* topic, byte* payload, unsigned int length) {
    String message;
    for (unsigned int i = 0; i < length; i++) {
        message += (char)payload[i];
    }

    Serial.print("Message received on topic ");
    Serial.print(topic);
    Serial.print(": ");
    Serial.println(message);
/////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////

    if (String(topic) == mqttTopic1) {
        if (message == "ON") {
            digitalWrite(LED_PIN_1, HIGH);
            Serial.println("LED 1 turned ON via MQTT");
        } else if (message == "OFF") {
            digitalWrite(LED_PIN_1, LOW);
            Serial.println("LED 1 turned OFF via MQTT");
        }
    } else if (String(topic) == mqttTopic2) {
        if (message == "ON") {
            digitalWrite(LED_PIN_2, HIGH);
            Serial.println("LED 2 turned ON via MQTT");
        } else if (message == "OFF") {
            digitalWrite(LED_PIN_2, LOW);
            Serial.println("LED 2 turned OFF via MQTT");
        }
    } 
    else if (String(topic) == mqttTopic3) {
        if (message == "ON") {
            digitalWrite(LED_PIN_3, HIGH);
            Serial.println("LED 3 turned ON via MQTT");
        } else if (message == "OFF") {
            digitalWrite(LED_PIN_3, LOW);
            Serial.println("LED 3 turned OFF via MQTT");
        }
    } 
    else if (String(topic) == mqttTopic4) {
        if (message == "ON") {
            digitalWrite(LED_PIN_4, HIGH);
            Serial.println("LED 4 turned ON via MQTT");
        } else if (message == "OFF") {
            digitalWrite(LED_PIN_4, LOW);
            Serial.println("LED 4 turned OFF via MQTT");
        }
    } 
    else {
        Serial.println("Message on unrelated topic.");
    }
}
/////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////

// BLE Callbacks
class ConfigCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *characteristic) override {
    auto valueRaw = characteristic->getValue();
    String jsonString = String(valueRaw.c_str());
    Serial.println("Received JSON: " + jsonString);

    StaticJsonDocument<256> jsonDoc;
    DeserializationError error = deserializeJson(jsonDoc, jsonString);

    if (error) {
      Serial.println("JSON parsing failed!");
      return;
    }

    wifiSSID = jsonDoc["ssid"].as<String>();
    wifiPassword = jsonDoc["password"].as<String>();
    mqttBroker = jsonDoc["mqttBroker"].as<String>();

    credentialsReceived = true;
  }
};
/////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////

void setup() {
    Serial.begin(115200);
    pinMode(LED_PIN_1, OUTPUT);
    pinMode(LED_PIN_2, OUTPUT);
    pinMode(LED_PIN_3, OUTPUT);
    pinMode(LED_PIN_4, OUTPUT);
    digitalWrite(LED_PIN_1, LOW);
    digitalWrite(LED_PIN_2, LOW);
    digitalWrite(LED_PIN_3, LOW);
    digitalWrite(LED_PIN_4, LOW);
/////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////

    BLEDevice::init("ESP32 WiFi & MQTT Config");
    BLEServer* server = BLEDevice::createServer();
    BLEService* service = server->createService(SERVICE_UUID);

    configCharacteristic = service->createCharacteristic(
        CONFIG_CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_WRITE);
    configCharacteristic->setCallbacks(new ConfigCallbacks());

    statusCharacteristic = service->createCharacteristic(
        STATUS_CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_NOTIFY);
    statusCharacteristic->addDescriptor(new BLE2902());

    service->start();
    BLEDevice::getAdvertising()->start();

    esp_bluedroid_init();
    esp_bluedroid_enable();

    bluetoothMacAddress = getBluetoothMacAddress();
    Serial.println("Bluetooth MAC Address: " + bluetoothMacAddress);
/////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////

    // Construct dynamic MQTT topics
    mqttTopic1 = bluetoothMacAddress + "/home/switch1";
    mqttTopic2 = bluetoothMacAddress + "/home/switch2";
    mqttTopic3 = bluetoothMacAddress + "/home/switch3";
    mqttTopic4 = bluetoothMacAddress + "/home/switch4";
    Serial.println("MQTT Topic for LED 1: " + mqttTopic1);
    Serial.println("MQTT Topic for LED 2: " + mqttTopic2);
    Serial.println("MQTT Topic for LED 3: " + mqttTopic3);
    Serial.println("MQTT Topic for LED 4: " + mqttTopic4);
    mqttClient.setCallback(mqttCallback);
}
/////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////

void loop() {
    if (credentialsReceived) {
        credentialsReceived = false;
        connectToWiFi();

        if (wifiConnectedFlag) {
            connectToMQTT();
        }

        if (wifiConnectedFlag && mqttConnectedFlag) {
            sendStatusToApp("Connected");
        }
    }

    if (mqttClient.connected()) {
        mqttClient.loop();
    }

    monitorWiFiStatus();
    delay(1000);
}
