%% SimuLift 3D - Example Scenario Script
% Demonstrates running a 3D simulation with the heavy_load scenario
% This script shows how to use the 3D features of SimuLift
% Author: Gianluigi Riccardi

%% Introduction
fprintf('\n╔════════════════════════════════════════════════════════╗\n');
fprintf('║  SimuLift 3D - Heavy Load Scenario Example            ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');

fprintf('This example demonstrates:\n');
fprintf('  • Running a 3D Simscape Multibody simulation\n');
fprintf('  • Configuring payload geometry and mass\n');
fprintf('  • Applying wind forces with aerodynamic drag\n');
fprintf('  • Analyzing sling dynamics and tensions\n');
fprintf('  • Visualizing results in 3D\n\n');

%% Step 1: Generate 3D Configuration
fprintf('Step 1: Generating 3D configuration for heavy load...\n');
fprintf('======================================================\n\n');

% Get the predefined heavy_load scenario configuration
config_3D = get_scenario_3D_config('heavy_load');

% Display the configuration
display_3D_config(config_3D);

%% Step 2: Safety Analysis (2D Calculations)
fprintf('Step 2: Performing safety analysis...\n');
fprintf('=====================================\n\n');

% Perform standard 2D safety checks
report = SimuLiftUtils.generate_safety_report(config_3D);
SimuLiftUtils.print_report(report);

% Additional analysis
fprintf('Additional 3D Considerations:\n');
fprintf('-----------------------------\n');

% Calculate payload volume and density
volume = config_3D.Payload_Length * config_3D.Payload_Width * config_3D.Payload_Height;
density = config_3D.Theoretical_Weight / volume;

fprintf('Payload Volume:     %.2f m³\n', volume);
fprintf('Payload Density:    %.2f kg/m³\n', density);

% Sling dynamics analysis
sling_mass = config_3D.Slings_Weight;
sling_stiffness = config_3D.Sling_Stiffness;
payload_mass = config_3D.Theoretical_Weight;

% Natural frequency of the system (simplified as mass-spring)
total_mass = payload_mass + sling_mass;
omega_n = sqrt(sling_stiffness / total_mass);
frequency_hz = omega_n / (2 * pi);
period = 2 * pi / omega_n;

fprintf('\nSling Dynamics:\n');
fprintf('  Natural Frequency:  %.2f rad/s (%.2f Hz)\n', omega_n, frequency_hz);
fprintf('  Oscillation Period: %.2f seconds\n', period);

% Damping analysis
c_critical = 2 * sqrt(sling_stiffness * total_mass);
damping_ratio = config_3D.Sling_Damping / c_critical;

fprintf('  Damping Ratio:      %.3f ', damping_ratio);
if damping_ratio < 0.3
    fprintf('(lightly damped - expect oscillations)\n');
elseif damping_ratio < 0.7
    fprintf('(moderately damped)\n');
elseif damping_ratio < 1.0
    fprintf('(heavily damped)\n');
else
    fprintf('(overdamped - slow settling)\n');
end

fprintf('\n');

%% Step 3: Wind Force Analysis
fprintf('Step 3: Analyzing wind effects...\n');
fprintf('==================================\n\n');

wind_speed = SimuLiftUtils.beaufort_to_wind_speed(config_3D.Beaufort_Scale);
wind_force = SimuLiftUtils.calculate_wind_force(wind_speed, config_3D.Exposed_Area, ...
                                                 config_3D.Drag_Coefficient);

fprintf('Wind Conditions:\n');
fprintf('  Beaufort Scale:     %d (%s)\n', config_3D.Beaufort_Scale, ...
        SimuLiftUtils.get_beaufort_description(config_3D.Beaufort_Scale));
fprintf('  Wind Speed:         %.2f m/s (%.2f km/h)\n', wind_speed, wind_speed * 3.6);
fprintf('  Drag Coefficient:   %.2f\n', config_3D.Drag_Coefficient);
fprintf('  Exposed Area:       %.2f m²\n', config_3D.Exposed_Area);
fprintf('  Wind Force:         %.2f N (%.2f kgf)\n\n', wind_force, wind_force / 9.81);

% Calculate lateral displacement (simplified)
lateral_accel = wind_force / total_mass;
fprintf('Effect on Payload:\n');
fprintf('  Lateral Acceleration: %.3f m/s²\n', lateral_accel);

% Estimate swing angle (simplified pendulum approximation)
L = config_3D.Sling_Length;  % Pendulum length
g = 9.81;
swing_angle = atan(lateral_accel / g) * (180 / pi);
fprintf('  Estimated Swing:      %.2f degrees\n\n', swing_angle);

%% Step 4: 3D Simulation Setup
fprintf('Step 4: Setting up 3D simulation...\n');
fprintf('====================================\n\n');

fprintf('Model Requirements:\n');
fprintf('  File:               SimuLift_3D.slx\n');
fprintf('  Toolbox:            Simscape Multibody\n');
fprintf('  Solver:             Variable-step (ode45)\n');
fprintf('  Simulation Time:    %.1f seconds\n\n', config_3D.Simulation_Time);

fprintf('Key Components:\n');
fprintf('  1. World Frame with gravity [0; 0; -9.81] m/s²\n');
fprintf('  2. Fixed crane hook at height %.2f m\n', config_3D.Height);
fprintf('  3. Hook body (mass: %.2f kg)\n', config_3D.Hook_Mass);
fprintf('  4. Flexible cable/sling:\n');
fprintf('     - Length: %.2f m\n', config_3D.Sling_Length);
fprintf('     - Stiffness: %.0f N/m\n', config_3D.Sling_Stiffness);
fprintf('     - Damping: %.0f N/(m/s)\n', config_3D.Sling_Damping);
fprintf('  5. Payload (rectangular solid):\n');
fprintf('     - Dimensions: %.2f × %.2f × %.2f m\n', ...
             config_3D.Payload_Length, config_3D.Payload_Width, config_3D.Payload_Height);
fprintf('     - Mass: %.0f kg\n', config_3D.Theoretical_Weight);
fprintf('  6. Wind force (horizontal, X-direction)\n\n');

%% Step 5: Run 3D Simulation
fprintf('Step 5: Running 3D simulation...\n');
fprintf('================================\n\n');

% Check if model exists
if exist('SimuLift_3D.slx', 'file')
    fprintf('Found SimuLift_3D.slx model.\n');
    fprintf('Starting simulation...\n\n');
    
    try
        % Run the 3D simulation
        simOut = run_simulift_3D('config', config_3D, 'verbose', true);
        
        fprintf('\n✅ 3D Simulation completed successfully!\n\n');
        
        fprintf('Visualization:\n');
        fprintf('  • Open Mechanics Explorer to view 3D animation\n');
        fprintf('  • Use rotation/zoom controls to inspect motion\n');
        fprintf('  • Check payload swing and cable tension\n\n');
        
    catch ME
        fprintf('\n⚠️  Simulation error: %s\n\n', ME.message);
        fprintf('Check model configuration and retry.\n\n');
    end
    
else
    fprintf('⚠️  SimuLift_3D.slx not found.\n\n');
    
    fprintf('Creating model instructions...\n');
    % This will generate instruction file
    run_simulift_3D('config', config_3D, 'simulate', false);
    
    fprintf('\nTo create the 3D model:\n');
    fprintf('  1. Open MATLAB/Simulink\n');
    fprintf('  2. Create new model: SimuLift_3D.slx\n');
    fprintf('  3. Follow instructions in: SimuLift_3D_Instructions.txt\n');
    fprintf('  4. Or see: SIMULIFT_3D_GUIDE.md for complete guide\n');
    fprintf('  5. Re-run this script after creating the model\n\n');
end

%% Step 6: Results Summary
fprintf('Step 6: Results Summary\n');
fprintf('=======================\n\n');

fprintf('SAFETY VERDICT:\n');
if report.safe_to_lift
    fprintf('  ✅ SAFE to proceed with lift\n\n');
    
    fprintf('RECOMMENDATIONS:\n');
    fprintf('  • Monitor wind conditions during lift\n');
    fprintf('  • Use tag lines to control swing\n');
    fprintf('  • Maintain clear zone around payload\n');
    fprintf('  • Follow standard rigging procedures\n\n');
    
    if contains(report.risk_level, 'HIGH') || contains(report.risk_level, 'MEDIUM')
        fprintf('CAUTIONS:\n');
        if report.load_ratio > 0.7
            fprintf('  ⚠️  Load is %.0f%% of crane capacity\n', report.load_ratio * 100);
        end
        if wind_speed > 10
            fprintf('  ⚠️  Wind speed %.2f m/s - monitor conditions\n', wind_speed);
        end
        if swing_angle > 5
            fprintf('  ⚠️  Expected swing angle: %.1f degrees\n', swing_angle);
        end
        fprintf('\n');
    end
else
    fprintf('  ❌ NOT SAFE - DO NOT PROCEED\n\n');
    
    fprintf('ISSUES:\n');
    if report.load_ratio > 1.0
        fprintf('  • OVERLOAD: Load exceeds crane capacity by %.0f%%\n', ...
                (report.load_ratio - 1.0) * 100);
    end
    if wind_speed > 20
        fprintf('  • DANGEROUS WIND: Speed %.2f m/s exceeds safe limit\n', wind_speed);
    end
    fprintf('\n');
    
    fprintf('ACTIONS REQUIRED:\n');
    fprintf('  • Review and reduce load if possible\n');
    fprintf('  • Consider higher capacity crane\n');
    fprintf('  • Wait for better weather conditions\n');
    fprintf('  • Consult certified lifting engineer\n\n');
end

%% Summary
fprintf('═══════════════════════════════════════════════════════\n');
fprintf('Example Completed\n');
fprintf('═══════════════════════════════════════════════════════\n\n');

fprintf('Key Takeaways:\n');
fprintf('  • 3D simulation provides detailed dynamic analysis\n');
fprintf('  • Wind forces cause lateral movement and payload swing\n');
fprintf('  • Sling stiffness and damping affect oscillation behavior\n');
fprintf('  • Safety checks should always precede lifting operations\n\n');

fprintf('Next Steps:\n');
fprintf('  • Try different scenarios: light_load, heavy_wind, critical\n');
fprintf('  • Modify parameters to see effects on dynamics\n');
fprintf('  • Compare 2D safety analysis with 3D simulation results\n');
fprintf('  • Use examples_3D.m for more comprehensive demonstrations\n\n');

fprintf('Commands to try:\n');
fprintf('  >> run_simulift(''Scenario'', ''heavy_load'', ''Use3D'', true)\n');
fprintf('  >> run_simulift_3D(''scenario'', ''heavy_wind'')\n');
fprintf('  >> examples_3D\n');
fprintf('  >> test_simulift_3D\n\n');
