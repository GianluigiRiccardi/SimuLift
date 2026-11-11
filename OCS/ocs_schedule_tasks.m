function schedule = ocs_schedule_tasks(data, config)
%OCS_SCHEDULE_TASKS Simple heuristic scheduling on daily horizon.

horizon = config.horizonDays;
startDate = config.today;

resourceCapacity = struct();
for i = 1:numel(data.resources)
    resourceCapacity.(data.resources(i).type) = data.resources(i).capacityHoursPerDay * data.resources(i).availability;
end

schedule = struct('taskId', {}, 'startDate', {}, 'endDate', {}, 'assignedResources', {}, 'status', {});

% Sort tasks by priority score if available
if isfield(data.tasks, 'priorityScore')
    [~, order] = sort([data.tasks.priorityScore], 'descend');
else
    order = 1:numel(data.tasks);
end

for dayOffset = 0:(horizon - 1)
    day = startDate + days(dayOffset);
    dailyCapacity = resourceCapacity;

    for idx = order
        task = data.tasks(idx);
        if ismember(task.status, {'done','cancelled'})
            continue;
        end
        if task.earliestStart > day
            continue;
        end
        if task.dueDate < day
            continue;
        end
        if ~local_permits_ready(task, data.permits, day)
            continue;
        end
        if ~local_dependencies_done(task, data.tasks)
            continue;
        end

        [canAllocate, assigned] = local_allocate_resources(task, dailyCapacity);
        if canAllocate
            dailyCapacity = local_apply_allocation(dailyCapacity, assigned);
            schedule(end+1) = struct('taskId', task.id, 'startDate', day, ...
                'endDate', day + hours(task.durationHours), 'assignedResources', assigned, 'status', 'scheduled');
        end
    end
end

ocs_log(config, sprintf('Scheduling complete: %d items', numel(schedule)));
end

function ok = local_permits_ready(task, permits, day)
if isempty(task.permitIds)
    ok = true;
    return;
end

ok = true;
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

function ok = local_dependencies_done(task, tasks)
if isempty(task.dependencies)
    ok = true;
    return;
end

ok = true;
for i = 1:numel(task.dependencies)
    depId = task.dependencies{i};
    depIdx = find(strcmp({tasks.id}, depId), 1);
    if isempty(depIdx)
        ok = false;
        return;
    end
    depStatus = tasks(depIdx).status;
    if ~strcmp(depStatus, 'done')
        ok = false;
        return;
    end
end
end

function [ok, assigned] = local_allocate_resources(task, dailyCapacity)
assigned = struct();
fields = fieldnames(task.resourceReq);
ok = true;
for i = 1:numel(fields)
    req = task.resourceReq.(fields{i});
    if ~isfield(dailyCapacity, fields{i})
        ok = false;
        return;
    end
    if dailyCapacity.(fields{i}) < req
        ok = false;
        return;
    end
    assigned.(fields{i}) = req;
end
end

function capacityOut = local_apply_allocation(capacityIn, assigned)
capacityOut = capacityIn;
fields = fieldnames(assigned);
for i = 1:numel(fields)
    capacityOut.(fields{i}) = capacityOut.(fields{i}) - assigned.(fields{i});
end
end
