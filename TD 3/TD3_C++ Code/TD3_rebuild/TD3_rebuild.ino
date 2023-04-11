//
// Created by T.Wu on 2021/4/13.
//

/*
    4.20 UPDATE
    主程序按照MATLAB的逻辑结构基本编译完成，没有实车无法测试。

    4.24 UPDATE
    源程序Bug过多，一晚上修改也无法正常运行。需要重构。

    4.25 UPDATE:
    主程序重构已经完成，调控转向PID中的逻辑问题需解决。具体为：
        1. reflectance 变量的具体算法需要改善，当前reflectance的示数为临时修补的，可能可以正常用。
        2. 在跟随白线直行时，速度低于预期速度；但在转弯时的速度为预期速度。(direction_compensation函数); 且uL明显小于uR
        3. encoder.h 无法正常读取encoder RPM数值
    实地测试，爬坡测试，断线调头测试，声呐测试未完成。

    4.26 UPDATE
    3已解决。
*/

#include "Arduino.h"
#include "MotorDriver.h"
#include "ReflectanceSensor.h"
#include "Encoder.h"

// Setup Motor
int motR_pins[3] = {4, 15, 18};
int motR_sign = -1;

int motL_pins[3] = {2, 12, 0};
int motL_sign = 1;

double w_max = 13.8735;
double wR_desired = 7;
double wL_desired = 7;
double uR_desired = wR_desired/w_max;
double uL_desired = wL_desired/w_max;
    // Set up two objects for MotorDriver classes (Right and Left motor object)
    MotorDriver Mr;
    MotorDriver Ml;

// Setup sensor
uint8_t SensorCount = 6;                          // Number of refectance sensors
uint8_t SensorPins[6] = {23, 22, 19, 27, 25, 32}; // Sensor pins
uint32_t Timeout = 2500;                          // Sensor reflect timeout (us)
    // Setup object of sensor
    ReflectanceSensor sensor;

    //Setup object of encoder
    Encoder encode_R(34, 36);
    Encoder encode_L(39, 35);

// Main Setup function
void setup()
{
    //Set up the Motors
    //Setup the Right Motor object
    Mr.SetBaseFreq(5000);                                             //PWM base frequency setup
    Mr.SetSign(motR_sign);                                            //Setup motor sign
    Mr.DriverSetup(motR_pins[0], 0, motR_pins[1], motR_pins[2]);      //Setup motor pins and channel
    Mr.MotorWrite(0);                                                 //Write 0 velocity to the motor when initialising

    //Setup the Left Motor object
    Ml.SetBaseFreq(5000);
    Ml.SetSign(motL_sign);
    Ml.DriverSetup(motL_pins[0], 1, motL_pins[1], motL_pins[2]);
    Ml.MotorWrite(0);

    sensor.SetSensorPins(SensorPins,SensorCount);           // Set the sensor pins
    sensor.SetTimeout(Timeout);                             // Set sensor timeout (us)
  
    //Begin Serial Communication
    Serial.begin(115200);
}

//
//   **Initilliaze finished**
//

// Direction dynamic compensation function
double reflectance_cal()
{
    // Read sensor
    sensor.ReadSensor();
    double reflectance_raw[SensorCount];
    double reflectance = 0;
    // Define six error constant for each sensor
    double error_constant[6] = {-0.04, -0.02, -0.01, 0.01, 0.02, 0.04};
    for(int i=0; i< SensorCount-1; i++)
    {
        reflectance_raw[0+i] = sensor.GetSensorValues(i);
        // The reflectance should be Min. -10 and Max. 10
        reflectance += reflectance_raw[0+i] * error_constant[0+i];
    }
    // Quantumlise "reflectance" to range -13.8375 to 13.8375
    /*
    for(int i=0;i<sensor.GetSensorCount();i++)
      Serial.printf("%d ",sensor.GetSensorValues(i));
    Serial.println();
    */
   // Serial.println(reflectance/100+0.6);
   return abs(reflectance/100+0.6);
}

// Algorithm class for PID calculation
class algorithm
{
    private:
    double kp=0, ki=0, kd=0, tot_error=0, diff_error=0, pre_error=0;
    //double PID_backup;
    public:
    algorithm(double P, double I, double D) : kp(P), ki(I), kd(D) {}
    double PID_value;
    double cal(double error)
    {
        PID_value = kp * error + ki * tot_error + kd * diff_error;
        /*
            if (abs(error) < 0.2)
            {
                PID_value = PID_backup;
            }
        */
        diff_error = error - pre_error;
        pre_error = error;
        tot_error += error;
        //Serial.println(PID_value);
        return PID_value;
    }
};

// Create a struct to allows function to return multiple values
struct U_D
{
    double uR_D, uL_D;
// Create a sub named by u_d
} u_d;

// Create a function using and edit variables in structure U_D
struct U_D direction_compensation(double PID_value)
{
    sensor.ReadSensor();
    // For line break and end point detecting
    int count;
    // Core compensation algorithm
    if((sensor.GetSensorValues(0) < 550 && sensor.GetSensorValues(1) < 625))
    {
        u_d.uR_D = (uR_desired - PID_value) * 1.2;
        u_d.uL_D = (uL_desired + PID_value) * 1.2;
        count = 0;
    }
    else if(sensor.GetSensorValues(1) < 1000)
    {
        u_d.uR_D = uR_desired - PID_value;
        u_d.uL_D = uL_desired + PID_value;
        count = 0;
    }
    else if((sensor.GetSensorValues(2) < 880 && sensor.GetSensorValues(2) < 370 && sensor.GetSensorValues(2) > 900))
    {
        u_d.uR_D = uR_desired - PID_value;
        u_d.uL_D = uL_desired + PID_value;
        count = 0;
    }
    else if((sensor.GetSensorValues(2) < 900 && sensor.GetSensorValues(3) < 400))
    {
        u_d.uR_D = uR_desired;
        u_d.uL_D = uL_desired;
        count = 0;
    }
    else if((sensor.GetSensorValues(3) < 700 && sensor.GetSensorValues(4) < 450))
    {
        u_d.uR_D = uR_desired + PID_value;
        u_d.uL_D = uL_desired - PID_value;
        count = 0;
    }
    else if((sensor.GetSensorValues(4) < 900 && sensor.GetSensorValues(5) < 1000))
    {
        u_d.uR_D = uR_desired + PID_value;
        u_d.uL_D = uL_desired - PID_value;
        count = 0;
    }
    else if((sensor.GetSensorValues(5) < 800))
    {
        u_d.uR_D = (uR_desired + PID_value) * 1.2;
        u_d.uL_D = (uL_desired - PID_value) * 1.2;
        count = 0;
    }
    else if(sensor.GetSensorValues(0) > 1800 && sensor.GetSensorValues(1) > 1800 && sensor.GetSensorValues(2) > 1800 && 
            sensor.GetSensorValues(3) > 1800 && sensor.GetSensorValues(4) > 1800 && sensor.GetSensorValues(5) > 1800)
    // If all sensors are not above the line
    // Line break and ending point compensation
    {
        /*
        // Experimental
        // Portable
            u_d.uR_D = uR_desired;
            u_d.uL_D = uL_desired;
            count += 1;
            // If right encoder is bigger than left encoder
            // Which means the bot wants to make a left turn before lossing line.
            // So give bot a backup PID to finish it's long-cherished wish
            if (encode_R.GetEncoder() > encode_L.GetEncoder())
            {
                Mr.MotorWrite();
                Ml.MotorWrite();
            }
            else if(encode_R.GetEncoder() < encode_L.GetEncoder())
            {
                Mr.MotorWrite();
                Ml.MotorWrite();
            }
            else
            // If no difference between two encoders, detected as line break. Normal speed has been applied
            {
                u_d.uR_D = uR_desired;
                u_d.uL_D = uL_desired;
            }
        */
    }
    else{u_d.uR_D = uR_desired; u_d.uL_D = uL_desired;}
    /*
    // Line break and ending point slow down
    // Experimental
    // Portable
    if (count >= 20 && count < 170)
    {
        float deaccelerate = (170-count)/100;
        u_d.uR_D = uR_desired * deaccelerate;
        u_d.uL_D = uL_desired * deaccelerate;
    }
    else if(count >= 170)
    {
        //terminate();
    }
    */
    return u_d;
}

void speed_compensation(double PID_SpeedR, double PID_SpeedL)
{
    double uR, uL;
    uR = (uR_desired - PID_SpeedR);
    uL = (uL_desired - PID_SpeedL);
    Mr.MotorWrite(uR);
    Ml.MotorWrite(-uL);
    //Serial.printf("%f   %f", uR, uL);
    //Serial.println();
    uR=0;
    uL=0;
}

    //Create objects for calculating PID value and setup PID parameter
    algorithm PID_direction(0.3, 0, 0.15);
    algorithm PID_speedR(0.8, 0, 0.2);
    algorithm PID_speedL(0.8, 0, 0.2);

void loop()
{
 // Outer loop
    // Calling a function to calculate the reflectance
    // Same as reflectance in MATLAB
    // Store in reflectance
    double reflectance = reflectance_cal();
    // Transmit reflectance to PID calculation (Can using pointer)
    // Read PID value
    double PID_Direction = PID_direction.cal(reflectance);
    // Reset value in class
    PID_direction.PID_value=0;
    // Compensate the speed accoring to sensing line-sensor
    direction_compensation(PID_Direction);

 // Inner loop
        // Calculate speed error by differeneing the desired speed and encoder speed
        double Speed_ErrR = u_d.uR_D - encode_R.GetEncoder();
        double Speed_ErrL = u_d.uL_D - encode_L.GetEncoder();
        // Reset desired speed
        u_d.uR_D = 0;
        u_d.uL_D = 0;
        // Calculate PID value for speed control
        double PID_SpeedR = PID_speedR.cal(Speed_ErrR);
        // Reset PID value
        PID_speedR.PID_value=0;
        double PID_SpeedL = PID_speedL.cal(Speed_ErrL);
        PID_speedL.PID_value=0;
        // Compensate speed value by directly writting speed value to motor Pin
        speed_compensation(PID_SpeedR, PID_SpeedL);
        // Reset the encoder count
        //Serial.println(u_d.uR_D, u_d.uL_D);
        // Reset PID value for speed control
        PID_SpeedR = 0;
        PID_SpeedL = 0;
        // Read encoder count
        Serial.printf("%f,  %f", encode_L.GetEncoder(), encode_R.GetEncoder());
        Serial.println();
        // Reset encoder count value
        encode_L.count_zero();
        encode_R.count_zero();

    // Delay for 20ms
    delay(20);
}
