function decisionLog = ocs_decision_support(data, schedule, config)
%OCS_DECISION_SUPPORT Generate trade-offs for resource overload.

resourceDemand = struct();
resourceCapacity = struct();
for i = 1:numel(data.resources)
    resourceCapacity.(data.resources(i).type) = data.resources(i).capacityHoursPerDay * data.resources(i).availability;
    resourceDemand.(data.resources(i).type) = 0;
end

for i = 1:numel(schedule)
    taskIdx = find(strcmp({data.tasks.id}, schedule(i).taskId), 1);
    if isempty(taskIdx)
        continue;
    end
    req = data.tasks(taskIdx).resourceReq;
    fields = fieldnames(req);
    for f = 1:numel(fields)
        resourceDemand.(fields{f}) = resourceDemand.(fields{f}) + req.(fields{f});
    end
end

decisionLog = struct('timestamp', {}, 'decision', {}, 'rationale', {}, 'impactedTasks', {});
logIdx = 1;
fields = fieldnames(resourceCapacity);
for i = 1:numel(fields)
    type = fields{i};
    if resourceDemand.(type) > resourceCapacity.(type)
        overload = resourceDemand.(type) - resourceCapacity.(type);
        [candidates, rationale] = local_find_deferrals(data, type, overload);
        decisionLog(logIdx) = struct('timestamp', datetime('now'), ...
            'decision', sprintf('Defer tasks requiring %s by %.1f hours', type, overload), ...
            'rationale', rationale, 'impactedTasks', {candidates});
        logIdx = logIdx + 1;
    end
end

if isempty(decisionLog)
    decisionLog(1) = struct('timestamp', datetime('now'), 'decision', 'No overload detected', ...
        'rationale', 'Resources within capacity', 'impactedTasks', {{}});
end

ocs_log(config, 'Decision support generated');
end

function [candidates, rationale] = local_find_deferrals(data, resourceType, overload)
% Identify lowest priority tasks using the resource type
eligible = [];
for i = 1:numel(data.tasks)
    task = data.tasks(i);
    if isfield(task.resourceReq, resourceType)
        eligible = [eligible, i]; %#ok<AGROW>
    end
end

if isempty(eligible)
    candidates = {};
    rationale = 'No eligible tasks found.';
    return;
end

if isfield(data.tasks, 'priorityScore')
    scores = [data.tasks(eligible).priorityScore];
else
    scores = zeros(1, numel(eligible));
end
[~, order] = sort(scores, 'ascend');

candidates = {};
accum = 0;
for i = 1:numel(order)
    task = data.tasks(eligible(order(i)));
    candidates{end+1} = task.id; %#ok<AGROW>
    accum = accum + task.resourceReq.(resourceType);
    if accum >= overload
        break;
    end
end

rationale = sprintf('Deferred lowest-priority tasks to recover %.1f hours', accum);
end
