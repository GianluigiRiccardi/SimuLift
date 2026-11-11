function [isValid, issues] = ocs_validate_data(data, config)
%OCS_VALIDATE_DATA Validate dataset integrity and constraints.

issues = {};

if ~isfield(data, 'tasks') || isempty(data.tasks)
    issues{end+1} = 'Missing tasks dataset.';
end

if ~isfield(data, 'resources') || isempty(data.resources)
    issues{end+1} = 'Missing resources dataset.';
end

% Validate task fields
reqFields = {'id','name','type','status','hseCriticality','ramsCriticality', ...
    'customerImpact','readiness','permitIds','resourceReq','durationHours', ...
    'earliestStart','dueDate','dependencies','costEstimate','remainingHours'};

if isfield(data, 'tasks')
    for i = 1:numel(data.tasks)
        task = data.tasks(i);
        for f = 1:numel(reqFields)
            if ~isfield(task, reqFields{f})
                issues{end+1} = sprintf('Task %s missing field: %s', task.id, reqFields{f});
            end
        end
        if task.earliestStart > task.dueDate
            issues{end+1} = sprintf('Task %s has earliestStart after dueDate.', task.id);
        end
        if task.hseCriticality < 0 || task.hseCriticality > 1
            issues{end+1} = sprintf('Task %s has invalid HSE criticality.', task.id);
        end
        if task.readiness < 0 || task.readiness > 1
            issues{end+1} = sprintf('Task %s has invalid readiness.', task.id);
        end
    end
end

% Check circular dependencies (simple detection)
if isfield(data, 'tasks')
    taskIds = {data.tasks.id};
    for i = 1:numel(data.tasks)
        deps = data.tasks(i).dependencies;
        if isempty(deps)
            continue;
        end
        for j = 1:numel(deps)
            depId = deps{j};
            if ~ismember(depId, taskIds)
                issues{end+1} = sprintf('Task %s has unknown dependency %s.', data.tasks(i).id, depId);
            end
            if strcmp(depId, data.tasks(i).id)
                issues{end+1} = sprintf('Task %s depends on itself.', data.tasks(i).id);
            end
        end
    end
end

% Check resource availability
resourceTypes = {data.resources.type};
if isfield(data, 'tasks')
    for i = 1:numel(data.tasks)
        req = data.tasks(i).resourceReq;
        reqNames = fieldnames(req);
        for r = 1:numel(reqNames)
            if ~ismember(reqNames{r}, resourceTypes)
                issues{end+1} = sprintf('Task %s requires unknown resource type %s.', data.tasks(i).id, reqNames{r});
            end
        end
    end
end

isValid = isempty(issues);

if ~isValid
    ocs_log(config, sprintf('Validation issues: %d', numel(issues)));
end
end
