function ocs_log(config, message)
%OCS_LOG Append a message to log file with timestamp.

if nargin < 2
    return;
end

stamp = datestr(datetime('now'), 'yyyy-mm-dd HH:MM:SS');
line = sprintf('[%s] %s\n', stamp, message);

fid = fopen(config.logFile, 'a');
if fid ~= -1
    fwrite(fid, line);
    fclose(fid);
else
    fprintf(1, '%s', line);
end
end
