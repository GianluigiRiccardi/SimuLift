function simulift_draw_crane(ax, R, opts)
%SIMULIFT_DRAW_CRANE Schema della gru e del carico per un risultato SimuLift.
%   simulift_draw_crane(ax, R) disegna negli assi ax (axes o uiaxes) una
%   autogru gommata schematica (stabilizzatori, braccio telescopico) con
%   bozzello, imbracatura, carico e vento, usando il risultato R di
%   simulift_static_check. Sul disegno non ci sono dati numerici (sono
%   nelle tabelle): solo il peso dentro il carico e, nel sottotitolo,
%   l'eventuale nota su attrezzatura sottostante o carico a terra. I limiti
%   degli assi sono stretti attorno alla scena, per sfruttare lo spazio.
%
%   Il disegno e' statico. Il braccio e' in scala (lunghezza
%   P.Boom_reach_m, inclinazione P.Boom_angle_deg sull'orizzontale); il
%   corpo della gru e il carico sono schematici. Riflette inoltre i dati per:
%   - carico sollevato se il verdetto e' favorevole, a terra se negato;
%   - numero di rami (fino a 4) e angolo dell'imbracatura (bilancino
%     sotto i 12 gradi dalla verticale);
%   - lunghezza delle frecce del vento proporzionale alla velocita';
%   - colori di carico e vento secondo gli allarmi;
%   - attrezzatura sotto il carico (sezione della linea), evidenziata in
%     ambra se e' richiesto il piano di contingency.
%
%   Opzione Language = "it" (default) o "en".

arguments
    ax
    R (1,1) struct
    opts.Language (1,1) string {mustBeMember(opts.Language, ["it" "en"])} = "it"
end

en = opts.Language == "en";
P = R.Parameters;
red = [0.85 0.10 0.10];
green = [0.10 0.60 0.10];
yellow = [0.96 0.76 0.10];
dark = [0.20 0.20 0.22];

% --- Geometria del braccio dai dati: lunghezza [m] e inclinazione [deg] ---
base = [1.5 2.75];                 % perno del braccio, sul retro della torretta [m]
boomLen_m = 15;
boomAngle_deg = 60;
if isfield(P, "Boom_reach_m") && P.Boom_reach_m > 0
    boomLen_m = P.Boom_reach_m;
end
if isfield(P, "Boom_angle_deg")
    boomAngle_deg = P.Boom_angle_deg;
end
tip = base + boomLen_m * [cosd(boomAngle_deg) sind(boomAngle_deg)];
% limiti stretti attorno a gru, carico e frecce del vento: il disegno
% occupa tutto lo spazio disponibile
windLen = 0.4 + 3.0 * R.WindSpeed_ms / 36.9;
xMin = -0.4;
yMin = -0.5;
xMax = max(tip(1) + 2.2 + windLen, 7.5);
yMax = max(tip(2) + 0.7, 4.5);

cla(ax);
hold(ax, "on");
axis(ax, "equal");
ax.XLim = [xMin xMax];
ax.YLim = [yMin yMax];
ax.XTick = [];
ax.YTick = [];
ax.XColor = "none";
ax.YColor = "none";
ax.Color = [0.93 0.96 1.00];

% --- Terreno ---
patch(ax, [xMin xMax xMax xMin], [0 0 yMin yMin], [0.72 0.68 0.60], "EdgeColor", "none");
plot(ax, [xMin xMax], [0 0], "Color", dark, "LineWidth", 1.5);

% --- Autogru gommata: stabilizzatori, telaio, ruote ---
steel = [0.45 0.45 0.48];
for xo = [0.35 5.65]
    % trave dello stabilizzatore, stelo e piastra di appoggio
    plot(ax, [xo xo], [1.25 0.12], "Color", steel, "LineWidth", 5);
    rectangle(ax, "Position", [xo-0.45 0 0.9 0.14], "FaceColor", dark, "EdgeColor", "k");
end
rectangle(ax, "Position", [0.2 1.0 5.6 0.6], "Curvature", 0.2, ...
    "FaceColor", yellow, "EdgeColor", "k");                 % telaio
for xw = [1.55 4.45]
    rectangle(ax, "Position", [xw-0.68 0.2 1.36 1.36], "Curvature", [1 1], ...
        "FaceColor", dark, "EdgeColor", "k");               % pneumatico
    rectangle(ax, "Position", [xw-0.32 0.56 0.64 0.64], "Curvature", [1 1], ...
        "FaceColor", [0.75 0.75 0.78], "EdgeColor", "k");   % cerchio
end

% --- Torretta, contrappeso, cabina ---
rectangle(ax, "Position", [1.0 1.6 2.9 1.0], "Curvature", 0.12, ...
    "FaceColor", yellow, "EdgeColor", "k");
rectangle(ax, "Position", [0.45 1.6 0.75 1.15], "Curvature", 0.15, ...
    "FaceColor", steel, "EdgeColor", "k");                  % contrappeso
rectangle(ax, "Position", [3.7 1.6 1.25 1.35], "Curvature", 0.2, ...
    "FaceColor", yellow, "EdgeColor", "k");                 % cabina
rectangle(ax, "Position", [4.0 2.1 0.8 0.7], "Curvature", 0.25, ...
    "FaceColor", [0.65 0.85 0.95], "EdgeColor", "k");       % vetro

% --- Braccio telescopico: tre sfili a sezione decrescente ---
u = (tip - base) / norm(tip - base);
n = [-u(2) u(1)];
breaks = [0 0.42 0.72 1];                                   % frazioni di lunghezza degli sfili
halfW = [0.36 0.28 0.20];
shade = [1.00 0.93 0.86];
% cilindro di sollevamento, dalla torretta al primo sfilo
cylFoot = [3.3 2.35];
cylHead = base + 0.30*boomLen_m*u - halfW(1)*n;
plot(ax, [cylFoot(1) cylHead(1)], [cylFoot(2) cylHead(2)], "Color", steel, "LineWidth", 6);
cylMid = (cylFoot + cylHead) / 2;
plot(ax, [cylMid(1) cylHead(1)], [cylMid(2) cylHead(2)], "Color", [0.80 0.80 0.83], "LineWidth", 3);
for k = 3:-1:1
    p0 = base + breaks(k)*boomLen_m*u;
    p1 = base + breaks(k+1)*boomLen_m*u;
    if k > 1
        p0 = p0 - 0.03*boomLen_m*u;                         % sovrapposizione dentro lo sfilo precedente
    end
    corners = [p0 + halfW(k)*n; p1 + halfW(k)*n; p1 - halfW(k)*n; p0 - halfW(k)*n];
    patch(ax, corners(:, 1), corners(:, 2), yellow * shade(k), ...
        "EdgeColor", [0.45 0.33 0.02], "LineWidth", 1.2);
end
rectangle(ax, "Position", [base(1)-0.22 base(2)-0.22 0.44 0.44], "Curvature", [1 1], ...
    "FaceColor", dark, "EdgeColor", "k");                   % perno del braccio
rectangle(ax, "Position", [tip(1)-0.25 tip(2)-0.25 0.5 0.5], "Curvature", [1 1], ...
    "FaceColor", dark, "EdgeColor", "k");                   % puleggia di testa

% --- Carico, imbracatura, bozzello ---
lifted = ~R.GlobalAlarm;
wLoad = 1.8 + min(1.6, P.Theoretical_Weight / 5000);
hLoad = 1.3;
yLift = max(2.1, min(4.2, tip(2) - 6));   % quota del carico sollevato, sotto la punta del braccio
yLoad = yLift * lifted;
xc = tip(1);
yTop = yLoad + hLoad;
hasAsset = isfield(R, "Asset") && ~ismember(R.Asset, ["" "none"]);
hooked = lifted || ~hasAsset;      % con una linea sotto il gancio, il carico negato resta a lato
xl = xc - 3.3 * ~hooked;           % ascissa del baricentro del carico

notes = strings(1, 0);             % note riportate nel sottotitolo, non sul disegno

% --- Attrezzatura sotto il percorso del carico (sezione della linea) ---
if hasAsset
    amber = [0.95 0.60 0.10];
    switch R.Asset
        case "firewater", pipeColor = [0.85 0.15 0.10];
        case "other",     pipeColor = [0.55 0.55 0.58];
        case "toxic",     pipeColor = [0.60 0.35 0.75];
        otherwise,        pipeColor = [0.90 0.75 0.20];
    end
    if R.Asset == "building"
        % edificio occupato: sagoma con finestre
        rectangle(ax, "Position", [xc-1.0 0 2.0 1.4], "FaceColor", [0.80 0.78 0.74], "EdgeColor", "k");
        for xwin = xc + [-0.7 -0.15 0.4]
            rectangle(ax, "Position", [xwin 0.6 0.35 0.45], "FaceColor", [0.65 0.85 0.95], "EdgeColor", "k");
        end
    elseif R.Asset == "electrical"
        % linea elettrica: palo con traversa e conduttori in sezione
        plot(ax, [xc xc], [0 1.5], "Color", dark, "LineWidth", 3);
        plot(ax, [xc-0.7 xc+0.7], [1.35 1.35], "Color", dark, "LineWidth", 3);
        plot(ax, xc + [-0.6 0 0.6], [1.5 1.6 1.5], "o", "MarkerFaceColor", [0.95 0.80 0.10], ...
            "MarkerEdgeColor", "k", "MarkerSize", 6);
    else
        % linea o attrezzatura: tubazione in sezione su appoggio
        rectangle(ax, "Position", [xc-0.45 0 0.9 0.35], "FaceColor", [0.5 0.5 0.5], "EdgeColor", "k");
        rectangle(ax, "Position", [xc-0.4 0.35 0.8 0.8], "Curvature", [1 1], ...
            "FaceColor", pipeColor, "EdgeColor", "k", "LineWidth", 1.5);
    end
    if R.ContingencyRequired
        rectangle(ax, "Position", [xc-1.3 0 2.6 1.9], "EdgeColor", amber, ...
            "LineStyle", "--", "LineWidth", 2);
        assetLabel = R.AssetName + pick(en, " (contingency plan)", " (piano di contingency)");
    else
        assetLabel = R.AssetName;
    end
    notes(end+1) = pick(en, "under the load: ", "sotto il carico: ") + assetLabel;
end
beta = P.Sling_angle_deg;
showBeta = beta > 0;               % angolo dichiarato: lo si disegna e lo si etichetta
if ~showBeta
    beta = 35;                     % dati di imbracatura assenti: tiranti generici, senza etichetta
end
nLegs = min(max(round(P.Sling_legs), 1), 4);
if nLegs == 1
    xAtt = xc;
else
    xAtt = xc + linspace(-wLoad/2, wLoad/2, nLegs) * 0.9;
end
if ~hooked
    yHook = max(2.5, min(7.5, tip(2) - 2));   % gancio libero: carico non agganciato
elseif beta < 12 && nLegs > 1
    % rami quasi verticali: bilancino
    yHook = yTop + 1.6;
    plot(ax, [xAtt(1) xAtt(end)], [yHook-0.5 yHook-0.5], "Color", dark, "LineWidth", 4);
    plot(ax, [xc xc], [yHook yHook-0.5], "Color", dark, "LineWidth", 2);
    for x = xAtt
        plot(ax, [x x], [yHook-0.5 yTop], "Color", [0.85 0.35 0.05], "LineWidth", 1.8);
    end
else
    hs = min(max((0.45*wLoad) / tand(max(beta, 12)), 0.7), 3.4);
    yHook = yTop + hs;
    for x = xAtt
        plot(ax, [xc x], [yHook yTop], "Color", [0.85 0.35 0.05], "LineWidth", 1.8);
    end
end
if nLegs > 1 && hooked && showBeta
    text(ax, xAtt(end) + 0.25, yTop + 0.7, sprintf("\\beta = %g\\circ", beta), "FontSize", 9);
end
rectangle(ax, "Position", [xc-0.3 yHook 0.6 0.7], "Curvature", 0.3, ...
    "FaceColor", [0.80 0.15 0.10], "EdgeColor", "k");
plot(ax, [xc-0.1 xc-0.1], [yHook+0.7 tip(2)], "Color", [0.3 0.3 0.3], "LineWidth", 1);
plot(ax, [xc+0.1 xc+0.1], [yHook+0.7 tip(2)], "Color", [0.3 0.3 0.3], "LineWidth", 1);

loadAlarm = R.OverloadAlarm || R.SlingAlarm || (R.ImpactInVerdict && R.ImpactAlarm);
if loadAlarm
    loadColor = [0.95 0.70 0.68];
    edgeColor = red;
elseif isfield(R, "ContingencyRequired") && R.ContingencyRequired
    loadColor = [0.99 0.88 0.65];
    edgeColor = [0.95 0.60 0.10];
else
    loadColor = [0.70 0.88 0.72];
    edgeColor = green;
end
rectangle(ax, "Position", [xl-wLoad/2 yLoad wLoad hLoad], "Curvature", 0.08, ...
    "FaceColor", loadColor, "EdgeColor", edgeColor, "LineWidth", 2);
text(ax, xl, yLoad + hLoad/2, sprintf("%g kg", P.Theoretical_Weight), ...
    "HorizontalAlignment", "center", "FontWeight", "bold", "FontSize", 10);
if ~lifted
    notes(end+1) = pick(en, "load on the ground: lift not authorised", ...
        "carico a terra: sollevamento non autorizzato");
end

% --- Vento ---
windColor = pick(R.WindAlarm, red, [0.15 0.45 0.85]);
len = windLen;
yw = yLoad + hLoad/2 + [-0.8 0 0.8] + 1.2;
quiver(ax, (xMax - 0.3)*ones(1, 3), yw, -len*ones(1, 3), zeros(1, 3), "off", ...
    "Color", windColor, "LineWidth", 1.8, "MaxHeadSize", 0.6);

% --- Titolo: nessun dato numerico sul disegno (sono gia' nelle tabelle).
% Resta solo l'eventuale nota operativa (carico a terra / attrezzatura).
title(ax, pick(en, "Lift layout", "Schema del sollevamento"));
if isempty(notes)
    subtitle(ax, "");
else
    subtitle(ax, notes(:), "FontSize", 9);          % una nota per riga: non viene tagliata
end
hold(ax, "off");
end

function v = pick(cond, a, b)
if cond
    v = a;
else
    v = b;
end
end
