function simulift_import_excel(xlsxFile, slxFile)
% SIMULIFT_IMPORT_EXCEL  Legge i dati di un sollevamento da un file Excel
% (template SimuLift_Dati_Sollevamento.xlsx) e aggiorna i blocchi Constant
% corrispondenti nel modello Simulink SimuLift, salvando una nuova copia.
%
% Uso:
%   simulift_import_excel('SimuLift_Dati_Sollevamento.xlsx', 'SimuLift_v1_2_WithLamps.slx')
%
% Il file Excel deve avere l'intestazione in riga 4 con le colonne:
%   Parametro | Blocco Simulink | Valore | Unità | Note
% e i dati a partire dalla riga 5 (formato del template fornito).

if nargin < 1 || isempty(xlsxFile)
    xlsxFile = 'SimuLift_Dati_Sollevamento.xlsx';
end
if nargin < 2 || isempty(slxFile)
    slxFile = 'SimuLift_v1_2_WithLamps.slx';
end

xlsxFile = fullfile(pwd, xlsxFile);
slxFile  = fullfile(pwd, slxFile);

if ~isfile(xlsxFile)
    error('simulift_import_excel:fileNotFound', 'File Excel non trovato: %s', xlsxFile);
end
if ~isfile(slxFile)
    error('simulift_import_excel:fileNotFound', 'File modello non trovato: %s', slxFile);
end

% --- Leggi la tabella dati (intestazione riga 4, dati da riga 5) ---
opts = detectImportOptions(xlsxFile, 'Sheet', 'Dati Sollevamento');
opts.VariableNamesRange = 'A4';
opts.DataRange = 'A5';
opts.VariableNamingRule = 'preserve';
T = readtable(xlsxFile, opts);
T = T(~cellfun(@isempty, T.("Blocco Simulink")), :);

fprintf('Letti %d parametri da: %s\n', height(T), xlsxFile);

% --- Apri il modello ---
[~, mdl, ~] = fileparts(slxFile);
load_system(slxFile);
root = [mdl '/Subsystem'];

% --- Applica ciascun valore al blocco Constant corrispondente ---
applied = 0;
skipped = {};
for i = 1:height(T)
    blockName = strtrim(T.("Blocco Simulink"){i});
    value = T.("Valore")(i);
    blockPath = [root '/' blockName];

    if ~getSimulinkBlockHandle_exists(blockPath)
        skipped{end+1} = blockName; %#ok<AGROW>
        fprintf('  [SALTATO] Blocco non trovato: %s\n', blockName);
        continue;
    end

    set_param(blockPath, 'Value', num2str(value));
    fprintf('  [OK] %s = %s\n', blockName, num2str(value));
    applied = applied + 1;
end

% --- Salva una nuova copia aggiornata ---
[p, n, ~] = fileparts(slxFile);
dstFile = fullfile(p, [n '_aggiornato.slx']);
save_system(mdl, dstFile);
close_system(mdl, 0);

fprintf('\nApplicati %d/%d parametri.\n', applied, height(T));
if ~isempty(skipped)
    fprintf('Blocchi non trovati (verificare nomi nel template): %s\n', strjoin(skipped, ', '));
end
fprintf('Salvato: %s\n', dstFile);
fprintf('DONE_OK\n');
end

function tf = getSimulinkBlockHandle_exists(blockPath)
try
    h = get_param(blockPath, 'Handle');
    tf = ishandle(h);
catch
    tf = false;
end
end
