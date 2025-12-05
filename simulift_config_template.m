%% SimuLift Configuration Template
% Copy this file and modify parameters for your specific scenario
% Save with a descriptive name like 'config_my_project.m'

function config = simulift_config_template()
    % SIMULIFT_CONFIG_TEMPLATE Template for creating custom configurations
    %
    % Usage:
    %   1. Copy this file and rename it (e.g., config_my_lift.m)
    %   2. Modify the parameters below
    %   3. Load and use: config = config_my_lift();
    %   4. Run: run_simulift('config', config);
    
    %% Load Parameters
    config.Theoretical_Weight = 3000;  % kg - Mass of the payload
    % The actual weight of the object being lifted
    
    %% Rigging Equipment
    config.Pulley_Weight = 50;         % kg - Mass of pulley system
    % Weight of the pulley/sheave assembly
    
    config.Slings_Weight = 30;         % kg - Mass of slings/chains
    % Weight of lifting slings, chains, or cables
    
    %% Crane Specifications
    config.Crane_Capacity = 5000;      % kg - Maximum crane capacity
    % Safe working load (SWL) of the crane
    
    config.Safety_Factor = 1.25;       % Dimensionless - Safety multiplier
    % Typical values:
    %   1.1 - 1.25: Standard operations
    %   1.5 - 2.0: Critical/precision lifts
    %   > 2.0: Extreme conditions
    
    %% Impact Analysis
    config.Height = 2;                 % m - Potential drop height
    % Maximum height the load could fall from
    
    config.Deformation_Limit = 0.2;    % m - Stopping distance
    % Distance over which impact is absorbed
    % Smaller values = higher impact force
    % Typical values:
    %   0.01 - 0.05: Rigid materials (steel, concrete)
    %   0.1 - 0.3: Moderate absorption (wood, rubber pads)
    %   > 0.3: High absorption (foam, airbags)
    
    %% Wind Conditions
    config.Beaufort_Scale = 6;         % Beaufort scale (0-12)
    % Wind force classification:
    %   0-3: Calm to gentle breeze (safe)
    %   4-6: Moderate to strong breeze (caution)
    %   7-9: Gale conditions (dangerous)
    %   10-12: Storm to hurricane (operations impossible)
    
    config.Exposed_Area = 1.5;         % m² - Surface area exposed to wind
    % Projected area perpendicular to wind direction
    % For irregular shapes, use maximum projected area
    
    %% Additional Notes
    % Total load = Theoretical_Weight + Pulley_Weight + Slings_Weight
    % Effective load = Total load × Safety_Factor
    % Overload occurs when: Effective load > Crane_Capacity
    
end

%% Example Configurations

function config = config_light_maintenance()
    % Light maintenance equipment lift
    config.Theoretical_Weight = 800;
    config.Pulley_Weight = 25;
    config.Slings_Weight = 15;
    config.Crane_Capacity = 3000;
    config.Safety_Factor = 1.5;
    config.Height = 1.5;
    config.Deformation_Limit = 0.2;
    config.Beaufort_Scale = 4;
    config.Exposed_Area = 1.0;
end

function config = config_heavy_industrial()
    % Heavy industrial equipment installation
    config.Theoretical_Weight = 7000;
    config.Pulley_Weight = 120;
    config.Slings_Weight = 80;
    config.Crane_Capacity = 10000;
    config.Safety_Factor = 1.3;
    config.Height = 3;
    config.Deformation_Limit = 0.3;
    config.Beaufort_Scale = 5;
    config.Exposed_Area = 4.0;
end

function config = config_precision_assembly()
    % Precision component assembly
    config.Theoretical_Weight = 350;
    config.Pulley_Weight = 20;
    config.Slings_Weight = 10;
    config.Crane_Capacity = 1500;
    config.Safety_Factor = 1.8;
    config.Height = 1;
    config.Deformation_Limit = 0.15;
    config.Beaufort_Scale = 3;
    config.Exposed_Area = 0.6;
end

function config = config_outdoor_windy()
    % Outdoor lift in windy conditions
    config.Theoretical_Weight = 2000;
    config.Pulley_Weight = 40;
    config.Slings_Weight = 25;
    config.Crane_Capacity = 5000;
    config.Safety_Factor = 1.5;
    config.Height = 2;
    config.Deformation_Limit = 0.2;
    config.Beaufort_Scale = 8;  % Gale conditions
    config.Exposed_Area = 2.5;
end
