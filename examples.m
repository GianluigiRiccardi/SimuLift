%% SimuLift - Examples and Scenarios
% This script demonstrates various usage examples of SimuLift
% Author: Gianluigi Riccardi

%% Example 1: Basic Usage - Default Scenario
% Run SimuLift with default parameters
fprintf('Example 1: Running default scenario...\n\n');

% Create default configuration
config_default = struct(...
    'Theoretical_Weight', 3000, ...
    'Pulley_Weight', 50, ...
    'Slings_Weight', 30, ...
    'Safety_Factor', 1.25, ...
    'Height', 2, ...
    'Deformation_Limit', 0.2, ...
    'Beaufort_Scale', 6, ...
    'Exposed_Area', 1.5, ...
    'Crane_Capacity', 5000);

% Generate and display report
report = SimuLiftUtils.generate_safety_report(config_default);
SimuLiftUtils.print_report(report);

%% Example 2: Light Load in Calm Weather
fprintf('Example 2: Light load, calm weather...\n\n');

config_light = struct(...
    'Theoretical_Weight', 800, ...
    'Pulley_Weight', 25, ...
    'Slings_Weight', 15, ...
    'Safety_Factor', 1.5, ...
    'Height', 1.5, ...
    'Deformation_Limit', 0.2, ...
    'Beaufort_Scale', 2, ...
    'Exposed_Area', 1.0, ...
    'Crane_Capacity', 3000);

report_light = SimuLiftUtils.generate_safety_report(config_light);
SimuLiftUtils.print_report(report_light);

%% Example 3: Heavy Load Analysis
fprintf('Example 3: Heavy industrial load...\n\n');

config_heavy = struct(...
    'Theoretical_Weight', 7000, ...
    'Pulley_Weight', 120, ...
    'Slings_Weight', 80, ...
    'Safety_Factor', 1.3, ...
    'Height', 3, ...
    'Deformation_Limit', 0.3, ...
    'Beaufort_Scale', 5, ...
    'Exposed_Area', 4.0, ...
    'Crane_Capacity', 10000);

report_heavy = SimuLiftUtils.generate_safety_report(config_heavy);
SimuLiftUtils.print_report(report_heavy);

%% Example 4: Wind Impact Analysis
fprintf('Example 4: Comparing different wind conditions...\n\n');

beaufort_scales = [3, 6, 9];
wind_descriptions = cell(size(beaufort_scales));
wind_speeds = zeros(size(beaufort_scales));
wind_forces = zeros(size(beaufort_scales));

exposed_area = 2.0;  % m²

fprintf('Wind Condition Comparison:\n');
fprintf('==========================\n\n');

for i = 1:length(beaufort_scales)
    b = beaufort_scales(i);
    wind_descriptions{i} = SimuLiftUtils.get_beaufort_description(b);
    wind_speeds(i) = SimuLiftUtils.beaufort_to_wind_speed(b);
    wind_forces(i) = SimuLiftUtils.calculate_wind_force(wind_speeds(i), exposed_area);
    
    fprintf('Beaufort %d - %s:\n', b, wind_descriptions{i});
    fprintf('  Wind Speed: %.2f m/s (%.2f km/h)\n', ...
            wind_speeds(i), wind_speeds(i) * 3.6);
    fprintf('  Wind Force: %.2f N (on %.1f m² area)\n\n', ...
            wind_forces(i), exposed_area);
end

%% Example 5: Impact Force Comparison
fprintf('Example 5: Impact force for different drop heights...\n\n');

mass = 100;  % kg
deformation = 0.1;  % m
heights = [0.5, 1.0, 2.0, 3.0, 5.0];  % m

fprintf('Impact Force Analysis (%.0f kg object, %.2f m deformation):\n', ...
        mass, deformation);
fprintf('=========================================================\n\n');

for h = heights
    impact_n = SimuLiftUtils.calculate_impact_force(mass, h, deformation);
    impact_kgf = SimuLiftUtils.newtons_to_kgf(impact_n);
    
    fprintf('  Drop height %.1f m: %.2f N (%.2f kgf)\n', ...
            h, impact_n, impact_kgf);
end
fprintf('\n');

%% Example 6: Safety Factor Impact
fprintf('Example 6: Effect of safety factor on load capacity...\n\n');

load = 2500;  % kg
capacity = 5000;  % kg
safety_factors = [1.0, 1.1, 1.25, 1.5, 2.0];

fprintf('Safety Factor Analysis (Load: %.0f kg, Capacity: %.0f kg):\n', ...
        load, capacity);
fprintf('==========================================================\n\n');

for sf = safety_factors
    effective_load = load * sf;
    is_safe = SimuLiftUtils.check_overload(load, capacity, sf);
    ratio = effective_load / capacity;
    
    fprintf('  SF %.2f: Effective load = %.0f kg (%.1f%% capacity) - %s\n', ...
            sf, effective_load, ratio * 100, ...
            iif(is_safe, '✅ SAFE', '❌ OVERLOAD'));
end
fprintf('\n');

%% Example 7: Real-world Scenario - Pipe Installation
fprintf('Example 7: Real-world scenario - Pipe installation...\n\n');

fprintf('Scenario: Installing a 3-meter steel pipe during moderate wind\n');
fprintf('==============================================================\n\n');

config_pipe = struct(...
    'Theoretical_Weight', 450, ...  % Heavy pipe
    'Pulley_Weight', 35, ...
    'Slings_Weight', 20, ...
    'Safety_Factor', 1.4, ...       % Standard safety margin
    'Height', 1.0, ...               % Low drop risk
    'Deformation_Limit', 0.15, ...
    'Beaufort_Scale', 5, ...         % Fresh breeze
    'Exposed_Area', 1.2, ...         % Cylindrical pipe
    'Crane_Capacity', 2000);

report_pipe = SimuLiftUtils.generate_safety_report(config_pipe);
SimuLiftUtils.print_report(report_pipe);

fprintf('Recommendation: ');
if report_pipe.safe_to_lift
    if contains(report_pipe.risk_level, 'LOW')
        fprintf('Proceed with lift. Conditions are favorable.\n\n');
    else
        fprintf('Proceed with caution. Monitor wind conditions.\n\n');
    end
else
    fprintf('DO NOT PROCEED. Address safety concerns first.\n\n');
end

%% Example 8: Batch Analysis - Multiple Configurations
fprintf('Example 8: Batch analysis of multiple scenarios...\n\n');

scenarios = {
    'Light machinery', 1200, 1.5, 4, 3500;
    'Heavy equipment', 6000, 1.25, 6, 8000;
    'Moderate load', 2800, 1.3, 5, 5000;
    'Precision part', 350, 1.8, 3, 1500
};

fprintf('Batch Safety Analysis:\n');
fprintf('=====================\n\n');

for i = 1:size(scenarios, 1)
    name = scenarios{i, 1};
    weight = scenarios{i, 2};
    sf = scenarios{i, 3};
    beaufort = scenarios{i, 4};
    capacity = scenarios{i, 5};
    
    cfg = struct(...
        'Theoretical_Weight', weight, ...
        'Pulley_Weight', weight * 0.02, ...  % 2% of load
        'Slings_Weight', weight * 0.01, ...  % 1% of load
        'Safety_Factor', sf, ...
        'Height', 2, ...
        'Deformation_Limit', 0.2, ...
        'Beaufort_Scale', beaufort, ...
        'Exposed_Area', 1.5, ...
        'Crane_Capacity', capacity);
    
    rep = SimuLiftUtils.generate_safety_report(cfg);
    
    fprintf('%d. %s:\n', i, name);
    fprintf('   Load: %.0f kg, Capacity: %.0f kg\n', ...
            rep.total_mass, capacity);
    fprintf('   Status: %s\n', ...
            iif(rep.safe_to_lift, '✅ SAFE', '❌ UNSAFE'));
    fprintf('   Risk: %s\n\n', rep.risk_level);
end

fprintf('═══════════════════════════════════════════\n');
fprintf('End of Examples\n');
fprintf('═══════════════════════════════════════════\n\n');

function result = iif(condition, true_val, false_val)
    % IIF Inline if function
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
