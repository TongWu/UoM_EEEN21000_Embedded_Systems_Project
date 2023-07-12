![](https://images.wu.engineer/images/2023/07/11/e14bcc9b09332ab5f6771ce87a3a6e62.png)

Embedded Systems Project 2020-21

DESIGN REPORT \#2

Title: Buggy design

Group Number: 37

| Group members:     | ID Number | I confirm that this is the group’s own work. |
|--------------------|-----------|----------------------------------------------|
| Marton Gonczy      | 10541775  | ☒                                            |
| Cavan Grant        | 10513220  | ☒                                            |
| ZhiYuan Zhu        | 10783135  | ☒                                            |
| Tong Wu            | 10497665  | ☒                                            |
| Abdulaziz Al-Madhi | 10444432  | ☒                                            |
| Bulei Sun          | 10465003  | ☒                                            |

Tutor: Wuqiang Yang

Date: 10/12/2020

Contents

[1. Introduction](#introduction)

2\. Software

3\. Line Sensor Characterisation

4\. Circuit diagram for proposed line sensors

5\. Non-line sensors

6\. Control

7\. Hardware overview

8\. Summary

9\. References

# Introduction

Design report 2 aims to describe how the buggy hardware and software will be implemented. The report consists of six parts which describe chassis design, control theory, software design, line and non-line sensors and their circuitry. These aspects are inevitable when designing a buggy and, therefore, this report is very important.

In the software design part, a high-level description of the buggy’s software is defined. Further on in the project this description will help to code the final program which will drive the buggy on the track. The key behaviours of the buggy there are described such as starting up the buggy, sensing the wall and following the line when the track is straight and when it turns. This part also contains case diagrams which visualise program code and show the connections between hardware components and how they interact with each other.

The second part in this report describes the characteristics of different line sensors and compares them with each other. This part is based on the data which was provided in the sensor lab of the Embedded System Project course module. It also describes how the experiments were made and this data was obtained. At the end of this part a line sensor is chosen for the buggy to use. The characteristics of this line sensor are used in other parts therefore it is important to obtain these correctly.

The third part strictly connects to the previous part as here the circuitry for the line sensors is created. Besides the resistors have to be calculated for the infrared LEDs and detectors, a control circuit has to be designed to switch individual sensors on as they cannot be switch on at the same time. Schematic diagram, PCB- layout diagram and a wiring connection diagram are made to show the circuit

The third part includes the non-line sensors. There are non-line sensors which are provided to the project such as encoders, battery monitors and motor current sensors. Further the group can choose other types of sensors if needed. The non-line sensor part discusses how the provided non-line sensors work how they can be used to calculate specified values. In terms of non-provided sensors, the section raises the question of other sensors to use them to sense other aspects of the track or the buggy.

The control part describes two types of control theory algorithms which are proportional and bang-bang theory and discusses the hardware implementation of motor control. It compares these two control algorithms with each other and chooses one for the project. It is important in this project to precisely design the control algorithm being the actual code will use this to drive the buggy through the track. If the control algorithm is wrongly implemented the buggy will not be as effective or even it will not be able to complete the track.

The final part of this report is the hardware overview which contains the design of the buggy’s chassis. It shows how individual particles will fit onto the chassis. The previous design report is strictly connected to this part as that report focused on gearbox selection. In the chassis design it is important to calculate the turning circle of that buggy by reason of the track has walls and if the chassis is not designed carefully the buggy might hit the walls when turning around. Likewise, the centre of gravity should be paid attention to when designing the chassis.

All these parts are the key elements of this project as connecting all the parts together determine the whole buggy and its behaviour on the track and in the race. Therefore, it is crucial for the team to work out and correctly design these aspects of the buggy. This design report gives the plan for the team how the code is written and how the buggy is constructed.

# Software

To begin creating a high-level description of the buggy’s software it’s functional requirements must be known. To achieve this the following functional summary was created, outlining the desired capabilities of the buggy:

-   When powered on the buggy will enter a sleep state for 2 minutes. Upon receiving a Bluetooth signal the buggy will search for the line beneath it, if the line is not found in 30 seconds it will broadcast an error signal. If no signal is received in 2 minutes buggy will shut down after broadcasting a corresponding error message.
-   Once the line is located the buggy will accelerate forwards up to a maximum speed which will be monitored by a control system of the motors with input from the encoders.
-   When the line sensors return that line has a turn an interrupt will trigger a turn protocol in the control of the motors Causing the buggy to turn.
-   If ultrasound sensor returns a signal that a wall is too close the buggy will slow down until the wall is safely avoided.
-   If Battery monitor Returns a low value a Bluetooth error will be signalled.
-   Upon receiving a Bluetooth interrupt signal sent by the user the buggy will stop in designated zone and make a 180-degree turn.
-   If the buggy loses the line for more than 30 seconds it will re-enter sleep state and send a corresponding error message.

Whilst completing software design to fit these functions the limitations from the hardware must be considered. The 2 constraints of the buggy found are shown below:

-   Memory- STM has a memory of approximately 512 kB
-   Control loop Frequency: must execute at 50 Hz, as at max speed the line may move from 1 sensor to another within approx. 20ms which corresponds to an update frequency of 50Hz

The constraint on the memory of the device is unlikely to have an impact on design as it is in great surplus for what will be required by the buggy’s system. However, the control frequency will need to be considered in the design by ensuring control loop functions are as time efficient as possible.

To begin the design of the software a context was created showing all the actors and the direction of dataflow between them and the system, shown in Figure 1:

![](https://images.wu.engineer/images/2023/07/11/d9a89ed1d290ae4be722e8698fcc31ef.png)

Figure 1

Table 1

![](https://images.wu.engineer/images/2023/07/11/055d5682d8697bab890b62cad446880c.png)

A detailed description of each message in the context diagram is shown in Table 1.

Using all the information above a use case diagram can be created, showing a high-level architecture of the buggy’s software and how each function interacts with actors and other functions, shown by Figure 2:

![](https://images.wu.engineer/images/2023/07/11/f8439a1f038097ba5f28795b9ab63ec6.png)

Figure 2

The State function is where the Start-up procedure and current state of the buggy is stored. State is stored as a compilation of different variables: if it is active, current location in comparison to the line, close to a wall, current battery level, to do a 180-degree turn or if an error has been encountered.

The line function processes the information from the line sensors and then outputs messages informing the state function if the buggy is following line and the current location of the line is sent to the control function when it is required.

The control Segment receives messages from the state function to determine what process is taking place: stopping, line following, slowing or 180-degree turn. In the default line-following mode it then uses line location messages directly from the line function to determine the speeds needing to be applied to each motor. To control each motor the control function sends a current message to each motor and monitors current speed from incoming encoder messages allowing for accurate control of each motor.

From the use case diagram, a draft of objects and their corresponding function prototypes can be created to be used in creation of the software:

The Motor Class will allow the user to set a PWM signal to operate the motor with set high and low time periods, as well as returning the current speed in form float of the motors to be used by control.

Motor:

void setPwm (High_period, Low_period);

float getSpeed ();

Control will inherit the motor class to allow it to control the motors. It will then have function. The 180° turn function will return a bool value of true once its completed the turn so State knows to continue. All other operation modes are void functions as they run indefinitely until interrupted.

Control: public Motor

bool180 turn ();

void Stop ();

Void Linefollow (Line_Location);

Void Wall ();

A Bluetooth Class will allow for a connection to be made and for signals to be sent and received through this connection. Connection will be setup done upon initialisation of the object. The send function will allow for an error message to be sent and received will upon an interrupt trigger of a received signal store the sent message to be accessed by the system.

Bluetooth

Void Send (error);

Int Received ();

The line sensor Class will allow the LED of each sensor par to be toggled on and the value to be read and then return a bool value for if the line is under that line.

Line Sensor

Void toggle ();

Bool sense ();

The Sensor array will inherit the Line sensor class to allow it to control and access all the line sensors. The bool on line function will be run to check if it is on the line and Line_Location will return an int value corresponding to which sensor the line is under.

Sensor Array: public Sensor

Int Line_Location ();

bool On_Line ();

The ultrasonic sensor will be capable of returning a float value of distance to the wall and a Boolean value f or if it is within an arbitrary certain distance

Ultrasonic

Float distance();

Bool near();

The Battery object will be able to return the Current int percentage ‘charge’ of the battery.

Battery

Int getPercent();

# Line Sensor Characterisation

In this section, the data of the electronic components for detecting the white line position are compared and the characteristics of the sensors that may be selected are summarised and compared to help select the correct set of electronic components. Several groups of transmitters and receivers are paired. In addition, errors and accidents and their solutions are summarized.

In the experiment, the TCRT5000 - LED / Opto-transistor and LED / LDR sensors are used. The sensitivity of TCRT5000 is observed by changing the horizontal orientation and the distance between the sensor and the surface. During the experiment, the resistance of the LED was 160 ohms, the resistance of the Opto-transistor was 5k6 ohms, the resistance of the LDR was 1K ohms,The height measurement error is + / - 1.5 mm, the scope accuracy is + / - 0.08 V, and the gap measurement error is + / - 1 mm.

Table 2

| Height (cm) | Voltage (V)  |
|-------------|--------------|
|  0          | 4.2          |
| 0.1         | 3.9          |
| 0.2         | 0.3          |
| 0.3         | 0.3          |
| 0.4         | 0.3          |
| 0.5         | 0.6          |

In Experiment 1 (Table 2), the relation between the sensitivity of TCRT5000 and height is obtained. Tcrt5000 - LED / Opto-transistor are aligned along the white line (normal buggy configuration). Table 1 showed the variation of voltage with the change of optical sensor height. The sensor was slowly raised from 0 cm to 1 cm, and the voltage was recorded at every 0.1 cm. It can be seen from the chart that the voltage drops slowly from the beginning. When the height reaches 0.2 cm, the voltage drops suddenly to 0.3 V, and maintains at 0.3V until the height reaches 0.5 cm. From 0.5 cm, the voltage increases with the rise of height. The final value is 3.1 V when the height reaches 1cm.

|       |  Gap (mm)   |     |     |     |     |
|-------|-------------|-----|-----|-----|-----|
| x(cm) | 0.5         | 5   | 10  | 15  | 19  |
| -3    | 4.7         | 4.7 | 4.9 | 4.9 | 5   |
| -2.5  | 4.8         | 4.7 | 4.9 | 4.9 | 5   |
| -2    | 4.7         | 4.7 | 4.9 | 4.9 | 5   |
| -1.5  | 4.7         | 4.7 | 4.8 | 4.8 | 5   |
| -1    | 4.7         | 3.4 | 4.1 | 4.5 | 4.7 |
| -0.75 | 2.7         | 1.2 | 3.4 | 4.3 | 4.5 |

|       | Gap (mm) |     |     |     |     |
|-------|----------|-----|-----|-----|-----|
| x(cm) | 0.5      | 5   | 10  | 15  | 19  |
| -3    | 4.7      | 4.7 | 4.9 | 4.9 | 5   |
| -2.5  | 4.7      | 4.7 | 4.9 | 4.9 | 5   |
| -2    | 4.7      | 4.7 | 4.9 | 4.9 | 5   |
| -1.5  | 4.7      | 4.7 | 4.7 | 4.8 | 4.9 |
|  -1   | 4.3      | 3.5 | 4.3 | 4.6 | 4.7 |
| -0.75 | 2.3      | 2   | 3.6 | 4.3 | 4.6 |

In the second group of experiments (Table3) (Table4), the sensors were placed in different orientations, and moved across the white line at different heights to observe the sensitivity of TCRT5000. From the table comparison, it can be seen that the orientation of the sensors has very little to no effect on the sensitivity, and the two groups of values are similar. When the offline height of sensor is 5 mm, the discrepancy between the values is the largest, in other words, it is the most sensitive. However, when this value is 19 mm, the change of voltage is the minimum.

Table 5

|       |  Gap (mm) |     |     |     |     |
|-------|-----------|-----|-----|-----|-----|
| x(cm) | 1         | 6   | 11  | 16  | 21  |
| -3    | 2         | 2   | 2.1 | 2.2 | 2.2 |
| -2.5  | 2         | 2   | 2   | 2.2 | 2.2 |
| -2    | 2         | 2   | 2.1 | 2.1 | 2.2 |
| -1.5  | 1.9       | 2   | 2.1 | 2.2 | 2.2 |
| -1    | 1.6       | 1.8 | 2   | 2   | 2.1 |
| -0.75 | 1.32      | 1.5 | 2   | 2   | 2   |

Table 5 shows the values of Experiment 3 which is repeating Experiment 2 with another LDR (VT90N2), thus comparing the sensitivity of this sensor with TCRT5000 (Table 3 and 4). The sensor is aligned along the white line (normal buggy configuration). It can be seen from the table that the smaller the distance from the surface is the more sensitive the sensors are. But the magnitude of the change is not as dramatic as that of TCRT5000. It can be concluded that the performance of TCRT5000 is better than that of VT90N2.

Table 6 [1]

| Detector               | BPW17N     | TEKT5400S  | TCRT5000 |     |
|------------------------|------------|------------|----------|-----|
| Peak current(mA)       | 100        | 200        | 100      |     |
| Suggested current(mA)  | 50         | 100        | /        |     |
| Optimal wavelength(nm) | 825        | 920        | /        |     |
| Spectral range         | 620 to 960 | 850 to 980 | /        |     |
| Half angle(deg)        | ± 12       | ± 37       | /        |     |
| Turn-on time (μs)      | 4.8        | 6          | /        |     |
| Dark current(nA)       | Max        | 200        | 100      | 200 |
|                        | Typ.       | 1          | 1        | 10  |

Table 7 [1]

| \`Emitting Diode/LED lamp | Suggested forward current(mA) | Radiant power(mW) | Peak wavelength(nm) | Half angle(deg) | Rise time(ns) |
|---------------------------|-------------------------------|-------------------|---------------------|-----------------|---------------|
| OVL-5521                  | 20                            | /                 | /                   | ±15             | /             |
| SFH203P                   | /                             | /                 | 850                 | ±75             | 5             |
| SFH203PFA                 | /                             | /                 | 900                 | ±75             | 5             |
| OPE5685                   | 50                            | /                 | 850                 | ±22             | 25            |
| TSHA6203                  | 100                           | /                 | 875                 | ±12             | 600           |
| TSKS5400S                 | 50                            | 10                | 950                 | ±30             | 800           |
| TCRT5000                  | 60                            | /                 | 940                 | /               | /             |

Table 6 is a comparison of possible transistors and their important parameters.

\-BPW17N has a narrow viewing angle and a wider spectrum bandwidth. It is suitable for receiving visible light and near-infrared radiation. The range of the received signal is limited, but it is not sensitive to background light.

\-TEKT5400S has narrow range of spectrum bandwidth and a wide receiving angle. It has side view lens, high radial sensitivity, and fast response time. The daylight blocking filter matched with 940 nm emitters However, TEKT5400S can receive fewer kinds of waves.

\-The detector part of TCRT5000 contains a daylight blocking filter. It has been paired and assembled with an emitter to receive a fixed wavelength of 950nm. It has lower power and larger maximum and typical dark current.

Table 7 shows and compares the possible emitting diode / LED lamp and their important parameters.

\-OVL-5521 has high luminous output and water clear lens, smaller suggested current, and a narrower viewing angle.

\-The values of SFH203P and SFH203PFA are similar. SFH203P has a wider spectral bandwidth, and both have relatively wide half angle and short switching time.

\-With high speed (25 ns rise time), wide beam angle, low forward voltage, high power, and high reliability. OPE5685 can be used for pulse operation.

\-TSHA6203 has low forward voltage, narrow half angle, low speed. It is suitable for high pulse current operation.

\-TSKS5400s is equipped with side view lens, low forward voltage and features of high reliability, high radial power. It is suitable for high pulse current operation.

\-TCRT5000 is equipped with a designated phototransistor, which emits 950nm fixed wavelength signal, which is more convenient.

When the receiver and transmitter are paired, on the basis of ensuring that the transmitted wave can be correctly received by the transistor, it is also necessary to ensure that the waveform of peak sensitivity is appropriate as far as possible. Then the most suitable four groups of photo transformer and emitter (including TCRT5000 already matched) are selected. BPW17N can match SFH203P and OPE5685. TEKT5400s can be paired with SFH203PFA, and the matched TCRT5000.

If the sensor works under the condition of direct sunlight or serious influence of background light, BPW17N and TCRT5000 should be selected as far as possible. If there is a problem like line breaks, the sensor can be stopped to ensure that the car will not get into chaos, and the sensor will not continue to work until the white line reappears.

Through the comparison and summary, we decided to adopt TCRT5000. The TCRT5000 has a daylight blocking filter, which is very sensitive. Wavelength does not need to be considered as it does not matter if it matches or not.

# Circuit diagram for proposed line sensors

![](https://images.wu.engineer/images/2023/07/11/4facd8911484056593457701f903f410.png)

![](https://images.wu.engineer/images/2023/07/11/f991e168270346b4262cc4bc16b4dfb7.png)![](https://images.wu.engineer/images/2023/07/11/803b62e0ff55188ad4cefcfe6819123f.png)Figure 3

The pictures above are the schematic diagram, PCB-layout diagram and wiring connection diagram, which show how the project will demonstrate the PCB on the buggy and the connection between those components.

I found it very useful to look up the Altium Designer website [2] to learn how to create a schematic diagram and PCB. Under the guidance of it, as shown on the first picture, there are 6 TCRT5000 sensors on the top left corner. TCRT5000 sensor consists of two components, one is an infrared LED which emits 940-950 nm wavelength of electromagnetic wave, the other is a phototransistor which will produce current when photoelectron is hitting the transistor. All LEDs are connected to VDD, the power supply, and in series with a resistor which is about 180 ohms. Due to the maximum current that the LED can undertake is 60 mA and power dissipation is 100 mW, with 5-volt power supply and forward voltage typically lies between 1.25-1.5 V, the resistor should be configured to ensure not overloading the led.

(1)

Therefore, we set the voltage to be 1.4 which is the average of the typical value and assume current to be 20 mA, 40 mA, 60 mA. Finally, the resistor should be 180 ohms, 90 ohms and 60 ohms separately result from Equation 1. According to the experimental measurement condition used in the sensor characterization, the 180 ohms resistor was chosen to use finally. As for transistor resistor, the is 0.4 V and with ranges from 0.001 A, 0.0005 A to 0.0002 A. The transistor resistor varies from 4600 ohms, 9200 ohms to 23000 ohms according to Equation 2.

(2)

As well as the led resistor, 5600 ohms resistor was used in series with the transistor, and current was 0.8213 mA correspondingly. To indicate which sensor is working, we still need a RLD which consists of a visible led and a current limitation resistor for each infrared led which is right below the 6 sensors. It’s also shown on the right of figure 3 that there are two headers and a Darlington buffer. For the top one which is the power supply for the whole sensor PCB, the one in the middle is the analog output for each sensor and AnalogIn pin will be connected to it. The bottom one on Figure 1 is Darlington buffer which is connected to microcontroller from input and sensor led from output. Darlington buffer will control which one to work at a time. If the input was high which means the output will be set to high and there is no voltage drop on the sensor led, therefore led was disabled as well as the other led.

Second picture in Figure 4 shows how the connection will be constructed. At the bottom, left header was designed to convey the output from sensor to the microcontroller which will be measured in voltage and through AnalogIn configuration which can distinguish the level of voltage. From sensor1 to sensor6, we connected it to CN8 pins which has 6 AnalogIn configuration pins. The right header which is the power supply header will supply the whole PCB power and with ultrasonic sensor just aside the power header. The power supply will come from the motor drive board and the ultrasonic sensor will directly connected to microcontroller boarded therefore it has more flexibility rather than line sensor pins. Also, ultrasonic sensor will be connected to the pin configured to AnalogIn mode. The Figure 5 shows how will the wires be connected to these three boards. All the red wires are power supply. The motors and power supply from battery are connected to the motor driver board. In addition, power will be delivered from motor drive board to the Nucleo board and sensor board. A PWM control wire is connected between motor driver board and Nucleo board to control the motors. 6 AnalogIn wires are connected between sensor board and Nucleo board which is also shown on Figure 3.

# Non line-sensors

Regarding sensors that are provided with the buggy, it was seen that the project is not only given with line sensors. Non-line sensors are also presented with this project, such as encoders, battery monitors, and motor’s current sensors. Consequently, this part will discuss the capabilities of the Non-Line sensor, the connection between sensors and the microcontroller, and other sensors alternatives that give advantages to ease the competition.

Firstly, speed sensing is one of the significant non-line sensors that are provided with the buggy. Measuring the buggy speed is essential and have main advantages such as controlling the buggy’s stops in perfect timing by reversing the current’s motor, measuring the length of the track, increasing the accuracy of following the line, and have a significant role in keeping the buggy be capable of moving in a constant speed due to the interface between the microcontroller and the sensor.

Therefore, to estimate the wheel’s speed, an encoder that is fixed on the motor’s shaft, and a photo-interrupter sensor are used to detect the disk’s rotation. Due to the phototransistor’s output states, that relies on the rotating light beam position and sensors response time, a square wave pulse is extracted which then can be used to calculate the motor’s speed. The wheel velocity is then found by using both motor’s speed and gear ratio. One way of calculating the speed from an encoder is to count the rising edges within a specific period, and at each rising edge an interrupt is generated. Moreover, An AEAT-601B-F06 quadrature encoder is used to also measure the direction of the wheel. In depth, due to the encoder’s output wave forms, wheel’s direction is measured.

Thoroughly, there are several ways for the MCU to get measurements from the quadrature encoder. However, the most precise way is by using the built-in quadrature encoder peripheral (TIM2 CH1, CH2) and TIM5 (CH1, CH2), because they have a 32-bit Quadrature encoders interface mode, where the encoder’s resolution can be doubled or quadrupled to 1024 counts per revolution. Moreover, as mentioned above, the encoder ticks (rising edges) are an accumulative value. Therefore, the encoder measurements setup will be as following, initialise timer, clear encoder ticks, read the change of encoder ticks after dt, and restart the timer. Using mbed platform to interface encoders to the Nucleo, the obtained measurements will then be processed and used to calculate the robot’s angular velocity.

Then, the battery monitor is a sensor that measures the battery’s total voltage and accumulated current. Monitoring the battery is essential, and that is to know the buggy battery’s status and capacity continuously throughout the race to have reliable battery management and energy distribution plan. Dallas DS2781 integrated circuit is used to monitor the battery, that is by sampling current at regular intervals *∆T*, and the current samples then are added together. Therefore, the energy use E is given by in Equation 3 if the battery voltage remains constant throughout the test.

(3)

Then, motor sensors are used to measure the current applied to the motor to trace any overheating caused by a continuous high current applied to motor. due to the provided two current sensing circuits (A and B), the microcontroller is able to measure the motor’s sensor by measuring the potential difference across a 0.1 ohms resistor that’s connected in series with the motor, between IsenseA+ and IsenseA- and between IsenseB+ and IsenseB- respectively.

Lastly, regarding alternative sensors that might be purchased to give the buggy extra advantages. It was discussed and obtained that to have a buggy that is sensitive towards most of the obstacles, an ultrasonic sensor (HC-SR04), also known as sonar sensor, must be used. Ultrasonic sensors are electrical devices that estimate an object’s distance by the emission of high-frequency soundwaves and convert the reflected wave to an electrical signal. HC-SR04 is made of two main cylinders: the emitter, which releases ultrasonic sound, and the receiver, which collects the sound after bouncing back of the target. In terms of distance measurements since the speed of sound (v) is almost constant which is about 340m/s. The time (t) it takes, between the transmitter 40 kHz ultrasound emission through the air until its bounce back from an object to the receiver, is measured by the sensor. Therefore, using Equation 4 seen below, the distance between the obstacle and the sensor can be obtained, as seen the distance is multiplied by a factor of two because the sound must travel twice the distance [4].

(4)

According to HC-SR04 user map and its interface with the STM32, the sensor has four pins which are: VCC, which must be connected to 5 V; Trig, which is an input pin to trigger the measurement (PB10); Echo, which is an output pin which sent out a square wave (PA8); and a GND, which is connected to the ground [3]. Consequently, to implement and use the sensor with the MCU, Trig must be pulled up for ten microseconds and the sensor will emit eight pulses of ultrasound, as the sound travels through air and bounces back, Echo will be high then the measured time is used to obtain the distance, as seen in Equation 4 [4].

Regarding HC-SR04 pros and cons, the ultrasound sensor provides several significant advantages that increase the buggy’s performance, yet it has some disadvantages that must be taken into consideration. In terms of disadvantages that might affect HC-SR04’s sensitivity and measurements accuracy; Firstly, the speed of sound is not always consistent because it depends on several factors, such as the materials medium and temperature; Then, obstacles might not have smooth or constant surfaces such as the incline which then this will then lead to several waves bouncing back to the Echo, and this will have a significant effect on the measurements’ accuracy. Lastly, Ultrasonic sensors provides the buggy several important pros. With ultrasonic sensor the buggy will have extra sensor that aid the ability to detect obstacles that the buggy will face such as walls, ramps and turns. Therefore, the buggy will have the ability to simultaneously update and adapt with the track’s obstacles, and this will give the buggy a solid advantage to overcome the obstacles smoothly [4].

# Control

**Line detect and control the wheel speed/direction**

The infrared sensor has been chosen to detect the line. From the lab result, the voltage output will decrease when the line is closing the sensor.

For the wheel speed control, PWM (Pulse-width modulation) is used. PWM can be set by changing the duty cycle, as shown in Figure 6. Duty cycle *D* is the rate between the time of high state and the switching cycle *T*. And the final speed is the , which is the average speed in one cycle.

(5)

![](https://images.wu.engineer/images/2023/07/11/86de78b3a08a212eaca82d57cce7b444.png)

Figure 6

Wheel direction can be changed by changing the speed of single wheel, which can be modified by H-bridge and PWM. Four switches in H-bridge can control the current direction passing through the motor, and let the motor having forward, reverse direction or zero speed.

To guide the Buggy back to the line and let the buggy turn, the feedback control system is used to detect the line error by a series of sensors. Change the single wheel speed to offset the deviation and guide the Buggy back.

**Proportional vs bang-bang controllers**

Bang-bang controller means that the controller will correct itself by a fixed configure when it deviates from the expected measurement. ‘Dead zone’ can be added to the bang-bang controller as an improvement. The motor will not be affected when the measurement is in the dead zone. The dead zone can lessen the frequency of the speed changing. The Bang-bang controller will cause the underdamped or unstable condition, shown in Figure 7, because this controller will switch abruptly between two states.

![](https://images.wu.engineer/images/2023/07/11/3e5772883813dc34f3c1e048b4ea72f2.png)

The proportional controller will let the Buggy correct itself by a proportional measurement. This controller will give a more stable and smooth control process, while it may need more computing than the bang-bang controller because it is always computing the error. In Figure 7, an underdamped may occur when the proportional controller has been implemented in the system. Critically damped will occur when the proportional controller adds the integral and differentiation part. The Pros and Cons of bang-bang and proportional controller are listed in Table 8 below.

Table 8

|              | Pros                                                  | Cons                                                              |
|--------------|-------------------------------------------------------|-------------------------------------------------------------------|
| Bang-bang    | Easy to achieve Fast to execute                       | Need a long time to settle down Always shaking with a given angle |
| Proportional | Correct the deviation dynamically Fast to settle down | Need more compute                                                 |

**Things to control**

1.  Wheel speed: To get the optimal speed in a straight line and correct the direction when the Buggy is making a turn. Calculating wheel speed by using the PID algorithm, change wheel speed by setting PWM.
2.  Wheel direction: Changed by H-bridge, which can set the wheel direction to forward, reverse direction or zero speed.
3.  Switching frequency: how long does the duty ratio is, it determined how quickly does the motor need to change the PWM.

**Algorithm choice**

The proportional-integral-derivative (PID) controller has been chosen to control the direction of the Buggy. For the proportional controller, the difference between the sensor measurement and the set-up value (which wishes to be 0) called error. Then Equation 6 showed the relationship between the speed difference and the error.

(6)

Where *u(t)* is the manipulated variable, *e* is error, *t* is time and is termed the proportional gain. cannot be too low because it may need a long time to correct it. Also, it cannot be too high because it may over-active and will make massive speed changes even there is a small deviation.

There are some control problems need to be solved when the Buggy is running. For example, the loss of forces brings about the deviation of the entire Buggy. The forces loss ineluctable, like friction and motor loss. These losses will make the Buggy stay slightly to one side of the line, which is termed as a steady-state error. To cope with this, integration part needs to be added to the controller to avoid the steady-state error.

Integration action can add up steady-state error and plus them into the algorithm. Integration has been used to integrate the error with time. Equation 7 of the PI controller has been written below.

(7)

Where is the integral gain. Where *e(t)* is the error in t seconds.

Also, when the Buggy needs steering, its wheel speed may decrease to have a more significant angle to steering. PI controller can handle with this, while the Buggy may rollover or motor overheat when the voltage of the motor changes drastically without a damper. So, the derivation part needs to be added. Derivative action can provide damping to the controller by split the change of error into small pieces, which can make the Buggy moves more smoothly. Equation 8 of the PID controller has been written below.

(8)

Where is the derivative gain.

There are different combinations for PID controllers. Pros and Cons of these controllers are listed in Table 9.

Table 9

|     | Pros                                       | Cons                                                          |
|-----|--------------------------------------------|---------------------------------------------------------------|
| P   | Easy to execute                            | Need a long time to settle down May have a steady-state error |
| PD  | Response fast                              | May have a steady-state error                                 |
| PI  | No steady-state error                      | Need a long time to settle down                               |
| PID | No steady-state error Stable Response fast |                                                               |

In order to get a precise and stable system, the proportional controller can only solve a part of control problems. Add the integral and derivative part to the controller are essential. PID control feedback system can have precise and stable control. Also, it can smooth the Buggy and correct the steady-state error.

**Factors affecting the algorithm**

When sensors are designing and setting up, some factors may affect the algorithm. From the lab result, the gap between the sensor and the white line will directly influence the voltage output of the sensor. When the different gap of the sensor has been chosen, three constants which are set in the algorithm (*P, I, D*) should be reset.

When the Buggy is testing and debugging, it is essential to show that which sensor is read by the system. Groupmates can easily find which sensor is read by the system if there is a LED show the operational status of each sensor. It can let debugging quickly and more uncomplicated to improve the algorithm.

In the control system, sensors should be read separately in order to get each sensors’ voltage output correctly. So, each sensor should occupy an interface on the motor drive board.

**Sensor implementation**

![](https://images.wu.engineer/images/2023/07/11/0face33cc7f650edc39e417d60a2b231.png)

Figure 8

For sensor implementation part, TCRT5000 sensor has been used in line detecting. TCRT5000 contains an infrared emitter and receiver. Six TCRT5000 sensors all in analogue type are planned to implement in the Buggy, as shown in Figure 8. Five sensors are placed in one line, while the gap between each sensor is slightly different. For the three sensors located in the centre of the arrangement, they are planned to detect the slight shaking of the Buggy. So, the gap will be 1.2 cm. In this case, the effective detecting area (a circle with a radius of 1.5cm) of the three sensors will overlap. When the Buggy slightly deviates from the white line, it will be detected by two or three sensors and back to the microcontroller. The microcontroller can accurately determine the error and correct the deviation by changing the PWM.

The two sensors on both sides play a role when there is a vast deviation between the Buggy and the white line, like turning or unpredictable accident. The gap between

these two side sensors is 2.4 cm, while there is still a part of the effective detecting range that overlaps. It ensures that the control system will continue working when a vast deviation occurred.

Another sensor will be placed in the top centre. Its function is to assist the centre

sensors in correcting the set-point. Also, it can detect the line breaks before the centre sensors to assist the control system to operate.

The line sensor board will have some interfaces to connect the motor drive board. VDD and GND as power supply and the ground will be connected to CN4 connector of the motor drive board. Six sensors need to be read separately. So, they are planned to be connected to A0-A5 interface of the CN8 connecter on the motor drive board.

**Plan for algorithm implementation**

![](https://images.wu.engineer/images/2023/07/11/6289cb47848c9c288389989a0a161136.png)

Figure 9

The flowchart of the PID control algorithm has been shown in Figure 9. It shows the process of the algorithm.

![](https://images.wu.engineer/images/2023/07/11/670eec01e3877ecb840595fc7d6f503c.png)

Figure 10

First, the distance between sensors and the white line should be calculated. The distance can be termed as ‘error value ’. A python-based algorithm is found on the CSDN website [5], which using a fitting algorithm to fit a binomial equation from several points. This fitting algorithm is planned to use to calculate the distance between the sensor and the white line. There are eight values that can be used in this algorithm from the sensor lab results table. The fitting figure is shown in Figure 10, and the Equation 9 has been shown below.

(9)

Where is the distance between the sensor and white line, is the voltage output of the sensor. By calculating , two results should be outputted. Determine which result should be used by judging the position of the sensor during polling. More data for sensors can be obtained in future experiments, so a more precise equation can be calculated by fitting algorithm.

Then, the calculated error value should be put into the PID algorithm below.

(10)

(11)

Error value should be negative for the left side sensors. So, for the left wheel speed, there should be a negative sign before the *P* action. *D* action is a damper, so its sign should be opposite to the *P* action. Mention that three gain values, , and should be tried in the future test and give the optimal solution.

In the implementation, the integral and derivate function may slow down the response time for the microcontroller. So, the integration part in Equation 10 and Equation 11 can be changed to Equation 12.

(12)

Where is the sampling error at kth sampling instant. And the derivative part in Equation 10 and Equation 11 can be changed to Equation 13

(13)

New speed values should be calculated by the algorithm, which are and . These speed values show the difference between the actual speed and the new speed. Use speed values to set the PWM of the motor. Then, the left and right wheel speed change to the expected value. Finally, use two new wheel speed as inputs to start a new loop.

**Solutions of line breaks and direct sunlight**

During the testing and the final race, there are several problems that need to be considered—for example, line breaks and direct sunlight. The problem of line breaks can be solved by adding a timer in the software. The timer is ordered to countdown the time that the Buggy needs to pass through the break. From the slides in ESP week 1 [6], line breaks are up to 6 mm. So, the time can be calculated by 6mm divided by the speed of the Buggy. Then, using the wait command and ISR function to let the Buggy keep running when a line break occurred.

The problem of direct sunlight can be solved by software. Turn off the infrared emitter to detect the environment's infrared intensity by the receiver. Then, use the measured value as the offset. When the algorithm is reading the output value of the sensor, subtract the offset to get the correct value.

# Hardware overview

This section is about the process of chassis design. How the buggy’s dimensions were determined, which material will be used and how the subcomponents were fitted onto the chassis.

The first step was to determine what overall dimensions can the buggy have. For the reason that the buggy would have to turn around the track without hitting the walls the maximum turning circle had to be obtained.Here the team followed the guidance given in Engineering Drawing video of week 9 by Sam Walsh [7].

After this exercise was repeated the team decided to use the dimensions of the layout shown in the video which is 165 mm x 140 mm shown on Figure 11. After the gearboxes and castor ball were fitted the remaining components had to be placed. Being the battery pack is the heaviest item on the chassis this had to be fitted taking into consideration the centre of gravity of the buggy. Eventually it was placed over the wheels after going through all possibilities and following the videos guidance.

![](https://images.wu.engineer/images/2023/07/11/657c220f6fb47604a31fe28bd8c744d0.png)

Figure 11

![](https://images.wu.engineer/images/2023/07/11/73997d93fecabb4342ea5a9fefe69db3.png)![](https://images.wu.engineer/images/2023/07/11/cd29977e88d08f94fff279fb5d5ccaca.png)

Figure 12 Figure 13

When fittin the PCB-s onto the chassis an issue come up which is that these cannot be fitted directly onto the chassis due to the soldering on the back of the PCB-s. After some research a solution was found on the Farnell website. A particle called standoff can be used to create space between the PCB and the plastic sheet, these were created in Solidworks using the data sheets [8][9][10][11] found on the Farnell website. Also additional sheets were designed for fitting the Nucleo board and the sensor PCB onto the buggy these are shown on Figure 12 and Figure 13. Holes on the layout were created using the technique show in the video [7].

After assembling the buggy in Solidworks the chassis had to be tested if it can turn around the track and go through the tunnel on the race day. Therefore, the model of the track and the tunnel were created in the program to test the buggy.

Regarding chassis manufacture, several materials were taken into consideration such as POM Acetal Copolymer (Acetyl), 1060 Alloy (Aluminium), and 201 Annealed Stainless Steel. Materials have different advantages and disadvantages to each other. Therefore, to choose the perfect material for chassis construction, several aspects were considered such as the ease of manufacture, and the weight of the chassis after the material is implemented because the minimum amount of weight is required, so the buggy maintain both its speed and battery life throughout the track. However, the most critical aspect that was taken into consideration is the strength of the material, which is marked due to the deflection (bending) of the chassis when the maximum loading is subjected to it. Therefore, Equation 14 is used to calculate the deflection (x) of the material when a distributed load (w) is subjected it, where, E is the materials Modulus of elasticity, l is length, b is chassis breadth, and h is the height of chassis.

(14)

However, the due to SolidWorks stress analysis the chassis deflection calculation for each material was obtained when a mass of 1.4 kg (Buggy’s maximum mass) is subjected to the chassis. Firstly, it was noticed that as the density and the Elastic modulus of the material increases, the chassis deflection decreases when its subjected to weight. From SolidWorks stress analysis, it was seen that when the chassis is constructed from Steel, it has the minimum deflection with a value of 4.15e-06 m; oppositely, when its constructed from Acetyl it has a significant deflection with a value of 3.2e-04 m; however, the chassis deflection when it is manufactured from aluminium is mild, with a value of 1.24e-05 m which lies in between both Steel and Acetyl.

# Summary

This report gave an overall view of how the team thinks to build and program the buggy. In this report a few aspects had to be considered like the width and height of the track, sensor characteristics and how the buggy would interact with these sensors. The buggy’s chassis was made with paying attention to the width and the height of the track so the buggy would not hit any wall.

An initial software design was made, giving an overarching view of how all the individual components will interact with each other and the system. The list of class function prototypes will allow for an easier software development in future as it allows for programmers to correctly reference functions that have not been written yet.

The results in the sensor characteristics part show that TCRT5000 is more sensitive, and it is the most sensitive when the height is 5 mm. LED / Opto-transistor are aligned across the width of the white line or along the white line will not affect the sensitivity of TCRT5000. After examining different sensors, the TCRT5000 was selected and will be used because its performance is suitable in all aspects.

It is clearly shown that how many wires was used and how the connections were linked together through the wiring diagram. To meet the requirement of measuring voltage level from the output of sensors, the AnalogIn mode was set for each pin as well as the ultrasonic sensor pins and pictures also show which pin possesses AnalogIn mode. The schematic diagram and PCB board diagram demonstrate how the PCB was designed by displaying the circuitry.

Non-line sensors are also presented with this project such as encoders, battery monitors, motor sensors and the ultrasonic sensor HC-SR04, which is recommended to purchase by the team. Firstly, Encoders are speed measuring sensors; therefore, they are essential to control the motor’s displacement and velocity throughout the race. Then Battery monitor is a sensor that measures the total voltage across the batteries, and it is needed to trace the energy of the batteries for reliable energy management. The third sensor provided is the motor current sensor; it will be used in the buggy to trace any continuous maximum current to overcome motor overheating. Lastly, ultrasonic sensor HC-SR04 is used to give the buggy extra advantages to win the race. HC-SR04 is chosen to aid the buggy’s ability to detect obstacles such as walls and ramps.

The control part shows the detailed information about the control theory, algorithm, and its implementation. In order to get a stable and smooth control system, the PID algorithm has been chosen for the Buggy, which includes proportional, integral and differentiation part. These three parts play a role in control the Buggy respectively, which is proportional adjustment, eliminate the steady-state error and reduce the Buggy shaking. Also, line breaks and direct sunlight has been discussed as control problems. These problems can be solved by adding an additional sensor and adding functions in software.

When designing the chassis, the dimensions of the track were important as these determine the turning circle the buggy can have and therefore the width and length of the buggy. The chassis’ main layer decided to be 160 mm x 140 mm after calculations were done. The chassis has three additional layer which was designed by the team. The first is the main layer which holds all the components. The other plastic layers are designed to hold the Nucleo board and the sensor PCB. These layers will be constructed from Acetyl which has a maximum deformation of 3.259e-4 m.

# References

[1]<https://online.manchester.ac.uk/webapps/blackboard/content/listContent.jsp?course_id=_62951_1&content_id=_11792750_1> ,[accessed 5th December 2020] [2]https://my.altium.com/altium-designer/getting-started/interaction-projects ,[accessed 11th December 2020]

[3] elecfreaks.com/download/EF03085-HC-SR04_Ultrasonic_Module_User_Guide.pdf, [accessed 5th December 2020]

[4][www.playembedded.org](http://www.playembedded.org/) ,[accessed 6th December 2020]

[5] <https://blog.csdn.net/bitcarmanlee/article/details/78398556>, [accessed 9th December 2020]

[6] https://online.manchester.ac.uk/bbcswebdav/pid-12022462-dt-content-rid-49220177_1/xid-49220177_1 ,[accessed 8th December 2020]

[7]https://online.manchester.ac.uk/webapps/blackboard/content/listContent.jsp?course_id=_62951_1&content_id=_12152442_1, [accessed 1st December 2020]

[8] <http://www.farnell.com/datasheets/1740392.pdf> ,[accessed 5th December 2020]

[9] <http://www.farnell.com/datasheets/58173.pdf> ,[accessed 5th December 2020]

[10] <http://www.farnell.com/datasheets/58177.pdf> ,[accessed 5th December 2020]

[11] <http://www.farnell.com/datasheets/1957894.pdf> ,[accessed 5th December 2020]
