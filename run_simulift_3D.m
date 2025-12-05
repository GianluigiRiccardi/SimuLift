%% SimuLift 3D - Simscape Multibody Simulation Runner
% This function runs the 3D lifting simulation using Simscape Multibody
% Author: Gianluigi Riccardi
% Enhanced version with 3D visualization and dynamics

function simOut = run_simulift_3D(varargin)
    % RUN_SIMULIFT_3D Main function to run SimuLift 3D simulations
    %
    % Usage:
    %   run_simulift_3D() - Interactive mode with default parameters
    %   run_simulift_3D('config', params) - Run with custom parameters
    %   run_simulift_3D('scenario', scenario_name) - Run predefined scenario
    %
    % Examples:
    %   run_simulift_3D()
    %   run_simulift_3D('scenario', 'light_load')
    %   run_simulift_3D('scenario', 'heavy_wind')
    %
    % The 3D model includes:
    %   - Crane hook (rigid body)
    %   - Sling system (cables or rigid linkages)
    %   - Payload block (rectangular solid)
    %   - Wind force (aerodynamic drag)
    %   - Joints and constraints
    
    % Parse inputs
    p = inputParser;
    addParameter(p, 'config', [], @isstruct);
    addParameter(p, 'scenario', 'default', @ischar);
    addParameter(p, 'model', 'SimuLift_3D.slx', @ischar);
    addParameter(p, 'verbose', true, @islogical);
    addParameter(p, 'simulate', true, @islogical);
    parse(p, varargin{:});
    
    config = p.Results.config;
    scenario = p.Results.scenario;
    modelPath = p.Results.model;
    verbose = p.Results.verbose;
    simulate = p.Results.simulate;
    
    % Load configuration
    if isempty(config)
        if strcmp(scenario, 'default')
            config = get_default_3D_config();
        else
            config = get_scenario_3D_config(scenario);
        end
    end
    
    if verbose
        fprintf('\n========================================\n');
        fprintf('  SimuLift 3D - Multibody Simulation\n');
        fprintf('========================================\n\n');
        fprintf('Running scenario: %s\n\n', scenario);
        display_3D_config(config);
    end
    
    % Check if model exists
    if ~exist(modelPath, 'file')
        if verbose
            fprintf('⚠️  3D model not found: %s\n', modelPath);
            fprintf('Creating model structure and configuration...\n\n');
        end
        create_3D_model_structure(modelPath, config);
        
        if ~simulate
            fprintf('Model structure created. Open in Simulink to build the 3D model:\n');
            fprintf('   open_system(''%s'')\n\n', modelPath);
            fprintf('Required components:\n');
            fprintf('  • Crane hook (Simscape Multibody Rigid Body)\n');
            fprintf('  • Sling system (Simscape Multibody Flexible Cable or Rigid Links)\n');
            fprintf('  • Payload (Simscape Multibody Solid Block - Rectangular)\n');
            fprintf('  • Joints: Hook→Sling (Spherical), Sling→Payload (Revolute/Universal)\n');
            fprintf('  • Wind force (External Force & Torque block)\n');
            fprintf('  • Mechanism Configuration (Solver Configuration block)\n\n');
            simOut = [];
            return;
        end
    end
    
    % Load the model
    try
        load_system(modelPath);
        modelName = bdroot;
        
        if verbose
            fprintf('Loaded 3D model: %s\n\n', modelPath);
        end
    catch ME
        error('SimuLift3D:ModelLoadError', ...
              'Failed to load 3D model: %s\n\nCreate the model first or set simulate=false.', ...
              ME.message);
    end
    
    % Apply configuration to model using SimulationInput
    try
        simIn = apply_3D_config_to_model(modelName, config, verbose);
    catch ME
        close_system(modelName, 0);
        error('SimuLift3D:ConfigError', ...
              'Failed to apply configuration: %s', ME.message);
    end
    
    % Run simulation
    if verbose
        fprintf('Running 3D simulation...\n');
    end
    
    try
        simOut = sim(simIn);
        
        if verbose
            fprintf('3D Simulation completed successfully!\n\n');
            
            % Display results if available
            display_3D_results(simOut, config);
        end
        
    catch ME
        close_system(modelName, 0);
        error('SimuLift3D:SimulationError', ...
              '3D Simulation failed: %s', ME.message);
    end
    
    % Keep model open for 3D visualization
    if verbose
        fprintf('\n========================================\n');
        fprintf('  3D Simulation Complete\n');
        fprintf('========================================\n');
        fprintf('\nThe model remains open for 3D visualization.\n');
        fprintf('To view animation, use Mechanics Explorer.\n');
        fprintf('Close model with: close_system(''%s'', 0)\n\n', modelName);
    end
end

function config = get_default_3D_config()
    % GET_DEFAULT_3D_CONFIG Returns default 3D simulation parameters
    
    % Standard lifting parameters
    config.Theoretical_Weight = 3000;  % kg - Payload mass
    config.Pulley_Weight = 50;         % kg - Not used in 3D (hook mass instead)
    config.Slings_Weight = 30;         % kg - Sling mass
    config.Safety_Factor = 1.25;       % Safety multiplier
    config.Height = 2;                 % m - Initial vertical offset (drop height)
    config.Deformation_Limit = 0.2;    % m - Deformation margin (damping reference)
    config.Beaufort_Scale = 6;         % Beaufort wind scale
    config.Exposed_Area = 1.5;         % m² - Surface area for wind
    config.Crane_Capacity = 5000;      % kg - Crane capacity
    
    % 3D-specific parameters
    config.Payload_Length = 2.0;       % m - Rectangular solid dimension
    config.Payload_Width = 1.5;        % m - Rectangular solid dimension
    config.Payload_Height = 1.0;       % m - Rectangular solid dimension
    config.Hook_Mass = 50;             % kg - Hook rigid body mass
    config.Sling_Length = 3.0;         % m - Length of sling cables
    config.Sling_Damping = 100;        % N/(m/s) - Cable damping coefficient
    config.Sling_Stiffness = 10000;    % N/m - Cable stiffness
    config.Drag_Coefficient = 1.2;     % Cd - Drag coefficient for payload
    config.Air_Density = 1.225;        % kg/m³ - Air density at sea level
    config.Simulation_Time = 10;       % s - Simulation duration
    config.Gravity = [0; 0; -9.81];    % m/s² - Gravity vector
end

function config = get_scenario_3D_config(scenario)
    % GET_SCENARIO_3D_CONFIG Returns configuration for predefined 3D scenarios
    
    switch lower(scenario)
        case 'light_load'
            config.Theoretical_Weight = 500;
            config.Pulley_Weight = 20;
            config.Slings_Weight = 10;
            config.Safety_Factor = 1.5;
            config.Height = 1;
            config.Deformation_Limit = 0.15;
            config.Beaufort_Scale = 3;
            config.Exposed_Area = 0.8;
            config.Crane_Capacity = 2000;
            % 3D-specific
            config.Payload_Length = 1.0;
            config.Payload_Width = 0.8;
            config.Payload_Height = 0.6;
            config.Hook_Mass = 20;
            config.Sling_Length = 2.0;
            config.Sling_Damping = 80;
            config.Sling_Stiffness = 8000;
            config.Drag_Coefficient = 1.1;
            config.Air_Density = 1.225;
            config.Simulation_Time = 10;
            config.Gravity = [0; 0; -9.81];
            
        case 'heavy_load'
            config.Theoretical_Weight = 8000;
            config.Pulley_Weight = 100;
            config.Slings_Weight = 80;
            config.Safety_Factor = 1.25;
            config.Height = 3;
            config.Deformation_Limit = 0.25;
            config.Beaufort_Scale = 4;
            config.Exposed_Area = 3.0;
            config.Crane_Capacity = 12000;
            % 3D-specific
            config.Payload_Length = 3.0;
            config.Payload_Width = 2.0;
            config.Payload_Height = 1.5;
            config.Hook_Mass = 100;
            config.Sling_Length = 4.0;
            config.Sling_Damping = 150;
            config.Sling_Stiffness = 15000;
            config.Drag_Coefficient = 1.3;
            config.Air_Density = 1.225;
            config.Simulation_Time = 15;
            config.Gravity = [0; 0; -9.81];
            
        case 'heavy_wind'
            config.Theoretical_Weight = 2000;
            config.Pulley_Weight = 40;
            config.Slings_Weight = 25;
            config.Safety_Factor = 1.5;
            config.Height = 2;
            config.Deformation_Limit = 0.2;
            config.Beaufort_Scale = 9;  % Strong gale
            config.Exposed_Area = 2.5;
            config.Crane_Capacity = 5000;
            % 3D-specific
            config.Payload_Length = 2.5;
            config.Payload_Width = 2.0;
            config.Payload_Height = 0.8;
            config.Hook_Mass = 40;
            config.Sling_Length = 3.0;
            config.Sling_Damping = 100;
            config.Sling_Stiffness = 10000;
            config.Drag_Coefficient = 1.5;  % Higher drag for flat surface
            config.Air_Density = 1.225;
            config.Simulation_Time = 12;
            config.Gravity = [0; 0; -9.81];
            
        case 'critical'
            config.Theoretical_Weight = 4500;
            config.Pulley_Weight = 60;
            config.Slings_Weight = 40;
            config.Safety_Factor = 1.1;  % Low safety factor
            config.Height = 5;
            config.Deformation_Limit = 0.05;  % Small deformation
            config.Beaufort_Scale = 7;
            config.Exposed_Area = 2.0;
            config.Crane_Capacity = 5000;
            % 3D-specific
            config.Payload_Length = 2.0;
            config.Payload_Width = 1.5;
            config.Payload_Height = 1.2;
            config.Hook_Mass = 60;
            config.Sling_Length = 5.0;  % Long sling
            config.Sling_Damping = 120;
            config.Sling_Stiffness = 12000;
            config.Drag_Coefficient = 1.2;
            config.Air_Density = 1.225;
            config.Simulation_Time = 20;  % Longer observation
            config.Gravity = [0; 0; -9.81];
            
        otherwise
            config = get_default_3D_config();
    end
end

function simIn = apply_3D_config_to_model(modelName, config, verbose)
    % APPLY_3D_CONFIG_TO_MODEL Applies configuration parameters to 3D model
    % Uses SimulationInput object for programmatic parameter setting
    
    % Create SimulationInput object
    simIn = Simulink.SimulationInput(modelName);
    
    % Calculate wind speed from Beaufort scale
    wind_speed = SimuLiftUtils.beaufort_to_wind_speed(config.Beaufort_Scale);
    
    % Calculate payload volume and verify mass/density consistency
    payload_volume = config.Payload_Length * config.Payload_Width * config.Payload_Height;
    payload_density = config.Theoretical_Weight / payload_volume;
    
    if verbose
        fprintf('Setting 3D model parameters:\n');
        fprintf('  Payload dimensions: %.2f x %.2f x %.2f m\n', ...
                config.Payload_Length, config.Payload_Width, config.Payload_Height);
        fprintf('  Payload volume: %.3f m³\n', payload_volume);
        fprintf('  Payload density: %.2f kg/m³\n', payload_density);
        fprintf('  Wind speed: %.2f m/s (Beaufort %d)\n\n', ...
                wind_speed, config.Beaufort_Scale);
    end
    
    % Set model workspace variables using setVariable
    % These variables should be referenced in the Simscape blocks
    
    % Payload parameters
    simIn = simIn.setVariable('payload_mass', config.Theoretical_Weight);
    simIn = simIn.setVariable('payload_length', config.Payload_Length);
    simIn = simIn.setVariable('payload_width', config.Payload_Width);
    simIn = simIn.setVariable('payload_height', config.Payload_Height);
    simIn = simIn.setVariable('payload_density', payload_density);
    
    % Hook parameters
    simIn = simIn.setVariable('hook_mass', config.Hook_Mass);
    
    % Sling parameters
    simIn = simIn.setVariable('sling_mass', config.Slings_Weight);
    simIn = simIn.setVariable('sling_length', config.Sling_Length);
    simIn = simIn.setVariable('sling_damping', config.Sling_Damping);
    simIn = simIn.setVariable('sling_stiffness', config.Sling_Stiffness);
    
    % Wind and aerodynamic parameters
    simIn = simIn.setVariable('wind_speed', wind_speed);
    simIn = simIn.setVariable('beaufort_scale', config.Beaufort_Scale);
    simIn = simIn.setVariable('exposed_area', config.Exposed_Area);
    simIn = simIn.setVariable('drag_coefficient', config.Drag_Coefficient);
    simIn = simIn.setVariable('air_density', config.Air_Density);
    
    % Initial conditions and simulation parameters
    simIn = simIn.setVariable('initial_height', config.Height);
    simIn = simIn.setVariable('safety_factor', config.Safety_Factor);
    simIn = simIn.setVariable('deformation_limit', config.Deformation_Limit);
    simIn = simIn.setVariable('gravity', config.Gravity);
    
    % Crane capacity for safety checks
    simIn = simIn.setVariable('crane_capacity', config.Crane_Capacity);
    
    % Set simulation time
    simIn = simIn.setModelParameter('StopTime', num2str(config.Simulation_Time));
    
    % Set solver parameters for Simscape Multibody
    % Use variable-step solver for better accuracy with physical systems
    simIn = simIn.setModelParameter('SolverType', 'Variable-step');
    simIn = simIn.setModelParameter('Solver', 'ode45');  % or 'ode15s' for stiff systems
    simIn = simIn.setModelParameter('RelTol', '1e-3');
    simIn = simIn.setModelParameter('AbsTol', 'auto');
    
    % Enable data logging
    simIn = simIn.setModelParameter('SaveOutput', 'on');
    simIn = simIn.setModelParameter('OutputSaveName', 'yout');
end

function display_3D_config(config)
    % DISPLAY_3D_CONFIG Pretty prints the 3D configuration
    
    fprintf('3D Configuration Parameters:\n');
    fprintf('============================\n\n');
    
    fprintf('PAYLOAD:\n');
    fprintf('  Mass:               %g kg\n', config.Theoretical_Weight);
    fprintf('  Dimensions:         %.2f x %.2f x %.2f m\n', ...
            config.Payload_Length, config.Payload_Width, config.Payload_Height);
    payload_volume = config.Payload_Length * config.Payload_Width * config.Payload_Height;
    fprintf('  Volume:             %.3f m³\n', payload_volume);
    fprintf('  Density:            %.2f kg/m³\n\n', config.Theoretical_Weight / payload_volume);
    
    fprintf('LIFTING SYSTEM:\n');
    fprintf('  Hook Mass:          %g kg\n', config.Hook_Mass);
    fprintf('  Sling Mass:         %g kg\n', config.Slings_Weight);
    fprintf('  Sling Length:       %.2f m\n', config.Sling_Length);
    fprintf('  Sling Stiffness:    %g N/m\n', config.Sling_Stiffness);
    fprintf('  Sling Damping:      %g N/(m/s)\n\n', config.Sling_Damping);
    
    fprintf('OPERATIONAL:\n');
    total_mass = config.Theoretical_Weight + config.Hook_Mass + config.Slings_Weight;
    fprintf('  Total Mass:         %g kg\n', total_mass);
    fprintf('  Crane Capacity:     %g kg\n', config.Crane_Capacity);
    fprintf('  Safety Factor:      %g\n', config.Safety_Factor);
    fprintf('  Initial Height:     %g m\n', config.Height);
    fprintf('  Deformation Limit:  %g m\n\n', config.Deformation_Limit);
    
    wind_speed = SimuLiftUtils.beaufort_to_wind_speed(config.Beaufort_Scale);
    fprintf('ENVIRONMENTAL:\n');
    fprintf('  Beaufort Scale:     %g (%s)\n', config.Beaufort_Scale, ...
            SimuLiftUtils.get_beaufort_description(config.Beaufort_Scale));
    fprintf('  Wind Speed:         %.2f m/s (%.2f km/h)\n', wind_speed, wind_speed * 3.6);
    fprintf('  Exposed Area:       %g m²\n', config.Exposed_Area);
    fprintf('  Drag Coefficient:   %.2f\n', config.Drag_Coefficient);
    fprintf('  Air Density:        %.3f kg/m³\n\n', config.Air_Density);
    
    fprintf('SIMULATION:\n');
    fprintf('  Duration:           %g s\n', config.Simulation_Time);
    fprintf('  Gravity:            [%.2f, %.2f, %.2f] m/s²\n\n', ...
            config.Gravity(1), config.Gravity(2), config.Gravity(3));
end

function display_3D_results(simOut, config)
    % DISPLAY_3D_RESULTS Display 3D simulation results
    
    fprintf('3D Simulation Results:\n');
    fprintf('======================\n\n');
    
    % Generate standard safety report
    report = SimuLiftUtils.generate_safety_report(config);
    
    fprintf('SAFETY ANALYSIS:\n');
    fprintf('  Load Ratio:         %.1f%% of capacity\n', report.load_ratio * 100);
    fprintf('  Risk Level:         %s\n', report.risk_level);
    fprintf('  Safe to Lift:       %s\n\n', ...
            iif(report.safe_to_lift, '✅ YES', '❌ NO'));
    
    % Wind force calculation
    wind_speed = SimuLiftUtils.beaufort_to_wind_speed(config.Beaufort_Scale);
    wind_force = SimuLiftUtils.calculate_wind_force(wind_speed, config.Exposed_Area, ...
                                                     config.Drag_Coefficient);
    
    fprintf('WIND EFFECTS:\n');
    fprintf('  Wind Force:         %.2f N (%.2f kgf)\n', wind_force, wind_force/9.81);
    fprintf('  Wind Description:   %s\n\n', report.wind_description);
    
    fprintf('IMPACT ANALYSIS:\n');
    fprintf('  Calculated Impact:  %.2f N (%.2f kgf)\n', ...
            report.impact_force_n, report.impact_force_kgf);
    
    fprintf('\n3D VISUALIZATION:\n');
    fprintf('  Open Mechanics Explorer to view 3D animation\n');
    fprintf('  Use Simscape Results Explorer for detailed plots\n\n');
end

function create_3D_model_structure(modelPath, config)
    % CREATE_3D_MODEL_STRUCTURE Creates a template/documentation for the 3D model
    % Note: Actual Simscape Multibody model must be created in Simulink GUI
    
    % Create a text file with instructions for building the model
    [filepath, name, ~] = fileparts(modelPath);
    if isempty(filepath)
        filepath = '.';
    end
    instructionFile = fullfile(filepath, [name '_Instructions.txt']);
    
    fid = fopen(instructionFile, 'w');
    if fid == -1
        warning('Could not create instruction file');
        return;
    end
    
    fprintf(fid, 'SimuLift 3D Model Creation Instructions\n');
    fprintf(fid, '========================================\n\n');
    fprintf(fid, 'Model File: %s\n\n', modelPath);
    fprintf(fid, 'Required Simscape Multibody Components:\n');
    fprintf(fid, '--------------------------------------\n\n');
    
    fprintf(fid, '1. WORLD FRAME\n');
    fprintf(fid, '   - Add: Mechanism Configuration block\n');
    fprintf(fid, '   - Set gravity: [0; 0; -9.81] m/s²\n\n');
    
    fprintf(fid, '2. CRANE HOOK (Fixed Reference Point)\n');
    fprintf(fid, '   - Add: Rigid Transform block\n');
    fprintf(fid, '   - Position: [0; 0; initial_height] (from workspace)\n');
    fprintf(fid, '   - This represents the crane hook attachment point\n\n');
    
    fprintf(fid, '3. HOOK BODY\n');
    fprintf(fid, '   - Add: Solid block (or Brick Solid)\n');
    fprintf(fid, '   - Mass: hook_mass (from workspace)\n');
    fprintf(fid, '   - Small dimensions: [0.1 x 0.1 x 0.2] m\n\n');
    
    fprintf(fid, '4. SLING SYSTEM\n');
    fprintf(fid, '   Option A - Flexible Cable:\n');
    fprintf(fid, '   - Add: Cable block (Simscape Multibody/Body Elements)\n');
    fprintf(fid, '   - Length: sling_length (from workspace)\n');
    fprintf(fid, '   - Damping: sling_damping (from workspace)\n');
    fprintf(fid, '   - Stiffness: sling_stiffness (from workspace)\n\n');
    fprintf(fid, '   Option B - Rigid Links (simpler):\n');
    fprintf(fid, '   - Add: Cylindrical Solid blocks\n');
    fprintf(fid, '   - Total mass: sling_mass (from workspace)\n');
    fprintf(fid, '   - Connect with Revolute Joints for flexibility\n\n');
    
    fprintf(fid, '5. PAYLOAD\n');
    fprintf(fid, '   - Add: Brick Solid block\n');
    fprintf(fid, '   - Dimensions: [payload_length, payload_width, payload_height] (from workspace)\n');
    fprintf(fid, '   - Mass: payload_mass (from workspace)\n');
    fprintf(fid, '   - Or use density: payload_density (from workspace)\n\n');
    
    fprintf(fid, '6. JOINTS\n');
    fprintf(fid, '   - Hook to Sling: Spherical Joint (allows swinging)\n');
    fprintf(fid, '   - Sling to Payload: Universal Joint or Spherical Joint\n\n');
    
    fprintf(fid, '7. WIND FORCE\n');
    fprintf(fid, '   - Add: External Force & Torque block\n');
    fprintf(fid, '   - Connect to Payload frame\n');
    fprintf(fid, '   - Force calculation (use MATLAB Function block):\n');
    fprintf(fid, '     F_wind = 0.5 * air_density * wind_speed^2 * exposed_area * drag_coefficient\n');
    fprintf(fid, '   - Direction: [1; 0; 0] (X-axis, horizontal wind)\n\n');
    
    fprintf(fid, '8. SENSORS (Optional for data logging)\n');
    fprintf(fid, '   - Add: Transform Sensor (for payload position)\n');
    fprintf(fid, '   - Add: Joint Sensor (for cable tensions)\n\n');
    
    fprintf(fid, '9. VISUALIZATION\n');
    fprintf(fid, '   - Add colors and geometry to Solid blocks\n');
    fprintf(fid, '   - Enable Mechanics Explorer\n\n');
    
    fprintf(fid, 'Workspace Variables (set by run_simulift_3D.m):\n');
    fprintf(fid, '-----------------------------------------------\n');
    fprintf(fid, '  payload_mass       = %.2f kg\n', config.Theoretical_Weight);
    fprintf(fid, '  payload_length     = %.2f m\n', config.Payload_Length);
    fprintf(fid, '  payload_width      = %.2f m\n', config.Payload_Width);
    fprintf(fid, '  payload_height     = %.2f m\n', config.Payload_Height);
    fprintf(fid, '  hook_mass          = %.2f kg\n', config.Hook_Mass);
    fprintf(fid, '  sling_mass         = %.2f kg\n', config.Slings_Weight);
    fprintf(fid, '  sling_length       = %.2f m\n', config.Sling_Length);
    fprintf(fid, '  sling_damping      = %.2f N/(m/s)\n', config.Sling_Damping);
    fprintf(fid, '  sling_stiffness    = %.2f N/m\n', config.Sling_Stiffness);
    fprintf(fid, '  wind_speed         = %.2f m/s\n', ...
            SimuLiftUtils.beaufort_to_wind_speed(config.Beaufort_Scale));
    fprintf(fid, '  exposed_area       = %.2f m²\n', config.Exposed_Area);
    fprintf(fid, '  drag_coefficient   = %.2f\n', config.Drag_Coefficient);
    fprintf(fid, '  air_density        = %.3f kg/m³\n', config.Air_Density);
    fprintf(fid, '  initial_height     = %.2f m\n', config.Height);
    fprintf(fid, '  gravity            = [0; 0; -9.81] m/s²\n\n');
    
    fprintf(fid, 'Solver Settings:\n');
    fprintf(fid, '---------------\n');
    fprintf(fid, '  Type: Variable-step\n');
    fprintf(fid, '  Solver: ode45 (or ode15s for stiff systems)\n');
    fprintf(fid, '  Stop time: %.1f seconds\n\n', config.Simulation_Time);
    
    fprintf(fid, 'Next Steps:\n');
    fprintf(fid, '----------\n');
    fprintf(fid, '1. Create new Simulink model: %s\n', modelPath);
    fprintf(fid, '2. Add Simscape Multibody components as described above\n');
    fprintf(fid, '3. Reference workspace variables in block parameters\n');
    fprintf(fid, '4. Connect blocks according to the physical system\n');
    fprintf(fid, '5. Run: run_simulift_3D(''scenario'', ''heavy_load'')\n\n');
    
    fclose(fid);
    
    fprintf('Created instruction file: %s\n', instructionFile);
    fprintf('Follow these instructions to build the 3D model in Simulink.\n\n');
end

function result = iif(condition, true_val, false_val)
    % IIF Inline if function
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
