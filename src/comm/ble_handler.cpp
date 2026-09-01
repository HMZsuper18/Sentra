#include "comm/ble_handler.h"
#include "comm/wifi_manager.h"
#include "storage/preferences_store.h"
#include "display/display.h"
#include "control/command_parser.h"
#include "control/motor_driver.h"
#include "config.h"
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

bool bleConnected = false;
extern String currentErrors;

static BLEServer* pServer = nullptr;
static BLEService* pService = nullptr;
static BLECharacteristic* pWifiNameChar = nullptr;
static BLECharacteristic* pWifiPassChar = nullptr;
static BLECharacteristic* pBoardNameChar = nullptr;
static BLECharacteristic* pErrorsChar = nullptr;
static BLECharacteristic* pDebugChar = nullptr;
static BLECharacteristic* pVoiceCmdChar = nullptr;
static BLECharacteristic* pVoiceRespChar = nullptr;

class ServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        bleConnected = true;
        Serial.println("App connected via BLE");
        pushStatus("App Connected");
    }
    void onDisconnect(BLEServer* pServer) {
        bleConnected = false;
        Serial.println("App disconnected via BLE");
        pushStatus("Ready");
    }
};

class WifiNameCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pChar) {
        String newSsid = pChar->getValue().c_str();
        if (newSsid.length() > 0) {
            setStoredSsid(newSsid);
            Serial.print("WiFi SSID updated: ");
            Serial.println(newSsid);
            pushStatus("WiFi Updated");
        }
    }
};

class WifiPassCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pChar) {
        String newPass = pChar->getValue().c_str();
        if (newPass.length() > 0) {
            setStoredPassword(newPass);
            Serial.print("WiFi Password updated: ");
            Serial.println(newPass);
            pushStatus("WiFi Updated");
            connectToWifi();
        }
    }
};

class BoardNameCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pChar) {
        String newName = pChar->getValue().c_str();
        if (newName.length() > 0) {
            setBoardName(newName);
            Serial.print("Board Name updated: ");
            Serial.println(newName);
        }
    }
};

class VoiceCmdCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pChar) {
        String cmd = pChar->getValue().c_str();
        if (cmd.length() > 0) {
            Serial.print("Voice command received: ");
            Serial.println(cmd);
            pushStatus("Processing...");
            handleVoiceCommand(cmd);
        }
    }
};

String buildSystemPrompt() {
    return "You are a robot controller for a 4-wheel robot with motors 1-4 and an OLED display. "
           "Output ONLY valid JSON without any markdown, extra text, or formatting. "
           "JSON structure: {\"reply\":\"Egyptian Arabic response\",\"motors\":{\"motor_1\":\"forward 5|backward 3|left|right|stop\",\"motor_2\":\"...\",\"motor_3\":\"...\",\"motor_4\":\"...\"},\"oled\":\"Status: ... | BLE: Connected\"}. "
           "Motor commands: \"forward N\" (N seconds), \"backward N\", \"left\" (turn left 1s), \"right\" (turn right 1s), \"stop\". "
           "Keep reply concise in Egyptian Arabic. OLED must show movement status and BLE connection.";
}

String callOpenRouterAPI(const String& userText) {
    if (WiFi.status() != WL_CONNECTED) {
        currentErrors = "E006";
        return "";
    }

    HTTPClient http;
    http.setTimeout(15000);
    http.begin("https://openrouter.ai/api/v1/chat/completions");
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "Bearer " + String(OPENROUTER_API_KEY));
    http.addHeader("HTTP-Referer", "https://github.com/sentra-robot");
    http.addHeader("X-Title", "Sentra Robot");

    StaticJsonDocument<1024> doc;
    doc["model"] = "deepseek/deepseek-chat";
    doc["max_tokens"] = 200;
    doc["temperature"] = 0.1;
    
    JsonArray messages = doc.createNestedArray("messages");
    JsonObject sysMsg = messages.createNestedObject();
    sysMsg["role"] = "system";
    sysMsg["content"] = buildSystemPrompt();
    
    JsonObject userMsg = messages.createNestedObject();
    userMsg["role"] = "user";
    userMsg["content"] = userText;

    String requestBody;
    serializeJson(doc, requestBody);

    int httpCode = http.POST(requestBody);
    String response = "";
    
    if (httpCode > 0) {
        response = http.getString();
        Serial.printf("OpenRouter HTTP %d: %s\n", httpCode, response.c_str());
    } else {
        Serial.printf("OpenRouter HTTP error: %s\n", http.errorToString(httpCode).c_str());
        currentErrors = "E007";
    }
    
    http.end();
    return response;
}

void parseAndExecuteJSON(const String& jsonStr) {
    StaticJsonDocument<1024> doc;
    DeserializationError err = deserializeJson(doc, jsonStr);
    
    if (err) {
        Serial.print("JSON parse error: ");
        Serial.println(err.c_str());
        currentErrors = "E008";
        return;
    }

    const char* reply = doc["reply"] | "تم";
    JsonObject motors = doc["motors"];
    const char* oled = doc["oled"] | "Ready | BLE: Connected";

    pushStatus(oled);

    if (motors) {
        for (int i = 1; i <= 4; i++) {
            String key = "motor_" + String(i);
            const char* motorCmd = motors[key] | "stop";
            String cmdStr = motorCmd;
            cmdStr.trim();
            
            unsigned long duration = 0;
            if (cmdStr.startsWith("forward")) {
                int spaceIdx = cmdStr.indexOf(' ');
                if (spaceIdx > 0) {
                    duration = cmdStr.substring(spaceIdx + 1).toInt() * 1000;
                } else {
                    duration = MOTOR_DURATION_MOVE;
                }
                switch (i) {
                    case 1: pushMove(moveForward, duration); break;
                    case 2: pushMove(moveForward, duration); break;
                    case 3: pushMove(moveForward, duration); break;
                    case 4: pushMove(moveForward, duration); break;
                }
            } else if (cmdStr.startsWith("backward")) {
                int spaceIdx = cmdStr.indexOf(' ');
                if (spaceIdx > 0) {
                    duration = cmdStr.substring(spaceIdx + 1).toInt() * 1000;
                } else {
                    duration = MOTOR_DURATION_MOVE;
                }
                switch (i) {
                    case 1: pushMove(moveBackward, duration); break;
                    case 2: pushMove(moveBackward, duration); break;
                    case 3: pushMove(moveBackward, duration); break;
                    case 4: pushMove(moveBackward, duration); break;
                }
            } else if (cmdStr == "left") {
                if (i == 1 || i == 2) pushMove(turnLeft, MOTOR_DURATION_TURN);
                else pushMove(turnRight, MOTOR_DURATION_TURN);
            } else if (cmdStr == "right") {
                if (i == 1 || i == 2) pushMove(turnRight, MOTOR_DURATION_TURN);
                else pushMove(turnLeft, MOTOR_DURATION_TURN);
            } else if (cmdStr == "stop") {
                // Will be handled by stopMotors if all are stop
            }
        }
    }

    if (moveQueueLen > 0) {
        runNextMove();
    } else {
        stopMotors();
        motorRunning = false;
    }
    
    pushMotorStates();

    if (pVoiceRespChar && bleConnected) {
        StaticJsonDocument<512> respDoc;
        respDoc["reply"] = reply;
        respDoc["oled"] = oled;
        String respStr;
        serializeJson(respDoc, respStr);
        pVoiceRespChar->setValue(respStr.c_str());
        pVoiceRespChar->notify();
        Serial.print("Sent response: ");
        Serial.println(respStr);
    }
}

void handleVoiceCommand(const String& cmd) {
    currentErrors = "";
    String response = callOpenRouterAPI(cmd);
    
    if (response.length() > 0) {
        StaticJsonDocument<1024> doc;
        DeserializationError err = deserializeJson(doc, response);
        
        if (!err) {
            const char* content = doc["choices"][0]["message"]["content"] | "";
            if (strlen(content) > 0) {
                parseAndExecuteJSON(content);
            } else {
                currentErrors = "E009";
            }
        } else {
            currentErrors = "E008";
        }
    }
}

void initBLE() {
    String boardName = getBoardName();
    BLEDevice::init(boardName.c_str());
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    pService = pServer->createService(SERVICE_UUID);

    pWifiNameChar = pService->createCharacteristic(
        CHAR_WIFI_NAME,
        BLECharacteristic::PROPERTY_WRITE
    );
    pWifiNameChar->setCallbacks(new WifiNameCallbacks());
    pWifiNameChar->setValue("");

    pWifiPassChar = pService->createCharacteristic(
        CHAR_WIFI_PASS,
        BLECharacteristic::PROPERTY_WRITE
    );
    pWifiPassChar->setCallbacks(new WifiPassCallbacks());
    pWifiPassChar->setValue("");

    pBoardNameChar = pService->createCharacteristic(
        CHAR_BOARD_NAME,
        BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_READ
    );
    pBoardNameChar->setCallbacks(new BoardNameCallbacks());
    pBoardNameChar->setValue(boardName.c_str());

    pErrorsChar = pService->createCharacteristic(
        CHAR_ERRORS,
        BLECharacteristic::PROPERTY_READ
    );
    pErrorsChar->setValue("OK");

    pDebugChar = pService->createCharacteristic(
        CHAR_DEBUG,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    pDebugChar->setValue("");
    pDebugChar->addDescriptor(new BLE2902());

    pVoiceCmdChar = pService->createCharacteristic(
        CHAR_VOICE_CMD,
        BLECharacteristic::PROPERTY_WRITE
    );
    pVoiceCmdChar->setCallbacks(new VoiceCmdCallbacks());
    pVoiceCmdChar->setValue("");

    pVoiceRespChar = pService->createCharacteristic(
        CHAR_VOICE_RESP,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    pVoiceRespChar->setValue("");
    pVoiceRespChar->addDescriptor(new BLE2902());

    pService->start();

    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(pService->getUUID());
    pAdvertising->setScanResponse(true);
    pAdvertising->start();

    Serial.println("BLE started, waiting for app connection...");
    pushStatus("BLE Ready");
}

void updateBLEInfo() {
    if (!bleConnected) return;

    String boardName = getBoardName();
    pBoardNameChar->setValue(boardName.c_str());
    pErrorsChar->setValue(currentErrors.isEmpty() ? "OK" : currentErrors.c_str());

    String debugInfo = "IP:" + WiFi.localIP().toString();
    debugInfo += "|RSSI:" + String(WiFi.RSSI());
    debugInfo += "|Mem:" + String(ESP.getFreeHeap());
    debugInfo += "|Uptime:" + String(millis() / 1000);
    pDebugChar->setValue(debugInfo.c_str());
    pDebugChar->notify();
}