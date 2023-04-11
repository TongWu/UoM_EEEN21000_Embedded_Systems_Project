function my_alg = task5(my_alg, robot)
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
    my_alg('right encoder') = 0;
    my_alg('left encoder') = 0;
    % Initialise motor controller
    my_alg('error') = 0;
    my_alg('tot_error') = 0;
    my_alg('diff_error') = 0;
    my_alg('PID') = 0;
    my_alg('pre_error') = 0;
    
    my_alg('kp') = 0.25;
    my_alg('ki') = 0.0012;
    my_alg('kd') = 0.15;
    
    my_alg('PID_backup') = 0;
    % Initialise time parameters
    % CHANGE sampling_outer (outer loop) to 0.01, from 0.005
    my_alg('sampling_outer') = 0.005;
    % ADD sampling_inner about 0.005
    my_alg('sampling_inner') = 0.0025;
    my_alg('t_outer_loop') = tic;
    my_alg('t_inner_loop') = tic;
    my_alg('t_finish') = 63;
    
    % desired wheel velocity
    my_alg('wR_desired') = 6;
    my_alg('wL_desired') = 6;
    
    my_alg('wR_desired_temp') = my_alg('wR_desired');
    my_alg('wL_desired_temp') = my_alg('wL_desired');
    my_alg('wR_cutoff') = my_alg('wR_desired')+2;
    my_alg('wL_cutoff') = my_alg('wL_desired')+2;
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
end


time = toc(my_alg('tic'));      % Get time since start of session
%% Time loop removed. The program will terminated until the buggy finish following the line
if time < my_alg('t_finish')    % Check for algorithm finish time
    dt = toc(my_alg('t_outer_loop'));
    w_max = 13.8735;
    %%%%%%%%%%%% Outer Loop %%%%%%%%%%%%
    if dt>my_alg('sampling_outer')  % Execute code when desired outer loop sampling time is reached
        my_alg('t_outer_loop') = tic;
        % Salculate PID value, in angular speed(wR, wL)
        
        if my_alg('error') > 0.02
            my_alg('PID') = my_alg('kp')*my_alg('error') +  my_alg('ki')*my_alg('tot_error') + my_alg('kd')*my_alg('diff_error');
        elseif my_alg('error') == 0
            my_alg('PID_backup') = my_alg('PID');
        end
        
        % Previous error
        my_alg('pre_error') = my_alg('error');
        % Calculate total error
        my_alg('tot_error') = my_alg('tot_error') + my_alg('error');
        % Calculate error difference
        my_alg('diff_error') = my_alg('error') - my_alg('pre_error');
        
        %read the reflectance
        %%%%%%%%%% UPDATED FOR TD3 %%%%%%%%%%
        %line = my_alg('reflectance raw');
        line = my_alg('reflectance_raw');
        %%%%%%%%%% END UPDATE %%%%%%%%%%%%%%%
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
%             if my_alg('right encoder') > my_alg('left encoder')
%                 my_alg('right motor') = (my_alg('wR_desired')/w_max) + my_alg('PID_backup');
%                 my_alg('left motor') = (my_alg('wL_desired')/w_max) - my_alg('PID_backup');
%             elseif my_alg('right encoder') < my_alg('left encoder')
%                 my_alg('right motor') = (my_alg('wR_desired')/w_max) - my_alg('PID_backup');
%                 my_alg('left motor') = (my_alg('wL_desired')/w_max) + my_alg('PID_backup');
%             elseif my_alg('right encoder') == my_alg('left encoder')
%                 my_alg('right motor') = (my_alg('wR_desired')/w_max);
%                 my_alg('left motor') = (my_alg('wL_desired')/w_max);
%             end
        end
        % Normal Line break Slow down
        if time<15
            if my_alg('count') >= 10 && my_alg('count') < 150
%                 deaccelerate = (100 - my_alg('count'))/100;
                my_alg('right motor') = (my_alg('wR_desired')/w_max);
                my_alg('left motor') = (my_alg('wL_desired')/w_max);
            end
        elseif time>15 && time<50 && my_alg('count') >=50 && my_alg('count')<82
            % Applying full duty ratio to let the buggy make a turn,
            % when the buggy turn to 360 degree, it will automatically
            % read 500 value for sensor
            my_alg('right motor') = 1;
            my_alg('left motor') = -1;
        elseif time>50 && my_alg('count') >=10
            my_alg('right motor') = 0;
            my_alg('left motor') = 0;
        end
        
    end
    %%%%% END FOR OUTER LOOP %%%%%
    
    %%%%% INNER LOOP %%%%%
    dt = toc(my_alg('t_inner_loop'));

    if dt>my_alg('sampling_inner')
        my_alg('t_inner_loop') = tic;
        if my_alg('right encoder')>my_alg('wR_cutoff') && my_alg('left encoder')>my_alg('wL_cutoff')
            my_alg('wR_desired') = 0;
            my_alg('wL_desired') = 0;
        elseif my_alg('right encoder')<4 && my_alg('left encoder')<4
            my_alg('wR_desired') = w_max;
            my_alg('wL_desired') = w_max;
        else
            my_alg('wR_desired') = my_alg('wR_desired_temp');
            my_alg('wL_desired') = my_alg('wL_desired_temp');
        end

    end
        % Save data for ploting
        my_alg('wR_all') = [my_alg('wR_all') my_alg('right encoder')];
        my_alg('wL_all') = [my_alg('wL_all') my_alg('left encoder')];
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
    plot(my_alg('wR_all'));
    hold on
    plot(my_alg('wL_all'));
    
end


return