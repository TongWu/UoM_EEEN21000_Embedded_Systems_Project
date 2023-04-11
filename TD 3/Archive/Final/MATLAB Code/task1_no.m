function my_alg = task1_no(my_alg, robot)
% This function implements two control loops:
%   - the inner loop implements angular velocity controllers for both
%   wheels;
%   - the outer loop implements a proportional controller for holding a
%   constant distance to a wall using the sonar;
%
%  Load world_wall.json in the Gui to test the example.
%
% Mohamed Mustafa, August 2020
% -------------------------------------------------------------------------
%
% Reading data from sensors (if present on the robot)
%    my_alg('right encoder') - right encoder velocity
%    my_alg('left encoder')  - left encoder velocity
%    my_alg('reflectance')   - reflectance sensor output value
%    my_alg('reflectance raw')   - reflectance sensor raw output values
%    my_alg('sonar')         - sonar measured distance (m)
%
% Sending controls to actuators (if present on the robot)
%    my_alg('right motor')   - sets the right motor input signal (pwm or angular velocity)
%    my_alg('left motor')    - sets the left motor input signal (pwm or angular velocity)
%    my_alg('servo motor')   - sets the servomotor angle (radians)
% -------------------------------------------------------------------------
if my_alg('is_first_time')
    %% Setup initial parameters here
    
    my_alg('dc_motor_signal_mode') = 'voltage_pwm';     % change if necessary to 'omega_setpoint'
    
    % Initialise motor controller
    my_alg('error') = 0;
    my_alg('tot_error') = 0;
    my_alg('diff_error') = 0;
    my_alg('PID') = 0;
    my_alg('pre_error') = 0;
    
    my_alg('kp') = 0.5;
    my_alg('ki') = 0.0006;
    my_alg('kd') = 0.5;
    
    
    % Initialise time parameters
    my_alg('sampling_time') = 0.01;
    my_alg('t_loop') = tic;
    my_alg('t_finish') = 40;
    
    % desired wheel velocity
    my_alg('wR_desired') = 7;
    my_alg('wL_desired') = 7;
    
    my_alg('servo motor') = 1.57;
    
    % sonar_distance_parameter
    my_alg('sonar_dist') = 0;
    my_alg('dist_left_wall') = [];
    
    % line sensor parameter
    my_alg('sensor') = 0;
    
    my_alg('sensor_1') = 0;
    my_alg('sensor_2') = 0;
    my_alg('sensor_3') = 0;
    my_alg('sensor_4') = 0;
    my_alg('sensor_5') = 0;
    my_alg('sensor_6') = 0;
    my_alg('sensor_7') = 0;
    my_alg('sensor_8') = 0;
    
    my_alg('count')=0;
    my_alg('final_distance')=0.006/(((my_alg('wR_desired')+my_alg('wR_desired'))/2)*0.05);
    
    % Plotting Data
    my_alg('wR_all')=[];
    my_alg('wL_all')=[];
    my_alg('uR_all')=[];
    my_alg('uL_all')=[];
end

time = toc(my_alg('tic'));      % Get time since start of session
%% Time loop removed. The program will terminated until the buggy finish following the line
    if time < my_alg('t_finish')    % Check for algorithm finish time
    dt = toc(my_alg('t_loop'));
    if dt>my_alg('sampling_time')  % Execute code when desired outer loop sampling time is reached
        my_alg('t_loop') = tic;
        %PID算法
        %基本理论：
        %1. 读取8个传感器的数据：如在右侧4个读出500，则左偏；反之向左偏
        %2. 当中间两个（从左往右数第4,5个）传感器都读出或只有一个读出500，那么判定为直行，直到误差扩大才进行PID调整
        %3. 当最两侧的两个传感器（共四个）读出500，则判定为严重偏离预定轨道，PID仍旧采用，但减缓速度

        % Salculate PID value, in angular speed(wR, wL)
        my_alg('PID') = my_alg('kp')*my_alg('error') +  my_alg('ki')*my_alg('tot_error') + my_alg('kd')*my_alg('diff_error');
        % Previous error
        my_alg('pre_error') = my_alg('error');
        % Calculate total error
        my_alg('tot_error') = my_alg('tot_error') + my_alg('error');
        % Calculate error difference
        my_alg('diff_error') = my_alg('error') - my_alg('pre_error');
        
        %read the reflectance
        line = my_alg('reflectance_raw');
        %store the reflectance for each sensor
        my_alg('sensor_1') = line(1,1);
        my_alg('sensor_2') = line(1,2);
        my_alg('sensor_3') = line(1,3);
        my_alg('sensor_4') = line(1,4);
        my_alg('sensor_5') = line(1,5);
        my_alg('sensor_6') = line(1,6);
        my_alg('sensor_7') = line(1,7);
        my_alg('sensor_8') = line(1,8);
        
        %set the error
        %if two centre sensors above the line
        if (my_alg('sensor_4') == 500 || my_alg('sensor_5') == 500)
            my_alg('error') = 0;
        else 
            my_alg('error')=abs(my_alg('reflectance'));
        end
        
        w_max = 13.8735;
        if (my_alg('sensor_4') == 500 || my_alg('sensor_5') == 500)
            my_alg('right motor') = my_alg('wR_desired')/w_max;
            my_alg('left motor') = my_alg('wL_desired')/w_max;
            my_alg('count') = 0;
        % if the right middle sensors above the line
        elseif (my_alg('sensor_5') == 500 || my_alg('sensor_6') == 500)
            my_alg('right motor') = ((my_alg('wR_desired')/w_max) - my_alg('PID'));
            my_alg('left motor') = ((my_alg('wL_desired')/w_max) + my_alg('PID'));
            my_alg('count') = 0;
        % if the left middle sensors above the line
        elseif (my_alg('sensor_3') == 500 || my_alg('sensor_4') == 500)
            my_alg('right motor') = ((my_alg('wR_desired')/w_max) + my_alg('PID'));
            my_alg('left motor') = ((my_alg('wL_desired')/w_max) - my_alg('PID'));
            my_alg('count') = 0;
        % if the right edge sensors above the line
        elseif (my_alg('sensor_7') == 500 || my_alg('sensor_8') == 500)
            my_alg('right motor') = ((my_alg('wR_desired')/w_max) - my_alg('PID'))*0.7;
            my_alg('left motor') = ((my_alg('wL_desired')/w_max) + my_alg('PID'))*0.7;
            my_alg('count') = 0;
        % if the left edge sensors above the line
        elseif (my_alg('sensor_1') == 500 || my_alg('sensor_2') == 500)
            my_alg('right motor') = ((my_alg('wR_desired')/w_max) + my_alg('PID'))*0.7;
            my_alg('left motor') = ((my_alg('wL_desired')/w_max) - my_alg('PID'))*0.7;
            my_alg('count') = 0;
        % if all sensors are not above the line
        elseif my_alg('sensor_1') == 2500 && my_alg('sensor_2') == 2500 && my_alg('sensor_3') == 2500 && my_alg('sensor_4') == 2500 && my_alg('sensor_5') == 2500 && my_alg('sensor_6') == 2500 && my_alg('sensor_7') == 2500 && my_alg('sensor_8') == 2500
            my_alg('right motor') = my_alg('wR_desired')/w_max;
            my_alg('left motor') = my_alg('wL_desired')/w_max;
            my_alg('count') = my_alg('count') + 1;
        end
        
        my_alg('uL_all') = [my_alg('uL_all') my_alg('left motor')];
        my_alg('uR_all') = [my_alg('uR_all') my_alg('right motor')];
                my_alg('wR_all') = [my_alg('wR_all') my_alg('right encoder')];
        my_alg('wL_all') = [my_alg('wL_all') my_alg('left encoder')];
%         after all sensors are not above the line
%         if (my_alg('count') > 0 && round(my_alg('final_distance')/my_alg('sampling_time')))
%             %judge whether there is a line break
%             
%             if(my_alg('count') > round(my_alg('final_distance')/my_alg('sampling_time')))
%                 %the whole process should be done or derive the track
%                 %terminate the program
%                 my_alg('is_done')=true;
%               %% Finish algorithm and plot results
%                 % Stop motors
%                 my_alg('right motor') = 0;
%                 my_alg('left motor') = 0;
%                 % Set servo angle to 0
%                 my_alg('servo motor') = 0;
%             end  
%         end
    end
%     else
%         %% Finish algorithm and plot results
%         
%         % Stop motors
%         my_alg('right motor') = 0;
%         my_alg('left motor') = 0;
%         
%         % Set servo angle to 0
%         my_alg('servo motor') = 0;
%         
%         % Stop session
%         my_alg('is_done') = true;
%         

    else
         %% Finish algorithm and plot results
         
         % Stop motors
         my_alg('right motor') = 0;
         my_alg('left motor') = 0;
         
         % Set servo angle to 0
         my_alg('servo motor') = 0;
         
         % Stop session
         my_alg('is_done') = true;

         % Plot Data
         figure(2);
         plot(my_alg('uR_all'));
         hold on
         plot(my_alg('uL_all'));
         figure(3);
         plot(my_alg('wR_all'));
         hold on
         plot(my_alg('wL_all'));
         
    end
return