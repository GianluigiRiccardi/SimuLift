function ocs_run_tests(config)
%OCS_RUN_TESTS Manual validation checklist and edge cases.

fprintf('\n--- OCS Manual Test Checklist ---\n');
checklist = {
    'Load demo dataset without errors',
    'Priority score generated for all tasks',
    'Schedule respects permits and dependencies',
    'Decision support flags resource overload',
    'Daily Ops Brief generated',
    'Export files created (CSV/MAT/JSON)'
    };
for i = 1:numel(checklist)
    fprintf('[ ] %s\n', checklist{i});
end

fprintf('\n--- Running Edge Case Tests ---\n');

% Edge case 1: missing task field
[data, ~] = ocs_load_demo_data(config);
badData = data;
badData.tasks(1) = rmfield(badData.tasks(1), 'name');
[valid, issues] = ocs_validate_data(badData, config);
local_report_edge('Missing field', valid, issues);

% Edge case 2: invalid dates
badData = data;
badData.tasks(2).earliestStart = badData.tasks(2).dueDate + days(1);
[valid, issues] = ocs_validate_data(badData, config);
local_report_edge('Invalid dates', valid, issues);

% Edge case 3: circular dependency
badData = data;
badData.tasks(3).dependencies = {badData.tasks(3).id};
[valid, issues] = ocs_validate_data(badData, config);
local_report_edge('Circular dependency', valid, issues);

% Edge case 4: unknown resource type
badData = data;
badData.tasks(4).resourceReq.unknown_res = 5;
[valid, issues] = ocs_validate_data(badData, config);
local_report_edge('Unknown resource', valid, issues);

% Edge case 5: permit not available
badData = data;
badData.permits(1).status = 'rejected';
[schedule] = ocs_schedule_tasks(badData, config);
if isempty(schedule)
    fprintf('[PASS] Permit not available: schedule empty as expected.\n');
else
    fprintf('[WARN] Permit not available: schedule has %d items.\n', numel(schedule));
end
end

function local_report_edge(name, valid, issues)
if ~valid
    fprintf('[PASS] %s: detected %d issues.\n', name, numel(issues));
else
    fprintf('[FAIL] %s: no issues detected.\n', name);
end
end
