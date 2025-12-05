%% SimuLift 3D - Examples and Scenarios
% This script demonstrates various usage examples of SimuLift 3D
% Author: Gianluigi Riccardi

%% Example 1: Basic 3D Usage - Default Scenario
fprintf('Example 1: Running default 3D scenario...\n\n');

% Run with default 3D configuration
% Note: This requires SimuLift_3D.slx to exist
% If the model doesn't exist, it will generate instructions
run_simulift_3D('scenario', 'default', 'simulate', false);

fprintf('\n════════════════════════════════════════════\n\n');

%% Example 2: Light Load 3D Simulation
fprintf('Example 2: Light load 3D simulation...\n\n');

% Small payload in calm conditions
% Demonstrates basic 3D dynamics
run_simulift('Scenario', 'light_load', 'Use3D', true);

fprintf('\n════════════════════════════════════════════\n\n');

%% Example 3: Heavy Load with 3D Visualization
fprintf('Example 3: Heavy industrial load 3D...\n\n');

% Large payload requiring careful handling
% Shows complex multi-body dynamics
run_simulift('scenario', 'heavy_load', 'use3d', true);

fprintf('\n════════════════════════════════════════════\n\n');

%% Example 4: Wind Effects in 3D
fprintf('Example 4: Wind effects on payload in 3D...\n\n');

% High wind scenario showing aerodynamic forces
% Demonstrates lateral payload movement
run_simulift_3D('scenario', 'heavy_wind');

fprintf('\n════════════════════════════════════════════\n\n');

%% Example 5: Custom 3D Configuration
fprintf('Example 5: Custom 3D configuration...\n\n');

% Create a custom configuration with specific 3D parameters
config_custom_3D = struct(...
    'Theoretical_Weight', 1500, ...  % Medium load
    'Pulley_Weight', 30, ...
    'Slings_Weight', 20, ...
    'Safety_Factor', 1.4, ...
    'Height', 2.5, ...               % Initial drop height
    'Deformation_Limit', 0.18, ...
    'Beaufort_Scale', 5, ...         % Fresh breeze
    'Exposed_Area', 2.0, ...
    'Crane_Capacity', 4000, ...
    % 3D-specific parameters
    'Payload_Length', 1.8, ...       % Elongated payload
    'Payload_Width', 1.2, ...
    'Payload_Height', 0.9, ...
    'Hook_Mass', 35, ...
    'Sling_Length', 3.5, ...
    'Sling_Damping', 90, ...
    'Sling_Stiffness', 9500, ...
    'Drag_Coefficient', 1.25, ...
    'Air_Density', 1.225, ...
    'Simulation_Time', 12, ...
    'Gravity', [0; 0; -9.81]);

run_simulift_3D('config', config_custom_3D, 'simulate', false);

fprintf('\n════════════════════════════════════════════\n\n');

%% Example 6: Comparison - 2D vs 3D Parameters
fprintf('Example 6: Comparing 2D and 3D simulation approaches...\n\n');

config_compare = struct(...
    'Theoretical_Weight', 2500, ...
    'Pulley_Weight', 45, ...
    'Slings_Weight', 28, ...
    'Safety_Factor', 1.3, ...
    'Height', 2, ...
    'Deformation_Limit', 0.2, ...
    'Beaufort_Scale', 6, ...
    'Exposed_Area', 1.8, ...
    'Crane_Capacity', 5000);

fprintf('Running 2D simulation:\n');
fprintf('---------------------\n');
report_2D = SimuLiftUtils.generate_safety_report(config_compare);
SimuLiftUtils.print_report(report_2D);

fprintf('\nRunning 3D simulation setup:\n');
fprintf('---------------------------\n');
% Add 3D-specific parameters
config_compare.Payload_Length = 2.0;
config_compare.Payload_Width = 1.5;
config_compare.Payload_Height = 1.0;
config_compare.Hook_Mass = 45;
config_compare.Sling_Length = 3.0;
config_compare.Sling_Damping = 100;
config_compare.Sling_Stiffness = 10000;
config_compare.Drag_Coefficient = 1.2;
config_compare.Air_Density = 1.225;
config_compare.Simulation_Time = 10;
config_compare.Gravity = [0; 0; -9.81];

run_simulift_3D('config', config_compare, 'simulate', false);

fprintf('\n════════════════════════════════════════════\n\n');

%% Example 7: Different Payload Geometries
fprintf('Example 7: Testing different payload shapes...\n\n');

shapes = {
    'Compact cube',    1.5, 1.5, 1.5;
    'Flat panel',      3.0, 2.0, 0.5;
    'Long beam',       4.0, 0.5, 0.5;
    'Standard box',    2.0, 1.5, 1.0
};

base_mass = 1000;  % kg - constant mass
fprintf('Payload Geometry Analysis (constant mass: %d kg):\n', base_mass);
fprintf('=================================================\n\n');

for i = 1:size(shapes, 1)
    name = shapes{i, 1};
    length = shapes{i, 2};
    width = shapes{i, 3};
    height = shapes{i, 4};
    
    volume = length * width * height;
    density = base_mass / volume;
    
    % Calculate approximate exposed area (front face + side face)
    exposed_area = (width * height) + (length * height);
    
    % Wind force estimate
    wind_speed = SimuLiftUtils.beaufort_to_wind_speed(6);  % Beaufort 6
    wind_force = SimuLiftUtils.calculate_wind_force(wind_speed, exposed_area, 1.2);
    
    fprintf('%d. %s:\n', i, name);
    fprintf('   Dimensions: %.1f x %.1f x %.1f m\n', length, width, height);
    fprintf('   Volume: %.2f m³, Density: %.1f kg/m³\n', volume, density);
    fprintf('   Exposed area: %.2f m²\n', exposed_area);
    fprintf('   Wind force (B6): %.2f N\n\n', wind_force);
end

fprintf('\n════════════════════════════════════════════\n\n');

%% Example 8: Sling Stiffness Effects
fprintf('Example 8: Impact of sling stiffness on dynamics...\n\n');

stiffness_values = [5000, 10000, 15000, 20000];  % N/m
fprintf('Sling Stiffness Analysis:\n');
fprintf('=========================\n\n');

for k = stiffness_values
    % Calculate natural frequency (simplified)
    mass = 2000;  % kg
    omega_n = sqrt(k / mass);
    period = 2 * pi / omega_n;
    
    fprintf('  Stiffness: %d N/m\n', k);
    fprintf('    Natural frequency: %.2f rad/s (%.2f Hz)\n', omega_n, omega_n/(2*pi));
    fprintf('    Period: %.2f s\n', period);
    
    if period < 1.0
        fprintf('    → Fast oscillations, may need damping\n\n');
    elseif period > 3.0
        fprintf('    → Slow swinging, stable behavior\n\n');
    else
        fprintf('    → Moderate oscillations, typical\n\n');
    end
end

fprintf('════════════════════════════════════════════\n\n');

%% Example 9: Wind Speed Impact on Different Areas
fprintf('Example 9: Wind effects on different exposed areas...\n\n');

beaufort_range = [3, 6, 9];
area_range = [0.5, 1.5, 3.0];  % m²

fprintf('Wind Force Matrix (N):\n');
fprintf('=====================\n\n');
fprintf('%-15s', 'Area \\ Beaufort');
for b = beaufort_range
    fprintf('  B=%d    ', b);
end
fprintf('\n');
fprintf('%-15s', '---------------');
for b = beaufort_range
    fprintf('  ------  ');
end
fprintf('\n');

for area = area_range
    fprintf('%.1f m²          ', area);
    for b = beaufort_range
        wind_speed = SimuLiftUtils.beaufort_to_wind_speed(b);
        force = SimuLiftUtils.calculate_wind_force(wind_speed, area, 1.2);
        fprintf('  %6.1f  ', force);
    end
    fprintf('\n');
end

fprintf('\n════════════════════════════════════════════\n\n');

%% Example 10: Safety Recommendations for 3D Scenarios
fprintf('Example 10: Safety recommendations based on 3D analysis...\n\n');

scenarios_3D = {
    'Warehouse operation', 800,  1.5, 3, 2500;
    'Construction site',   3500, 1.3, 6, 6000;
    'Marine loading',      5000, 1.2, 7, 8000;
    'Emergency recovery',  1200, 1.8, 5, 3000
};

fprintf('3D Scenario Safety Assessment:\n');
fprintf('==============================\n\n');

for i = 1:size(scenarios_3D, 1)
    name = scenarios_3D{i, 1};
    weight = scenarios_3D{i, 2};
    sf = scenarios_3D{i, 3};
    beaufort = scenarios_3D{i, 4};
    capacity = scenarios_3D{i, 5};
    
    cfg = struct(...
        'Theoretical_Weight', weight, ...
        'Pulley_Weight', weight * 0.02, ...
        'Slings_Weight', weight * 0.015, ...
        'Safety_Factor', sf, ...
        'Height', 2, ...
        'Deformation_Limit', 0.2, ...
        'Beaufort_Scale', beaufort, ...
        'Exposed_Area', 1.5, ...
        'Crane_Capacity', capacity);
    
    rep = SimuLiftUtils.generate_safety_report(cfg);
    
    fprintf('%d. %s:\n', i, name);
    fprintf('   Load: %.0f kg, Capacity: %.0f kg\n', rep.total_mass, capacity);
    fprintf('   Wind: %s (%.1f m/s)\n', rep.wind_description, rep.wind_speed);
    fprintf('   Status: %s\n', iif(rep.safe_to_lift, '✅ SAFE', '❌ UNSAFE'));
    fprintf('   Risk: %s\n', rep.risk_level);
    
    % 3D-specific recommendations
    if contains(rep.risk_level, 'HIGH') || contains(rep.risk_level, 'CRITICAL')
        fprintf('   Recommendations:\n');
        fprintf('     • Use 3D simulation to verify dynamics\n');
        if rep.wind_speed > 15
            fprintf('     • Monitor wind direction and gusts\n');
            fprintf('     • Consider postponing lift\n');
        end
        if rep.load_ratio > 0.85
            fprintf('     • Verify crane capacity and stability\n');
            fprintf('     • Use additional safety measures\n');
        end
    else
        fprintf('   Recommendations:\n');
        fprintf('     • Standard 3D safety protocols\n');
        fprintf('     • Monitor conditions during lift\n');
    end
    fprintf('\n');
end

fprintf('═══════════════════════════════════════════\n');
fprintf('End of 3D Examples\n');
fprintf('═══════════════════════════════════════════\n\n');

fprintf('Note: To run actual 3D simulations, you need to:\n');
fprintf('1. Create SimuLift_3D.slx in Simulink\n');
fprintf('2. Add Simscape Multibody components as described\n');
fprintf('3. Run: run_simulift(''Scenario'', ''heavy_load'', ''Use3D'', true)\n\n');

function result = iif(condition, true_val, false_val)
    % IIF Inline if function
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
