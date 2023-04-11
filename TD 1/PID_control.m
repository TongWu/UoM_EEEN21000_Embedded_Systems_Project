%PID control file
clc, clear all
restoredefaultpath
addpath(genpath(pwd))

R1 = RobotClass('json_fname', 'puzzle_bot_0002.json');

W = WorldClass('fname', 'world_empty.json');
figure(1)
h_w = W.plot();
%set the simulation parameters
total_time = 10; %set total time that the simulation will run
sampling_time=0.005; % set the sampling time
t_start=tic;
t_loop=tic;

%setpoints for left and right wheels
wR_set=7 ;
wL_set=7 ;

%initiallise read data from right and left encoders
wR=0;
wL=0;

%initiallise the vectors of right and left wheel speed to plot data
wR_all=[];
wL_all=[];
uR_all=[];
uL_all=[];
pid_valueR_all=[];
pid_valueL_all=[];

%initiallise PID controller parameters
kp = 0.53;
ki = 12.5;
kd = 0;
pre_errorR = 0;
int_errorR = 0; %integrated error
pre_errorL = 0;
int_errorL = 0; %integrated error

while toc(t_start) < total_time
    dt=toc(t_loop);
    try
        delete([h_r, h_s])
    catch
    end
    h_r = R1.plot('simple');
    h_s = R1.plot_measurements('left encoder');
    h_s = R1.plot_measurements('right encoder');
    
    if dt>sampling_time
        t_loop=tic;
        
        %calculate PID right value
        errorR = wR_set - wR;
        uR = kp * errorR + ki * int_errorR + kd * (errorR - pre_errorR)/dt;
        int_errorR = errorR*dt + int_errorR; %sum the total error
        pre_errorR = errorR; %set the error as previous error for next loop
        pre_velocityR = wR; %set real velocity for previous velocity for next loop

        %set PID value to encoder
        
        
        %calculate PID left value
        errorL = wL_set - wL;
        uL = kp * errorL + ki * int_errorL + kd * (errorL - pre_errorL)/dt;
        int_errorL = errorL*dt + int_errorL; %sum the total error
        pre_errorL = errorL; %set the error as previous error for next loop
        pre_velocityL = wL; %set real velocity for previous velocity for next loop


uL_all = [uL_all uL];
uR_all = [uR_all uR];
        
       %% Do not edit this section
        % Update robot in this order: actuators, pose (in simulation), sensors
        actuator_signals = {'right motor', uR, 'left motor', uL};
        sensor_readings = R1.update(dt, W, 'kinematics', 'voltage_pwm', actuator_signals{:});
        
        % Update encoder velocity readings
        wR = sensor_readings('right encoder');
        wL = sensor_readings('left encoder');
    end
    pause(0.001)
end

actuator_signals = {'right motor', 0, 'left motor', 0,'servo motor',0};
R1.update(dt, W, 'kinematics', 'voltage_pwm', actuator_signals{:});

% Plot wheel angular velocities
figure(2)
plot(pid_valueR_all);
hold on
plot(pid_valueL_all);
legend('Right wheel speed','Left wheel speed');
figure(3)
plot(uR_all);
hold on
plot(uL_all);
legend('Right motor duty ratio','Left motor duty ratio');


