%% SimuLift - Main Entry Point Script
% This script provides an easy interface to run SimuLift simulations
% Author: Gianluigi Riccardi
% Enhanced version with automation capabilities

function run_simulift(varargin)
    % RUN_SIMULIFT Main function to run SimuLift simulations
    %
    % Usage:
    %   run_simulift() - Interactive mode with default parameters
    %   run_simulift('config', params) - Run with custom parameters
    %   run_simulift('scenario', scenario_name) - Run predefined scenario
    %   run_simulift('Scenario', scenario_name, 'Use3D', true) - Run 3D simulation
    %
    % Parameters:
    %   'config'   - Structure with simulation parameters (optional)
    %   'scenario' - Predefined scenario name: 'default', 'light_load', 
    %                'heavy_load', 'heavy_wind', 'critical'
    %   'Use3D'    - Boolean flag to use 3D Simscape Multibody model (default: false)
    %   'model'    - Path to Simulink model (optional)
    %   'verbose'  - Display detailed output (default: true)
    %
    % Examples:
    %   run_simulift()
    %   run_simulift('scenario', 'light_load')
    %   run_simulift('scenario', 'heavy_wind')
    %   run_simulift('Scenario', 'heavy_load', 'Use3D', true)  % 3D mode
    %   run_simulift('scenario', 'default', 'use3d', true)     % 3D mode (case-insensitive)
    
    % Parse inputs
    p = inputParser;
    addParameter(p, 'config', [], @isstruct);
    addParameter(p, 'scenario', 'default', @ischar);
    addParameter(p, 'Scenario', 'default', @ischar);  % Alternative capitalization
    addParameter(p, 'model', 'Simulift/SimuLift.slx', @ischar);
    addParameter(p, 'verbose', true, @islogical);
    addParameter(p, 'Use3D', false, @islogical);  % New parameter for 3D simulation
    addParameter(p, 'use3d', false, @islogical);  % Alternative lowercase
    parse(p, varargin{:});
    
    config = p.Results.config;
    % Support both 'scenario' and 'Scenario' (case-insensitive)
    scenario = p.Results.scenario;
    if ~strcmp(p.Results.Scenario, 'default')
        scenario = p.Results.Scenario;
    end
    modelPath = p.Results.model;
    verbose = p.Results.verbose;
    % Support both 'Use3D' and 'use3d' (case-insensitive)
    use3D = p.Results.Use3D || p.Results.use3d;
    
    % Check if Simulink model exists
    % Try multiple possible model locations
    possible_paths = {
        modelPath,
        'Simulift/SimuLift.slx',
        'SimuLift (4).slx'  % Legacy filename
    };
    
    modelFound = false;
    for i = 1:length(possible_paths)
        if exist(possible_paths{i}, 'file')
            modelPath = possible_paths{i};
            modelFound = true;
            break;
        end
    end
    
    if ~modelFound
        error('SimuLift:ModelNotFound', ...
              'Cannot find SimuLift model file. Tried: %s', ...
              strjoin(possible_paths, ', '));
    end
    
    % Load configuration
    if isempty(config)
        if strcmp(scenario, 'default')
            config = get_default_config();
        else
            config = get_scenario_config(scenario);
        end
    end
    
    % Check if 3D mode is requested
    if use3D
        % Delegate to 3D simulation function
        if verbose
            fprintf('\n========================================\n');
            fprintf('  SimuLift - 3D Mode Requested\n');
            fprintf('========================================\n\n');
            fprintf('Redirecting to 3D Simscape Multibody simulation...\n\n');
        end
        run_simulift_3D('scenario', scenario, 'config', config, 'verbose', verbose);
        return;
    end
    
    if verbose
        fprintf('\n========================================\n');
        fprintf('  SimuLift - Predictive Safety Model\n');
        fprintf('========================================\n\n');
        fprintf('Running scenario: %s\n\n', scenario);
        display_config(config);
    end
    
    % Load the model
    try
        load_system(modelPath);
        modelName = bdroot;
    catch ME
        error('SimuLift:ModelLoadError', ...
              'Failed to load model: %s', ME.message);
    end
    
    % Apply configuration to model
    try
        apply_config_to_model(modelName, config);
    catch ME
        close_system(modelName, 0);
        error('SimuLift:ConfigError', ...
              'Failed to apply configuration: %s', ME.message);
    end
    
    % Run simulation
    if verbose
        fprintf('Running simulation...\n');
    end
    
    try
        simOut = sim(modelName);
        
        if verbose
            fprintf('Simulation completed successfully!\n\n');
            
            % Display results if available
            display_results(simOut, config);
        end
        
    catch ME
        close_system(modelName, 0);
        error('SimuLift:SimulationError', ...
              'Simulation failed: %s', ME.message);
    end
    
    % Close model
    close_system(modelName, 0);
    
    if verbose
        fprintf('\n========================================\n');
        fprintf('  Simulation Complete\n');
        fprintf('========================================\n\n');
    end
end

function config = get_default_config()
    % GET_DEFAULT_CONFIG Returns default simulation parameters
    
    config.Theoretical_Weight = 3000;  % kg - Payload
    config.Pulley_Weight = 50;         % kg
    config.Slings_Weight = 30;         % kg
    config.Safety_Factor = 1.25;       % Safety multiplier
    config.Height = 2;                 % m - Drop height
    config.Deformation_Limit = 0.2;    % m - Deformation margin
    config.Beaufort_Scale = 6;         % Beaufort wind scale
    config.Exposed_Area = 1.5;         % m² - Surface area
    config.Crane_Capacity = 5000;      % kg
end

function config = get_scenario_config(scenario)
    % GET_SCENARIO_CONFIG Returns configuration for predefined scenarios
    
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
            
        otherwise
            config = get_default_config();
    end
end

function apply_config_to_model(modelName, config)
    % APPLY_CONFIG_TO_MODEL Applies configuration parameters to model blocks
    
    fields = fieldnames(config);
    for i = 1:length(fields)
        field = fields{i};
        value = config.(field);
        
        % Try to find and set the block parameter
        try
            blockPath = [modelName '/' field];
            if ~isempty(find_system(modelName, 'Name', field))
                set_param(blockPath, 'Value', num2str(value));
            end
        catch
            % Block might not exist or have different structure
            % Continue without error
        end
    end
end

function display_config(config)
    % DISPLAY_CONFIG Pretty prints the configuration
    
    fprintf('Configuration Parameters:\n');
    fprintf('-------------------------\n');
    fprintf('  Payload:            %g kg\n', config.Theoretical_Weight);
    fprintf('  Pulley Weight:      %g kg\n', config.Pulley_Weight);
    fprintf('  Slings Weight:      %g kg\n', config.Slings_Weight);
    fprintf('  Total Load:         %g kg\n', config.Theoretical_Weight + ...
                                              config.Pulley_Weight + ...
                                              config.Slings_Weight);
    fprintf('  Crane Capacity:     %g kg\n', config.Crane_Capacity);
    fprintf('  Safety Factor:      %g\n', config.Safety_Factor);
    fprintf('  Drop Height:        %g m\n', config.Height);
    fprintf('  Deformation Limit:  %g m\n', config.Deformation_Limit);
    fprintf('  Beaufort Scale:     %g\n', config.Beaufort_Scale);
    fprintf('  Exposed Area:       %g m²\n\n', config.Exposed_Area);
end

function display_results(simOut, config)
    % DISPLAY_RESULTS Display simulation results
    
    fprintf('Results:\n');
    fprintf('--------\n');
    
    % Calculate expected impact force
    g = 9.81;  % m/s²
    total_mass = config.Theoretical_Weight + config.Pulley_Weight + ...
                 config.Slings_Weight;
    impact_force = (total_mass * g * config.Height) / config.Deformation_Limit;
    
    fprintf('  Calculated Impact Force: %.2f N (%.2f kgf)\n', ...
            impact_force, impact_force/g);
    
    % Calculate load factor
    load_factor = (total_mass * config.Safety_Factor) / config.Crane_Capacity;
    fprintf('  Load Factor: %.2f%%\n', load_factor * 100);
    
    if load_factor > 1.0
        fprintf('  ❌ OVERLOAD DETECTED!\n');
    else
        fprintf('  ✅ Load within capacity\n');
    end
    
    % Wind speed calculation (simplified Beaufort)
    wind_speed = 0.836 * (config.Beaufort_Scale^1.5);
    fprintf('  Estimated Wind Speed: %.2f m/s\n', wind_speed);
    
    % Wind force (simplified)
    air_density = 1.225;  % kg/m³
    wind_force = 0.5 * air_density * wind_speed^2 * config.Exposed_Area;
    fprintf('  Estimated Wind Force: %.2f N\n', wind_force);
end
