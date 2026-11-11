function [priorityTable, data] = ocs_prioritize_tasks(data, config)
%OCS_PRIORITIZE_TASKS Compute multi-criteria priority score.

weights = struct('hse', 0.25, 'rams', 0.15, 'criticalPath', 0.15, ...
    'customer', 0.15, 'permit', 0.1, 'resource', 0.1, 'due', 0.05, 'readiness', 0.05);

permitsMap = containers.Map({data.permits.id}, {data.permits.status});
resourceAvailability = struct();
for i = 1:numel(data.resources)
    resourceAvailability.(data.resources(i).type) = data.resources(i).availability;
end

% Build dependency map to estimate critical path influence
taskIds = {data.tasks.id};
criticalPathScore = zeros(numel(data.tasks), 1);
for i = 1:numel(data.tasks)
    successors = 0;
    for j = 1:numel(data.tasks)
        if any(strcmp(data.tasks(j).dependencies, data.tasks(i).id))
            successors = successors + 1;
        end
    end
    criticalPathScore(i) = min(1, successors / 3);
end

scores = zeros(numel(data.tasks), 1);
for i = 1:numel(data.tasks)
    task = data.tasks(i);

    permitReadiness = local_permit_readiness(task.permitIds, permitsMap, config.today);
    resAvail = local_resource_availability(task.resourceReq, resourceAvailability);
    dueUrgency = max(0, 1 - days(task.dueDate - config.today) / config.horizonDays);

    score = weights.hse * task.hseCriticality + ...
        weights.rams * task.ramsCriticality + ...
        weights.criticalPath * criticalPathScore(i) + ...
        weights.customer * task.customerImpact + ...
        weights.permit * permitReadiness + ...
        weights.resource * resAvail + ...
        weights.due * dueUrgency + ...
        weights.readiness * task.readiness;

    scores(i) = score;
    data.tasks(i).priorityScore = score;
    data.tasks(i).permitReadiness = permitReadiness;
    data.tasks(i).resourceAvailability = resAvail;
end

[sortedScores, idx] = sort(scores, 'descend');
priorityTable = table({data.tasks(idx).id}', {data.tasks(idx).name}', sortedScores, ...
    {data.tasks(idx).status}', 'VariableNames', {'TaskId','TaskName','PriorityScore','Status'});

ocs_log(config, 'Priority scoring complete');
end

function permitReadiness = local_permit_readiness(permitIds, permitsMap, today)
if isempty(permitIds)
    permitReadiness = 1;
    return;
end

statusOk = 0;
for i = 1:numel(permitIds)
    if permitsMap.isKey(permitIds{i})
        status = permitsMap(permitIds{i});
        if strcmp(status, 'approved')
            statusOk = statusOk + 1;
        end
    end
end
permitReadiness = statusOk / numel(permitIds);
end

function resAvail = local_resource_availability(resourceReq, availabilityMap)
fields = fieldnames(resourceReq);
if isempty(fields)
    resAvail = 1;
    return;
end
vals = zeros(numel(fields), 1);
for i = 1:numel(fields)
    if isfield(availabilityMap, fields{i})
        vals(i) = availabilityMap.(fields{i});
    else
        vals(i) = 0.5;
    end
end
resAvail = mean(vals);
end
