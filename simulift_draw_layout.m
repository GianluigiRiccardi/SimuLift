function [info, hImage] = simulift_draw_layout(ax, Lay, R, opts)
%SIMULIFT_DRAW_LAYOUT Sovrappone gru, raggio e carico a una planimetria.
%   [info, hImage] = simulift_draw_layout(ax, Lay, R) disegna negli assi ax
%   la planimetria Lay.Img (matrice immagine; vuota = griglia bianca) e vi
%   sovrappone, in coordinate pixel dell'immagine:
%     - il segmento di scala (Lay.ScalePts, 2x2);
%     - l'autogru vista dall'alto in Lay.Crane (telaio, ruote,
%       stabilizzatori, contrappeso e braccio rivolto al punto di
%       sollevamento; ingombri indicativi), con il cerchio della proiezione
%       orizzontale del braccio (R.BoomProjection_m, da sbraccio e
%       inclinazione);
%     - il punto di sollevamento in Lay.Lift, con peso del carico e
%       attrezzatura sorvolata (R.AssetName);
%     - la distanza gru - punto di sollevamento.
%   Lay.PxPerM e' la scala [pixel/m]; Lay.ScaleSet indica se e' stata
%   tarata su due punti a distanza nota.
%
%   info.Distance_m e' la distanza misurata, info.Projection_m la proiezione
%   del braccio, info.Difference_m la loro differenza, info.Consistent e'
%   true se |differenza| <= Tolerance_m (default 2 m: la proiezione parte
%   dalla cerniera del braccio, la distanza dal centro della gru;
%   tolleranza di progetto, assunzione).
%
%   hImage e' l'handle dell'immagine (per intercettare i clic); gli altri
%   oggetti non sono selezionabili.

arguments
    ax
    Lay (1,1) struct
    R (1,1) struct
    opts.Language (1,1) string {mustBeMember(opts.Language, ["it" "en"])} = "it"
    opts.Tolerance_m (1,1) double {mustBeNonnegative} = 2
end

en = opts.Language == "en";
img = Lay.Img;
if isempty(img)
    img = ones(600, 900, 3);               % nessuna planimetria: foglio bianco
end
ppm = Lay.PxPerM;
blue = [0.10 0.35 0.85];
red = [0.85 0.10 0.10];
green = [0.05 0.55 0.10];
amber = [0.90 0.50 0.00];

cla(ax);
hImage = image(ax, img);
hold(ax, "on");
axis(ax, "image");
ax.XTick = [];
ax.YTick = [];
box(ax, "on");

info = struct("Distance_m", NaN, "Projection_m", R.BoomProjection_m, ...
    "Difference_m", NaN, "Consistent", false, "ScaleSet", Lay.ScaleSet);
overlay = gobjects(0);

% barra di riferimento da 10 m
[nRows, ~, ~] = size(img);
x0 = 0.04 * size(img, 2);
y0 = 0.96 * nRows;
overlay(end+1) = plot(ax, [x0 x0 + 10*ppm], [y0 y0], "k", "LineWidth", 4);
overlay(end+1) = text(ax, x0, y0 - 0.025*nRows, "10 m" + ...
    pick(Lay.ScaleSet, "", pick(en, " (scale not set)", " (scala non tarata)")), ...
    "FontWeight", "bold", "BackgroundColor", "w", "Margin", 1);

% segmento di taratura
if size(Lay.ScalePts, 1) >= 1
    overlay(end+1) = plot(ax, Lay.ScalePts(:, 1), Lay.ScalePts(:, 2), "-+", ...
        "Color", [0.5 0 0.6], "LineWidth", 1.5, "MarkerSize", 10);
end

% gru e cerchio della proiezione del braccio
if ~isempty(Lay.Crane)
    c = Lay.Crane;
    rPx = R.BoomProjection_m * ppm;
    th = linspace(0, 2*pi, 181);
    overlay(end+1) = plot(ax, c(1) + rPx*cos(th), c(2) + rPx*sin(th), "--", ...
        "Color", blue, "LineWidth", 1.5);
    % --- autogru vista dall'alto (ingombri indicativi, in metri) ---
    side = 3.1 * ppm;                      % semi-base degli stabilizzatori: 6.2 m
    yellow = [0.96 0.76 0.10];
    steel = [0.35 0.35 0.38];
    for sx = [-1 1]
        for sy = [-1 1]
            % trave dello stabilizzatore e piastra di appoggio
            overlay(end+1) = plot(ax, c(1) + sx*[2.2 3.1]*ppm, c(2) + sy*[1.1 3.1]*ppm, ...
                "Color", steel, "LineWidth", 4); %#ok<AGROW>
            overlay(end+1) = rectangle(ax, "Position", ...
                [c(1)+sx*3.1*ppm-0.45*ppm, c(2)+sy*3.1*ppm-0.45*ppm, 0.9*ppm, 0.9*ppm], ...
                "FaceColor", steel, "EdgeColor", "k"); %#ok<AGROW>
        end
    end
    overlay(end+1) = rectangle(ax, "Position", [c(1)-3.0*ppm c(2)-1.25*ppm 6.0*ppm 2.5*ppm], ...
        "Curvature", 0.15, "FaceColor", yellow, "EdgeColor", "k", "LineWidth", 1.5);   % telaio 6 x 2.5 m
    for sx = [-1.9 1.9]
        for sy = [-1.25 1.25]
            overlay(end+1) = rectangle(ax, "Position", ...
                [c(1)+sx*ppm-0.65*ppm, c(2)+sy*ppm-0.22*ppm, 1.3*ppm, 0.44*ppm], ...
                "Curvature", 0.4, "FaceColor", [0.15 0.15 0.17], "EdgeColor", "k"); %#ok<AGROW>
        end
    end
    % torretta e braccio orientati verso il punto di sollevamento
    if ~isempty(Lay.Lift) && norm(Lay.Lift - c) > 0
        dirBoom = (Lay.Lift - c) / norm(Lay.Lift - c);
    else
        dirBoom = [1 0];
    end
    nrm = [-dirBoom(2) dirBoom(1)];
    tail = c - 1.6*ppm*dirBoom;            % contrappeso dietro la ralla
    cw = [tail + 1.1*ppm*nrm; tail - 1.1*ppm*nrm; ...
        tail + 0.7*ppm*dirBoom - 1.1*ppm*nrm; tail + 0.7*ppm*dirBoom + 1.1*ppm*nrm];
    overlay(end+1) = patch(ax, cw(:, 1), cw(:, 2), steel, "EdgeColor", "k");
    tipPx = c + rPx*dirBoom;
    boom = [c - 0.9*ppm*dirBoom + 0.45*ppm*nrm; tipPx + 0.22*ppm*nrm; ...
        tipPx - 0.22*ppm*nrm; c - 0.9*ppm*dirBoom - 0.45*ppm*nrm];
    overlay(end+1) = patch(ax, boom(:, 1), boom(:, 2), yellow * 0.9, ...
        "EdgeColor", [0.45 0.33 0.02], "LineWidth", 1.5);
    overlay(end+1) = rectangle(ax, "Position", [c(1)-1.0*ppm c(2)-1.0*ppm 2.0*ppm 2.0*ppm], ...
        "Curvature", [1 1], "FaceColor", "none", "EdgeColor", "k", "LineWidth", 1.5);   % ralla
    overlay(end+1) = plot(ax, tipPx(1), tipPx(2), "o", "MarkerSize", 8, ...
        "MarkerFaceColor", [0.80 0.15 0.10], "MarkerEdgeColor", "k");                   % gancio
    overlay(end+1) = plot(ax, c(1), c(2), "k+", "MarkerSize", 10, "LineWidth", 2);
    overlay(end+1) = text(ax, c(1), c(2) + side + 0.03*nRows, sprintf(pick(en, ...
        "CRANE - boom %g m at %g deg (projection %.1f m)", ...
        "GRU - braccio %g m a %g gradi (proiezione %.1f m)"), ...
        R.Parameters.Boom_reach_m, R.Parameters.Boom_angle_deg, R.BoomProjection_m), ...
        "HorizontalAlignment", "center", "Color", blue, "FontWeight", "bold", ...
        "BackgroundColor", "w", "Margin", 1);
end

% punto di sollevamento, carico e attrezzatura sorvolata
if ~isempty(Lay.Lift)
    p = Lay.Lift;
    if R.GlobalAlarm
        col = red;
    elseif R.ContingencyRequired
        col = amber;
    else
        col = green;
    end
    overlay(end+1) = plot(ax, p(1), p(2), "o", "MarkerSize", 14, "LineWidth", 3, "Color", col);
    overlay(end+1) = plot(ax, p(1), p(2), "x", "MarkerSize", 14, "LineWidth", 3, "Color", col);
    label = sprintf(pick(en, "LOAD %g kg", "CARICO %g kg"), R.Parameters.Theoretical_Weight);
    if R.AssetName ~= ""
        label = label + newline + pick(en, "over: ", "sopra: ") + R.AssetName;
    end
    label = label + newline + R.Verdict;
    overlay(end+1) = text(ax, p(1) + 0.02*size(img, 2), p(2), label, "Color", col, ...
        "FontWeight", "bold", "BackgroundColor", "w", "Margin", 2);
end

% distanza gru - punto di sollevamento
if ~isempty(Lay.Crane) && ~isempty(Lay.Lift)
    info.Distance_m = norm(Lay.Lift - Lay.Crane) / ppm;
    info.Difference_m = info.Distance_m - R.BoomProjection_m;
    info.Consistent = abs(info.Difference_m) <= opts.Tolerance_m;
    col = pick(info.Consistent, green, red);
    overlay(end+1) = plot(ax, [Lay.Crane(1) Lay.Lift(1)], [Lay.Crane(2) Lay.Lift(2)], ...
        "-", "Color", col, "LineWidth", 2.5);
    m = (Lay.Crane + Lay.Lift) / 2;
    overlay(end+1) = text(ax, m(1), m(2), sprintf("%.1f m", info.Distance_m), ...
        "Color", col, "FontWeight", "bold", "HorizontalAlignment", "center", ...
        "BackgroundColor", "w", "Margin", 2);
end

set(overlay, "PickableParts", "none");     % i clic arrivano all'immagine
title(ax, pick(en, "Lift layout on site plan", "Layout del sollevamento su planimetria"));
hold(ax, "off");
end

function v = pick(cond, a, b)
if cond
    v = a;
else
    v = b;
end
end
