classdef SimuLiftApp < matlab.apps.AppBase
    %SIMULIFTAPP Verifica statica di un sollevamento con schema della gru (IT/EN).
    %   SimuLiftApp apre l'applicazione in italiano; SimuLiftApp("en") in
    %   inglese. La lingua si cambia anche dal menu a tendina.
    %
    %   I dati si inseriscono nella tabella (colonna Valore); il calcolo
    %   parte con il pulsante "Lancia simulazione". Dopo ogni modifica i
    %   risultati vengono marcati come non aggiornati finche' non si
    %   rilancia. Il caricamento da Excel resta disponibile.
    %
    %   Regole al posto del calcolo d'urto:
    %   - carico > 500 kg sopra o vicino ad attrezzature in esercizio o
    %     edifici occupati, oppure qualunque carico sopra linee elettriche
    %     o gas tossici: "LIFT WITH CONTINGENCY PLAN" con elenco di azioni;
    %   - classificazione STANDARD / NON STANDARD / CRITICO con i motivi.
    %   In questo l'app diverge dal modello Simulink, dove la forza d'urto
    %   m g h / delta concorre alla lampada finale.
    %
    %   Calcoli: simulift_static_check (verifica STATICA algebrica: nessuna
    %   dinamica del carico). Schema: simulift_draw_crane (non in scala).
    %
    %   App programmatica basata sugli stessi componenti di App Designer.
    %   Strumento dimostrativo: non sostituisce il piano di sollevamento, le
    %   tabelle di carico del costruttore e le verifiche di D.Lgs. 81/08 ed
    %   EN 13001.

    properties (Access = public)
        UIFigure
    end

    properties (Access = private)
        C = struct()                    % controlli
        Lang (1,1) string = "it"
        Values                          % valori correnti dei parametri
        Asset (1,1) string = "none"     % cosa c'e' sotto o vicino al percorso del carico
        Tandem (1,1) logical = false    % due o piu' attrezzature di sollevamento insieme
        NonStd (1,1) logical = false    % attrezzature di sollevamento non standard
        Result = struct()
        Stale (1,1) logical = true
        SourceFile = ""
        Dict
        TabIndex (1,1) double = 1       % scheda selezionata (mantenuta al cambio lingua)
        % Layout su planimetria: coordinate in pixel dell'immagine
        Lay = struct("Img", [], "PxPerM", 20, "ScaleSet", false, ...
            "ScalePts", zeros(0, 2), "Crane", [], "Lift", [])
        ClickMode (1,1) string = ""     % "", "scale1", "scale2", "crane", "lift"
        LayInfo = struct()
        RigValues                       % dati del piano di imbracatura
        DocValues                       % testi del Piano di Carico (stringhe)
        Rig = struct()                  % ultimo risultato di simulift_rigging
    end

    properties (Constant, Access = private)
        % campo, etichetta IT, etichetta EN, unita', default, massimo
        % Default: dataset generico del template Excel del progetto.
        ParamDefs = {
            "Theoretical_Weight",   "Peso da sollevare",            "Weight to lift",              "kg",  1000, Inf
            "Slings_weight",        "Catene / imbracature",         "Chains / slings",             "kg",  100,  Inf
            "Pulley_weight",        "Bozzello",                     "Hook block",                  "kg",  360,  Inf
            "Contingency_pct",      "Contingency sul peso",         "Contingency on weight",       "%",   25,   Inf
            "Crane_Capacity",       "Portata sollevabile",          "Liftable capacity",           "kg",  7500, Inf
            "Beaufort_scale",       "Vento (Beaufort 0-12)",        "Wind (Beaufort 0-12)",        "-",   3,    12
            "Wind_limit_ms",        "Velocita' vento ammessa",      "Allowed wind speed",          "m/s", 14,   Inf
            "Boom_reach_m",         "Sbraccio (lunghezza braccio)", "Boom reach (boom length)",    "m",   15,   Inf
            "Boom_angle_deg",       "Inclinazione braccio",         "Boom angle",                  "deg", 60,   89
            }
        % Schema dei dati: analisi dei carichi con contingency sul peso. La
        % velocita' del vento ammessa (default 14 m/s, valore di esempio)
        % va letta dal manuale della gru. Sbraccio e inclinazione sono
        % descrittivi: orientano lo schema, non entrano nelle verifiche.
        AssetKeys = ["none" "diesel" "gasoline" "firewater" "other" ...
            "building" "electrical" "toxic"]
        % Piano di imbracatura a due punti: campo, etichetta IT, etichetta
        % EN, unita', default (dataset generico), ascisse da un'estremita'.
        % Dati del documento "Piano di Carico": campo di simulift_plan_pdf,
        % etichetta IT, etichetta EN. I valori di default sono un esempio
        % con nomi e dati di fantasia.
        DocDefs = {
            "Title",           "Titolo del documento",       "Document title"
            "Subject",         "Oggetto del sollevamento",   "Subject of the lift"
            "Company",         "Impresa",                    "Company"
            "JobNumber",       "Commessa n.",                "Job number"
            "Site",            "Sito / cantiere",            "Site"
            "Client",          "Committente",                "Client"
            "Date",            "Data di redazione",          "Date"
            "Author",          "Responsabile del piano",     "Plan owner"
            "Revision",        "Revisione",                  "Revision"
            "Status",          "Stato del documento",        "Document status"
            "Supervisor",      "Preposto",                   "Supervisor"
            "Operator",        "Gruista / operatore",        "Crane operator"
            "Rigger",          "Addetto all'imbracatura",    "Rigger"
            "Signaller",       "Segnalatore a terra",        "Signaller"
            "SafetyOfficer",   "Responsabile sicurezza",     "Safety officer"
            "LoadDescription", "Descrizione del carico",     "Load description"
            "LoadType",        "Tipo di carico",             "Load type"
            "Crane",           "Mezzo di sollevamento",      "Crane"
            "CraneInspection", "Ultima verifica periodica",  "Last periodic inspection"
            "Accessories",     "Accessori di imbracatura",   "Rigging accessories"
            }
        RigDefs = {
            "Length_m",    "Lunghezza del carico",              "Load length",                    "m",  6
            "CoG_x_m",     "Baricentro (da un'estremita')",     "Centre of gravity (from one end)","m", 3
            "CoG_depth_m", "Baricentro sotto i punti di presa", "CoG below the pick points",      "m",  0
            "Pick1_m",     "Punto di presa 1",                  "Pick point 1",                   "m",  1
            "Pick2_m",     "Punto di presa 2",                  "Pick point 2",                   "m",  5
            "Leg1_m",      "Lunghezza tirante 1",               "Sling 1 length",                 "m",  3
            "Leg2_m",      "Lunghezza tirante 2",               "Sling 2 length",                 "m",  3
            "WLL_kg",      "Portata tirante (0 = non verificata)", "Sling WLL (0 = not checked)", "kg", 0
            }
    end

    methods (Access = public)
        function app = SimuLiftApp(language)
            arguments
                language (1,1) string {mustBeMember(language, ["it" "en"])} = "it"
            end
            % La cartella dell'app deve restare sul path: i callback e le
            % funzioni di calcolo devono funzionare anche se l'utente cambia
            % la cartella corrente mentre l'app e' aperta.
            addpath(fileparts(mfilename("fullpath")));
            app.Dict = makeDict();
            app.Lang = language;
            app.Values = cell2mat(app.ParamDefs(:, 5));
            app.RigValues = cell2mat(app.RigDefs(:, 5));
            docDefaults = simulift_plan_pdf("defaults");
            app.DocValues = arrayfun(@(f) string(docDefaults.(f)), string(app.DocDefs(:, 1)));
            app.UIFigure = uifigure("Position", [60 50 1320 800], "Visible", "off");
            buildUI(app);
            registerApp(app, app.UIFigure);
            runSimulation(app);
            app.UIFigure.Visible = "on";
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure);
        end

        function R = getResult(app)
            %GETRESULT Ultimo risultato calcolato (test e automazione).
            R = app.Result;
        end

        function tf = isStale(app)
            %ISSTALE true se i dati sono cambiati dopo l'ultima simulazione.
            tf = app.Stale;
        end

        function setParameter(app, name, value, run)
            %SETPARAMETER Imposta un parametro; run = true (default) rilancia.
            arguments
                app
                name (1,1) string
                value (1,1) double
                run (1,1) logical = true
            end
            i = find(string(app.ParamDefs(:, 1)) == name);
            app.Values(i) = value;
            app.C.Table.Data.Value(i) = value;
            markStale(app);
            if run
                runSimulation(app);
            end
        end

        function setAsset(app, asset, run)
            %SETASSET Attrezzatura sotto il carico: "none", "diesel",
            %"gasoline", "firewater", "other"; run = true (default) rilancia.
            arguments
                app
                asset (1,1) string {mustBeMember(asset, ["none" "diesel" "gasoline" ...
                    "firewater" "other" "building" "electrical" "toxic"])}
                run (1,1) logical = true
            end
            app.Asset = asset;
            app.C.Asset.Value = asset;
            markStale(app);
            if run
                runSimulation(app);
            end
        end

        function setFlags(app, tandem, nonStandard)
            %SETFLAGS Imposta "attrezzature simultanee" e "attrezzature non
            %standard" e rilancia (test e automazione).
            app.Tandem = tandem;
            app.NonStd = nonStandard;
            app.C.Tandem.Value = tandem;
            app.C.NonStd.Value = nonStandard;
            runSimulation(app);
        end

        function setLayoutImage(app, img)
            %SETLAYOUTIMAGE Imposta la planimetria (matrice immagine) e azzera scala e punti.
            if ismatrix(img)
                img = repmat(img, 1, 1, 3);         % scala di grigi -> RGB
            end
            app.Lay = struct("Img", img, "PxPerM", defaultScale(img), "ScaleSet", false, ...
                "ScalePts", zeros(0, 2), "Crane", [], "Lift", []);
            app.ClickMode = "";
            refreshLayout(app);
        end

        function setLayoutScale(app, p1, p2, distance_m)
            %SETLAYOUTSCALE Tara la scala: due punti [x y] in pixel a distanza nota [m].
            app.Lay.ScalePts = [p1; p2];
            app.Lay.PxPerM = norm(p2 - p1) / distance_m;
            app.Lay.ScaleSet = true;
            app.ClickMode = "";
            refreshLayout(app);
        end

        function setLayoutPoint(app, which, p)
            %SETLAYOUTPOINT Posiziona "crane" o "lift" in pixel [x y].
            if which == "crane"
                app.Lay.Crane = p;
            else
                app.Lay.Lift = p;
            end
            refreshLayout(app);
        end

        function info = getLayoutInfo(app)
            info = app.LayInfo;
        end

        function setRigging(app, name, value)
            %SETRIGGING Imposta un dato del piano di imbracatura e ricalcola.
            i = string(app.RigDefs(:, 1)) == name;
            app.RigValues(i) = value;
            app.C.RigTable.Data.Value(i) = value;
            refreshRigging(app);
        end

        function G = getRigging(app)
            G = app.Rig;
        end

        function setDoc(app, name, value)
            %SETDOC Imposta un dato del documento (vedi DocDefs), es. setDoc(app, "Site", "...").
            i = string(app.DocDefs(:, 1)) == name;
            app.DocValues(i) = string(value);
            app.C.DocTable.Data.Value(i) = string(value);
        end

        function file = writePlan(app, file, previewFolder)
            %WRITEPLAN Scrive il Piano di Carico in PDF nel file indicato.
            %Usa i dati correnti delle schede; il documento e' in italiano.
            arguments
                app
                file (1,1) string
                previewFolder (1,1) string = ""
            end
            [P, windLimit_ms] = currentParameters(app);
            R = simulift_static_check(P, WindSpeedLimit_ms=windLimit_ms, ...
                UnderlyingAsset=app.Asset, SimultaneousEquipment=app.Tandem, ...
                NonStandardEquipment=app.NonStd, Language="it");
            rigNames = string(app.RigDefs(:, 1));
            try
                geo = cell2struct(num2cell(app.RigValues(rigNames ~= "WLL_kg")), ...
                    cellstr(rigNames(rigNames ~= "WLL_kg")), 1);
                G = simulift_rigging(P.Theoretical_Weight, geo, ...
                    WLL_kg=app.RigValues(rigNames == "WLL_kg"), Language="it");
            catch
                G = struct();                    % imbracatura non valida: sezione omessa
            end
            doc = cell2struct(cellstr(app.DocValues), cellstr(string(app.DocDefs(:, 1))), 1);
            simulift_plan_pdf(file, R, Doc=doc, Rigging=G, Layout=app.Lay, ...
                PreviewFolder=previewFolder);
        end

        function selectTab(app, index)
            app.TabIndex = index;
            app.C.Tabs(index).Parent.SelectedTab = app.C.Tabs(index);
        end

        function setLanguage(app, language)
            app.Lang = language;
            rebuild(app);
        end
    end

    methods (Access = private)
        function s = tr(app, key)
            d = app.Dict.(key);
            s = d(1 + (app.Lang == "en"));
        end

        function rebuild(app)
            wasStale = app.Stale;
            delete(app.UIFigure.Children);
            buildUI(app);
            if wasStale || isempty(fieldnames(app.Result))
                markStale(app);
            else
                runSimulation(app);
            end
        end

        function buildUI(app)
            app.UIFigure.Name = tr(app, "title");
            root = uigridlayout(app.UIFigure, [1 1]);
            root.Padding = [4 4 4 4];
            tg = uitabgroup(root, "SelectionChangedFcn", @(src, ~) onTab(app, src));
            tabCheck = uitab(tg, "Title", tr(app, "tabCheck"));
            tabLayout = uitab(tg, "Title", tr(app, "tabLayout"));
            tabRig = uitab(tg, "Title", tr(app, "tabRig"));
            tabDoc = uitab(tg, "Title", tr(app, "tabDoc"));
            app.C.Tabs = [tabCheck tabLayout tabRig tabDoc];
            buildDocTab(app, tabDoc);
            tg.SelectedTab = app.C.Tabs(app.TabIndex);
            buildLayoutTab(app, tabLayout);
            buildRiggingTab(app, tabRig);
            main = uigridlayout(tabCheck, [2 2]);
            main.ColumnWidth = {430, "1x"};
            main.RowHeight = {"1x", 24};

            % --- Colonna dati ---
            left = uigridlayout(main, [11 2]);
            left.RowHeight = {24, "1x", 24, 22, 22, 46, 42, 28, 28, 28, 28};
            left.ColumnWidth = {"1x", 170};
            left.Padding = [0 0 0 0];

            uilabel(left, "Text", tr(app, "tableTitle"), "FontWeight", "bold");
            app.C.Lang = uidropdown(left, "Items", {'Italiano', 'English'}, ...
                "ItemsData", ["it" "en"], "Value", app.Lang, ...
                "ValueChangedFcn", @(src, ~) setLanguage(app, string(src.Value)));

            labels = string(app.ParamDefs(:, 2 + (app.Lang == "en")));
            data = table(labels, app.Values, string(app.ParamDefs(:, 4)), ...
                'VariableNames', ["Parameter" "Value" "Unit"]);
            app.C.Table = uitable(left, "Data", data, ...
                "ColumnName", cellstr(split(tr(app, "tableCols"), "|")), ...
                "ColumnEditable", [false true false], ...
                "ColumnWidth", {"1x", 90, 50}, "RowName", {}, ...
                "CellEditCallback", @(~, evt) onCellEdit(app, evt));
            wide(app.C.Table);

            uilabel(left, "Text", tr(app, "asset"), "FontWeight", "bold");
            app.C.Asset = uidropdown(left, ...
                "Items", cellstr(split(tr(app, "assetItems"), "|")), ...
                "ItemsData", app.AssetKeys, "Value", app.Asset, ...
                "ValueChangedFcn", @(src, ~) onAsset(app, src));
            app.C.Tandem = uicheckbox(left, "Text", tr(app, "tandem"), ...
                "Value", app.Tandem, "ValueChangedFcn", @(~, ~) onFlags(app));
            wide(app.C.Tandem);
            app.C.NonStd = uicheckbox(left, "Text", tr(app, "nonStd"), ...
                "Value", app.NonStd, "ValueChangedFcn", @(~, ~) onFlags(app));
            wide(app.C.NonStd);

            wide(uibutton(left, "Text", tr(app, "run"), "FontSize", 16, ...
                "FontWeight", "bold", "BackgroundColor", [0.13 0.45 0.80], ...
                "FontColor", "w", "ButtonPushedFcn", @(~, ~) runSimulation(app)));
            wide(uibutton(left, "Text", tr(app, "planButton"), "FontSize", 14, ...
                "FontWeight", "bold", "BackgroundColor", [0.10 0.50 0.25], ...
                "FontColor", "w", "ButtonPushedFcn", @(~, ~) generatePlan(app)));
            wide(uibutton(left, "Text", tr(app, "excel"), ...
                "ButtonPushedFcn", @(~, ~) loadExcel(app)));
            wide(uibutton(left, "Text", tr(app, "reset"), ...
                "ButtonPushedFcn", @(~, ~) resetDefaults(app)));
            wide(uibutton(left, "Text", tr(app, "report"), ...
                "ButtonPushedFcn", @(~, ~) exportReport(app)));
            wide(uilabel(left, "Text", tr(app, "hint"), "FontColor", [0.4 0.4 0.4]));

            % --- Colonna risultati ---
            r = uigridlayout(main, [5 1]);
            r.RowHeight = {50, 44, "2.2x", "1x", 0};
            app.C.RGrid = r;
            r.Padding = [0 0 0 0];

            app.C.Verdict = uilabel(r, "Text", "", "FontSize", 24, ...
                "FontWeight", "bold", "HorizontalAlignment", "center", "FontColor", "w");

            lg = uigridlayout(r, [1 6]);
            lg.ColumnWidth = repmat({30, "1x"}, 1, 3);
            lg.Padding = [10 5 10 5];
            keys = ["Overload" "Wind" "Class"];
            for k = keys
                app.C.("Lamp" + k) = uilamp(lg);
                app.C.("Label" + k) = uilabel(lg, "Text", tr(app, "lamp" + k), ...
                    "FontWeight", "bold");
            end

            mid = uigridlayout(r, [1 2]);
            % lo schema della gru e' limitato in altezza, non in larghezza:
            % meta' dello spazio a testa, cosi' il grafico non si restringe
            mid.ColumnWidth = {"1x", "1x"};
            mid.Padding = [0 0 0 0];
            app.C.CraneAx = uiaxes(mid);
            app.C.CraneAx.Toolbar.Visible = "off";
            disableDefaultInteractivity(app.C.CraneAx);
            app.C.BarAx = uiaxes(mid);
            ylabel(app.C.BarAx, tr(app, "barY"));
            title(app.C.BarAx, tr(app, "barTitle"));
            grid(app.C.BarAx, "on");

            app.C.Results = uitable(r, "ColumnEditable", false, "RowName", {});
            app.C.Contingency = uilabel(r, "Text", "", "WordWrap", "on", ...
                "FontWeight", "bold", "FontColor", [0.70 0.38 0.00], ...
                "VerticalAlignment", "top");

            app.C.Status = uilabel(main, "Text", "");
            app.C.Status.Layout.Row = 2;
            app.C.Status.Layout.Column = [1 2];
        end

        function onCellEdit(app, evt)
            i = evt.Indices(1);
            v = evt.NewData;
            maxV = app.ParamDefs{i, 6};
            if ~(isnumeric(v) && isscalar(v) && isfinite(v) && v >= 0 && v <= maxV)
                app.C.Table.Data.Value(i) = app.Values(i);
                uialert(app.UIFigure, sprintf(tr(app, "badValue"), maxV), ...
                    tr(app, "badValueTitle"), "Icon", "warning");
                return
            end
            app.Values(i) = v;
            if app.SourceFile ~= ""
                app.SourceFile = app.SourceFile + " " + tr(app, "edited");
            end
            markStale(app);
        end

        function onAsset(app, src)
            app.Asset = string(src.Value);
            markStale(app);
        end

        function onFlags(app)
            app.Tandem = app.C.Tandem.Value;
            app.NonStd = app.C.NonStd.Value;
            markStale(app);
        end

        function markStale(app)
            app.Stale = true;
            grey = [0.60 0.60 0.60];
            app.C.Verdict.Text = tr(app, "stale");
            app.C.Verdict.BackgroundColor = grey;
            for k = ["Overload" "Wind" "Class"]
                app.C.("Lamp" + k).Color = grey;
            end
            app.C.LabelClass.Text = tr(app, "lampClass");
            app.C.Status.Text = tr(app, "staleStatus");
            app.C.Contingency.Text = "";
            app.C.RGrid.RowHeight{5} = 0;
        end

        function [P, windLimit_N] = currentParameters(app)
            full = cell2struct(num2cell(app.Values), cellstr(string(app.ParamDefs(:, 1))), 1);
            windLimit_N = full.Wind_limit_ms;      % velocita' ammessa [m/s]
            P = rmfield(full, "Wind_limit_ms");
        end

        function runSimulation(app)
            try
                [P, windLimit_N] = currentParameters(app);
                R = simulift_static_check(P, WindSpeedLimit_ms=windLimit_N, ...
                    UnderlyingAsset=app.Asset, SimultaneousEquipment=app.Tandem, ...
                    NonStandardEquipment=app.NonStd, Language=app.Lang);
            catch err
                app.Result = struct();
                app.C.Verdict.Text = tr(app, "invalid");
                app.C.Verdict.BackgroundColor = [0.5 0.5 0.5];
                app.C.Status.Text = err.message;
                return
            end
            app.Result = R;
            app.Stale = false;

            red = [0.85 0.10 0.10];
            green = [0.10 0.60 0.10];
            amber = [0.95 0.60 0.10];
            app.C.Verdict.Text = R.Verdict;
            app.C.Verdict.BackgroundColor = pick(R.GlobalAlarm, red, ...
                pick(R.ContingencyRequired, amber, green));
            info = classLines(app, R);
            app.C.Contingency.Text = strjoin(info, newline);
            app.C.RGrid.RowHeight{5} = 20 * numel(info);
            app.C.LampOverload.Color = pick(R.OverloadAlarm, red, green);
            app.C.LampWind.Color = pick(R.WindAlarm, red, green);
            % classificazione: verde standard, giallo non standard, ambra critico
            switch R.ClassCode
                case "critical",    classColor = amber;
                case "nonstandard", classColor = [0.93 0.83 0.10];
                otherwise,          classColor = green;
            end
            app.C.LampClass.Color = classColor;
            app.C.LabelClass.Text = R.Class;

            app.C.Results.Data = R.Table;
            app.C.Results.ColumnName = cellstr(split(tr(app, "resCols"), "|"));

            simulift_draw_crane(app.C.CraneAx, R, Language=app.Lang);

            util = 100 * [R.CraneUtilization, R.WindSpeed_ms / R.WindSpeedLimit_ms, ...
                R.GrossUtilization];
            names = split(tr(app, "barLabels"), "|").';
            labels = 1:numel(util);          % ascisse numeriche: etichette su due righe
            shown = min(util, 200);          % scala limitata al 200%
            shown(isnan(util)) = 0;          % min(NaN, 200) vale 200: azzerare sui NaN di util
            cla(app.C.BarAx);
            hb = bar(app.C.BarAx, labels, shown, 0.6, "FaceColor", "flat");
            app.C.BarAx.XTick = labels;
            app.C.BarAx.XTickLabel = replace(names, "/", "\newline");   % "a/b" -> a sopra, b sotto
            app.C.BarAx.XTickLabelRotation = 0;
            app.C.BarAx.XLim = [0.4, numel(util) + 0.6];
            barColors = repmat(green, numel(util), 1);
            barColors(util > 100, :) = repmat(red, nnz(util > 100), 1);
            barColors(3, :) = classColor;     % carico lordo / portata: soglie 80% e 90%
            hb.CData = barColors;
            yline(app.C.BarAx, [80 90], ":", ["80%" "90%"], "Color", [0.4 0.4 0.4]);
            yline(app.C.BarAx, 100, "--k", tr(app, "limit"));
            ylim(app.C.BarAx, [0 215]);
            txt = compose("%.0f%%", util);
            txt(isnan(util)) = "n/a";
            text(app.C.BarAx, labels, shown + 7, txt, "HorizontalAlignment", "center");

            src = app.SourceFile;
            if src == ""
                src = tr(app, "manual");
            end
            app.C.Status.Text = sprintf(tr(app, "status"), src, ...
                string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss")));
            refreshLayout(app);
            refreshRigging(app);
        end

        % ================= Scheda: layout su planimetria =================

        function onTab(app, src)
            app.TabIndex = find(app.C.Tabs == src.SelectedTab);
        end

        function buildLayoutTab(app, tab)
            g = uigridlayout(tab, [1 2]);
            g.ColumnWidth = {300, "1x"};
            c = uigridlayout(g, [10 2]);
            c.RowHeight = {30, 24, 30, 30, 30, 30, 22, "1x", 22, 120};
            c.ColumnWidth = {"1x", 90};
            c.Padding = [0 0 0 0];
            wide(uibutton(c, "Text", tr(app, "layLoad"), "FontWeight", "bold", ...
                "ButtonPushedFcn", @(~, ~) loadPlan(app)));
            uilabel(c, "Text", tr(app, "layDist"));
            app.C.LayDist = uieditfield(c, "numeric", "Value", 10, "Limits", [0 Inf], ...
                "LowerLimitInclusive", "off");
            wide(uibutton(c, "Text", tr(app, "layScale"), ...
                "ButtonPushedFcn", @(~, ~) startClick(app, "scale1")));
            wide(uibutton(c, "Text", tr(app, "layCrane"), ...
                "ButtonPushedFcn", @(~, ~) startClick(app, "crane")));
            wide(uibutton(c, "Text", tr(app, "layLift"), ...
                "ButtonPushedFcn", @(~, ~) startClick(app, "lift")));
            wide(uibutton(c, "Text", tr(app, "layClear"), ...
                "ButtonPushedFcn", @(~, ~) clearLayout(app)));
            wide(uilabel(c, "Text", tr(app, "layHintTitle"), "FontWeight", "bold"));
            app.C.LayHint = uilabel(c, "Text", "", "WordWrap", "on", "VerticalAlignment", "top");
            wide(app.C.LayHint);
            wide(uilabel(c, "Text", tr(app, "layInfoTitle"), "FontWeight", "bold"));
            app.C.LayInfo = uilabel(c, "Text", "", "WordWrap", "on", "VerticalAlignment", "top");
            wide(app.C.LayInfo);
            app.C.LayAx = uiaxes(g);
            app.C.LayAx.Toolbar.Visible = "off";
            disableDefaultInteractivity(app.C.LayAx);
        end

        function loadPlan(app)
            [f, p] = uigetfile({"*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp", tr(app, "layImages"); ...
                "*.pdf;*.dwg;*.dxf", "PDF / DWG / DXF"}, tr(app, "layLoad"));
            figure(app.UIFigure);
            if isequal(f, 0)
                return
            end
            [~, ~, ext] = fileparts(f);
            if ismember(lower(string(ext)), [".pdf" ".dwg" ".dxf"])
                uialert(app.UIFigure, tr(app, "layNoCad"), tr(app, "layLoad"), "Icon", "warning");
                return
            end
            try
                [img, map] = imread(fullfile(p, f));
                if ~isempty(map)
                    img = ind2rgb(img, map);
                end
            catch err
                uialert(app.UIFigure, err.message, tr(app, "layLoad"));
                return
            end
            setLayoutImage(app, img);
        end

        function startClick(app, mode)
            app.ClickMode = mode;
            refreshLayout(app);
        end

        function onLayoutClick(app, evt)
            p = evt.IntersectionPoint(1:2);
            switch app.ClickMode
                case "scale1"
                    app.Lay.ScalePts = p;
                    app.ClickMode = "scale2";
                case "scale2"
                    setLayoutScale(app, app.Lay.ScalePts(1, :), p, app.C.LayDist.Value);
                    return
                case "crane"
                    app.Lay.Crane = p;
                    app.ClickMode = "";
                case "lift"
                    app.Lay.Lift = p;
                    app.ClickMode = "";
                otherwise
                    return
            end
            refreshLayout(app);
        end

        function clearLayout(app)
            img = app.Lay.Img;
            app.Lay = struct("Img", img, "PxPerM", defaultScale(img), "ScaleSet", false, ...
                "ScalePts", zeros(0, 2), "Crane", [], "Lift", []);
            app.ClickMode = "";
            refreshLayout(app);
        end

        function refreshLayout(app)
            if isempty(fieldnames(app.Result))
                return
            end
            [info, hImage] = simulift_draw_layout(app.C.LayAx, app.Lay, app.Result, ...
                Language=app.Lang);
            hImage.ButtonDownFcn = @(~, evt) onLayoutClick(app, evt);
            app.LayInfo = info;
            hints = struct("none", "layHintNone", "scale1", "layHintScale1", ...
                "scale2", "layHintScale2", "crane", "layHintCrane", "lift", "layHintLift");
            key = app.ClickMode;
            if key == ""
                key = "none";
            end
            app.C.LayHint.Text = tr(app, hints.(key));
            lines = pick(info.ScaleSet, tr(app, "layScaleOk"), tr(app, "layScaleNo"));
            if ~isnan(info.Distance_m)
                lines(end+1) = sprintf(tr(app, "layDistance"), info.Distance_m, ...
                    info.Projection_m, info.Difference_m);
                lines(end+1) = pick(info.Consistent, tr(app, "layConsistent"), tr(app, "layInconsistent"));
            end
            app.C.LayInfo.Text = strjoin(lines, newline);
        end

        % ================= Scheda: dati del documento =================

        function buildDocTab(app, tab)
            g = uigridlayout(tab, [3 1]);
            g.RowHeight = {44, "1x", 46};
            uilabel(g, "Text", tr(app, "docExplain"), "WordWrap", "on", ...
                "VerticalAlignment", "top", "BackgroundColor", [1.00 0.98 0.88]);
            labels = string(app.DocDefs(:, 2 + (app.Lang == "en")));
            data = table(labels, app.DocValues, 'VariableNames', ["Field" "Value"]);
            app.C.DocTable = uitable(g, "Data", data, ...
                "ColumnName", cellstr(split(tr(app, "docCols"), "|")), ...
                "ColumnEditable", [false true], "ColumnWidth", {300, "1x"}, "RowName", {}, ...
                "CellEditCallback", @(~, evt) onDocEdit(app, evt));
            uibutton(g, "Text", tr(app, "planButton"), "FontSize", 15, "FontWeight", "bold", ...
                "BackgroundColor", [0.10 0.50 0.25], "FontColor", "w", ...
                "ButtonPushedFcn", @(~, ~) generatePlan(app));
        end

        function onDocEdit(app, evt)
            app.DocValues(evt.Indices(1)) = string(evt.NewData);
        end

        function generatePlan(app)
            if app.Stale || isempty(fieldnames(app.Result))
                uialert(app.UIFigure, tr(app, "staleStatus"), tr(app, "planButton"));
                return
            end
            [f, p] = uiputfile("*.pdf", tr(app, "planButton"), "Piano_di_Carico.pdf");
            figure(app.UIFigure);
            if isequal(f, 0)
                return
            end
            dlg = uiprogressdlg(app.UIFigure, "Title", tr(app, "planButton"), ...
                "Message", tr(app, "planBusy"), "Indeterminate", "on");
            try
                writePlan(app, fullfile(p, f));
                close(dlg);
                app.C.Status.Text = tr(app, "planDone") + " " + string(fullfile(p, f));
                uialert(app.UIFigure, tr(app, "planDone") + newline + string(fullfile(p, f)), ...
                    tr(app, "planButton"), "Icon", "success");
            catch err
                close(dlg);
                uialert(app.UIFigure, err.message, tr(app, "planButton"));
            end
        end

        % ================= Scheda: piano di imbracatura =================

        function buildRiggingTab(app, tab)
            g = uigridlayout(tab, [1 2]);
            g.ColumnWidth = {430, "1x"};
            c = uigridlayout(g, [5 1]);
            c.RowHeight = {22, 270, 40, 30, "1x"};
            c.Padding = [0 0 0 0];
            app.C.RigLoad = uilabel(c, "Text", "", "FontWeight", "bold");
            labels = string(app.RigDefs(:, 2 + (app.Lang == "en")));
            data = table(labels, app.RigValues, string(app.RigDefs(:, 4)), ...
                'VariableNames', ["Parameter" "Value" "Unit"]);
            app.C.RigTable = uitable(c, "Data", data, ...
                "ColumnName", cellstr(split(tr(app, "tableCols"), "|")), ...
                "ColumnEditable", [false true false], "ColumnWidth", {"1x", 90, 50}, ...
                "RowName", {}, "CellEditCallback", @(~, evt) onRigEdit(app, evt));
            uibutton(c, "Text", tr(app, "rigRun"), "FontSize", 15, "FontWeight", "bold", ...
                "BackgroundColor", [0.13 0.45 0.80], "FontColor", "w", ...
                "ButtonPushedFcn", @(~, ~) refreshRigging(app));
            uibutton(c, "Text", tr(app, "rigApply"), ...
                "ButtonPushedFcn", @(~, ~) applyRigSuggestion(app));
            app.C.RigMsg = uilabel(c, "Text", "", "WordWrap", "on", "VerticalAlignment", "top");
            r = uigridlayout(g, [3 1]);
            r.RowHeight = {66, "1.9x", "1x"};
            r.Padding = [0 0 0 0];
            uilabel(r, "Text", tr(app, "rigExplain"), "WordWrap", "on", ...
                "VerticalAlignment", "top", "BackgroundColor", [1.00 0.98 0.88]);
            % a sinistra l'assetto con i dati inseriti, a destra quello con
            % i punti di presa proposti (mostrato solo se il carico e' sbilanciato)
            app.C.RigAxGrid = uigridlayout(r, [1 2]);
            app.C.RigAxGrid.Padding = [0 0 0 0];
            app.C.RigAx = uiaxes(app.C.RigAxGrid);
            app.C.RigAx2 = uiaxes(app.C.RigAxGrid);
            for a = [app.C.RigAx app.C.RigAx2]
                a.Toolbar.Visible = "off";
                disableDefaultInteractivity(a);
            end
            app.C.RigResults = uitable(r, "ColumnEditable", false, "RowName", {});
        end

        function onRigEdit(app, evt)
            i = evt.Indices(1);
            v = evt.NewData;
            if ~(isnumeric(v) && isscalar(v) && isfinite(v) && v >= 0)
                app.C.RigTable.Data.Value(i) = app.RigValues(i);
                return
            end
            app.RigValues(i) = v;
            refreshRigging(app);
        end

        function applyRigSuggestion(app)
            if isempty(fieldnames(app.Rig))
                return
            end
            names = string(app.RigDefs(:, 1));
            s = app.Rig.Suggestion;
            app.RigValues(names == "Pick1_m") = s.Pick1_m;
            app.RigValues(names == "Pick2_m") = s.Pick2_m;
            app.RigValues(names == "Leg1_m") = s.Leg_m;
            app.RigValues(names == "Leg2_m") = s.Leg_m;
            app.C.RigTable.Data.Value = app.RigValues;
            refreshRigging(app);
        end

        function refreshRigging(app)
            names = string(app.RigDefs(:, 1));
            mass_kg = app.Values(string(app.ParamDefs(:, 1)) == "Theoretical_Weight");
            app.C.RigLoad.Text = sprintf(tr(app, "rigLoad"), mass_kg);
            geo = cell2struct(num2cell(app.RigValues(names ~= "WLL_kg")), ...
                cellstr(names(names ~= "WLL_kg")), 1);
            try
                G = simulift_rigging(mass_kg, geo, WLL_kg=app.RigValues(names == "WLL_kg"), ...
                    Language=app.Lang);
            catch err
                app.Rig = struct();
                cla(app.C.RigAx);
                title(app.C.RigAx, "");
                app.C.RigAxGrid.ColumnWidth = {"1x", 0};
                app.C.RigResults.Data = table();
                app.C.RigMsg.Text = err.message;
                app.C.RigMsg.FontColor = [0.85 0.10 0.10];
                return
            end
            app.Rig = G;
            simulift_draw_rigging(app.C.RigAx, G, Language=app.Lang, Title=tr(app, "rigNow"));
            % se il carico e' sbilanciato, a destra l'assetto con i punti di presa proposti
            shown = false;
            if G.TiltAlarm
                try
                    geo2 = geo;
                    geo2.Pick1_m = G.Suggestion.Pick1_m;
                    geo2.Pick2_m = G.Suggestion.Pick2_m;
                    geo2.Leg1_m = G.Suggestion.Leg_m;
                    geo2.Leg2_m = G.Suggestion.Leg_m;
                    G2 = simulift_rigging(mass_kg, geo2, ...
                        WLL_kg=app.RigValues(names == "WLL_kg"), Language=app.Lang);
                    simulift_draw_rigging(app.C.RigAx2, G2, Language=app.Lang, ...
                        Title=tr(app, "rigAfter"));
                    shown = true;
                catch
                    % proposta non realizzabile con questa geometria: si mostra solo lo stato attuale
                end
            end
            if shown
                app.C.RigAxGrid.ColumnWidth = {"1x", "1x"};
            else
                cla(app.C.RigAx2);
                app.C.RigAxGrid.ColumnWidth = {"1x", 0};
            end
            app.C.RigResults.Data = G.Table;
            app.C.RigResults.ColumnName = cellstr(split(tr(app, "resCols"), "|"));
            app.C.RigMsg.Text = strjoin([G.Messages; ""; tr(app, "rigNote")], newline);
            app.C.RigMsg.FontColor = pick(G.Alarm, [0.70 0.38 0.00], [0.05 0.45 0.10]);
        end

        function loadExcel(app)
            [f, p] = uigetfile("*.xlsx", tr(app, "excel"));
            figure(app.UIFigure);
            if isequal(f, 0)
                return
            end
            try
                P = simulift_read_excel(fullfile(p, f));
            catch err
                uialert(app.UIFigure, err.message, tr(app, "excel"));
                return
            end
            known = string(app.ParamDefs(:, 1));
            for i = find(isfield(P, known)).'
                app.Values(i) = min(max(P.(known(i)), 0), app.ParamDefs{i, 6});
            end
            app.C.Table.Data.Value = app.Values;
            app.SourceFile = string(f);
            runSimulation(app);
            base = ["Theoretical_Weight" "Pulley_weight" "Slings_weight" ...
                "Crane_Capacity" "Beaufort_scale"];
            notFound = base(~isfield(P, base));
            if ~isempty(notFound)
                uialert(app.UIFigure, tr(app, "missing") + " " + join(notFound, ", "), ...
                    tr(app, "excel"), "Icon", "warning");
            end
        end

        function resetDefaults(app)
            app.Values = cell2mat(app.ParamDefs(:, 5));
            app.C.Table.Data.Value = app.Values;
            app.Asset = "none";
            app.C.Asset.Value = "none";
            app.Tandem = false;
            app.NonStd = false;
            app.C.Tandem.Value = false;
            app.C.NonStd.Value = false;
            app.SourceFile = "";
            runSimulation(app);
        end

        function exportReport(app)
            if app.Stale || isempty(fieldnames(app.Result))
                uialert(app.UIFigure, tr(app, "staleStatus"), tr(app, "report"));
                return
            end
            [f, p] = uiputfile({"*.txt", "TXT"; "*.pdf", "PDF"}, tr(app, "report"), ...
                "SimuLift_Report.txt");
            figure(app.UIFigure);
            if isequal(f, 0)
                return
            end
            target = fullfile(p, f);
            try
                if endsWith(f, ".pdf", "IgnoreCase", true)
                    exportapp(app.UIFigure, target);
                else
                    writelines(reportText(app), target);
                end
            catch err
                uialert(app.UIFigure, err.message, tr(app, "report"));
            end
        end

        function lines = classLines(app, R)
            % Classificazione, motivi e azioni di contingency (colonna di testo).
            head = tr(app, "classHead") + ": " + R.Class;
            if R.ClassCode == "critical"
                head = head + " - " + tr(app, "approval");
            end
            lines = [head; "  - " + R.ClassReasons(:); "  > " + R.ContingencyActions(:)];
        end

        function txt = reportText(app)
            R = app.Result;
            src = app.SourceFile;
            if src == ""
                src = tr(app, "manual");
            end
            D = app.C.Table.Data;
            txt = [
                tr(app, "repTitle")
                tr(app, "repDate") + ": " + string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"))
                tr(app, "repSource") + ": " + src
                ""
                tr(app, "repVerdict") + ": " + R.Verdict
                tr(app, "asset") + ": " + app.C.Asset.Items{app.AssetKeys == app.Asset}
                tr(app, "tandem") + ": " + pick(app.Tandem, tr(app, "yes"), tr(app, "no"))
                tr(app, "nonStd") + ": " + pick(app.NonStd, tr(app, "yes"), tr(app, "no"))
                classLines(app, R)
                ""
                tr(app, "tableTitle") + ":"
                compose("  %-32s = %g %s", D.Parameter, D.Value, D.Unit)
                ""
                tr(app, "repResults") + ":"
                splitlines(string(formattedDisplayText(R.Table)))
                ""
                tr(app, "disclaimer")
                ];
        end
    end
end

function wide(h)
h.Layout.Column = [1 2];
end

function ppm = defaultScale(img)
% Scala provvisoria [pixel/m] prima della taratura: larghezza = 45 m.
if isempty(img)
    ppm = 20;                              % foglio bianco 900 px
else
    ppm = size(img, 2) / 45;
end
end

function v = pick(cond, a, b)
if cond
    v = a;
else
    v = b;
end
end

function d = makeDict()
% Testi dell'interfaccia: [italiano, inglese].
d.title = ["SimuLift - Verifica statica del sollevamento", "SimuLift - Static lift check"];
d.tabCheck = ["Verifica", "Check"];
d.tabLayout = ["Layout su planimetria", "Layout on site plan"];
d.tabRig = ["Piano di imbracatura", "Rigging plan"];
d.tabDoc = ["Dati del documento", "Document data"];
d.planButton = ["Genera Piano di Carico (PDF)", "Generate Load Plan (PDF)"];
d.planBusy = ["Scrittura del PDF in corso...", "Writing the PDF..."];
d.planDone = ["Piano di Carico salvato:", "Load plan saved:"];
d.docCols = ["Campo|Valore", "Field|Value"];
d.docExplain = ["Dati che compaiono nel Piano di Carico: modificare la colonna Valore. I valori iniziali sono un esempio con nomi di fantasia. Carichi, mezzo, layout e imbracatura vengono dalle altre schede. Il documento e' in italiano.", ...
    "Data shown in the Load Plan: edit the Value column. The initial values are an example with fictitious names. Loads, crane, layout and rigging come from the other tabs. The document is written in Italian."];
d.layLoad = ["Carica planimetria (immagine)...", "Load site plan (image)..."];
d.layImages = ["Immagini", "Images"];
d.layNoCad = ["I file PDF, DWG e DXF non si possono leggere direttamente: esportare la planimetria da AutoCAD come immagine PNG o JPEG (comando STAMPA o ESPORTA) e caricarla.", ...
    "PDF, DWG and DXF files cannot be read directly: export the site plan from AutoCAD as a PNG or JPEG image (PLOT or EXPORT command) and load it."];
d.layDist = ["Distanza nota [m]", "Known distance [m]"];
d.layScale = ["Tara la scala (clicca 2 punti)", "Set the scale (click 2 points)"];
d.layCrane = ["Posiziona la gru (1 clic)", "Place the crane (1 click)"];
d.layLift = ["Posiziona il punto di sollevamento (1 clic)", "Place the lift point (1 click)"];
d.layClear = ["Azzera scala e posizioni", "Reset scale and positions"];
d.layHintTitle = ["Cosa fare ora", "What to do now"];
d.layInfoTitle = ["Misure", "Measurements"];
d.layHintNone = ["Scegliere un comando qui sopra, poi cliccare sulla planimetria. Carico, attrezzatura sorvolata, sbraccio e inclinazione vengono dalla scheda Verifica.", ...
    "Choose a command above, then click on the site plan. Load, equipment below, boom reach and angle come from the Check tab."];
d.layHintScale1 = ["Cliccare il PRIMO punto di una distanza nota.", "Click the FIRST point of a known distance."];
d.layHintScale2 = ["Cliccare il SECONDO punto della distanza nota.", "Click the SECOND point of the known distance."];
d.layHintCrane = ["Cliccare il centro della gru.", "Click the centre of the crane."];
d.layHintLift = ["Cliccare il punto di sollevamento del carico.", "Click the lift point of the load."];
d.layScaleOk = ["Scala tarata su due punti.", "Scale set from two points."];
d.layScaleNo = ["Scala NON tarata: le distanze non sono affidabili.", "Scale NOT set: distances are not reliable."];
d.layDistance = ["Distanza gru-carico %.1f m; proiezione del braccio %.1f m; differenza %+.1f m.", ...
    "Crane-to-load distance %.1f m; boom projection %.1f m; difference %+.1f m."];
d.layConsistent = ["Coerente con sbraccio e inclinazione (entro 2 m).", "Consistent with boom reach and angle (within 2 m)."];
d.layInconsistent = ["NON coerente con sbraccio e inclinazione: rivedere posizione della gru o configurazione del braccio.", ...
    "NOT consistent with boom reach and angle: review the crane position or the boom configuration."];
d.rigLoad = ["Peso da sollevare: %g kg (dalla scheda Verifica)", "Weight to lift: %g kg (from the Check tab)"];
d.rigExplain = ["Come leggere lo schema: il carico e' visto di fianco, appeso al gancio della gru con due tiranti. Una volta sollevato, il baricentro si porta sempre sotto il gancio (linea tratteggiata): se i punti di presa non sono simmetrici rispetto al baricentro, il carico si inclina e un tirante lavora piu' dell'altro. Verde = bilanciato, rosso = da rivedere. Le distanze si misurano da un'estremita' del carico.", ...
    "How to read the sketch: the load is seen from the side, hanging from the crane hook on two slings. Once lifted, the centre of gravity always moves under the hook (dashed line): if the pick points are not symmetric about the centre of gravity, the load tilts and one sling carries more than the other. Green = balanced, red = to be revised. Distances are measured from one end of the load."];
d.rigNow = ["COM'E' ORA (dati inseriti)", "AS IT IS NOW (entered data)"];
d.rigAfter = ["COME DIVENTA (punti di presa proposti)", "AS IT BECOMES (proposed pick points)"];
d.rigRun = ["Calcola piano di imbracatura", "Compute rigging plan"];
d.rigApply = ["Applica punti di presa bilanciati", "Apply balanced pick points"];
d.rigNote = ["Due punti di presa su gancio singolo, statica piana. Strumento di supporto: il piano di imbracatura va verificato da personale competente.", ...
    "Two pick points on a single hook, plane statics. Support tool: the rigging plan must be checked by competent personnel."];
d.tableTitle = ["Dati del sollevamento", "Lift data"];
d.tableCols = ["Parametro|Valore|Unita'", "Parameter|Value|Unit"];
d.asset = ["Sotto o vicino al carico", "Under or near the load"];
d.assetItems = ["Niente|Linea gasolio|Linea benzina|Linea antincendio|Altra attrezzatura in esercizio|Edificio occupato|Linea elettrica|Attrezzatura con gas tossici", ...
    "Nothing|Diesel line|Gasoline line|Firewater line|Other in-service equipment|Occupied building|Electrical line|Equipment with toxic gas"];
d.tandem = ["Due o piu' attrezzature di sollevamento insieme", "Two or more lifting appliances together"];
d.nonStd = ["Attrezzature di sollevamento non standard", "Non-standard lifting equipment"];
d.classHead = ["Classificazione del sollevamento", "Lift classification"];
d.approval = ["approvazione preventiva richiesta", "prior approval required"];
d.run = ["Lancia simulazione", "Run simulation"];
d.excel = ["Carica dati da Excel...", "Load data from Excel..."];
d.reset = ["Ripristina valori di default", "Restore default values"];
d.report = ["Esporta report (.txt / .pdf)...", "Export report (.txt / .pdf)..."];
d.hint = ["Modificare la colonna Valore, poi lanciare.", "Edit the Value column, then run."];
d.lampOverload = ["Portata sollevabile", "Liftable capacity"];
d.lampWind = ["Vento", "Wind"];
d.lampClass = ["Classificazione", "Classification"];
d.barY = ["Utilizzo del limite [%]", "Limit utilisation [%]"];
d.barTitle = ["Utilizzo rispetto ai limiti", "Utilisation against limits"];
d.barLabels = ["Totale/su portata|Vento/su ammesso|Carico lordo/su portata", "Total/vs capacity|Wind/vs allowed|Gross load/vs capacity"];
d.limit = ["limite", "limit"];
d.resCols = ["Grandezza|Valore|Unita'|Limite|Esito", "Quantity|Value|Unit|Limit|Outcome"];
d.stale = ["DATI MODIFICATI - LANCIARE LA SIMULAZIONE", "DATA CHANGED - RUN THE SIMULATION"];
d.staleStatus = ["Risultati non aggiornati: premere ""Lancia simulazione"".", "Results out of date: press ""Run simulation""."];
d.invalid = ["DATI NON VALIDI", "INVALID DATA"];
d.badValue = ["Valore non valido: serve un numero tra 0 e %g. Ripristinato il valore precedente.", ...
    "Invalid value: a number between 0 and %g is required. Previous value restored."];
d.badValueTitle = ["Valore non valido", "Invalid value"];
d.edited = ["(modificato)", "(edited)"];
d.manual = ["inserimento manuale", "manual entry"];
d.status = ["Dati: %s | calcolo del %s | verifica statica dimostrativa, non sostituisce il piano di sollevamento", ...
    "Data: %s | computed %s | demonstrative static check, does not replace the lift plan"];
d.missing = ["Parametri non presenti nel file (mantenuto il valore corrente):", ...
    "Parameters not found in the file (current value kept):"];
d.repTitle = ["SimuLift - Report di verifica statica", "SimuLift - Static check report"];
d.repDate = ["Data", "Date"];
d.repSource = ["Origine dati", "Data source"];
d.repVerdict = ["VERDETTO", "VERDICT"];
d.repResults = ["Risultati", "Results"];
d.yes = ["si", "yes"];
d.no = ["no", "no"];
d.disclaimer = ["Strumento dimostrativo: non sostituisce il piano di sollevamento, le tabelle di carico del costruttore e le verifiche previste da D.Lgs. 81/08 ed EN 13001.", ...
    "Demonstrative tool: it does not replace the lift plan, the manufacturer's load charts and the checks required by applicable regulations and EN 13001."];
end
