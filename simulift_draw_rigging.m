function simulift_draw_rigging(ax, G, opts)
%SIMULIFT_DRAW_RIGGING Disegna il piano di imbracatura calcolato da simulift_rigging.
%   simulift_draw_rigging(ax, G) disegna in scala, negli assi ax, il carico
%   visto di fianco nell'assetto che assume una volta sollevato: gancio,
%   due tiranti, punti di presa, baricentro e verticale del gancio.
%
%   Le scritte stanno fuori dalla figura, in zone riservate, per non
%   sovrapporsi: i dati dei due tiranti negli angoli in alto, le posizioni
%   di punti di presa e baricentro in una fascia sotto il carico (con una
%   linea di richiamo), peso e inclinazione nel sottotitolo.
%
%   Opzioni Name=Value:
%     Language  "it" (default) o "en"
%     Title     titolo del disegno (default: "Piano di imbracatura")

arguments
    ax
    G (1,1) struct
    opts.Language (1,1) string {mustBeMember(opts.Language, ["it" "en"])} = "it"
    opts.Title (1,1) string = ""
end

en = opts.Language == "en";
W = G.World;
geo = G.Geometry;
red = [0.85 0.10 0.10];
green = [0.10 0.60 0.10];
slingColor = [0.85 0.35 0.05];
grey = [0.45 0.45 0.45];

% --- limiti: figura al centro, margini riservati alle scritte ---
allX = [W.Body(:, 1); W.Hook(1)];
allY = [W.Body(:, 2); W.Hook(2) + 0.7];
span = max(max(allX) - min(allX), max(allY) - min(allY));
xLim = [min(allX) - 0.42*span, max(allX) + 0.42*span];
yLim = [min(allY) - 0.34*span, max(allY) + 0.06*span];
yLabels = min(allY) - 0.10*span;           % quota della fascia di etichette sotto il carico

cla(ax);
hold(ax, "on");
axis(ax, "equal");
ax.XLim = xLim;
ax.YLim = yLim;
ax.XTick = [];
ax.YTick = [];
box(ax, "on");

% --- carico, nell'assetto che assume appeso ---
if G.TiltAlarm
    face = [0.95 0.70 0.68];
    edge = red;
else
    face = [0.70 0.88 0.72];
    edge = green;
end
patch(ax, W.Body(:, 1), W.Body(:, 2), face, "EdgeColor", edge, "LineWidth", 2);

% --- verticale del gancio: il baricentro si porta sempre qui sotto ---
plot(ax, [W.Hook(1) W.Hook(1)], [W.Hook(2) yLabels], "--", "Color", grey);

% --- tiranti e punti di presa ---
picks = [W.Pick1; W.Pick2];
legLen = [geo.Leg1_m geo.Leg2_m];
pickPos = [geo.Pick1_m geo.Pick2_m];
sep = 0.34 * span;                         % distanza minima tra le etichette in basso
xLab = [min(picks(1, 1), W.CoG(1) - sep), max(picks(2, 1), W.CoG(1) + sep)];
for i = 1:2
    col = slingColor;
    if G.Angle_deg(i) > 60 || (G.WllChecked && G.WllAlarm)
        col = red;
    end
    plot(ax, [W.Hook(1) picks(i, 1)], [W.Hook(2) picks(i, 2)], "Color", col, "LineWidth", 2.5);
    % dati del tirante nell'angolo in alto dal suo lato
    if i == 1
        xText = xLim(1) + 0.02*span;
        align = "left";
    else
        xText = xLim(2) - 0.02*span;
        align = "right";
    end
    text(ax, xText, yLim(2) - 0.03*span, sprintf(pick(en, ...
        "SLING %d\n%.2f m  -  %.0f kg\n%.0f\\circ from vertical", ...
        "TIRANTE %d\n%.2f m  -  %.0f kg\n%.0f\\circ dalla verticale"), ...
        i, legLen(i), G.Tension_kg(i), G.Angle_deg(i)), ...
        "HorizontalAlignment", align, "VerticalAlignment", "top", ...
        "Color", col, "FontWeight", "bold", "FontSize", 10);
    % punto di presa: marcatore, linea di richiamo ed etichetta sotto il carico
    plot(ax, [picks(i, 1) xLab(i)], [picks(i, 2) yLabels], ":", "Color", grey);
    plot(ax, picks(i, 1), picks(i, 2), "s", "MarkerSize", 10, ...
        "MarkerFaceColor", [0.2 0.2 0.22], "MarkerEdgeColor", "k");
    text(ax, xLab(i), yLabels - 0.01*span, sprintf(pick(en, ...
        "pick %d\n%.2f m", "presa %d\n%.2f m"), i, pickPos(i)), ...
        "HorizontalAlignment", "center", "VerticalAlignment", "top", "FontSize", 9);
end

% --- baricentro ---
plot(ax, W.CoG(1), W.CoG(2), "o", "MarkerSize", 11, "MarkerFaceColor", "k", ...
    "MarkerEdgeColor", "w", "LineWidth", 1.5);
text(ax, W.CoG(1), yLabels - 0.01*span, sprintf(pick(en, ...
    "CoG\n%.2f m", "baricentro\n%.2f m"), geo.CoG_x_m), ...
    "HorizontalAlignment", "center", "VerticalAlignment", "top", ...
    "FontSize", 9, "FontWeight", "bold");

% --- gancio ---
plot(ax, [W.Hook(1) W.Hook(1)], [W.Hook(2) W.Hook(2) + 0.7], "Color", [0.3 0.3 0.3], "LineWidth", 2.5);
plot(ax, W.Hook(1), W.Hook(2), "o", "MarkerSize", 14, "MarkerFaceColor", [0.80 0.15 0.10], ...
    "MarkerEdgeColor", "k");
text(ax, W.Hook(1), W.Hook(2) + 0.75, pick(en, "crane hook", "gancio della gru"), ...
    "HorizontalAlignment", "center", "VerticalAlignment", "bottom", "FontSize", 9);

ttl = opts.Title;
if ttl == ""
    ttl = pick(en, "Rigging plan", "Piano di imbracatura");
end
title(ax, ttl + " - " + G.Verdict, "Color", edge);
subtitle(ax, sprintf(pick(en, "load %g kg  -  tilt %.1f\\circ", ...
    "carico %g kg  -  inclinazione %.1f\\circ"), G.Mass_kg, G.Tilt_deg), "FontSize", 10);
hold(ax, "off");
end

function v = pick(cond, a, b)
if cond
    v = a;
else
    v = b;
end
end
