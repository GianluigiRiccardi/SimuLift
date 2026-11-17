function R = SimuLift_Mobile(opts)
%SIMULIFT_MOBILE Verifica statica del sollevamento da riga di comando (telefono).
%   SimuLift_Mobile() esegue la verifica con i dati di default, stampa un
%   report compatto e disegna lo schema della gru in una figura unica.
%   Pensata per MATLAB Mobile, dove le app a finestra (uifigure) non sono
%   disponibili: un solo comando, pochi caratteri da digitare.
%
%   Esempi:
%     SimuLift_Mobile(Load_kg=2000, Slings_kg=100, Capacity_kg=6000, Reach_m=18, BoomAngle_deg=55)
%     SimuLift_Mobile(Load_kg=1000, Asset="gasoline")
%     SimuLift_Mobile(Excel="SimuLift_Dati_Sollevamento.xlsx", Language="en")
%
%   Opzioni Name=Value (stesso schema dell'app SimuLiftApp):
%     Load_kg, Slings_kg, Block_kg  peso da sollevare, catene/imbracature,
%                                   bozzello [kg]
%     Contingency_pct               contingency sul peso da sollevare [%]
%     Capacity_kg                   portata sollevabile nella configurazione [kg]
%     Beaufort, WindLimit_ms        vento e velocita' ammessa in esercizio [m/s]
%     Reach_m, BoomAngle_deg        sbraccio (lunghezza braccio) [m] e
%                                   inclinazione [deg]: solo per lo schema
%     Asset                         sotto o vicino al carico: "none" (default),
%                                   "diesel", "gasoline", "firewater", "other",
%                                   "building", "electrical", "toxic"
%     Tandem, NonStdEquipment       piu' attrezzature insieme / attrezzature
%                                   non standard (default false)
%     Excel                         file dati del template (pesi, portata, vento)
%     Language                      "it" (default) o "en"
%     Plot                          disegna lo schema (default true)
%
%   Verifica statica dimostrativa: non sostituisce il piano di sollevamento.

arguments
    opts.Load_kg (1,1) double {mustBeNonnegative} = 1000
    opts.Slings_kg (1,1) double {mustBeNonnegative} = 100
    opts.Block_kg (1,1) double {mustBeNonnegative} = 360
    opts.Contingency_pct (1,1) double {mustBeNonnegative} = 25
    opts.Capacity_kg (1,1) double {mustBePositive} = 7500
    opts.Beaufort (1,1) double {mustBeBetween(opts.Beaufort, 0, 12)} = 3
    opts.WindLimit_ms (1,1) double {mustBePositive} = 14
    opts.Reach_m (1,1) double {mustBePositive} = 15
    opts.BoomAngle_deg (1,1) double {mustBeBetween(opts.BoomAngle_deg, 0, 89)} = 60
    opts.Asset (1,1) string {mustBeMember(opts.Asset, ["none" "diesel" "gasoline" ...
        "firewater" "other" "building" "electrical" "toxic"])} = "none"
    opts.Tandem (1,1) logical = false
    opts.NonStdEquipment (1,1) logical = false
    opts.Excel (1,1) string = ""
    opts.Language (1,1) string {mustBeMember(opts.Language, ["it" "en"])} = "it"
    opts.Plot (1,1) logical = true
end

addpath(fileparts(mfilename("fullpath")));
P = struct("Theoretical_Weight", opts.Load_kg, "Slings_weight", opts.Slings_kg, ...
    "Pulley_weight", opts.Block_kg, "Contingency_pct", opts.Contingency_pct, ...
    "Crane_Capacity", opts.Capacity_kg, "Beaufort_scale", opts.Beaufort, ...
    "Boom_reach_m", opts.Reach_m, "Boom_angle_deg", opts.BoomAngle_deg);
if opts.Excel ~= ""
    X = simulift_read_excel(opts.Excel);
    for n = intersect(string(fieldnames(X)).', ["Theoretical_Weight" "Slings_weight" ...
            "Pulley_weight" "Crane_Capacity" "Beaufort_scale"])
        P.(n) = X.(n);
    end
end

R = simulift_static_check(P, UnderlyingAsset=opts.Asset, ...
    SimultaneousEquipment=opts.Tandem, NonStandardEquipment=opts.NonStdEquipment, ...
    WindSpeedLimit_ms=opts.WindLimit_ms, Language=opts.Language);

% --- Report compatto (righe corte, leggibili su schermo stretto) ---
T = R.Table;
fprintf("\n=== SimuLift: %s ===\n", R.Verdict);
for i = 1:height(T)
    fprintf("%s\n   %.5g %s  [%s]\n", T.Grandezza(i), T.Valore(i), T.Unita(i), T.Esito(i));
end
fprintf("--- %s ---\n", R.Class);
for i = 1:numel(R.ClassReasons)
    fprintf("- %s\n", R.ClassReasons(i));
end
for i = 1:numel(R.ContingencyActions)
    fprintf("! %s\n", R.ContingencyActions(i));
end
if opts.Language == "en"
    fprintf("Demonstrative static check: does not replace the lift plan.\n\n");
else
    fprintf("Verifica statica dimostrativa: non sostituisce il piano di sollevamento.\n\n");
end

if opts.Plot
    fig = figure("Name", "SimuLift", "Color", "w");
    ax = axes(fig);
    simulift_draw_crane(ax, R, Language=opts.Language);
    if R.GlobalAlarm
        col = [0.85 0.10 0.10];
    elseif R.ContingencyRequired
        col = [0.95 0.60 0.10];
    else
        col = [0.10 0.60 0.10];
    end
    % il sottotitolo contiene gia' i dati del braccio e del vento
    title(ax, R.Verdict, "Color", col, "FontWeight", "bold", "FontSize", 14);
end
if nargout == 0
    clear R
end
end
