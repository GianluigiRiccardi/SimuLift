function config = ocs_init_config()
%OCS_INIT_CONFIG Initialize configuration parameters.

config = struct();
config.industry = 'Rail/Alstom-like';
config.horizonDays = 7;
config.resourceTypes = {'crew_mech','crew_elec','crane','permit_officer'};
config.kpiTargets = struct('planReliability', 0.8, 'operationalReadiness', 0.85);
config.customers = {'SONATRACH','ICOS','RFI','TRENORD','METRO-NORTH'};
config.safetyGates = {'ATEX','confined_space','lifting_plan'};
config.today = dateshift(datetime('now'), 'start', 'day');
config.logFile = fullfile(pwd, 'OCS', 'ocs_log.txt');
config.exportDir = fullfile(pwd, 'OCS', 'exports');
config.dataDir = fullfile(pwd, 'OCS', 'data');

if ~exist(config.exportDir, 'dir')
    mkdir(config.exportDir);
end
if ~exist(config.dataDir, 'dir')
    mkdir(config.dataDir);
end
end
