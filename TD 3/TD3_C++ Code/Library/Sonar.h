#ifndef Sonar_h
#define Sonar_h
#include "Arduino.h"

class Sonar
{
    private:
    uint8_t SonarPin;
    uint8_t SonarSign;
    double distance;
    double duration;

    public:
    Sonar(int pin) {SonarPin = pin;}

    double GetDistance() 
    {
        pinMode(SonarPin, OUTPUT);
        // Turn on the Sonar
        digitalWrite(SonarPin, HIGH);
        // Delay for specific time
        delay(20);
        // Close the sonar
        digitalWrite(SonarPin, LOW);
        pinMode(SonarPin, INPUT);
        duration = pulseIn(SonarPin, HIGH);
        // 3.4029 for sonic speed, 0.02 for delay time
        distance = duration*3.4029/0.02;
        return distance;
    }
};

#endif