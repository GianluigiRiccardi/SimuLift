function ocs_export_data(state, config)
%OCS_EXPORT_DATA Export tasks to CSV and store MAT/JSON state.

if ~exist(config.exportDir, 'dir')
    mkdir(config.exportDir);
end

% Task table
tasks = state.data.tasks;
ids = {tasks.id}';
names = {tasks.name}';
status = {tasks.status}';
priority = nan(numel(tasks), 1);
if isfield(tasks, 'priorityScore')
    priority = [tasks.priorityScore]';
end

permitList = cell(numel(tasks), 1);
for i = 1:numel(tasks)
    permitList{i} = strjoin(tasks(i).permitIds, '|');
end

T = table(ids, names, status, priority, [tasks.hseCriticality]', [tasks.ramsCriticality]', ...
    [tasks.customerImpact]', [tasks.readiness]', permitList, [tasks.durationHours]', ...
    [tasks.remainingHours]', [tasks.wipAgeDays]', 'VariableNames', ...
    {'TaskId','TaskName','Status','PriorityScore','HSE','RAMS','CustomerImpact', ...
    'Readiness','Permits','DurationHours','RemainingHours','WipAgeDays'});

csvFile = fullfile(config.exportDir, sprintf('tasks_%s.csv', datestr(config.today, 'yyyymmdd')));
writetable(T, csvFile);

% Decision log
if isempty(state.decisionLog)
    decisionTable = table();
else
    decisionTable = table({state.decisionLog.timestamp}', {state.decisionLog.decision}', ...
        {state.decisionLog.rationale}', 'VariableNames', {'Timestamp','Decision','Rationale'});
end

logFile = fullfile(config.exportDir, sprintf('decision_log_%s.csv', datestr(config.today, 'yyyymmdd')));
writetable(decisionTable, logFile);

% Save MAT
matFile = fullfile(config.dataDir, sprintf('ocs_state_%s.mat', datestr(config.today, 'yyyymmdd')));
save(matFile, 'state');

% Save JSON
jsonFile = fullfile(config.dataDir, sprintf('ocs_state_%s.json', datestr(config.today, 'yyyymmdd')));
jsonText = jsonencode(state);
fid = fopen(jsonFile, 'w');
if fid ~= -1
    fwrite(fid, jsonText, 'char');
    fclose(fid);
end

ocs_log(config, 'Export completed');
end
