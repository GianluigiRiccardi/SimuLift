%% SimuLift Utility Functions
% Collection of utility functions for lift safety calculations
% Author: Gianluigi Riccardi

classdef SimuLiftUtils
    % SIMULIFTUTILS Utility class for lift safety calculations
    
    methods (Static)
        
        function force = calculate_impact_force(mass, height, deformation)
            % CALCULATE_IMPACT_FORCE Calculates impact force from drop
            %
            % Inputs:
            %   mass - Object mass in kg
            %   height - Drop height in meters
            %   deformation - Deformation/stopping distance in meters
            %
            % Output:
            %   force - Impact force in Newtons
            %
            % Formula: F = (m * g * h) / Δs
            %
            % Example:
            %   force = SimuLiftUtils.calculate_impact_force(40, 2, 0.01);
            
            g = 9.81;  % m/s² - gravitational acceleration
            
            if deformation <= 0
                error('Deformation must be positive');
            end
            
            force = (mass * g * height) / deformation;
        end
        
        function force_kgf = newtons_to_kgf(force_n)
            % NEWTONS_TO_KGF Converts force from Newtons to kilogram-force
            %
            % Input:
            %   force_n - Force in Newtons
            %
            % Output:
            %   force_kgf - Force in kilogram-force
            
            g = 9.81;
            force_kgf = force_n / g;
        end
        
        function safe = check_overload(load_mass, crane_capacity, safety_factor)
            % CHECK_OVERLOAD Checks if load exceeds crane capacity
            %
            % Inputs:
            %   load_mass - Total load mass in kg
            %   crane_capacity - Crane capacity in kg
            %   safety_factor - Safety factor multiplier
            %
            % Output:
            %   safe - Boolean, true if safe, false if overload
            
            effective_load = load_mass * safety_factor;
            safe = effective_load <= crane_capacity;
        end
        
        function wind_speed = beaufort_to_wind_speed(beaufort_scale)
            % BEAUFORT_TO_WIND_SPEED Converts Beaufort scale to wind speed
            %
            % Input:
            %   beaufort_scale - Beaufort scale value (0-12)
            %
            % Output:
            %   wind_speed - Wind speed in m/s
            %
            % Uses empirical formula: v = 0.836 * B^(3/2)
            
            if beaufort_scale < 0 || beaufort_scale > 12
                warning('Beaufort scale should be between 0 and 12');
            end
            
            wind_speed = 0.836 * (beaufort_scale ^ 1.5);
        end
        
        function force = calculate_wind_force(wind_speed, area, drag_coef)
            % CALCULATE_WIND_FORCE Calculates wind force on object
            %
            % Inputs:
            %   wind_speed - Wind speed in m/s
            %   area - Exposed area in m²
            %   drag_coef - Drag coefficient (default: 1.0 for flat plate)
            %
            % Output:
            %   force - Wind force in Newtons
            %
            % Formula: F = 0.5 * ρ * v² * A * Cd
            
            if nargin < 3
                drag_coef = 1.0;  % Default drag coefficient
            end
            
            air_density = 1.225;  % kg/m³ at sea level, 15°C
            force = 0.5 * air_density * wind_speed^2 * area * drag_coef;
        end
        
        function desc = get_beaufort_description(beaufort_scale)
            % GET_BEAUFORT_DESCRIPTION Returns description of Beaufort scale
            %
            % Input:
            %   beaufort_scale - Beaufort scale value (0-12)
            %
            % Output:
            %   desc - Text description of wind conditions
            
            descriptions = {
                'Calm', ...                          % 0
                'Light air', ...                     % 1
                'Light breeze', ...                  % 2
                'Gentle breeze', ...                 % 3
                'Moderate breeze', ...               % 4
                'Fresh breeze', ...                  % 5
                'Strong breeze', ...                 % 6
                'High wind/Moderate gale', ...       % 7
                'Gale/Fresh gale', ...               % 8
                'Strong gale', ...                   % 9
                'Storm/Whole gale', ...              % 10
                'Violent storm', ...                 % 11
                'Hurricane force'                    % 12
            };
            
            scale_idx = round(beaufort_scale) + 1;
            if scale_idx < 1
                scale_idx = 1;
            elseif scale_idx > length(descriptions)
                scale_idx = length(descriptions);
            end
            
            desc = descriptions{scale_idx};
        end
        
        function report = generate_safety_report(config)
            % GENERATE_SAFETY_REPORT Generates comprehensive safety report
            %
            % Input:
            %   config - Structure with simulation parameters
            %
            % Output:
            %   report - Structure with calculated safety metrics
            
            g = 9.81;
            
            % Calculate total mass
            report.total_mass = config.Theoretical_Weight + ...
                               config.Pulley_Weight + ...
                               config.Slings_Weight;
            
            % Impact force analysis
            report.impact_force_n = SimuLiftUtils.calculate_impact_force(...
                report.total_mass, ...
                config.Height, ...
                config.Deformation_Limit);
            report.impact_force_kgf = report.impact_force_n / g;
            
            % Overload analysis
            report.effective_load = report.total_mass * config.Safety_Factor;
            report.load_ratio = report.effective_load / config.Crane_Capacity;
            report.overload_safe = report.load_ratio <= 1.0;
            
            % Wind analysis
            report.wind_speed = SimuLiftUtils.beaufort_to_wind_speed(...
                config.Beaufort_Scale);
            report.wind_description = SimuLiftUtils.get_beaufort_description(...
                config.Beaufort_Scale);
            report.wind_force = SimuLiftUtils.calculate_wind_force(...
                report.wind_speed, ...
                config.Exposed_Area);
            
            % Overall safety verdict
            report.safe_to_lift = report.overload_safe;
            
            % Risk level
            if report.load_ratio > 1.0
                report.risk_level = 'CRITICAL - Overload';
            elseif report.load_ratio > 0.9
                report.risk_level = 'HIGH - Near capacity';
            elseif report.wind_speed > 20 || config.Beaufort_Scale >= 8
                report.risk_level = 'HIGH - Dangerous wind';
            elseif report.load_ratio > 0.75
                report.risk_level = 'MEDIUM - Moderate load';
            else
                report.risk_level = 'LOW - Safe conditions';
            end
        end
        
        function print_report(report)
            % PRINT_REPORT Prints formatted safety report
            %
            % Input:
            %   report - Report structure from generate_safety_report
            
            fprintf('\n╔════════════════════════════════════════════╗\n');
            fprintf('║    SimuLift - Safety Analysis Report      ║\n');
            fprintf('╚════════════════════════════════════════════╝\n\n');
            
            fprintf('LOAD ANALYSIS:\n');
            fprintf('  Total Mass:        %.2f kg\n', report.total_mass);
            fprintf('  Effective Load:    %.2f kg\n', report.effective_load);
            fprintf('  Load Ratio:        %.1f%%\n', report.load_ratio * 100);
            fprintf('  Overload Safe:     %s\n\n', ...
                    iif(report.overload_safe, '✅ YES', '❌ NO'));
            
            fprintf('IMPACT ANALYSIS:\n');
            fprintf('  Impact Force:      %.2f N (%.2f kgf)\n', ...
                    report.impact_force_n, report.impact_force_kgf);
            fprintf('\n');
            
            fprintf('WIND ANALYSIS:\n');
            fprintf('  Beaufort:          %s\n', report.wind_description);
            fprintf('  Wind Speed:        %.2f m/s (%.2f km/h)\n', ...
                    report.wind_speed, report.wind_speed * 3.6);
            fprintf('  Wind Force:        %.2f N\n\n', report.wind_force);
            
            fprintf('OVERALL VERDICT:\n');
            fprintf('  Risk Level:        %s\n', report.risk_level);
            fprintf('  Safe to Lift:      %s\n\n', ...
                    iif(report.safe_to_lift, '✅ YES', '❌ NO'));
            
            fprintf('════════════════════════════════════════════\n\n');
        end
        
    end
end

function result = iif(condition, true_val, false_val)
    % IIF Inline if function
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
