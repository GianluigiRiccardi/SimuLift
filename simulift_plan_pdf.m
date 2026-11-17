function file = simulift_plan_pdf(file, R, opts)
%SIMULIFT_PLAN_PDF Genera il Piano di Carico in PDF (A4, piu' pagine).
%   file = simulift_plan_pdf(file, R) scrive nel file PDF indicato il piano
%   costruito dal risultato R di simulift_static_check (calcolato con
%   Language="it").
%
%   Opzioni Name=Value:
%     Doc     struct con i dati del documento (testi). Campi non indicati
%             prendono il valore di simulift_plan_pdf("defaults"), che
%             restituisce un esempio con nomi e dati DI FANTASIA.
%     Rigging risultato di simulift_rigging (struct vuota = sezione omessa)
%     Layout  struct della planimetria usata da simulift_draw_layout
%             (struct vuota o senza gru e punto di sollevamento = sezione
%             sostituita da una nota)
%     PreviewFolder cartella in cui salvare anche un'immagine PNG per pagina
%             (default "": nessuna anteprima)
%
%   Doc = simulift_plan_pdf("defaults") restituisce la struct di esempio.
%
%   Sezioni: dati identificativi, personale coinvolto, descrizione del
%   carico, mezzo di sollevamento, analisi dei carichi, classificazione ed
%   esito, layout, piano di imbracatura, analisi dei rischi, piano di
%   contingency, procedura operativa, firme.
%
%   Le valutazioni di probabilita' e gravita' dei rischi e le fasi della
%   procedura sono testi generici di partenza: vanno rivisti e confermati
%   da chi redige e approva il piano. Il documento NON sostituisce le
%   verifiche di legge (D.Lgs. 81/08) ne' le tabelle di carico del
%   costruttore.
%
%   Realizzato con sole funzioni grafiche di base (exportgraphics con
%   Append): non richiede MATLAB Report Generator.

arguments
    file (1,1) string
    R struct = struct()
    opts.Doc (1,1) struct = struct()
    opts.Rigging struct = struct()
    opts.Layout struct = struct()
    opts.PreviewFolder (1,1) string = ""
end

if file == "defaults"
    file = defaultDoc();
    return
end
D = defaultDoc();
for f = string(fieldnames(opts.Doc)).'
    D.(f) = string(opts.Doc.(f));
end
P = R.Parameters;
G = opts.Rigging;
Lay = opts.Layout;
hasRig = ~isempty(G) && ~isempty(fieldnames(G));
hasLay = ~isempty(Lay) && ~isempty(fieldnames(Lay)) && ~isempty(Lay.Crane) && ~isempty(Lay.Lift);

% --- impaginazione: coordinate in cm, origine in alto a sinistra ---
pageW = 21; pageH = 29.7;
left = 1.6; width = pageW - 2*left;
navy = [0.10 0.22 0.42];
light = [0.86 0.90 0.95];
pageNo = 0;
fig = [];
ax = [];
y = 0;
if isfile(file)
    delete(file);
end

newPage();

% ================= pagina 1 =================
text(ax, pageW/2, y + 0.3, D.Title, "FontSize", 20, "FontWeight", "bold", ...
    "HorizontalAlignment", "center", "Color", navy);
text(ax, pageW/2, y + 1.3, D.Subject, "FontSize", 13, "HorizontalAlignment", "center");
y = y + 2.3;

section("DATI IDENTIFICATIVI");
kv("Commessa n.", D.JobNumber);
kv("Sito / cantiere", D.Site);
kv("Committente", D.Client);
kv("Data di redazione", D.Date);
kv("Responsabile del piano", D.Author);
kv("Revisione", D.Revision);
kv("Stato del documento", D.Status);

section("PERSONALE COINVOLTO");
kv("Preposto", D.Supervisor);
kv("Gruista / operatore", D.Operator);
kv("Addetto all'imbracatura", D.Rigger);
kv("Segnalatore a terra", D.Signaller);
kv("Responsabile sicurezza", D.SafetyOfficer);

section("DESCRIZIONE DEL CARICO");
kv("Descrizione", D.LoadDescription);
kv("Tipo di carico", D.LoadType);
kv("Peso da sollevare", kg(P.Theoretical_Weight));
kv("Catene / imbracature", kg(P.Slings_weight));
kv("Bozzello", kg(P.Pulley_weight));
kv(sprintf("Contingency (%g%%)", pct(P)), kg(R.Contingency_kg));
kv("TOTALE SOLLEVAMENTO", kg(R.DesignMass_kg), true);
kv("Eccedenza sollevabile", kg(R.OverloadMargin_kg));
kv("Sotto o vicino al percorso", pick(R.AssetName == "", "nessuna attrezzatura", R.AssetName));
if hasRig
    kv("Punti di imbracatura", sprintf("n. 2, a %.2f m e %.2f m da un'estremità", ...
        G.Geometry.Pick1_m, G.Geometry.Pick2_m));
    kv("Baricentro", sprintf("a %.2f m da un'estremità (vedi piano di imbracatura)", G.Geometry.CoG_x_m));
end

% ================= mezzo e analisi dei carichi =================
flushPage(); newPage();
section("MEZZO DI SOLLEVAMENTO");
kv("Mezzo", D.Crane);
kv("Ultima verifica periodica", D.CraneInspection);
kv("Sbraccio (lunghezza braccio)", sprintf("%g m", P.Boom_reach_m));
kv("Inclinazione del braccio", sprintf("%g°", P.Boom_angle_deg));
kv("Proiezione orizzontale del braccio", sprintf("%.1f m", R.BoomProjection_m));
kv("Portata sollevabile nella configurazione", kg(P.Crane_Capacity));
kv("Velocità del vento ammessa", sprintf("%g m/s (esercizio)", R.WindSpeedLimit_ms));
kv("Vento previsto", sprintf("Beaufort %g, pari a %.1f m/s", P.Beaufort_scale, R.WindSpeed_ms));

section("ANALISI DEI CARICHI - RIEPILOGO");
tableBlock(["Voce" "Valore" "Limite" "Esito"], [
    "Peso da sollevare", kg(P.Theoretical_Weight), "-", "-"
    "Catene / imbracature", kg(P.Slings_weight), "-", "-"
    "Bozzello", kg(P.Pulley_weight), "-", "-"
    sprintf("Contingency %g%%", pct(P)), kg(R.Contingency_kg), "-", "-"
    "TOTALE SOLLEVAMENTO", kg(R.DesignMass_kg), kg(P.Crane_Capacity), okText(R.OverloadAlarm)
    "Eccedenza sollevabile", kg(R.OverloadMargin_kg), "> 0 kg", okText(R.OverloadAlarm)
    "Utilizzo della portata", sprintf("%.0f %%", 100*R.CraneUtilization), "100 %", okText(R.OverloadAlarm)
    "Velocità del vento", sprintf("%.1f m/s", R.WindSpeed_ms), sprintf("%g m/s", R.WindSpeedLimit_ms), okText(R.WindAlarm)
    ], [7.2 3.6 3.6 3.4]);

section("CLASSIFICAZIONE ED ESITO");
kv("Esito della verifica", verdictText(R), true);
kv("Classificazione", R.Class + pick(R.ClassCode == "critical", " - approvazione preventiva richiesta", ""));
for s = accent(R.ClassReasons(:)).'
    bullet(s);
end


% ================= layout =================
flushPage(); newPage();
section("LAYOUT DEL SOLLEVAMENTO");
if hasLay
    info = drawing(11.0, @(a) simulift_draw_layout(a, Lay, R), true);
    kv("Distanza gru - punto di sollevamento", sprintf("%.1f m", info.Distance_m));
    kv("Proiezione del braccio", sprintf("%.1f m", info.Projection_m));
    kv("Coerenza posizione / braccio", pick(info.Consistent, ...
        "coerente (differenza entro 2 m)", "NON coerente: rivedere posizione o configurazione"));
    if ~info.ScaleSet
        bullet("Attenzione: scala della planimetria non tarata, distanze non affidabili.");
    end
else
    paragraph("Planimetria non inserita: allegare il layout con posizione della gru, " + ...
        "raggio di lavoro, percorso del carico e attrezzature sorvolate.");
end
% vista laterale: autogru, braccio in scala, carico e attrezzatura sottostante
ensure(8.8);
drawing(8.4, @(a) simulift_draw_crane(a, R));

% ================= piano di imbracatura =================
if hasRig
    ensure(17);
    section("PIANO DI IMBRACATURA");
    drawing(11.0, @(a) simulift_draw_rigging(a, G));
    kv("Tipo di imbracatura", "n. 2 tiranti su gancio singolo");
    kv("Accessori", D.Accessories);
    kv("Tirante 1", sprintf("lunghezza %.2f m, tiro %.0f kg, %.0f° dalla verticale", ...
        G.Geometry.Leg1_m, G.Tension_kg(1), G.Angle_deg(1)));
    kv("Tirante 2", sprintf("lunghezza %.2f m, tiro %.0f kg, %.0f° dalla verticale", ...
        G.Geometry.Leg2_m, G.Tension_kg(2), G.Angle_deg(2)));
    kv("Inclinazione del carico", sprintf("%.1f° - %s", G.Tilt_deg, ...
        pick(G.Balanced, "carico bilanciato", "carico NON bilanciato: rivedere i punti di presa")));
    kv("Angolo massimo ammesso", "60° tra tirante e verticale");
    bullet("Usare solo i punti di presa indicati e accessori marcati, integri e verificati.");
    bullet("Sollevamento di prova a circa 20 cm da terra per controllare assetto e stabilità.");
    bullet("Nessuna persona sotto il carico sospeso o nel suo raggio di caduta.");
end

% ================= rischi e contingency =================
flushPage(); newPage();
section("ANALISI DEI RISCHI E MISURE PREVENTIVE");
risks = [
    "Caduta del carico", "Bassa", "Alta", "Verifica di imbracature e accessori; area interdetta con transenne e segnaletica; nessuno sotto il carico."
    "Urto contro strutture o linee in esercizio", "Bassa", "Alta", "Funi di guida; segnalatore dedicato; percorso del carico definito nel layout."
    "Investimento di persone", "Bassa", "Alta", sprintf("Zona interdetta di raggio non inferiore a %g m; DPI: elmetto, scarpe di sicurezza, alta visibilità.", ceil(P.Boom_reach_m))
    "Cedimento del terreno sotto gli stabilizzatori", "Bassa", "Alta", "Piastre di ripartizione; verifica della portanza e del livellamento."
    "Vento oltre il limite", "Media", "Media", sprintf("Sospendere oltre %g m/s; controllo dell'anemometro e del bollettino meteo.", R.WindSpeedLimit_ms)
    "Guasto del mezzo o degli accessori", "Bassa", "Alta", "Verifiche periodiche in corso di validità; controllo visivo prima dell'uso."
    ];
if R.AssetName ~= ""
    risks(end+1, :) = ["Danno a " + R.AssetName + " con rilascio o fuori servizio", ...
        "Bassa", "Alta", "Vedi piano di contingency; valvole di intercettazione individuate e presidiate."];
end
tableBlock(["Rischio" "Prob." "Gravità" "Misure preventive / DPI"], risks, [5.0 1.5 1.6 9.7]);
paragraph("Probabilità e gravità sono valutazioni indicative di partenza: vanno confermate da chi redige e approva il piano.", true);

section("PIANO DI CONTINGENCY");
if R.ContingencyRequired
    for s = accent(R.ContingencyActions(:)).'
        bullet(s);
    end
else
    paragraph("Non richiesto per questo sollevamento: nessuna attrezzatura critica sotto o vicino al percorso del carico.");
end

% ================= procedura operativa e firme =================
ensure(13);
section("PROCEDURA OPERATIVA - SEQUENZA DELLE FASI");
steps = [
    "Sopralluogo preliminare", "Condizioni del sito, posizione della gru, pavimentazione, ostacoli e linee in esercizio."
    "Allestimento dell'area", sprintf("Transenne, segnaletica e controllo degli accessi; zona interdetta di raggio non inferiore a %g m.", ceil(P.Boom_reach_m))
    "Posizionamento del mezzo", "Piazzamento su piastre di ripartizione; stabilizzatori estesi e livellati."
    "Verifica delle attrezzature", "Controllo visivo di tiranti, grilli, gancio e dispositivo di sicurezza; documenti di verifica disponibili."
    "Misure di contingency", pick(R.ContingencyRequired, "Attuare il piano di contingency prima di imbracare il carico.", "Non previste.")
    "Imbracatura del carico", "Aggancio ai punti di presa previsti; angolo dei tiranti non oltre 60° dalla verticale."
    "Sollevamento di prova", "Sollevare di circa 20 cm e attendere: controllo di assetto, stabilità e assenza di oscillazioni."
    "Sollevamento e traslazione", sprintf("Manovra lenta con segnalatore e funi di guida; sospendere con vento oltre %g m/s.", R.WindSpeedLimit_ms)
    "Posa e disimbracatura", "Appoggio controllato, verifica della stabilità, rimozione di tiranti e accessori."
    "Chiusura dell'operazione", "Ripristino dell'area e rimozione delle misure di contingency; registrazione dell'esito."
    ];
steps = [string((1:size(steps, 1)).'), steps];
tableBlock(["N." "Fase" "Descrizione"], steps, [1.0 5.0 11.8]);

ensure(5);
section("FIRME");
tableBlock(["Ruolo" "Nome" "Firma e data"], [
    "Responsabile del piano", D.Author, " "
    "Preposto", D.Supervisor, " "
    "Responsabile sicurezza", D.SafetyOfficer, " "
    "Approvazione (se sollevamento critico)", " ", " "
    ], [6.2 5.6 6.0], 0.9);

flushPage();

% =====================================================================
%  funzioni di impaginazione (annidate: condividono fig, ax, y)
% =====================================================================
    function newPage()
        pageNo = pageNo + 1;
        fig = figure("Visible", "off", "Color", "w", "Units", "centimeters", ...
            "Position", [1 1 pageW pageH], "PaperUnits", "centimeters", ...
            "PaperSize", [pageW pageH], "PaperPosition", [0 0 pageW pageH]);
        ax = axes(fig, "Units", "normalized", "Position", [0 0 1 1], "XLim", [0 pageW], ...
            "YLim", [0 pageH], "YDir", "reverse", "Visible", "off", ...
            "DefaultTextInterpreter", "none");   % i testi dell'utente non sono TeX
        hold(ax, "on");
        % cornice bianca a pagina intera: l'esportazione conserva il formato A4
        patch(ax, [0 pageW pageW 0], [0 0 pageH pageH], "w", "EdgeColor", "none");
        text(ax, left, 1.0, D.Company, "FontWeight", "bold", "FontSize", 10, "Color", navy);
        text(ax, pageW - left, 1.0, D.Title, "FontWeight", "bold", "FontSize", 10, ...
            "HorizontalAlignment", "right", "Color", navy);
        text(ax, pageW - left, 1.5, D.Subject, "FontSize", 8, "HorizontalAlignment", "right");
        plot(ax, [left pageW - left], [1.8 1.8], "Color", navy, "LineWidth", 1.2);
        plot(ax, [left pageW - left], [pageH - 1.5 pageH - 1.5], "Color", navy, "LineWidth", 0.8);
        text(ax, left, pageH - 1.1, sprintf("%s  -  Rev. %s  -  %s  -  %s", D.Company, ...
            D.Revision, D.Date, D.JobNumber), "FontSize", 7.5);
        text(ax, pageW - left, pageH - 1.1, sprintf("Pag. %d", pageNo), "FontSize", 7.5, ...
            "HorizontalAlignment", "right");
        y = 2.6;
    end

    function flushPage()
        if pageNo == 1
            exportgraphics(fig, file, "ContentType", "vector");
        else
            exportgraphics(fig, file, "ContentType", "vector", "Append", true);
        end
        if opts.PreviewFolder ~= ""
            % anteprima PNG di ogni pagina, per il controllo dell'impaginazione
            exportgraphics(fig, fullfile(opts.PreviewFolder, sprintf("pagina_%d.png", pageNo)), ...
                "Resolution", 80);
        end
        close(fig);
    end

    function ensure(height_cm)
        % va a pagina nuova se non resta lo spazio indicato
        if y + height_cm > pageH - 2.0
            flushPage();
            newPage();
        end
    end

    function section(name)
        ensure(2.5);
        y = y + 0.35;
        patch(ax, left + [0 width width 0], y + [0 0 0.72 0.72], navy, "EdgeColor", "none");
        text(ax, left + 0.3, y + 0.36, name, "Color", "w", "FontWeight", "bold", "FontSize", 10.5);
        y = y + 0.85;
    end

    function kv(label, value, strong)
        if nargin < 3
            strong = false;
        end
        lines = wrapText(string(value), 54);
        h = 0.18 + 0.42*numel(lines);            % altezza della riga [cm]
        ensure(h);
        if strong
            patch(ax, left + [0 width width 0], y + [0 0 h h], light, "EdgeColor", "none");
        end
        text(ax, left + 0.2, y + 0.08, string(label) + ":", "FontWeight", "bold", ...
            "FontSize", 9, "Color", navy, "VerticalAlignment", "top");
        text(ax, left + 6.6, y + 0.08, join(lines, newline), "FontSize", 9, ...
            "VerticalAlignment", "top", "FontWeight", pick(strong, "bold", "normal"));
        y = y + h;
        plot(ax, left + [0 width], [y y], "Color", [0.85 0.85 0.85], "LineWidth", 0.4);
    end

    function bullet(str)
        lines = wrapText(string(str), 98);
        h = 0.42*numel(lines) + 0.14;
        ensure(h);
        text(ax, left + 0.3, y + 0.06, "•", "FontSize", 9, "VerticalAlignment", "top");
        text(ax, left + 0.7, y + 0.06, join(lines, newline), "FontSize", 9, "VerticalAlignment", "top");
        y = y + h;
    end

    function paragraph(str, small)
        if nargin < 2
            small = false;
        end
        fs = pick(small, 8, 9);
        lines = wrapText(string(str), pick(small, 115, 100));
        ensure(0.44*numel(lines) + 0.2);
        text(ax, left + 0.2, y - 0.2, join(lines, newline), "FontSize", fs, ...
            "VerticalAlignment", "top", "FontAngle", pick(small, "italic", "normal"));
        y = y + 0.44*numel(lines) + 0.3;
    end

    function tableBlock(headers, rows, widths_cm, minRow_cm)
        if nargin < 4
            minRow_cm = 0;
        end
        charsPerCm = 6.0;                         % stima per carattere 8.5 pt
        lineH = 0.46;                             % interlinea delle celle [cm]
        x0 = left + [0 cumsum(widths_cm)];
        ensure(1.9);
        y = y + 0.40;                             % stacco dalla fascia del titolo di sezione
        patch(ax, [x0(1) x0(end) x0(end) x0(1)], y - 0.3 + [0 0 0.6 0.6], navy, "EdgeColor", "none");
        for c = 1:numel(headers)
            text(ax, x0(c) + 0.15, y, headers(c), "Color", "w", "FontWeight", "bold", "FontSize", 8.5);
        end
        y = y + 0.6;
        for r = 1:size(rows, 1)
            cellLines = cell(1, numel(headers));
            nLines = 1;
            for c = 1:numel(headers)
                cellLines{c} = wrapText(rows(r, c), floor(widths_cm(c)*charsPerCm));
                nLines = max(nLines, numel(cellLines{c}));
            end
            h = max(lineH*nLines + 0.30, minRow_cm);
            if y + h > pageH - 2.0
                flushPage();
                newPage();
                y = y + 0.3;
            end
            if mod(r, 2) == 0
                patch(ax, [x0(1) x0(end) x0(end) x0(1)], y - 0.3 + [0 0 h h], ...
                    [0.95 0.96 0.98], "EdgeColor", "none");
            end
            for c = 1:numel(headers)
                text(ax, x0(c) + 0.15, y - 0.22, join(cellLines{c}, newline), "FontSize", 8.5, ...
                    "VerticalAlignment", "top");
            end
            y = y + h;
            plot(ax, [x0(1) x0(end)], [y - 0.3, y - 0.3], "Color", [0.75 0.75 0.75], "LineWidth", 0.4);
        end
        y = y + 0.35;
    end

    function out = drawing(height_cm, drawFcn, wantOutput)
        % assi figli alla quota corrente; il disegno e' fatto dalle
        % stesse funzioni dell'app. wantOutput = true se drawFcn restituisce un valore.
        if nargin < 3
            wantOutput = false;
        end
        child = axes(fig, "Units", "normalized", "Position", ...
            [(left + 0.6)/pageW, 1 - (y + height_cm)/pageH, (width - 1.2)/pageW, (height_cm - 1.4)/pageH]);
        out = [];
        if wantOutput
            out = drawFcn(child);
        else
            drawFcn(child);
        end
        y = y + height_cm + 0.3;
    end
end

% =====================================================================
%  funzioni locali
% =====================================================================

function D = defaultDoc()
% Esempio con nomi, impresa, sito e mezzo DI FANTASIA.
D.Title = "PIANO DI CARICO";
D.Subject = "Montaggio tubazione su pipe rack sopra linee in esercizio";
D.Company = "Impresa Esempio S.r.l.";
D.JobNumber = "PC-2026-001";
D.Site = "Stabilimento Esempio - Area 1";
D.Client = "Committente Esempio S.p.A.";
D.Date = string(datetime("today", "Format", "dd/MM/yyyy"));
D.Author = "Mario Rossi";
D.Revision = "00";
D.Status = "BOZZA - DA VERIFICARE";
D.Supervisor = "Luigi Bianchi";
D.Operator = "Giuseppe Verdi";
D.Rigger = "Paolo Neri";
D.Signaller = "Franco Gialli";
D.SafetyOfficer = "Ing. Carla Russo";
D.LoadDescription = "Tratto di tubazione in acciaio da montare su pipe rack";
D.LoadType = "Tubazione prefabbricata, lunghezza 6 m";
D.Crane = "Autogru gommata (marca e modello da indicare)";
D.CraneInspection = "da indicare";
D.Accessories = "2 tiranti di portata idonea, grilli (da indicare)";
end

function s = kg(v)
% massa con separatore delle migliaia all'italiana
digits = char(sprintf("%.0f", abs(v)));
out = '';
for k = 1:numel(digits)
    out(end+1) = digits(k); %#ok<AGROW>
    remaining = numel(digits) - k;
    if remaining > 0 && mod(remaining, 3) == 0
        out(end+1) = '.'; %#ok<AGROW>
    end
end
if v < 0
    out = ['-' out];
end
s = string(out) + " kg";
end

function p = pct(P)
if isfield(P, "Contingency_pct")
    p = P.Contingency_pct;
else
    p = 100 * (P.Safety_factor - 1);
end
end

function s = okText(alarm)
s = pick(alarm, "NON VERIFICATO", "verificato");
end

function s = verdictText(R)
if R.GlobalAlarm
    s = "SOLLEVAMENTO NON AUTORIZZATO (" + R.Verdict + ")";
elseif R.ContingencyRequired
    s = "SOLLEVAMENTO CON PIANO DI CONTINGENCY (" + R.Verdict + ")";
else
    s = "SOLLEVAMENTO AUTORIZZABILE (" + R.Verdict + ")";
end
end

function s = accent(s)
% i testi di calcolo usano l'apostrofo al posto dell'accento: qui si
% ripristinano le lettere accentate per il documento
s = regexprep(s, "a'(?=[\s\.,;:\)]|$)", "à");
s = regexprep(s, "(?<=\s)e'(?=[\s\.,;:\)]|$)", "è");
s = regexprep(s, "e'(?=[\s\.,;:\)]|$)", "é");
s = regexprep(s, "i'(?=[\s\.,;:\)]|$)", "ì");
s = regexprep(s, "o'(?=[\s\.,;:\)]|$)", "ò");
s = regexprep(s, "u'(?=[\s\.,;:\)]|$)", "ù");
end

function lines = wrapText(str, maxChars)
% a capo sulle parole, entro maxChars caratteri per riga
words = split(strip(str)).';
lines = strings(0, 1);
current = "";
for w = words
    if current == ""
        current = w;
    elseif strlength(current) + 1 + strlength(w) <= maxChars
        current = current + " " + w;
    else
        lines(end+1, 1) = current; %#ok<AGROW>
        current = w;
    end
end
lines(end+1, 1) = current;
end

function v = pick(cond, a, b)
if cond
    v = a;
else
    v = b;
end
end
