classdef test_simulift_rigging < matlab.unittest.TestCase
    % Verifica simulift_rigging (due punti di presa, gancio singolo) con
    % casi a soluzione analitica nota. Dati generici.

    methods (Test)
        function symmetricLoadIsLevel(tc)
            % Carico 6 m, baricentro al centro, prese a 1 m e 5 m, tiranti 3 m.
            % Angolo dalla verticale: asin(2/3); tiro = W / (2 cos(beta)).
            G = simulift_rigging(1000, tc.geo(3, 1, 5, 3, 3));
            beta = asind(2/3);
            tc.verifyEqual(G.Tilt_deg, 0, "AbsTol", 1e-9);
            tc.verifyEqual(G.Angle_deg, [beta beta], "AbsTol", 1e-9);
            tc.verifyEqual(G.Tension_kg, 1000/(2*cosd(beta)) * [1 1], "RelTol", 1e-12);
            tc.verifyTrue(G.Balanced);
            tc.verifyEqual(G.Verdict, "OK");
        end

        function offCentreCoGTiltsTheLoad(tc)
            % Baricentro spostato di 0.5 m, tiranti uguali: il gancio sta
            % sulla mezzeria delle prese, quindi tan(tilt) = e / h.
            G = simulift_rigging(1000, tc.geo(3.5, 1, 5, 3, 3));
            h = sqrt(3^2 - 2^2);
            tc.verifyEqual(G.Tilt_deg, atand(0.5/h), "AbsTol", 1e-9);
            tc.verifyFalse(G.Balanced);
            tc.verifyTrue(G.TiltAlarm);
            tc.verifyEqual(G.Verdict, "DA RIVEDERE");
            tc.verifyEqual(G.LowSide, "lato punto di presa 2");   % il lato piu' pesante scende
            tc.verifyGreaterThan(G.Tension_kg(2), G.Tension_kg(1));
        end

        function forcesAreInEquilibrium(tc)
            % Risultante dei tiri = peso, e momento nullo attorno al baricentro.
            G = simulift_rigging(2500, tc.geo(2.2, 0.5, 5.5, 3.2, 4.0, 0.3));
            W = G.World;
            u1 = (W.Hook - W.Pick1) / norm(W.Hook - W.Pick1);
            u2 = (W.Hook - W.Pick2) / norm(W.Hook - W.Pick2);
            F = G.Tension_kg(1)*u1 + G.Tension_kg(2)*u2;
            tc.verifyEqual(F, [0 2500], "AbsTol", 1e-8);
            r1 = W.Pick1 - W.CoG;
            r2 = W.Pick2 - W.CoG;
            M = G.Tension_kg(1)*(r1(1)*u1(2) - r1(2)*u1(1)) + ...
                G.Tension_kg(2)*(r2(1)*u2(2) - r2(2)*u2(1));
            tc.verifyEqual(M, 0, "AbsTol", 1e-8);
            tc.verifyEqual(W.CoG(1), W.Hook(1), "AbsTol", 1e-9);   % baricentro sotto il gancio
        end

        function suggestionsLevelTheLoad(tc)
            g = tc.geo(3.5, 1, 5, 3, 3);
            G = simulift_rigging(1000, g);
            s = G.Suggestion;
            % 1) punti di presa simmetrici rispetto al baricentro, tiranti uguali
            g1 = g; g1.Pick1_m = s.Pick1_m; g1.Pick2_m = s.Pick2_m;
            g1.Leg1_m = s.Leg_m; g1.Leg2_m = s.Leg_m;
            tc.verifyEqual(simulift_rigging(1000, g1).Tilt_deg, 0, "AbsTol", 1e-9);
            tc.verifyEqual(s.Pick1_m + s.Pick2_m, 2*3.5, "AbsTol", 1e-12);
            % 2) punti di presa attuali, tiranti di lunghezza diversa
            g2 = g; g2.Leg1_m = s.LevelLeg1_m; g2.Leg2_m = s.LevelLeg2_m;
            tc.verifyEqual(simulift_rigging(1000, g2).Tilt_deg, 0, "AbsTol", 1e-9);
        end

        function angleAndWllAlarms(tc)
            G = simulift_rigging(1000, tc.geo(3, 0.5, 5.5, 2.6, 2.6));   % tiranti corti
            tc.verifyGreaterThan(G.Angle_deg(1), 60);
            tc.verifyTrue(G.AngleAlarm);
            G = simulift_rigging(1000, tc.geo(3, 1, 5, 3, 3), WLL_kg=600);
            tc.verifyTrue(G.WllAlarm);                     % 670.8 kg per tirante > 600
            G = simulift_rigging(1000, tc.geo(3, 1, 5, 3, 3), WLL_kg=700);
            tc.verifyFalse(G.WllAlarm);
        end

        function invalidGeometry(tc)
            tc.verifyError(@() simulift_rigging(1000, tc.geo(0.5, 1, 5, 3, 3)), "simulift:unstable");
            tc.verifyError(@() simulift_rigging(1000, tc.geo(3, 5, 1, 3, 3)), "simulift:invalidParameter");
            tc.verifyError(@() simulift_rigging(1000, tc.geo(3, 1, 5, 1, 1)), "simulift:invalidParameter");
            tc.verifyError(@() simulift_rigging(1000, struct("Length_m", 6)), "simulift:missingParameter");
        end

        function englishTexts(tc)
            G = simulift_rigging(1000, tc.geo(3.5, 1, 5, 3, 3), Language="en");
            tc.verifyEqual(G.Verdict, "TO BE REVISED");
            tc.verifyEqual(G.Table.Grandezza(1), "Load tilt");
        end
    end

    methods (Static)
        function g = geo(xg, x1, x2, l1, l2, depth)
            if nargin < 6
                depth = 0;
            end
            g = struct("Length_m", 6, "CoG_x_m", xg, "CoG_depth_m", depth, ...
                "Pick1_m", x1, "Pick2_m", x2, "Leg1_m", l1, "Leg2_m", l2);
        end
    end
end
