function G = simulift_rigging(W_kg, geo, opts)
%SIMULIFT_RIGGING Piano di imbracatura a due punti di presa su gancio singolo.
%   G = simulift_rigging(W_kg, geo) calcola assetto e tiri di un carico di
%   massa W_kg [kg] appeso a un solo gancio con due tiranti. geo e' una
%   struct con (ascisse misurate da un'estremita' del carico):
%     Length_m     lunghezza del carico [m]
%     CoG_x_m      ascissa del baricentro [m]
%     CoG_depth_m  quota del baricentro sotto la linea dei punti di presa
%                  [m] (opzionale, default 0)
%     Pick1_m      ascissa del primo punto di presa [m]
%     Pick2_m      ascissa del secondo punto di presa [m]
%     Leg1_m       lunghezza del tirante sul punto 1 [m]
%     Leg2_m       lunghezza del tirante sul punto 2 [m]
%
%   Modello: statica piana di corpo rigido. All'equilibrio il baricentro si
%   porta sulla verticale del gancio; l'inclinazione del carico e i tiri
%   seguono dalla geometria (nessuna ipotesi di ripartizione uniforme).
%   Ipotesi: tiranti inestensibili e senza peso, attacchi a cerniera,
%   carico rigido, nessun effetto dinamico. NON copre i sollevamenti a tre
%   o quattro punti (staticamente indeterminati) ne' l'uso di bilancini.
%
%   Opzioni Name=Value:
%     WLL_kg       portata di lavoro del singolo tirante [kg] (0 = non verificata)
%     MaxAngle_deg angolo massimo del tirante dalla verticale (default 60;
%                  limite usuale per le imbracature, da verificare sulla
%                  norma e sulla targhetta degli accessori)
%     MaxTilt_deg  inclinazione del carico oltre la quale si segnala lo
%                  sbilanciamento (default 5: soglia di progetto, assunzione)
%     Language     "it" (default) o "en"
%
%   Output G: Tilt_deg, LowSide, Tension_kg (1x2), Angle_deg (1x2),
%   HookHeight_m, allarmi (AngleAlarm, WllAlarm, TiltAlarm), Balanced,
%   Verdict, Messages, Table, Suggestion (punti di presa simmetrici rispetto
%   al baricentro e, in alternativa, lunghezze dei tiranti che tengono il
%   carico orizzontale con i punti attuali) e World (coordinate per il
%   disegno, vedi simulift_draw_rigging).
%
%   Strumento di supporto: il piano di imbracatura va redatto e verificato
%   da personale competente (D.Lgs. 81/08), con accessori marcati e
%   verificati.

arguments
    W_kg (1,1) double {mustBePositive}
    geo (1,1) struct
    opts.WLL_kg (1,1) double {mustBeNonnegative} = 0
    opts.MaxAngle_deg (1,1) double {mustBePositive} = 60
    opts.MaxTilt_deg (1,1) double {mustBePositive} = 5
    opts.Language (1,1) string {mustBeMember(opts.Language, ["it" "en"])} = "it"
end

en = opts.Language == "en";
needed = ["Length_m" "CoG_x_m" "Pick1_m" "Pick2_m" "Leg1_m" "Leg2_m"];
missing = needed(~isfield(geo, needed));
if ~isempty(missing)
    error("simulift:missingParameter", "Parametri mancanti: %s", join(missing, ", "));
end
if ~isfield(geo, "CoG_depth_m")
    geo.CoG_depth_m = 0;
end
L = geo.Length_m; xg = geo.CoG_x_m; zc = geo.CoG_depth_m;
x1 = geo.Pick1_m; x2 = geo.Pick2_m; l1 = geo.Leg1_m; l2 = geo.Leg2_m;
vals = [L xg zc x1 x2 l1 l2];
if ~all(isfinite(vals)) || any(vals < 0) || L <= 0
    error("simulift:invalidParameter", pick(en, ...
        "Rigging data must be finite and non-negative.", ...
        "I dati di imbracatura devono essere finiti e non negativi."));
end
if ~(x1 < x2 && x2 <= L)
    error("simulift:invalidParameter", pick(en, ...
        "Pick points must satisfy 0 <= point 1 < point 2 <= length.", ...
        "I punti di presa devono rispettare 0 <= punto 1 < punto 2 <= lunghezza."));
end
if ~(xg > x1 && xg < x2)
    error("simulift:unstable", pick(en, ...
        "Centre of gravity outside the pick points: the load would overturn.", ...
        "Baricentro esterno ai punti di presa: il carico si ribalterebbe."));
end
d = x2 - x1;
if ~(l1 + l2 > d && abs(l1 - l2) < d)
    error("simulift:invalidParameter", pick(en, ...
        "Sling lengths not compatible with the distance between pick points.", ...
        "Lunghezze dei tiranti non compatibili con la distanza tra i punti di presa."));
end

% --- Geometria nel riferimento del carico (x lungo il carico, y verso l'alto) ---
a = (l1^2 - l2^2 + d^2) / (2*d);          % ascissa del gancio dal punto 1
h = sqrt(l1^2 - a^2);                     % quota del gancio sulla linea dei punti di presa
A1 = [x1 0]; A2 = [x2 0];
Hk = [x1 + a, h];
Gc = [xg, -zc];

% --- Equilibrio: baricentro sulla verticale del gancio ---
v = Gc - Hk;                              % dal gancio al baricentro: sara' la verticale
w = v / norm(v);                          % verso della gravita' nel riferimento del carico
phi_deg = -90 - atan2d(v(2), v(1));       % rotazione del carico nel riferimento assoluto
u1 = (Hk - A1) / l1;
u2 = (Hk - A2) / l2;
T = -[u1.' u2.'] \ (W_kg * w.');          % tiri [kg-forza espressi come massa equivalente]
beta = [acosd(dot(u1, -w)), acosd(dot(u2, -w))];   % angoli dei tiranti dalla verticale

G.Tilt_deg = abs(phi_deg);
if G.Tilt_deg < 0.05
    G.LowSide = "-";
elseif phi_deg < 0
    G.LowSide = pick(en, "pick point 2 side", "lato punto di presa 2");
else
    G.LowSide = pick(en, "pick point 1 side", "lato punto di presa 1");
end
G.Tension_kg = T.';
G.Angle_deg = beta;
G.HookHeight_m = h;
G.AngleAlarm = any(beta > opts.MaxAngle_deg);
G.WllChecked = opts.WLL_kg > 0;
G.WllAlarm = G.WllChecked && any(T > opts.WLL_kg);
G.TiltAlarm = G.Tilt_deg > opts.MaxTilt_deg;
G.Balanced = ~G.TiltAlarm;
G.Alarm = G.AngleAlarm || G.WllAlarm || G.TiltAlarm;

% --- Proposte per un carico orizzontale ---
s = min([d/2, xg, L - xg]);               % semi-distanza simmetrica ammessa dal carico
G.Suggestion.Pick1_m = xg - s;
G.Suggestion.Pick2_m = xg + s;
G.Suggestion.Leg_m = hypot(s, h);         % tiranti uguali, stessa quota del gancio
G.Suggestion.LevelLeg1_m = hypot(xg - x1, h);   % in alternativa: punti attuali, tiranti diversi
G.Suggestion.LevelLeg2_m = hypot(x2 - xg, h);

% --- Messaggi ---
msg = strings(0, 1);
if G.Balanced
    msg(end+1) = sprintf(pick(en, "Load balanced: tilt %.1f deg.", ...
        "Carico bilanciato: inclinazione %.1f gradi."), G.Tilt_deg);
else
    msg(end+1) = sprintf(pick(en, ...
        "Load NOT balanced: tilt %.1f deg, low on the %s.", ...
        "Carico NON bilanciato: inclinazione %.1f gradi, basso sul %s."), G.Tilt_deg, G.LowSide);
    msg(end+1) = sprintf(pick(en, ...
        "To level it with equal slings: pick points at %.2f m and %.2f m, slings %.2f m.", ...
        "Per tenerlo orizzontale con tiranti uguali: punti di presa a %.2f m e %.2f m, tiranti da %.2f m."), ...
        G.Suggestion.Pick1_m, G.Suggestion.Pick2_m, G.Suggestion.Leg_m);
    msg(end+1) = sprintf(pick(en, ...
        "Or keep the pick points and use slings of %.2f m and %.2f m.", ...
        "Oppure mantenere i punti di presa e usare tiranti da %.2f m e %.2f m."), ...
        G.Suggestion.LevelLeg1_m, G.Suggestion.LevelLeg2_m);
end
if G.AngleAlarm
    msg(end+1) = sprintf(pick(en, ...
        "Sling angle above %g deg from vertical: use longer slings or a spreader beam.", ...
        "Angolo del tirante oltre %g gradi dalla verticale: usare tiranti piu' lunghi o un bilancino."), ...
        opts.MaxAngle_deg);
end
if G.WllAlarm
    msg(end+1) = pick(en, "Sling tension above the working load limit.", ...
        "Tiro sul tirante superiore alla portata di lavoro.");
end
G.Messages = msg(:);
G.Verdict = pick(G.Alarm, pick(en, "TO BE REVISED", "DA RIVEDERE"), "OK");

% --- Tabella ---
names = pick(en, ["Load tilt"; "Sling 1 tension"; "Sling 2 tension"; ...
    "Sling 1 angle from vertical"; "Sling 2 angle from vertical"; "Hook height above pick points"], ...
    ["Inclinazione del carico"; "Tiro tirante 1"; "Tiro tirante 2"; ...
    "Angolo tirante 1 dalla verticale"; "Angolo tirante 2 dalla verticale"; ...
    "Quota gancio sui punti di presa"]);
Valore = [G.Tilt_deg; T(1); T(2); beta(1); beta(2); h];
Unita = ["deg"; "kg"; "kg"; "deg"; "deg"; "m"];
wll = opts.WLL_kg;
if ~G.WllChecked
    wll = NaN;
end
Limite = [opts.MaxTilt_deg; wll; wll; opts.MaxAngle_deg; opts.MaxAngle_deg; NaN];
alarm = pick(en, "ALARM", "ALLARME");
flag = @(tf) pick(tf, alarm, "ok");
Esito = [flag(G.TiltAlarm); "-"; "-"; flag(beta(1) > opts.MaxAngle_deg); ...
    flag(beta(2) > opts.MaxAngle_deg); "-"];
if G.WllChecked
    Esito(2) = flag(T(1) > opts.WLL_kg);
    Esito(3) = flag(T(2) > opts.WLL_kg);
end
G.Table = table(names, Valore, Unita, Limite, Esito, ...
    'VariableNames', ["Grandezza" "Valore" "Unita" "Limite" "Esito"]);

% --- Coordinate assolute per il disegno: rotazione attorno al gancio ---
Rm = [cosd(phi_deg) -sind(phi_deg); sind(phi_deg) cosd(phi_deg)];
toWorld = @(p) (Rm * (p - Hk).').' + Hk;
bodyH = max(0.12*L, 2*zc + 0.1*L);        % altezza della sagoma, solo grafica
G.World.Hook = Hk;
G.World.Pick1 = toWorld(A1);
G.World.Pick2 = toWorld(A2);
G.World.CoG = toWorld(Gc);
G.World.Body = toWorld([0 0; L 0; L -bodyH; 0 -bodyH]);
G.Mass_kg = W_kg;
G.Geometry = geo;
end

function v = pick(cond, a, b)
if cond
    v = a;
else
    v = b;
end
end
