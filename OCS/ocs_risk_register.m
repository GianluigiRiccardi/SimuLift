function register = ocs_risk_register(data, config)
%OCS_RISK_REGISTER Build risk matrix with mitigations.

register = struct('riskId', {}, 'name', {}, 'probability', {}, 'impact', {}, ...
    'severity', {}, 'mitigation', {}, 'linkedTasks', {});

for i = 1:numel(data.risks)
    risk = data.risks(i);
    register(i) = struct('riskId', risk.id, 'name', risk.name, ...
        'probability', risk.probability, 'impact', risk.impact, ...
        'severity', risk.probability * risk.impact, 'mitigation', risk.mitigation, ...
        'linkedTasks', {risk.linkedTasks});
end

[~, idx] = sort([register.severity], 'descend');
register = register(idx);

ocs_log(config, 'Risk register updated');
end
