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
#define LED_PIN_1 2  // GPIO for LED 1
#define LED_PIN_2 0  // GPIO for LED 2
#define LED_PIN_3 4  // GPIO for LED 1
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

// Global variables section (move this to the top of the file, before any functions)
BLEServer *server = nullptr;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Add this callback class for connection events
class MyServerCallbacks : public BLEServerCallbacks
{
    void onConnect(BLEServer *pServer)
    {
        deviceConnected = true;
        oldDeviceConnected = true;
        Serial.println("Device connected");

        // Reduce advertising interval for more stable connection
        BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
        pAdvertising->setMinInterval(100); // 100 * 0.625ms = 62.5ms
        pAdvertising->setMaxInterval(200); // 200 * 0.625ms = 125ms
    }

    void onDisconnect(BLEServer *pServer)
    {
        deviceConnected = false;
        Serial.println("Device disconnected");

        // Reset advertising to default parameters
        BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
        pAdvertising->setMinInterval(160); // Default min interval
        pAdvertising->setMaxInterval(320); // Default max interval

        // Restart advertising with a slight delay
        delay(500);
        pAdvertising->start();
    }
};

// Notify App
void sendStatusToApp(const char *message)
{
    // Only send status if a device is connected
    if (deviceConnected)
    {
        // Prepare JSON status message
        char jsonStatus[128];
        snprintf(jsonStatus, sizeof(jsonStatus),
                 "{\"type\":\"status\",\"message\":\"%s\",\"timestamp\":%lu}",
                 message, millis());

        // Send the status characteristic
        statusCharacteristic->setValue((uint8_t *)jsonStatus, strlen(jsonStatus));
        statusCharacteristic->notify();

        // If message is "Connected", stop Bluetooth after 2 seconds
        if (strcmp(message, "Connected") == 0)
        {
            delay(2000); // Wait 2 seconds to ensure message is sent
            stopBluetooth();
        }
    }
}

void stopBluetooth()
{
    // Stop advertising
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    if (pAdvertising)
    {
        pAdvertising->stop();
    }

    // Disconnect all connected devices
    if (server != nullptr)
    {
        server->disconnect(server->getConnId());
    }

    // Optional: Deinitialize Bluetooth
    esp_bluedroid_disable();
    esp_bt_controller_disable();

    Serial.println("Bluetooth stopped after successful connection");
}

void monitorWiFiStatus()
{
    static bool lastConnectionState = false;

    bool currentConnectionState = (WiFi.status() == WL_CONNECTED);
    if (currentConnectionState != lastConnectionState)
    {
        lastConnectionState = currentConnectionState;

        if (currentConnectionState && mqttConnectedFlag)
        {
            sendStatusToApp("Wi-Fi Connected");
        }
        else
        {
            sendStatusToApp("Wi-Fi Disconnected");
        }
    }
}

// Connect to Wi-Fi
void connectToWiFi()
{
    wifiSSID.trim();
    wifiPassword.trim();

    Serial.println("\nConnecting to Wi-Fi...");
    WiFi.disconnect(true);
    delay(1000);
    WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());

    int timeout = 30;
    while (WiFi.status() != WL_CONNECTED && timeout > 0)
    {
        delay(1000);
        Serial.print(".");
        timeout--;
    }

    if (WiFi.status() == WL_CONNECTED)
    {
        Serial.println("\nConnected to Wi-Fi!");
        Serial.print("SSID: ");
        Serial.println(wifiSSID);
        Serial.print("IP Address: ");
        Serial.println(WiFi.localIP());
        wifiConnectedFlag = true;

        // Do not send "Connected" immediately, wait for MQTT connection
        // sendStatusToApp("Connected");
    }
    else
    {
        Serial.println("\nWi-Fi Connection Failed");
        sendStatusToApp("Wi-Fi Failed");
        restartBLE();
    }
}
void restartBLE()
{
    BLEDevice::getAdvertising()->start();
    Serial.println("BLE restarted for new configuration");
}

String getBluetoothMacAddress()
{
    if (esp_bluedroid_get_status() == ESP_BLUEDROID_STATUS_ENABLED)
    {
        const uint8_t *mac = esp_bt_dev_get_address();
        char macStr[18];
        snprintf(macStr, sizeof(macStr), "%02X:%02X:%02X:%02X:%02X:%02X",
                 mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
        return String(macStr);
    }
    else
    {
        return "Bluetooth not initialized";
    }
}

// Connect to MQTT
void connectToMQTT()
{
    if (!wifiConnectedFlag)
    {
        Serial.println("Wi-Fi not connected. Cannot connect to MQTT.");
        return;
    }

    mqttClient.setServer(mqttBroker.c_str(), 1883);

    int mqttAttempts = 3;
    while (!mqttClient.connected() && mqttAttempts > 0)
    {
        Serial.println("Attempting to connect to MQTT...");
        Serial.print("Broker: ");
        Serial.println(mqttBroker);

        if (mqttClient.connect("ESP32Client"))
        {
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

            // Only send "Connected" if both WiFi and MQTT are connected
            sendStatusToApp("Connected");
            break;
        }
        else
        {
            Serial.print("Failed to connect to MQTT, rc=");
            Serial.println(mqttClient.state());

            // Send MQTT connection failure status
            sendStatusToApp("MQTT Failed");

            delay(5000);
            mqttAttempts--;
        }
    }

    // If MQTT connection fails after all attempts
    if (!mqttClient.connected())
    {
        Serial.println("MQTT Connection Failed");
        sendStatusToApp("MQTT Failed");
    }
}
/////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////

// MQTT Callback
void mqttCallback(char *topic, byte *payload, unsigned int length)
{
    String message;
    for (unsigned int i = 0; i < length; i++)
    {
        message += (char)payload[i];
    }

    Serial.print("Message received on topic ");
    Serial.print(topic);
    Serial.print(": ");
    Serial.println(message);
    /////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////

    if (String(topic) == mqttTopic1)
    {
        if (message == "ON")
        {
            digitalWrite(LED_PIN_1, HIGH);
            Serial.println("LED 1 turned ON via MQTT");
        }
        else if (message == "OFF")
        {
            digitalWrite(LED_PIN_1, LOW);
            Serial.println("LED 1 turned OFF via MQTT");
        }
    }
    else if (String(topic) == mqttTopic2)
    {
        if (message == "ON")
        {
            digitalWrite(LED_PIN_2, HIGH);
            Serial.println("LED 2 turned ON via MQTT");
        }
        else if (message == "OFF")
        {
            digitalWrite(LED_PIN_2, LOW);
            Serial.println("LED 2 turned OFF via MQTT");
        }
    }
    else if (String(topic) == mqttTopic3)
    {
        if (message == "ON")
        {
            digitalWrite(LED_PIN_3, HIGH);
            Serial.println("LED 3 turned ON via MQTT");
        }
        else if (message == "OFF")
        {
            digitalWrite(LED_PIN_3, LOW);
            Serial.println("LED 3 turned OFF via MQTT");
        }
    }
    else if (String(topic) == mqttTopic4)
    {
        if (message == "ON")
        {
            digitalWrite(LED_PIN_4, HIGH);
            Serial.println("LED 4 turned ON via MQTT");
        }
        else if (message == "OFF")
        {
            digitalWrite(LED_PIN_4, LOW);
            Serial.println("LED 4 turned OFF via MQTT");
        }
    }
    else
    {
        Serial.println("Message on unrelated topic.");
    }
}
/////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////

// BLE Callbacks
class ConfigCallbacks : public BLECharacteristicCallbacks
{
    void onWrite(BLECharacteristic *characteristic) override
    {
        auto valueRaw = characteristic->getValue();
        String jsonString = String(valueRaw.c_str());
        Serial.println("Received JSON: " + jsonString);

        StaticJsonDocument<256> jsonDoc;
        DeserializationError error = deserializeJson(jsonDoc, jsonString);

        if (error)
        {
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

void setup()
{
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
    server = BLEDevice::createServer();
    BLEService *service = server->createService(SERVICE_UUID);

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

    // Set server callbacks for connection events
    server->setCallbacks(new MyServerCallbacks());

    // Ensure advertising starts with connection callbacks
    BLEDevice::getAdvertising()->start();

    // Configure BLE advertising parameters for better stability
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->setMinInterval(160); // Minimum advertising interval
    pAdvertising->setMaxInterval(320); // Maximum advertising interval

    // Remove non-standard advertisement type
    // pAdvertising->setAdvertisementType(BLE_GAP_CONN_MODE_UND);

    // Set TX power to improve range and stability
    esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_DEFAULT, ESP_PWR_LVL_P9);
    esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_ADV, ESP_PWR_LVL_P9);
    esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_SCAN, ESP_PWR_LVL_P9);

    // Ensure advertising is started with default connectable mode
    pAdvertising->start();
}
/////////////////////////////////////////////////////////////////////////////////chage to if added new deviice  ////////////////////////////////////////////////////////////////////

void loop()
{
    // Existing loop code with additional stability checks
    if (!deviceConnected && oldDeviceConnected)
    {
        delay(500); // Give Bluetooth stack time to reset
        BLEDevice::getAdvertising()->start();
        Serial.println("Restarting BLE advertising");
        oldDeviceConnected = deviceConnected;
    }

    // Periodic connection health check
    static unsigned long lastConnectionCheck = 0;
    if (millis() - lastConnectionCheck > 60000) // Check every minute
    {
        if (!deviceConnected)
        {
            Serial.println("No active connection. Ensuring advertising.");
            BLEDevice::getAdvertising()->start();
        }
        lastConnectionCheck = millis();
    }

    // Existing loop logic
    if (credentialsReceived)
    {
        credentialsReceived = false;
        connectToWiFi();
        delay(2000);
        connectToMQTT();
    }

    if (mqttClient.connected())
    {
        mqttClient.loop();
    }

    monitorWiFiStatus();

    delay(1000);
}
