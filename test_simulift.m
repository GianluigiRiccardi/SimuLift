%% SimuLift - Test and Validation Script
% Runs multiple test scenarios to validate SimuLift functionality
% Author: Gianluigi Riccardi

function test_simulift()
    % TEST_SIMULIFT Runs validation tests for SimuLift
    %
    % This script tests various scenarios to ensure the model
    % correctly identifies safe and unsafe lifting conditions
    
    fprintf('\n╔════════════════════════════════════════════╗\n');
    fprintf('║  SimuLift - Validation Test Suite         ║\n');
    fprintf('╚════════════════════════════════════════════╝\n\n');
    
    % Test counter
    total_tests = 0;
    passed_tests = 0;
    
    %% Test 1: Safe light load scenario
    fprintf('Test 1: Safe Light Load...\n');
    config1 = struct(...
        'Theoretical_Weight', 500, ...
        'Pulley_Weight', 20, ...
        'Slings_Weight', 10, ...
        'Safety_Factor', 1.5, ...
        'Height', 1, ...
        'Deformation_Limit', 0.15, ...
        'Beaufort_Scale', 3, ...
        'Exposed_Area', 0.8, ...
        'Crane_Capacity', 2000);
    
    report1 = SimuLiftUtils.generate_safety_report(config1);
    total_tests = total_tests + 1;
    if report1.safe_to_lift && report1.load_ratio < 0.5
        fprintf('  ✅ PASSED - Correctly identified as safe\n\n');
        passed_tests = passed_tests + 1;
    else
        fprintf('  ❌ FAILED - Should be safe\n\n');
    end
    
    %% Test 2: Overload scenario
    fprintf('Test 2: Overload Detection...\n');
    config2 = struct(...
        'Theoretical_Weight', 5000, ...
        'Pulley_Weight', 100, ...
        'Slings_Weight', 50, ...
        'Safety_Factor', 1.3, ...
        'Height', 2, ...
        'Deformation_Limit', 0.2, ...
        'Beaufort_Scale', 4, ...
        'Exposed_Area', 2.0, ...
        'Crane_Capacity', 5000);
    
    report2 = SimuLiftUtils.generate_safety_report(config2);
    total_tests = total_tests + 1;
    if ~report2.safe_to_lift
        fprintf('  ✅ PASSED - Correctly identified overload\n\n');
        passed_tests = passed_tests + 1;
    else
        fprintf('  ❌ FAILED - Should detect overload\n\n');
    end
    
    %% Test 3: High wind scenario
    fprintf('Test 3: High Wind Conditions...\n');
    config3 = struct(...
        'Theoretical_Weight', 2000, ...
        'Pulley_Weight', 40, ...
        'Slings_Weight', 25, ...
        'Safety_Factor', 1.25, ...
        'Height', 2, ...
        'Deformation_Limit', 0.2, ...
        'Beaufort_Scale', 9, ...
        'Exposed_Area', 2.5, ...
        'Crane_Capacity', 5000);
    
    report3 = SimuLiftUtils.generate_safety_report(config3);
    total_tests = total_tests + 1;
    if strcmp(report3.risk_level, 'HIGH - Dangerous wind')
        fprintf('  ✅ PASSED - Correctly identified high wind risk\n\n');
        passed_tests = passed_tests + 1;
    else
        fprintf('  ❌ FAILED - Should detect dangerous wind\n\n');
    end
    
    %% Test 4: Impact force calculation
    fprintf('Test 4: Impact Force Calculation...\n');
    % 40 kg pipe, 2m drop, 1cm deformation should give ~7848 N
    impact = SimuLiftUtils.calculate_impact_force(40, 2, 0.01);
    expected = 7848;  % N
    tolerance = 10;   % N
    
    total_tests = total_tests + 1;
    if abs(impact - expected) < tolerance
        fprintf('  ✅ PASSED - Impact force: %.2f N (expected ~%.2f N)\n\n', ...
                impact, expected);
        passed_tests = passed_tests + 1;
    else
        fprintf('  ❌ FAILED - Impact force: %.2f N (expected ~%.2f N)\n\n', ...
                impact, expected);
    end
    
    %% Test 5: Beaufort scale conversion
    fprintf('Test 5: Beaufort to Wind Speed...\n');
    wind_speed = SimuLiftUtils.beaufort_to_wind_speed(6);
    % Beaufort 6 should be around 12-14 m/s
    total_tests = total_tests + 1;
    if wind_speed >= 10 && wind_speed <= 15
        fprintf('  ✅ PASSED - Wind speed: %.2f m/s for Beaufort 6\n\n', ...
                wind_speed);
        passed_tests = passed_tests + 1;
    else
        fprintf('  ❌ FAILED - Wind speed: %.2f m/s (expected 10-15 m/s)\n\n', ...
                wind_speed);
    end
    
    %% Test 6: Critical scenario (multiple risk factors)
    fprintf('Test 6: Critical Multi-Risk Scenario...\n');
    config6 = struct(...
        'Theoretical_Weight', 4500, ...
        'Pulley_Weight', 60, ...
        'Slings_Weight', 40, ...
        'Safety_Factor', 1.1, ...
        'Height', 5, ...
        'Deformation_Limit', 0.05, ...
        'Beaufort_Scale', 7, ...
        'Exposed_Area', 2.0, ...
        'Crane_Capacity', 5000);
    
    report6 = SimuLiftUtils.generate_safety_report(config6);
    total_tests = total_tests + 1;
    if ~report6.safe_to_lift || contains(report6.risk_level, 'CRITICAL')
        fprintf('  ✅ PASSED - Correctly identified critical conditions\n\n');
        passed_tests = passed_tests + 1;
    else
        fprintf('  ❌ FAILED - Should detect critical conditions\n\n');
    end
    
    %% Summary
    fprintf('╔════════════════════════════════════════════╗\n');
    fprintf('║           Test Summary                     ║\n');
    fprintf('╚════════════════════════════════════════════╝\n\n');
    fprintf('  Tests Run:     %d\n', total_tests);
    fprintf('  Tests Passed:  %d\n', passed_tests);
    fprintf('  Tests Failed:  %d\n', total_tests - passed_tests);
    fprintf('  Success Rate:  %.1f%%\n\n', (passed_tests/total_tests)*100);
    
    if passed_tests == total_tests
        fprintf('  ✅ All tests passed!\n\n');
    else
        fprintf('  ⚠️  Some tests failed. Review results above.\n\n');
    end
    
    %% Generate sample report
    fprintf('════════════════════════════════════════════\n');
    fprintf('Sample Safety Report for Default Scenario:\n');
    fprintf('════════════════════════════════════════════\n');
    
    default_config = struct(...
        'Theoretical_Weight', 3000, ...
        'Pulley_Weight', 50, ...
        'Slings_Weight', 30, ...
        'Safety_Factor', 1.25, ...
        'Height', 2, ...
        'Deformation_Limit', 0.2, ...
        'Beaufort_Scale', 6, ...
        'Exposed_Area', 1.5, ...
        'Crane_Capacity', 5000);
    
    default_report = SimuLiftUtils.generate_safety_report(default_config);
    SimuLiftUtils.print_report(default_report);
end
