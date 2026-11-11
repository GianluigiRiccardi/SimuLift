function kpi = ocs_kpi_engine(data, schedule, config)
%OCS_KPI_ENGINE Compute operational KPIs.

tasks = data.tasks;

readyCount = sum(strcmp({tasks.status}, 'ready') | strcmp({tasks.status}, 'in_progress'));
operationalReadiness = readyCount / max(1, numel(tasks));

completed = tasks(strcmp({tasks.status}, 'done'));
if isempty(completed)
    planReliability = 1;
else
    onTime = 0;
    for i = 1:numel(completed)
        if completed(i).dueDate >= completed(i).earliestStart
            onTime = onTime + 1;
        end
    end
    planReliability = onTime / numel(completed);
end

wip = tasks(strcmp({tasks.status}, 'in_progress'));
if isempty(wip)
    wipAging = 0;
    safetyExposure = 0;
else
    wipAging = mean([wip.wipAgeDays]);
    safetyExposure = mean([wip.hseCriticality]);
end

upcoming = tasks([tasks.dueDate] <= config.today + days(config.horizonDays));
notReady = upcoming(~strcmp({upcoming.status}, 'ready') & ~strcmp({upcoming.status}, 'in_progress'));
delayRisk = numel(notReady) / max(1, numel(upcoming));

% Resource utilization
availableHours = 0;
for i = 1:numel(data.resources)
    availableHours = availableHours + data.resources(i).capacityHoursPerDay * data.resources(i).availability * config.horizonDays;
end

scheduledHours = 0;
for i = 1:numel(schedule)
    taskIdx = find(strcmp({tasks.id}, schedule(i).taskId), 1);
    if ~isempty(taskIdx)
        scheduledHours = scheduledHours + tasks(taskIdx).durationHours;
    end
end
resourceUtilization = scheduledHours / max(1, availableHours);

costToComplete = sum([tasks.remainingHours]) * 150;

kpi = struct('operationalReadiness', operationalReadiness, ...
    'planReliability', planReliability, ...
    'wipAging', wipAging, ...
    'safetyExposure', safetyExposure, ...
    'delayRisk', delayRisk, ...
    'resourceUtilization', resourceUtilization, ...
    'costToComplete', costToComplete);

ocs_log(config, 'KPI engine computed');
end
