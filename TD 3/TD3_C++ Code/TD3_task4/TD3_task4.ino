//
// Created by T.Wu on 2021/4/17.
//
#include "Arduino.h"
#include "Encoder.h"
#include "MotorDriver.h"
#include "ReflectanceSensor.h"
#include "Sonar.h"
#include "ESP32Servo.h"

// Initiallise parameter
    // Set up motor
    MotorDriver R;
    MotorDriver L;
    int motR_pins[3] = {4, 15, 18};
    int motR_sign = -1;
    int motL_pins[3] = {2, 12, 0};
    int motL_sign = 1;
    // Set up sonar
    Sonar sonar(14);
    // Set up encoder
    Encoder encode_R(34,36);
    Encoder encode_L(39,35);
    // Set up servo motor
    Servo servo;
    int servo_pin = 5;
    float sonar_angle = 90;
    // Set up global variable
    double w_max = 13.8375;

void motor_setup() {
    //Set up the Motors
    //Setup the Right Motor object
    R.SetBaseFreq(5000);                                             //PWM base frequency setup
    R.SetSign(motR_sign);                                            //Setup motor sign
    R.DriverSetup(motR_pins[0], 0, motR_pins[1], motR_pins[2]);      //Setup motor pins and channel
    R.MotorWrite(0);                                                 //Write 0 velocity to the motor when initialising

    //Setup the Left Motor object
    L.SetBaseFreq(5000);
    L.SetSign(motL_sign);
    L.DriverSetup(motL_pins[0], 1, motL_pins[1], motL_pins[2]);
    L.MotorWrite(0);

    //Begin Serial Communication
    Serial.begin(115200);
}

void servo_setup()
{
    servo.attach(servo_pin);
    // Set sonar angle to 90 degrees
    servo.write(90);
}

double sonar_detect()
{
    double distance = sonar.GetDistance();
    return distance;
}

class algorithm{
private:
    int wR_desired, wL_desired;
    double sonar_distance;
public:
    //Constructor here
    algorithm(double wR, double wL) : wR_desired(wR), wL_desired(wL) {}

    // Algorithm calculation
    double cal()
    {
        // Scanning the wall to get the error
        sonar_distance = sonar_detect();
        if(sonar_distance>2 && sonar_angle==90)
        {
            servo.write(180);
        }
        else if(sonar_distance>2 && sonar_angle==180)
        {
            servo.write(90);
        }

        // Main control
        if(sonar_distance>2 && sonar_angle==90)
        {
            if(sonar_distance<1)
            {
                R.MotorWrite((wR_desired - (1-sonar_distance)*4)/w_max);
                L.MotorWrite((wR_desired + (1-sonar_distance)*4)/w_max);
            }
            else
            {
                R.MotorWrite((wR_desired + (sonar_distance-1)*4)/w_max);
                L.MotorWrite((wR_desired - (sonar_distance-1)*4)/w_max);
            }
        }
        else if(sonar_distance>2 && sonar_angle==180)
        {
            if(sonar_distance<1)
            {
                R.MotorWrite((wR_desired + (1-sonar_distance)*4)/w_max);
                L.MotorWrite((wR_desired - (1-sonar_distance)*4)/w_max);
            }
            else
            {
                R.MotorWrite((wR_desired - (sonar_distance-1)*4)/w_max);
                L.MotorWrite((wR_desired + (sonar_distance-1)*4)/w_max);
            }
        }
    }
};

void setup()
{
    motor_setup();
    servo_setup();
}

void loop()
{
    algorithm BB_sonar(8, 8);
    BB_sonar.cal();
    delay(10);
}
