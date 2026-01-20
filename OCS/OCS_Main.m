%% OCS_Main.m
% Operational Control System (OCS) - Main Script
% Industry: Rail/Alstom-like
% Horizon planning: 7 days
% No external toolboxes required.

clear; clc;

config = ocs_init_config();
ocs_log(config, 'OCS startup');

[data, meta] = ocs_load_demo_data(config);
[isValid, issues] = ocs_validate_data(data, config);
if ~isValid
    fprintf('Validation issues detected:\n');
    fprintf(' - %s\n', issues{:});
end

state = struct();
state.data = data;
state.meta = meta;
state.lastRun = datetime('now');
state.schedule = [];
state.priorities = [];
state.kpi = [];
state.riskRegister = [];
state.decisionLog = [];

runMenu = true;
while runMenu
    fprintf('\n=== Operational Control System (OCS) ===\n');
    fprintf('1) Morning control (prioritize + schedule)\n');
    fprintf('2) Constraint check (blocked tasks)\n');
    fprintf('3) Decision support (resource overload trade-offs)\n');
    fprintf('4) HSE-first gate check\n');
    fprintf('5) Stakeholder communication (Daily Ops Brief)\n');
    fprintf('6) End-of-day review (KPI + variance)\n');
    fprintf('7) Export data (CSV + MAT + JSON)\n');
    fprintf('8) Run tests\n');
    fprintf('9) Exit\n');

    choice = input('Select option [1-9]: ', 's');
    if isempty(choice)
        choice = '1';
    end

    switch choice
        case '1'
            [state.priorities, state.data] = ocs_prioritize_tasks(state.data, config);
            state.schedule = ocs_schedule_tasks(state.data, config);
            state.kpi = ocs_kpi_engine(state.data, state.schedule, config);
            state.riskRegister = ocs_risk_register(state.data, config);
            state.decisionLog = ocs_decision_support(state.data, state.schedule, config);
            ocs_generate_reports(state, config, 'morning');
        case '2'
            ocs_generate_reports(state, config, 'constraints');
        case '3'
            state.decisionLog = ocs_decision_support(state.data, state.schedule, config);
            ocs_generate_reports(state, config, 'decision');
        case '4'
            ocs_generate_reports(state, config, 'hse');
        case '5'
            ocs_generate_reports(state, config, 'brief');
        case '6'
            state.kpi = ocs_kpi_engine(state.data, state.schedule, config);
            ocs_generate_reports(state, config, 'eod');
        case '7'
            ocs_export_data(state, config);
        case '8'
            ocs_run_tests(config);
        case '9'
            runMenu = false;
        otherwise
            fprintf('Invalid choice.\n');
    end
end

ocs_log(config, 'OCS shutdown');
