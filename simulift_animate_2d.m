function simulift_animate_2d(xlsxFile, saveGif)
% SIMULIFT_ANIMATE_2D  Animazione 2D scenica del sollevamento SimuLift.
%
% Legge gli stessi dati usati da simulift_import_excel (template Excel) e
% anima una scena semplice: gru, carico che sale, vento, e un semaforo
% SAFE/ALARM calcolato con le STESSE formule del modello SimuLift_WithLamps.
%
% Uso:
%   simulift_animate_2d()                                  % usa il template di default, non salva gif
%   simulift_animate_2d('SimuLift_Dati_Sollevamento.xlsx')  % file Excel specifico
%   simulift_animate_2d('SimuLift_Dati_Sollevamento.xlsx', true)  % salva anche SimuLift_animazione.gif
%
% NOTA IMPORTANTE: le formule e le soglie qui sotto rispecchiano i blocchi
% del modello Simulink (Impact_Force_Calc, Overload_Margin, Wind_Force_Compute,
% Impact_Threshold=25000, Wind_Threshold_Compare=300). Se cambi le soglie o
% le formule nel modello .slx, aggiornale anche qui.

if nargin < 1 || isempty(xlsxFile)
    xlsxFile = 'SimuLift_Dati_Sollevamento.xlsx';
end
if nargin < 2 || isempty(saveGif)
    saveGif = false;
end

if ~java.io.File(xlsxFile).isAbsolute()
    xlsxFile = fullfile(pwd, xlsxFile);
end
if ~isfile(xlsxFile)
    error('simulift_animate_2d:fileNotFound', 'File Excel non trovato: %s', xlsxFile);
end

% ---------- 1) Leggi i parametri (stesso formato del template) ----------
opts = detectImportOptions(xlsxFile, 'Sheet', 'Dati Sollevamento');
opts.VariableNamesRange = 'A4';
opts.DataRange = 'A5';
opts.VariableNamingRule = 'preserve';
T = readtable(xlsxFile, opts);
T = T(~cellfun(@isempty, T.("Blocco Simulink")), :);

P = struct();
for i = 1:height(T)
    P.(T.("Blocco Simulink"){i}) = T.("Valore")(i);
end

% ---------- 2) Ricalcola le grandezze come nel modello Simulink ----------
g = 9.81;
total_mass   = P.Theoretical_Weight + P.Pulley_weight + P.Slings_weight;      % kg
weight_force = total_mass * g;                                                % N  (blocco Weight_Force)
potential_e  = weight_force * P.Drop_Height;                                  % J  (Potential_Energy_Term)
impact_force = potential_e / P.Deformation_Limit;                             % N  (Impact_Force_Calc)

% Come nel blocco Effective_load del modello: massa totale in kg per il
% fattore di sicurezza, confrontata con la portata della gru in kg.
effective_load  = total_mass * P.Safety_factor;                               % kg (Effective_load)
overload_margin = P.Crane_Capacity - effective_load;                          % kg (Overload_Margin)

% Beaufort -> velocità vento (m/s), stessa tabella del blocco Wind_Speed_Lookup
beaufort_bp    = [0 1 2 3 4 5 6 7 9 10 11 12];
wind_speed_tbl = [0 1.5 3.3 5.4 7.9 10.7 13.8 17.1 20.7 24.4 28.4 36.9];
wind_speed = interp1(beaufort_bp, wind_speed_tbl, P.Beaufort_scale, 'linear', 'extrap');

half_rho    = 0.5 * 1.225;
drag_coeff  = 1.0;   % Drag_Coefficient nel modello
wind_force  = half_rho * wind_speed^2 * drag_coeff * P.Exposed_surface_area;   % N (Wind_Force_Compute)

% ---------- 3) Verdetti (stesse soglie del modello) ----------
IMPACT_THRESHOLD = 25000;  % N  (blocco Impact_Threshold, <=)
WIND_THRESHOLD   = 300;    % N  (blocco Wind_Threshold_Compare, >)

impact_alarm   = impact_force > IMPACT_THRESHOLD;
overload_alarm = overload_margin < 0;
wind_alarm     = wind_force > WIND_THRESHOLD;
global_alarm   = impact_alarm || overload_alarm || wind_alarm;

if global_alarm
    verdictText = 'LIFT DENIED';
    verdictColor = [0.85 0.1 0.1];
else
    verdictText = 'SAFE TO LIFT';
    verdictColor = [0.1 0.6 0.1];
end

fprintf('Impact force:  %8.1f N  (soglia %d)  %s\n', impact_force, IMPACT_THRESHOLD, tern(impact_alarm,'ALARM','ok'));
fprintf('Overload marg: %8.1f kg  %s\n', overload_margin, tern(overload_alarm,'ALARM','ok'));
fprintf('Wind force:    %8.1f N  (soglia %d)  %s\n', wind_force, WIND_THRESHOLD, tern(wind_alarm,'ALARM','ok'));
fprintf('VERDETTO: %s\n', verdictText);

% ---------- 4) Scena 2D ----------
figVisible = 'on';
if batchStartupOptionUsed()
    figVisible = 'off'; % evita blocchi di rendering quando eseguito con -batch
end
fig = figure('Color','w','Position',[100 100 900 600], 'Name','SimuLift - Animazione 2D', 'Visible', figVisible);
ax = axes('Parent',fig); hold(ax,'on'); axis(ax,'equal'); axis(ax,[-2 14 0 14]);
xlabel(ax,'m'); ylabel(ax,'m'); title(ax,'SimuLift — Simulazione sollevamento');
grid(ax,'on'); box(ax,'on');

% Terreno
plot(ax, [-2 14], [0 0], 'k-', 'LineWidth', 2);

% Base gru + braccio (angolo fisso, solo estetico)
baseX = 1; baseY = 0;
boomAngleDeg = 60;
boomLen = 9;
tipX = baseX + boomLen*cosd(boomAngleDeg);
tipY = baseY + boomLen*sind(boomAngleDeg);
plot(ax, [baseX-0.6 baseX+0.6], [0 0], 'k-', 'LineWidth', 6); % base
plot(ax, [baseX baseX], [0 1], 'k-', 'LineWidth', 8);         % colonna
plot(ax, [baseX tipX], [1 tipY], 'k-', 'LineWidth', 5);       % braccio

% Semaforo verdetto (in alto a sinistra)
lampCenter = [0 13];
lamp = rectangle(ax, 'Position', [lampCenter(1)-0.6 lampCenter(2)-0.6 1.2 1.2], ...
    'Curvature',[1 1], 'FaceColor', verdictColor, 'EdgeColor','k','LineWidth',1.5);
verdictTxt = text(ax, lampCenter(1)+1, lampCenter(2), verdictText, ...
    'FontSize',13,'FontWeight','bold','Color',verdictColor,'VerticalAlignment','middle');

% Pannello numerico
infoTxt = text(ax, 8.5, 13.5, sprintf('Impatto: %.0f N\nMargine portata: %.0f kg\nVento: %.0f N', ...
    impact_force, overload_margin, wind_force), ...
    'FontSize',10,'VerticalAlignment','top','BackgroundColor',[1 1 1 0.7],'Margin',4);

% Carico e cavo (handle da aggiornare nel loop)
loadW = 1.4; loadH = 1.0;
cableLine = plot(ax, [tipX tipX], [tipY loadH], 'Color',[0.3 0.3 0.3],'LineWidth',1.2);
loadRect = rectangle(ax, 'Position', [tipX-loadW/2 0 loadW loadH], ...
    'FaceColor',[0.85 0.55 0.1], 'EdgeColor','k');

% Freccia vento
windArrowLen = min(3, 0.3 + wind_force/150);
windArrow = quiver(ax, 12.5, 8, -windArrowLen, 0, 0, 'Color',[0.2 0.5 0.9], ...
    'LineWidth',2,'MaxHeadSize',1.5);
windTxt = text(ax, 12.6, 8.6, sprintf('vento %.1f m/s', wind_speed), 'FontSize',9,'Color',[0.2 0.5 0.9]);

% ---------- 5) Loop di animazione: il carico sale dal terreno al braccio ----------
nFrames = 90;
targetLift = tipY - 1.2;   % altezza finale del carico sotto la punta braccio
frames(nFrames) = struct('cdata',[],'colormap',[]); %#ok<AGROW>

for k = 1:nFrames
    tNorm = k / nFrames;
    ease = 3*tNorm^2 - 2*tNorm^3;  % smoothstep: parte lenta, arriva dolce
    % estremità del cavo: parte con il carico appoggiato a terra e sale
    % fino a targetLift sotto la punta del braccio
    hookY = loadH + ease * (targetLift - loadH);

    sway = 0;
    if wind_force > 0
        sway = 0.15 * min(2, wind_force/150) * sin(2*pi*1.2*tNorm*nFrames/30);
    end
    cx = tipX + sway;

    set(cableLine, 'XData', [tipX cx], 'YData', [tipY hookY]);
    set(loadRect, 'Position', [cx-loadW/2, hookY-loadH, loadW, loadH]);

    drawnow;
    if saveGif
        frames(k) = getframe(fig);
    else
        pause(0.03);
    end
end

if saveGif
    gifPath = fullfile(fileparts(xlsxFile), 'SimuLift_animazione.gif');
    for k = 1:nFrames
        [imind, cm] = rgb2ind(frame2im(frames(k)), 256);
        if k == 1
            imwrite(imind, cm, gifPath, 'gif', 'Loopcount', inf, 'DelayTime', 0.05);
        else
            imwrite(imind, cm, gifPath, 'gif', 'WriteMode', 'append', 'DelayTime', 0.05);
        end
    end
    fprintf('GIF salvata: %s\n', gifPath);
end

fprintf('DONE_OK\n');
end

function s = tern(cond, a, b)
if cond, s = a; else, s = b; end
end
