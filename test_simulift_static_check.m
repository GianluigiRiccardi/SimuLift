classdef test_simulift_static_check < matlab.unittest.TestCase
    % Regressione del nucleo di calcolo SimuLift sul dataset generico di
    % default (carico 1000 kg, bozzello 360 kg, imbracature 100 kg, SF 1.25,
    % caduta 10 m, deformazione 0.2 m, Beaufort 3, area 3 m^2, portata 7500 kg).

    methods (Test)
        function defaultDataset(tc)
            R = simulift_static_check(tc.defaults());
            tc.verifyEqual(R.TotalMass_kg, 1460);
            tc.verifyEqual(R.WeightForce_N, 14322.6, "RelTol", 1e-9);
            tc.verifyEqual(R.DesignMass_kg, 1825);
            tc.verifyEqual(R.OverloadMargin_kg, 5675);      % in kg, non in N
            tc.verifyFalse(R.OverloadAlarm);
            tc.verifyEqual(R.WindSpeed_ms, 5.4);
            tc.verifyEqual(R.WindForce_N, 0.5*1.225*5.4^2*3, "RelTol", 1e-12);
            tc.verifyFalse(R.WindAlarm);
            tc.verifyEqual(R.ImpactForce_N, 716130, "RelTol", 1e-9);
            tc.verifyTrue(R.ImpactAlarm);
            tc.verifyEqual(R.Verdict, "LIFT DENIED");       % per il solo scenario di caduta
        end

        function impactExcludedFromVerdict(tc)
            R = simulift_static_check(tc.defaults(), IncludeImpactInVerdict=false);
            tc.verifyTrue(R.ImpactAlarm);
            tc.verifyEqual(R.Verdict, "SAFE TO LIFT");
        end

        function overloadAlarm(tc)
            P = tc.defaults();
            P.Crane_Capacity = 1800;                        % < 1825 kg di progetto
            R = simulift_static_check(P, IncludeImpactInVerdict=false);
            tc.verifyTrue(R.OverloadAlarm);
            tc.verifyEqual(R.Verdict, "LIFT DENIED");
        end

        function beaufortTableIncludesGrade8(tc)
            P = tc.defaults();
            P.Beaufort_scale = 8;
            R = simulift_static_check(P);
            tc.verifyEqual(R.WindSpeed_ms, 20.7);
            P.Beaufort_scale = 9;
            R = simulift_static_check(P);
            tc.verifyEqual(R.WindSpeed_ms, 24.4);
        end

        function slingCheck(tc)
            P = tc.defaults();
            P.Sling_legs = 2;
            P.Sling_angle_deg = 60;
            P.Sling_WLL_kg = 1200;
            R = simulift_static_check(P, IncludeImpactInVerdict=false);
            tc.verifyEqual(R.SlingLegLoad_kg, 1000, "RelTol", 1e-12);   % 1000/(2 cos 60)
            tc.verifyFalse(R.SlingAlarm);
            P.Sling_WLL_kg = 900;
            R = simulift_static_check(P, IncludeImpactInVerdict=false);
            tc.verifyTrue(R.SlingAlarm);
            tc.verifyEqual(R.Verdict, "LIFT DENIED");
        end

        function slingNotCheckedByDefault(tc)
            R = simulift_static_check(tc.defaults());
            tc.verifyFalse(R.SlingChecked);
            tc.verifyFalse(R.SlingAlarm);
        end

        function invalidInputs(tc)
            P = tc.defaults();
            tc.verifyError(@() simulift_static_check(rmfield(P, "Drop_Height")), ...
                "simulift:missingParameter");
            P.Deformation_Limit = 0;
            tc.verifyError(@() simulift_static_check(P), "simulift:invalidParameter");
            P = tc.defaults();
            P.Beaufort_scale = 13;
            tc.verifyError(@() simulift_static_check(P), "simulift:invalidParameter");
        end

        % --- Criteri a regole al posto del calcolo d'urto ---

        function over500kgAboveLineNeedsContingency(tc)
            % Tubazione da 1000 kg sopra una linea benzina.
            R = simulift_static_check(tc.rules(1000, 7500), UnderlyingAsset="gasoline");
            tc.verifyFalse(R.GlobalAlarm);
            tc.verifyTrue(R.ContingencyRequired);
            tc.verifyEqual(R.Verdict, "LIFT WITH CONTINGENCY PLAN");
            tc.verifyEqual(R.ClassCode, "critical");
            tc.verifyEqual(R.Class, "CRITICO");
            tc.verifyEqual(R.AssetName, "linea benzina");
            tc.verifyEqual(numel(R.ClassReasons), 1);
            tc.verifyEqual(numel(R.ContingencyActions), 3);
        end

        function upTo500kgAboveLineIsOk(tc)
            R = simulift_static_check(tc.rules(500, 7500), UnderlyingAsset="gasoline");
            tc.verifyFalse(R.ContingencyRequired);              % soglia: > 500 kg
            tc.verifyEqual(R.Verdict, "SAFE TO LIFT");
            tc.verifyEqual(R.ClassCode, "standard");
            R = simulift_static_check(tc.rules(501, 7500), UnderlyingAsset="gasoline");
            tc.verifyTrue(R.ContingencyRequired);
        end

        function heavyLoadWithNothingBelowIsStandard(tc)
            R = simulift_static_check(tc.rules(1000, 7500), UnderlyingAsset="none");
            tc.verifyFalse(R.ContingencyRequired);
            tc.verifyEqual(R.Verdict, "SAFE TO LIFT");
            tc.verifyEqual(R.ClassCode, "standard");
            tc.verifyEmpty(R.ClassReasons);
        end

        function electricalOrToxicIsCriticalAtAnyMass(tc)
            for asset = ["electrical" "toxic"]
                R = simulift_static_check(tc.rules(100, 7500), UnderlyingAsset=asset);
                tc.verifyEqual(R.ClassCode, "critical");
                tc.verifyTrue(R.ContingencyRequired);
            end
        end

        function equipmentFlagsMakeItCritical(tc)
            R = simulift_static_check(tc.rules(100, 7500), UnderlyingAsset="none", ...
                SimultaneousEquipment=true);
            tc.verifyEqual(R.ClassCode, "critical");
            tc.verifyFalse(R.ContingencyRequired);              % critico, ma niente sotto
            tc.verifyEqual(R.Verdict, "SAFE TO LIFT");
            R = simulift_static_check(tc.rules(100, 7500), UnderlyingAsset="none", ...
                NonStandardEquipment=true);
            tc.verifyEqual(R.ClassCode, "critical");
        end

        function capacityRatioClasses(tc)
            % massa lorda = carico + 0 (bozzello e imbracature nulli nel test)
            cls = @(load_kg, cap_kg) simulift_static_check(tc.rules(load_kg, cap_kg, 0), ...
                UnderlyingAsset="none").ClassCode;
            tc.verifyEqual(cls(8000, 10000), "standard");       % 80%: non supera
            tc.verifyEqual(cls(8500, 10000), "nonstandard");    % > 80%
            tc.verifyEqual(cls(9100, 10000), "critical");       % > 90%
            tc.verifyEqual(cls(19000, 23000), "critical");      % > 18 t e > 80%
            tc.verifyEqual(cls(19000, 30000), "standard");      % > 18 t ma 63%
            tc.verifyEqual(cls(46000, 100000), "critical");     % > 45 t
        end

        % --- Analisi dei carichi con contingency sul peso (dati generici) ---

        function loadSummaryWithContingency(tc)
            % Peso 2000 kg, catene 100 kg, bozzello 300 kg, contingency 25%
            % del peso (500 kg): totale 2900 kg; portata 6000 kg: eccedenza
            % 3100 kg. Vento ammesso 14 m/s.
            P = struct("Theoretical_Weight", 2000, "Slings_weight", 100, ...
                "Pulley_weight", 300, "Contingency_pct", 25, ...
                "Crane_Capacity", 6000, "Beaufort_scale", 3);
            R = simulift_static_check(P, UnderlyingAsset="none", WindSpeedLimit_ms=14);
            tc.verifyEqual(R.Contingency_kg, 500);
            tc.verifyEqual(R.DesignMass_kg, 2900);
            tc.verifyEqual(R.OverloadMargin_kg, 3100);
            tc.verifyFalse(R.WindAlarm);                        % 5.4 m/s < 14 m/s
            tc.verifyEqual(R.Verdict, "SAFE TO LIFT");
            tc.verifyEqual(R.ClassCode, "standard");
            tc.verifyEqual(R.Table.Valore(R.Table.Grandezza == "TOTALE SOLLEVAMENTO"), 2900);
            tc.verifyEqual(R.Table.Valore(R.Table.Grandezza == "Eccedenza sollevabile"), 3100);
            tc.verifyEqual(height(R.Table), 9);
        end

        function boomGeometryIsDescriptive(tc)
            P = struct("Theoretical_Weight", 2000, "Slings_weight", 100, ...
                "Pulley_weight", 300, "Contingency_pct", 25, "Crane_Capacity", 6000, ...
                "Beaufort_scale", 3, "Boom_reach_m", 18, "Boom_angle_deg", 60);
            R = simulift_static_check(P, UnderlyingAsset="none", WindSpeedLimit_ms=14);
            tc.verifyEqual(R.BoomProjection_m, 9, "AbsTol", 1e-9);
            tc.verifyEqual(R.DesignMass_kg, 2900);              % la geometria non cambia le verifiche
            P.Boom_angle_deg = 90;
            tc.verifyError(@() simulift_static_check(P, UnderlyingAsset="none", ...
                WindSpeedLimit_ms=14), "simulift:invalidParameter");
        end

        function windCheckedAsSpeed(tc)
            P = struct("Theoretical_Weight", 2000, "Slings_weight", 100, ...
                "Pulley_weight", 300, "Contingency_pct", 25, ...
                "Crane_Capacity", 6000, "Beaufort_scale", 7);  % 17.1 m/s
            R = simulift_static_check(P, UnderlyingAsset="none", WindSpeedLimit_ms=14);
            tc.verifyTrue(R.WindAlarm);
            tc.verifyEqual(R.Verdict, "LIFT DENIED");
            P.Beaufort_scale = 6;                               % 13.8 m/s
            R = simulift_static_check(P, UnderlyingAsset="none", WindSpeedLimit_ms=14);
            tc.verifyFalse(R.WindAlarm);
        end

        function denialPrevailsOverContingency(tc)
            P = tc.rules(1000, 1400);                       % 1460 kg lordi > portata
            R = simulift_static_check(P, UnderlyingAsset="diesel", Language="en");
            tc.verifyTrue(R.ContingencyRequired);
            tc.verifyEqual(R.Verdict, "LIFT DENIED");
            tc.verifyEqual(R.Class, "CRITICAL");
            tc.verifyEqual(R.AssetName, "diesel line");
            tc.verifyEqual(R.Table.Grandezza(10), "Gross load / capacity (classification)");
        end

        function tableIsConsistent(tc)
            R = simulift_static_check(tc.defaults());
            tc.verifyEqual(height(R.Table), 10);
            tc.verifyEqual(R.Table.Valore(1), R.TotalMass_kg);
        end
    end

    methods (Static)
        function P = rules(load_kg, capacity_kg, rigging_kg)
            % Dati per la modalita' a regole: niente altezza di caduta ne'
            % deformazione. SF = 1 per isolare le soglie di classificazione.
            if nargin < 3
                rigging_kg = 460;                           % bozzello 360 + imbracature 100
            end
            P = struct("Theoretical_Weight", load_kg, "Pulley_weight", rigging_kg, ...
                "Slings_weight", 0, "Safety_factor", 1, "Beaufort_scale", 3, ...
                "Exposed_surface_area", 3, "Crane_Capacity", capacity_kg);
        end

        function P = defaults()
            P = struct("Theoretical_Weight", 1000, "Pulley_weight", 360, ...
                "Slings_weight", 100, "Safety_factor", 1.25, "Drop_Height", 10, ...
                "Deformation_Limit", 0.2, "Beaufort_scale", 3, ...
                "Exposed_surface_area", 3, "Crane_Capacity", 7500);
        end
    end
end
