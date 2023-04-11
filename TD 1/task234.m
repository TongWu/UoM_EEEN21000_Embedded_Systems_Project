function my_alg = G37_make_a_square(my_alg, robot)
% This function implements velocity controllers for both wheels 
% and applies the desired setpoints for a specified amount of time.
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
    
    % Initialise wheel angular velocity contollers
    my_alg('wR_set') = 6;
    my_alg('wL_set') = 6;
    
    my_alg('control_right') = MotorControl();
    my_alg('control_left') = MotorControl();
    
    % Initialise vectors for saving velocity data
    my_alg('wR_all') = [];
    my_alg('wL_all') = [];
    my_alg('uR_all')=[];
    my_alg('uL_all')=[];
        
    % Initialise time parameters
    my_alg('t_sampling') = 0.003;
    my_alg('t_loop') = tic;
    my_alg('t_finish') = 42;
end

%% Loop code runs here

time = toc(my_alg('tic'));      % Get time since start of session

if time < my_alg('t_finish')    % Check for algorithm finish time
    
    dt = toc(my_alg('t_loop'));
    
    if dt>my_alg('t_sampling')  % execute code when desired sampling time is reached
        my_alg('t_loop') = tic;
        

        %% Add your loop code here (replace with your controller)%%%%%%%%%
        if time < 4
 % Drive
 my_alg('wR_set') = 5;
 my_alg('wL_set') = 5;
elseif time < 5
 % Drive
 my_alg('wR_set') = 9*pi/5;
 my_alg('wL_set') = 0;
elseif time < 9
 % Drive
 my_alg('wR_set') = 5;
 my_alg('wL_set') = 5;
elseif time < 10
 % Drive
 my_alg('wR_set') = 9*pi/5;
 my_alg('wL_set') = 0;
elseif time < 14
 % Drive
 my_alg('wR_set') = 5;
 my_alg('wL_set') = 5;
elseif time < 15
 % Drive
 my_alg('wR_set') = 9*pi/5;
 my_alg('wL_set') = 0;
elseif time < 19
 % Drive
 my_alg('wR_set') = 5;
 my_alg('wL_set') = 5;
elseif time < 20
 % Drive
 my_alg('wR_set') = 9*pi/5;
 my_alg('wL_set') = 0;
elseif time < 21
 % Drive
 my_alg('wR_set') = 0;
 my_alg('wL_set') = 0;
elseif time < 22
 % Drive
 my_alg('wR_set') = 9*pi/5;
 my_alg('wL_set') = 0;
elseif time < 26
 % Drive
 my_alg('wR_set') = 5;
 my_alg('wL_set') = 5;
elseif time < 27
 % Drive
 my_alg('wR_set') = 0;
 my_alg('wL_set') = 9*pi/5;
elseif time < 31
 % Drive
 my_alg('wR_set') = 5;
 my_alg('wL_set') = 5;
elseif time < 32
 % Drive
 my_alg('wR_set') = 0;
 my_alg('wL_set') = 9*pi/5;
elseif time < 36
 % Drive
 my_alg('wR_set') = 5;
 my_alg('wL_set') = 5;
elseif time < 37
 % Drive
 my_alg('wR_set') = 0;
 my_alg('wL_set') = 9*pi/5;
elseif time < 41
 % Drive
 my_alg('wR_set') = 5;
 my_alg('wL_set') = 5;
        end
                
        % Right wheel controller %%%%%%%%%%%%%%%%%%%%
        uR = my_alg('control_right').Control(my_alg('wR_set'),my_alg('right encoder'),dt);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Left wheel controller %%%%%%%%%%%%%%%%%%%%%
        uL = my_alg('control_left').Control(my_alg('wL_set'),my_alg('left encoder'),dt);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Apply pwm signal
        my_alg('right motor') = uR;
        my_alg('left motor') = uL;

        % Save data for ploting
        my_alg('wR_all') = [my_alg('wR_all') my_alg('right encoder')];
        my_alg('wL_all') = [my_alg('wL_all') my_alg('left encoder')];
        my_alg('uR_all') = [my_alg('uR_all') my_alg('right motor')];
        my_alg('uL_all') = [my_alg('uL_all') my_alg('left motor')];
        %% End %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   end

else
    %% Finish algorithm and plot results
    % Stop motors
    my_alg('right motor') = 0;
    my_alg('left motor') = 0;
    % Stop session
    my_alg('is_done') = true;
    
    % Plot saved velocities for right and left wheel
    figure(2);
    plot(my_alg('wR_all'));
    hold on
    plot(my_alg('wL_all'));
    xlabel('Number of Sampling');
    ylabel('Wheel Speed (in rad/s)');
    legend('Right encoder','Left encoder');
    title('Wheel speeds read from encoder');
    figure(3);
    plot(my_alg('uR_all'));
    hold on
    plot(my_alg('uL_all'));
    xlabel('Number of Sampling');
    ylabel('Duty ratio');
    legend('Right control signal','Left control signal');
    title('Control signals for two motors');
    figure(4)
    plot(my_alg('wR_all')*34);
    hold on
    plot(my_alg('wL_all')*34);
    xlabel('Number of Sampling');
    ylabel('Motor speed (in rad/s)');
    legend('Right motor speed','Left motor speed');
    title('Motor speeds convert from wheel speeds');
end

return