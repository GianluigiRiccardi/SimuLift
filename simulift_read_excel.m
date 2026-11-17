function P = simulift_read_excel(xlsxFile)
%SIMULIFT_READ_EXCEL Legge i parametri di sollevamento dal template Excel.
%   P = simulift_read_excel(xlsxFile) legge il foglio "Dati Sollevamento"
%   (intestazione in riga 4, dati da riga 5, colonne "Blocco Simulink" e
%   "Valore") e restituisce una struct con un campo per parametro, pronta
%   per simulift_static_check. Stesso formato usato da
%   simulift_import_excel.m; non modifica alcun modello.

arguments
    xlsxFile (1,1) string {mustBeFile}
end

io = detectImportOptions(xlsxFile, "Sheet", "Dati Sollevamento");
io.VariableNamesRange = "A4";
io.DataRange = "A5";
io.VariableNamingRule = "preserve";
T = readtable(xlsxFile, io);

names = strtrim(string(T.("Blocco Simulink")));
values = T.("Valore");
if ~isnumeric(values)
    values = str2double(string(values));
end

P = struct();
for i = 1:numel(names)
    if ismissing(names(i)) || names(i) == "" || isnan(values(i))
        continue
    end
    if ~isvarname(names(i))
        error("simulift:invalidName", ...
            "Nome di parametro non valido nel file Excel: ""%s"".", names(i));
    end
    P.(names(i)) = values(i);
end
end
