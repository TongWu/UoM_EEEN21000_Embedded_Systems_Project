//
// Created by T.Wu on 2021/4/13.
//
#include "Arduino.h"
#include "MotorDriver.h"
#include "ReflectanceSensor.h"
#include "Encoder.h"

// Define the global variable for motors
int motR_pins[3] = {4, 15, 18};
int motR_sign = -1;

int motL_pins[3] = {2, 12, 0};
int motL_sign = 1;

double w_max = 13.8735;

double wR_desired = 7;
double wL_desired = 7;
double wR_desired_temp = wR_desired;
double wL_desired_temp = wL_desired;
double wR_cutoff = wR_desired + 2;
double wL_cutoff = wL_desired + 2;

// Define the global variable for sensor
uint8_t SensorCount = 6;                                  // Number of refectance sensors
uint8_t SensorPins[6] = {23, 22, 19, 27, 25, 32};         // Sensor pins
uint32_t Timeout = 2500;                                  // Sensor reflect timeout (us)

// Define global configuartion of loop
int finish_time=40;
double sampling_time_outer = 0.001;
double sampling_time_inner = 0.0001;

// Define the global variable for sensor readings
// Get total number of sensor
ReflectanceSensor sensor;
int sensor_count = sensor.GetSensorCount();

// Set up two objects for MotorDriver classes (Right and Left motor object)
MotorDriver R;
MotorDriver L;
// Set up sensor

// Set up encoder
Encoder encode_R(34,36);
Encoder encode_L(39,35);
// Set up Timer

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

void sensor_setup() {
    sensor.SetSensorPins(SensorPins,SensorCount);
    sensor.SetTimeout(Timeout);
    Serial.begin(115200);
}


// Checked

void ddss() 
{

}

class algorithm{
private:

    //Define PID constant, error value here
    double kp, ki, kd;
    double error, tot_error = 0, diff_error = 0, pre_error = 0;
    double PID_value, PID_backup;
    double sensor_output[7];
    double reflectance;
    double deaccelerate;
    int wR_desired, wL_desired;
    int count = 0;

public:
    //Constructor here
    algorithm(double P, double I, double D, double wR, double wL) : kp(P), ki(I), kd(D), wR_desired(wR), wL_desired(wL) {}

    // Algorithm calculation
    double cal()
    {
        sensor.ReadSensor();
        double reflectance_raw[sensor_count];
        double reflectance=0;
        double sensor_output[sensor_count+1];
        for(int i=0;i<sensor.GetSensorCount();i++)
        {
            // Calculate the reflectance raw, same as "reflectance_raw" in MATLAB
            reflectance_raw[i] = sensor.GetSensorValues(i);
            // Calculate the reflectance, same as "reflectance" in MATLAB
            // Assume the minimum reflectance is -1, produced by sensor_5 and sensor_6 reading are 500, all others are 2500
            // The calculated error_constant for sensor_1 is -15/48000, -9/48000 for sensor_2, ...
            reflectance += reflectance_raw[i] * ((-15/48000)+i*(6/48000));
        }
        
        /*
        if(sensor.GetSensorValues(4) == 500 || sensor.GetSensorValues(5) == 500)
            {error = 0;}
        else {error = abs(reflectance);} // Function readsensor() should be reflectance() in MATLAB
        */

        reflectance = sensor_output[sensor_count];
        error = reflectance;
        PID_value = kp * error + ki * tot_error + kd * diff_error;
        if(error==0)
        {PID_backup = PID_value;}
        pre_error = error;
        tot_error += error;
        diff_error = error - pre_error;

        // Main if statement, setting the speed of two wheels
        if(sensor.GetSensorValues(4) == 500 || sensor.GetSensorValues(5) == 500)
        {
            R.MotorWrite(wR_desired/w_max);
            L.MotorWrite(wL_desired/w_max);
            count = 0;
            error = 0;
        }
        else if(sensor.GetSensorValues(1) == 500 || sensor.GetSensorValues(2) == 500)
        {
            R.MotorWrite( ( (wR_desired/w_max) + PID_value )*0.7 );
            L.MotorWrite( ( (wL_desired/w_max) - PID_value )*0.7 );
            count = 0;
            error = abs(reflectance);
        }
        else if(sensor.GetSensorValues(3) == 500 || sensor.GetSensorValues(4) == 500)
        {
            R.MotorWrite((wR_desired/w_max)+PID_value);
            L.MotorWrite((wL_desired/w_max)-PID_value);
            count = 0;
            error = abs(reflectance);
        }
        else if(sensor.GetSensorValues(5) == 500 || sensor.GetSensorValues(6) == 500)
        {
            R.MotorWrite((wR_desired/w_max)-PID_value);
            L.MotorWrite((wL_desired/w_max)+PID_value);
            count = 0;
            error = abs(reflectance);
        }
        else if(sensor.GetSensorValues(7) == 500 || sensor.GetSensorValues(8) == 500)
        {
            R.MotorWrite( ( (wR_desired/w_max) - PID_value )*0.7 );
            L.MotorWrite( ( (wL_desired/w_max) + PID_value )*0.7 );
            count = 0;
            error = abs(reflectance);
        }
        else if(sensor.GetSensorValues(1) == 2500 && sensor.GetSensorValues(2) == 2500 && sensor.GetSensorValues(3) == 2500 && sensor.GetSensorValues(4) == 2500 && sensor.GetSensorValues(5) == 2500 && sensor.GetSensorValues(6) == 2500)
        {
            R.MotorWrite(wR_desired/w_max);
            L.MotorWrite(wL_desired/w_max);
            count += 1;
            error = abs(reflectance);
            /* If all sensors not above the line, using the PID_backup to read the last PID value, 
               according the last reading of two encoders to judge which turn should buggy make. */
            // Experimental
            /*
            if (encode_R.speed()>encode_L.speed()) // When the buggy wants to turn right
            {
                R.MotorWrite( ( (wR_desired/w_max) + PID_backup );
                L.MotorWrite( ( (wL_desired/w_max) - PID_backup );
            }
            else if (encode_R.speed()<encode_L.speed())
            {
                R.MotorWrite( ( (wR_desired/w_max) - PID_backup );
                L.MotorWrite( ( (wL_desired/w_max) + PID_backup );
            }
            else
            {
                R.MotorWrite(wR_desired/w_max);
                L.MotorWrite(wL_desired/w_max);
            }
            */
        }
        // Line Break and Final Point slow down
        // Experimental
        if (millis()<15000)
        {
          if (count>=20 && count<170)
          {
            deaccelerate = (150-count)/100;
            R.MotorWrite((wR_desired/w_max)*deaccelerate);
            L.MotorWrite((wL_desired/w_max)*deaccelerate);
          }
        }
        else if (millis()>15000 && millis()<50000 && count>10)
        {
          R.MotorWrite(1);
          L.MotorWrite(-1);
        }
        else if (millis()>50000 && count > 10)
        {
          R.MotorWrite(0);
          L.MotorWrite(0);
        }
    }
};

/*
void main_control() {
    // Using For loop nesting to achieve inner loop and outer loop
    double dt;
    time.start();
    t_outer_loop.start();
    if (time.read() < finish_time)
    {
        // toc
        dt = t_outer_loop.read();
        if (dt > sampling_time_outer)
        {
            // Re-tic t_outer_loop
            t_outer_loop.reset();
            t_outer_loop.start();
            PID_outer.cal();
        }
        dt = t_inner_loop.read();
        if (dt > sampling_time_inner)
        {
            t_inner_loop.reset();
            t_inner_loop.start();
            if (encode_R.speed()>wR_cutoff && encode_L.speed()>wL_cutoff)
            {
                wR_desired = 0;
                wL_desired = 0;
            }
            else if(encode_R.speed()<4 && encode_L.speed()<4)
            {
                wR_desired = w_max;
                wL_desired = w_max;
            }
            else 
            {
                wR_desired = wR_desired_temp;
                wL_desired = wL_desired_temp;
            }
        }
    }
}
*/
void setup()
{
    motor_setup();
    sensor_setup();
}

void terminate()
{
    R.MotorWrite(0);
    L.MotorWrite(0);
}
void loop() {

    algorithm PID_outer(0.3, 0.01, 0.15, wR_desired, wL_desired);

    // main_control();
    PID_outer.cal();

    // Detecting whether is goes up or down a slope
    if(encode_R.GetEncoder()>wR_cutoff && encode_L.GetEncoder()>wL_cutoff)
    {
      R.MotorWrite(0);
      L.MotorWrite(0);
    }
    else if(encode_R.GetEncoder()<4 && encode_L.GetEncoder()<4)
    {
      R.MotorWrite(1);
      L.MotorWrite(1);
    }
    else 
    {
     wR_desired = wR_desired_temp;
     wL_desired = wL_desired_temp;
    }
    delay(10);
}
