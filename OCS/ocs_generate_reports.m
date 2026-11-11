function ocs_generate_reports(state, config, mode)
%OCS_GENERATE_REPORTS Display dashboard and generate daily brief.

if nargin < 3
    mode = 'morning';
end

data = state.data;

switch mode
    case 'morning'
        fprintf('\n--- Morning Control Dashboard ---\n');
        if ~isempty(state.priorities)
            disp(state.priorities(1:min(10,height(state.priorities)), :));
        end
        blocked = local_blocked_tasks(data, config.today);
        fprintf('Blocked tasks: %d\n', numel(blocked));
        riskTop = state.riskRegister(1:min(3, numel(state.riskRegister)));
        fprintf('Top risks:\n');
        for i = 1:numel(riskTop)
            fprintf(' - %s (Severity %.2f)\n', riskTop(i).name, riskTop(i).severity);
        end
        fprintf('KPIs: Operational Readiness %.2f | Plan Reliability %.2f | Delay Risk %.2f\n', ...
            state.kpi.operationalReadiness, state.kpi.planReliability, state.kpi.delayRisk);
    case 'constraints'
        fprintf('\n--- Constraint Check ---\n');
        blocked = local_blocked_tasks(data, config.today);
        if isempty(blocked)
            fprintf('No blocked tasks.\n');
        else
            for i = 1:numel(blocked)
                fprintf('Blocked: %s - %s\n', blocked{i,1}, blocked{i,2});
            end
        end
    case 'decision'
        fprintf('\n--- Decision Support ---\n');
        for i = 1:numel(state.decisionLog)
            fprintf('%s: %s\n', datestr(state.decisionLog(i).timestamp, 'yyyy-mm-dd HH:MM'), state.decisionLog(i).decision);
            fprintf('Rationale: %s\n', state.decisionLog(i).rationale);
        end
    case 'hse'
        fprintf('\n--- HSE Gate Check ---\n');
        gates = local_hse_gates(data, config.safetyGates);
        for i = 1:size(gates,1)
            fprintf('Gate: %s | Task: %s | Status: %s\n', gates{i,1}, gates{i,2}, gates{i,3});
        end
    case 'brief'
        brief = local_daily_brief(state, config);
        fprintf('\n--- Daily Ops Brief ---\n');
        fprintf('%s\n', brief);
    case 'eod'
        fprintf('\n--- End-of-Day Review ---\n');
        fprintf('Operational Readiness: %.2f\n', state.kpi.operationalReadiness);
        fprintf('Plan Reliability: %.2f\n', state.kpi.planReliability);
        fprintf('WIP Aging (days): %.2f\n', state.kpi.wipAging);
        fprintf('Safety Exposure: %.2f\n', state.kpi.safetyExposure);
        fprintf('Delay Risk: %.2f\n', state.kpi.delayRisk);
        fprintf('Resource Utilization: %.2f\n', state.kpi.resourceUtilization);
        fprintf('Cost to Complete (rough): %.2f\n', state.kpi.costToComplete);
end
end

function blocked = local_blocked_tasks(data, today)
blocked = {};
for i = 1:numel(data.tasks)
    task = data.tasks(i);
    if strcmp(task.status, 'blocked')
        blocked(end+1, :) = {task.id, 'Status blocked'}; %#ok<AGROW>
        continue;
    end
    if ~local_permits_ready(task, data.permits, today)
        blocked(end+1, :) = {task.id, 'Permit unavailable'}; %#ok<AGROW>
    end
end
end

function gates = local_hse_gates(data, safetyGates)
rows = {};
for i = 1:numel(data.tasks)
    task = data.tasks(i);
    if task.hseCriticality >= 0.8
        gate = safetyGates{min(numel(safetyGates), 1)};
        rows(end+1, :) = {gate, task.id, 'Gate required'}; %#ok<AGROW>
    end
end
if isempty(rows)
    gates = {'none','none','none'};
else
    gates = rows;
end
end

function brief = local_daily_brief(state, config)
stateLine = sprintf('Status: %d tasks total, %d scheduled today.', ...
    numel(state.data.tasks), numel(state.schedule));

riskLine = 'Top risks: ';
for i = 1:min(3, numel(state.riskRegister))
    riskLine = sprintf('%s%s (%.2f); ', riskLine, state.riskRegister(i).name, state.riskRegister(i).severity);
end

decisionLine = 'Decisions: ';
for i = 1:numel(state.decisionLog)
    decisionLine = sprintf('%s%s; ', decisionLine, state.decisionLog(i).decision);
end

kpiLine = sprintf('KPIs: Readiness %.2f | Plan Reliability %.2f | Delay Risk %.2f', ...
    state.kpi.operationalReadiness, state.kpi.planReliability, state.kpi.delayRisk);

requestLine = 'Requests: pending permits + resource balance checks.';
nextSteps = sprintf('Next steps: follow up with permit owners, confirm %s milestones.', ...
    strjoin({state.data.milestones.name}, ', '));

brief = sprintf(['Daily Ops Brief - %s\n%s\n%s\n%s\n%s\n%s\n%s'], ...
    datestr(config.today, 'yyyy-mm-dd'), stateLine, decisionLine, riskLine, kpiLine, requestLine, nextSteps);
end

function ok = local_permits_ready(task, permits, day)
ok = true;
if isempty(task.permitIds)
    return;
end

for i = 1:numel(task.permitIds)
    id = task.permitIds{i};
    permitIdx = find(strcmp({permits.id}, id), 1);
    if isempty(permitIdx)
        ok = false;
        return;
    end
    permit = permits(permitIdx);
    if ~strcmp(permit.status, 'approved')
        ok = false;
        return;
    end
    if day < permit.validFrom || day > permit.validTo
        ok = false;
        return;
    end
end
end
