function R = simulift_static_check(P, opts)
%SIMULIFT_STATIC_CHECK Verifica statica di un sollevamento (nucleo di calcolo).
%   R = simulift_static_check(P) calcola le grandezze del verificatore
%   statico SimuLift a partire dalla struct P, i cui campi hanno gli stessi
%   nomi dei blocchi Constant del modello Simulink / colonna "Blocco
%   Simulink" del template Excel:
%     Theoretical_Weight   massa del carico [kg]
%     Pulley_weight        massa del bozzello [kg]
%     Slings_weight        massa delle imbracature [kg]
%     Safety_factor        fattore di sicurezza sul carico [-]
%     Drop_Height          altezza di caduta ipotizzata [m]
%     Deformation_Limit    deformazione ammessa all'urto [m]
%     Beaufort_scale       grado Beaufort [0-12]
%     Exposed_surface_area superficie esposta al vento [m^2]
%     Crane_Capacity       portata della gru nella configurazione [kg]
%   Campi opzionali (verifica imbracatura, eseguita solo se Sling_WLL_kg > 0):
%     Sling_legs           numero di rami portanti [-] (default 2)
%     Sling_angle_deg      angolo del ramo dalla verticale [deg] (default 0)
%     Sling_WLL_kg         WLL del singolo ramo [kg] (default 0 = non verificato)
%     Drag_coefficient     coefficiente di resistenza [-] (default 1.0, come
%                          il blocco Drag_Coefficient del modello)
%
%   Opzioni Name=Value:
%     ImpactThreshold_N      soglia forza d'urto [N] (default 25000, blocco
%                            Impact_Threshold)
%     WindThreshold_N        soglia forza del vento [N] (default 300, blocco
%                            Wind_Threshold_Compare)
%     IncludeImpactInVerdict lo scenario di caduta concorre al verdetto
%                            (default true, come nel modello)
%     Language               lingua dei testi di R.Table: "it" (default) o "en"
%     UnderlyingAsset        cosa c'e' sotto o vicino al percorso del carico:
%                            "none", "diesel", "gasoline", "firewater",
%                            "other" (attrezzatura in esercizio),
%                            "building" (edificio occupato), "electrical",
%                            "toxic" (gas tossici). Se indicato, valgono le
%                            REGOLE al posto del calcolo d'urto (Drop_Height
%                            e Deformation_Limit non servono): carico > 500
%                            kg sopra attrezzature/edifici, oppure qualunque
%                            carico sopra linee elettriche/gas tossici ->
%                            "LIFT WITH CONTINGENCY PLAN" con
%                            R.ContingencyActions. "" (default) =
%                            comportamento del modello Simulink, governato
%                            da IncludeImpactInVerdict.
%     SimultaneousEquipment  due o piu' attrezzature di sollevamento
%                            operano insieme (default false)
%     NonStandardEquipment   attrezzature di sollevamento non standard
%                            (default false)
%
%     WindSpeedLimit_ms      velocita' del vento ammessa in esercizio [m/s],
%                            dal manuale della gru. Se > 0 il vento e'
%                            verificato in velocita' (non in forza) e
%                            Exposed_surface_area non serve.
%
%   Analisi dei carichi: se P contiene Contingency_pct [%], il totale e'
%   peso + imbracature + bozzello + contingency (percentuale del solo peso
%   da sollevare), Safety_factor non serve e R.Table riporta totale
%   sollevamento ed eccedenza sollevabile.
%
%   Geometria del braccio (opzionale, solo descrittiva): Boom_reach_m
%   (lunghezza del braccio, default 15) e Boom_angle_deg (inclinazione
%   sull'orizzontale, default 60); R.BoomProjection_m ne e' la proiezione
%   orizzontale. NON entra nelle verifiche: la portata nella configurazione
%   va letta dalla tabella di carico del costruttore.
%
%   Classificazione, sempre calcolata: R.Class = STANDARD / NON STANDARD /
%   CRITICO, R.ClassCode, R.ClassReasons, R.GrossUtilization. I criteri sono
%   impostazioni dello strumento; il sollevamento critico richiede
%   approvazione preventiva. Le azioni di contingency sono indicazioni
%   generiche, da adattare alle procedure di sito.
%
%   Differenze dichiarate rispetto a simulift_animate_2d.m:
%   - Margine di sovraccarico in kg (massa totale x SF contro portata in
%     kg), come nel blocco Effective_load del modello. Lo script di
%     animazione confronta N con kg e genera un falso allarme.
%   - Tabella Beaufort con il grado 8 presente (limiti superiori di classe
%     della scala WMO a 10 m). Nello script il breakpoint 8 manca e i gradi
%     9-11 risultano sottostimati (errore non conservativo). Il valore 36.9
%     m/s per il grado 12 e' un'assunzione ereditata dal modello.
%   - La verifica dell'imbracatura (ripartizione uniforme sui rami portanti,
%     T = m/(n cos(beta))) e' un'aggiunta; ipotesi: carico simmetrico,
%     baricentro centrato. Angolo massimo 60 deg dalla verticale (EN 13414-1,
%     da verificare sulla norma vigente).
%
%   Strumento dimostrativo: non sostituisce il piano di sollevamento, le
%   tabelle di carico del costruttore e le verifiche previste da
%   D.Lgs. 81/08 ed EN 13001.

arguments
    P (1,1) struct
    opts.ImpactThreshold_N (1,1) double {mustBePositive} = 25000
    opts.WindThreshold_N (1,1) double {mustBePositive} = 300
    opts.IncludeImpactInVerdict (1,1) logical = true
    opts.Language (1,1) string {mustBeMember(opts.Language, ["it" "en"])} = "it"
    opts.UnderlyingAsset (1,1) string {mustBeMember(opts.UnderlyingAsset, ...
        ["" "none" "diesel" "gasoline" "firewater" "other" "building" ...
        "electrical" "toxic"])} = ""
    opts.SimultaneousEquipment (1,1) logical = false
    opts.NonStandardEquipment (1,1) logical = false
    opts.WindSpeedLimit_ms (1,1) double {mustBeNonnegative} = 0
end

ruleMode = opts.UnderlyingAsset ~= "";
planMode = isfield(P, "Contingency_pct");   % analisi dei carichi con contingency sul peso
required = ["Theoretical_Weight" "Pulley_weight" "Slings_weight" ...
    "Beaufort_scale" "Crane_Capacity"];
if planMode
    P = applyDefault(P, "Safety_factor", 1);
else
    required = [required "Safety_factor"];
end
if opts.WindSpeedLimit_ms > 0
    % vento verificato in velocita': superficie esposta e Cd non servono
    P = applyDefault(P, "Exposed_surface_area", 0);
else
    required = [required "Exposed_surface_area"];
end
if ruleMode
    % criteri a regole: il calcolo d'urto non e' usato
    P = applyDefault(P, "Drop_Height", 0);
    P = applyDefault(P, "Deformation_Limit", 1);
else
    required = [required "Drop_Height" "Deformation_Limit"];
end
missing = required(~isfield(P, required));
if ~isempty(missing)
    error("simulift:missingParameter", "Parametri mancanti: %s", join(missing, ", "));
end
P = applyDefault(P, "Sling_legs", 2);
P = applyDefault(P, "Sling_angle_deg", 0);
P = applyDefault(P, "Sling_WLL_kg", 0);
P = applyDefault(P, "Drag_coefficient", 1.0);
P = applyDefault(P, "Boom_reach_m", 15);
P = applyDefault(P, "Boom_angle_deg", 60);

names = string(fieldnames(P)).';
for n = names
    v = P.(n);
    if ~(isnumeric(v) && isscalar(v) && isfinite(v) && v >= 0)
        error("simulift:invalidParameter", ...
            "Il parametro %s deve essere uno scalare finito non negativo.", n);
    end
end
mustBePositiveParam(P, ["Safety_factor" "Deformation_Limit" "Crane_Capacity" "Sling_legs"]);
if P.Beaufort_scale > 12
    error("simulift:invalidParameter", "Beaufort_scale deve essere tra 0 e 12.");
end
if P.Sling_angle_deg >= 90
    error("simulift:invalidParameter", "Sling_angle_deg deve essere < 90 deg.");
end

g_ms2 = 9.81;        % accelerazione di gravita' [m/s^2]
rho_kgm3 = 1.225;    % densita' aria ISA a livello del mare [kg/m^3]

% --- Masse e peso ---
R.TotalMass_kg = P.Theoretical_Weight + P.Pulley_weight + P.Slings_weight;
R.WeightForce_N = R.TotalMass_kg * g_ms2;

% --- Scenario di caduta: F = m g h / delta (limite superiore rigido-plastico) ---
R.ImpactForce_N = R.WeightForce_N * P.Drop_Height / P.Deformation_Limit;
R.ImpactThreshold_N = opts.ImpactThreshold_N;
R.ImpactAlarm = R.ImpactForce_N > opts.ImpactThreshold_N;

% --- Portata gru: massa di progetto (m x SF) contro portata, in kg ---
if planMode
    % riepilogo del piano: contingency in % applicata al solo peso da
    % sollevare; totale = peso + imbracature + bozzello + contingency
    R.Contingency_kg = P.Theoretical_Weight * P.Contingency_pct / 100;
    R.DesignMass_kg = R.TotalMass_kg + R.Contingency_kg;
else
    R.DesignMass_kg = R.TotalMass_kg * P.Safety_factor;
    R.Contingency_kg = R.DesignMass_kg - R.TotalMass_kg;
end
R.OverloadMargin_kg = P.Crane_Capacity - R.DesignMass_kg;
R.CraneUtilization = R.DesignMass_kg / P.Crane_Capacity;
R.OverloadAlarm = R.OverloadMargin_kg < 0;

% --- Vento: F = 0.5 rho v^2 Cd A ---
beaufort = 0:12;
windSpeed_ms = [0 1.5 3.3 5.4 7.9 10.7 13.8 17.1 20.7 24.4 28.4 32.6 36.9];
R.WindSpeed_ms = interp1(beaufort, windSpeed_ms, P.Beaufort_scale, "linear");
R.WindForce_N = 0.5 * rho_kgm3 * R.WindSpeed_ms^2 * P.Drag_coefficient ...
    * P.Exposed_surface_area;
R.WindThreshold_N = opts.WindThreshold_N;
R.WindAlarm = R.WindForce_N > opts.WindThreshold_N;
R.WindSpeedLimit_ms = opts.WindSpeedLimit_ms;
if opts.WindSpeedLimit_ms > 0
    % criterio del piano di sollevamento: velocita' del vento contro la
    % velocita' ammessa in esercizio dal costruttore della gru
    R.WindAlarm = R.WindSpeed_ms > opts.WindSpeedLimit_ms;
end

% --- Imbracatura (opzionale) ---
R.SlingChecked = P.Sling_WLL_kg > 0;
if R.SlingChecked
    R.SlingLegLoad_kg = P.Theoretical_Weight / (P.Sling_legs * cosd(P.Sling_angle_deg));
    R.SlingUtilization = R.SlingLegLoad_kg / P.Sling_WLL_kg;
    R.SlingAngleAlarm = P.Sling_angle_deg > 60;
    R.SlingAlarm = R.SlingUtilization > 1 || R.SlingAngleAlarm;
else
    R.SlingLegLoad_kg = NaN;
    R.SlingUtilization = NaN;
    R.SlingAngleAlarm = false;
    R.SlingAlarm = false;
end

% --- Geometria del braccio (descrittiva) ---
if P.Boom_angle_deg >= 90
    error("simulift:invalidParameter", "Boom_angle_deg deve essere < 90 deg.");
end
R.BoomProjection_m = P.Boom_reach_m * cosd(P.Boom_angle_deg);

% --- Classificazione del sollevamento ---
% Critico se anche una sola condizione e' vera; altrimenti non standard se
% il carico supera l'80% della portata; altrimenti standard.
% Convenzioni adottate:
% - soglie 500 kg / 18 t / 45 t: massa del solo carico (Theoretical_Weight);
% - rapporti con la portata: massa lorda sospesa (carico + bozzello +
%   imbracature), senza contingency ne' fattore di sicurezza.
R.Asset = opts.UnderlyingAsset;
load_kg = P.Theoretical_Weight;
R.GrossUtilization = R.TotalMass_kg / P.Crane_Capacity;
overEquipment = ismember(R.Asset, ["diesel" "gasoline" "firewater" "other" "building"]);
overHazard = ismember(R.Asset, ["electrical" "toxic"]);
crit = [load_kg > 500 && overEquipment
    overHazard
    opts.SimultaneousEquipment
    opts.NonStandardEquipment
    load_kg > 45000
    R.GrossUtilization > 0.90
    load_kg > 18000 && R.GrossUtilization > 0.80];
[R.AssetName, T] = classificationTexts(R.Asset, opts.Language);
R.ClassReasons = T.reasons(crit);
if any(crit)
    R.ClassCode = "critical";
elseif R.GrossUtilization > 0.80
    R.ClassCode = "nonstandard";
    R.ClassReasons = T.nonStandardReason;
else
    R.ClassCode = "standard";
end
R.Class = T.classNames(["standard" "nonstandard" "critical"] == R.ClassCode);

% --- Verdetto ---
if ruleMode
    % regola: carico > 500 kg sopra attrezzature critiche (o comunque sopra
    % linee elettriche / gas tossici) -> piano di contingency
    R.ImpactInVerdict = false;
    R.ImpactAlarm = false;
    R.ContingencyRequired = crit(1) || crit(2);
else
    % comportamento del modello Simulink: l'urto puo' negare il sollevamento
    R.ImpactInVerdict = opts.IncludeImpactInVerdict;
    R.ContingencyRequired = false;
end
R.GlobalAlarm = R.OverloadAlarm || R.WindAlarm || R.SlingAlarm ...
    || (R.ImpactInVerdict && R.ImpactAlarm);
if R.GlobalAlarm
    R.Verdict = "LIFT DENIED";
elseif R.ContingencyRequired
    R.Verdict = "LIFT WITH CONTINGENCY PLAN";
else
    R.Verdict = "SAFE TO LIFT";
end
R.ContingencyActions = strings(0, 1);
if R.ContingencyRequired
    R.ContingencyActions = [T.contingencyCommon; T.contingencyAsset];
end

% --- Tabella riassuntiva ---
Grandezza = ["Massa totale"; "Forza peso"; "Massa di progetto (m x SF)"; ...
    "Margine di portata"; "Utilizzo portata gru"; "Velocita' vento"; ...
    "Forza del vento"; "Carico per ramo imbracatura"; ...
    "Utilizzo WLL ramo"; "Forza d'urto (scenario caduta)"];
Valore = [R.TotalMass_kg; R.WeightForce_N; R.DesignMass_kg; ...
    R.OverloadMargin_kg; 100*R.CraneUtilization; R.WindSpeed_ms; ...
    R.WindForce_N; R.SlingLegLoad_kg; 100*R.SlingUtilization; R.ImpactForce_N];
Unita = ["kg"; "N"; "kg"; "kg"; "%"; "m/s"; "N"; "kg"; "%"; "N"];
Limite = [NaN; NaN; P.Crane_Capacity; 0; 100; NaN; opts.WindThreshold_N; ...
    P.Sling_WLL_kg; 100; opts.ImpactThreshold_N];
Esito = ["-"; "-"; esito(R.OverloadAlarm); esito(R.OverloadAlarm); ...
    esito(R.OverloadAlarm); "-"; esito(R.WindAlarm); "-"; "-"; esito(R.ImpactAlarm)];
if R.SlingChecked
    Esito(8:9) = esito(R.SlingAlarm);
else
    Limite(8:9) = NaN;
    Esito(8:9) = "non verificato";
end
if ~R.ImpactInVerdict
    Esito(10) = Esito(10) + " (informativo)";
end
if opts.Language == "en"
    % Stessa tabella con testi in inglese (i nomi delle variabili restano).
    Grandezza = ["Total mass"; "Weight force"; "Design mass (m x SF)"; ...
        "Capacity margin"; "Crane capacity utilisation"; "Wind speed"; ...
        "Wind force"; "Load per sling leg"; "Sling leg WLL utilisation"; ...
        "Impact force (drop scenario)"];
    Esito = replace(Esito, ["ALLARME" "non verificato" "informativo"], ...
        ["ALARM" "not checked" "informative"]);
end
if ruleMode
    % al posto della forza d'urto: rapporto usato dalla classificazione
    Grandezza(10) = T.grossRow;
    Valore(10) = 100 * R.GrossUtilization;
    Unita(10) = "%";
    Limite(10) = 80;
    Esito(10) = R.Class;
end
if planMode
    % tabella nel formato "Analisi dei carichi" del piano di sollevamento
    en = opts.Language == "en";
    if en
        Grandezza = ["Weight to lift"; "Chains / slings"; "Hook block"; ...
            sprintf("Contingency %g%%", P.Contingency_pct); "TOTAL LIFT"; ...
            "Liftable excess"; "Capacity utilisation"; "Wind speed"; ...
            "Gross load / capacity (classification)"];
    else
        Grandezza = ["Peso da sollevare"; "Catene / imbracature"; "Bozzello"; ...
            sprintf("Contingency %g%%", P.Contingency_pct); "TOTALE SOLLEVAMENTO"; ...
            "Eccedenza sollevabile"; "Utilizzo portata"; "Velocita' vento"; ...
            "Carico lordo / portata (classificazione)"];
    end
    Valore = [P.Theoretical_Weight; P.Slings_weight; P.Pulley_weight; ...
        R.Contingency_kg; R.DesignMass_kg; R.OverloadMargin_kg; ...
        100*R.CraneUtilization; R.WindSpeed_ms; 100*R.GrossUtilization];
    Unita = ["kg"; "kg"; "kg"; "kg"; "kg"; "kg"; "%"; "m/s"; "%"];
    Limite = [NaN; NaN; NaN; NaN; P.Crane_Capacity; 0; 100; NaN; 80];
    if opts.WindSpeedLimit_ms > 0
        Limite(8) = opts.WindSpeedLimit_ms;
    end
    Esito = ["-"; "-"; "-"; "-"; esito(R.OverloadAlarm); esito(R.OverloadAlarm); ...
        esito(R.OverloadAlarm); esito(R.WindAlarm); R.Class];
    if en
        Esito = replace(Esito, "ALLARME", "ALARM");
    end
end
R.Table = table(Grandezza, Valore, Unita, Limite, Esito);
R.Parameters = P;
end

function [name, T] = classificationTexts(asset, lang)
% Testi della classificazione e azioni di contingency. Le azioni sono
% indicazioni generiche: da adattare alle procedure di sito.
keys = ["diesel" "gasoline" "firewater" "other" "building" "electrical" "toxic"];
en = lang == "en";
if en
    names = ["diesel line" "gasoline line" "firewater line" "in-service equipment" ...
        "occupied building" "electrical line" "equipment containing toxic gas"];
    T.classNames = ["STANDARD" "NON-STANDARD" "CRITICAL"];
    T.reasons = [
        "Load above 500 kg travelling over or close to plant in service or buildings with people inside"
        "Travel over or close to power lines or plant holding toxic gas"
        "Lift carried out with more than one crane at the same time"
        "Special (non-standard) lifting gear in use"
        "Load above 45 t"
        "Load above 90% of the capacity"
        "Load above 18 t and above 80% of the capacity"];
    T.nonStandardReason = "Load above 80% of the capacity";
    T.grossRow = "Gross load / capacity (classification)";
    T.contingencyCommon = [
        "Contingency plan required before lifting."
        "Consider as alternatives: a load path that does not pass over the item, or mechanical protection."];
    byAsset = [
        "Identify the upstream and downstream isolation valves, check they can be operated and keep them attended; flammable product: spill containment and fire watch."
        "Identify the upstream and downstream isolation valves, check they can be operated and keep them attended; flammable product: spill containment and fire watch."
        "Identify the isolation valves and keep them attended; isolating the firewater line reduces fire protection: provide compensating measures."
        "Define how the equipment is isolated and made safe if hit."
        "Clear or bar access to the rooms under the load path for the whole lift."
        "Request de-energisation or keep the safety distances from live parts."
        "Define isolation of the equipment, gas detection, escape routes and PPE for the lifting crew."];
else
    names = ["linea gasolio" "linea benzina" "linea antincendio" "attrezzatura in esercizio" ...
        "edificio occupato" "linea elettrica" "attrezzatura con gas tossici"];
    T.classNames = ["STANDARD" "NON STANDARD" "CRITICO"];
    T.reasons = [
        "Carico oltre 500 kg in transito sopra o in prossimita' di impianti in esercizio o edifici con persone"
        "Transito sopra o in prossimita' di linee elettriche o di impianti con gas tossici"
        "Sollevamento eseguito con piu' mezzi contemporaneamente"
        "Uso di attrezzature di sollevamento speciali (non standard)"
        "Carico oltre 45 t"
        "Carico oltre il 90% della portata"
        "Carico oltre 18 t e oltre l'80% della portata"];
    T.nonStandardReason = "Carico oltre l'80% della portata";
    T.grossRow = "Carico lordo / portata (classificazione)";
    T.contingencyCommon = [
        "Piano di contingency richiesto prima del sollevamento."
        "Valutare in alternativa: percorso del carico che non sorvoli l'elemento, oppure protezione meccanica."];
    byAsset = [
        "Individuare le valvole di intercettazione a monte e a valle, verificarne la manovrabilita' e presidiarle; prodotto infiammabile: contenimento dello sversamento e presidio antincendio."
        "Individuare le valvole di intercettazione a monte e a valle, verificarne la manovrabilita' e presidiarle; prodotto infiammabile: contenimento dello sversamento e presidio antincendio."
        "Individuare le valvole di intercettazione e presidiarle; l'intercettazione dell'antincendio riduce la protezione dell'area: prevedere misure compensative."
        "Definire come intercettare e mettere in sicurezza l'attrezzatura in caso di urto."
        "Sgomberare o interdire i locali sotto il percorso del carico per tutta la durata."
        "Richiedere il fuori tensione oppure rispettare le distanze di sicurezza dalle parti attive."
        "Definire intercettazione dell'attrezzatura, rilevazione gas, vie di fuga e DPI per la squadra."];
end
name = "";
T.contingencyAsset = strings(0, 1);
if ismember(asset, keys)
    name = names(keys == asset);
    T.contingencyAsset = byAsset(keys == asset);
end
end

function P = applyDefault(P, name, value)
if ~isfield(P, name) || isempty(P.(name)) || (isnumeric(P.(name)) && any(isnan(P.(name))))
    P.(name) = value;
end
end

function mustBePositiveParam(P, names)
for n = names
    if P.(n) <= 0
        error("simulift:invalidParameter", "Il parametro %s deve essere > 0.", n);
    end
end
end

function s = esito(alarm)
if alarm
    s = "ALLARME";
else
    s = "ok";
end
end
