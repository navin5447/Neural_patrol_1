#include <Arduino.h>

const char* deviceName = "NP FIELD UNIT 01";
float currentTempC = 63.0f;
String processState = "AMPLIFICATION";
int progress = 78;

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("SpeciesTrace firmware booted");
  Serial.println("Device: NP FIELD UNIT 01");
}

void loop() {
  Serial.print("TEMP:");
  Serial.print(currentTempC);
  Serial.print("C STATE:");
  Serial.print(processState);
  Serial.print(" PROGRESS:");
  Serial.println(progress);

  currentTempC += 0.2f;
  if (currentTempC > 65.0f) {
    currentTempC = 62.0f;
  }

  if (progress < 100) {
    progress += 1;
  } else {
    progress = 78;
  }

  delay(2000);
}
