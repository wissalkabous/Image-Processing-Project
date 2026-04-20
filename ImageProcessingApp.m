classdef ImageProcessingApp < matlab.apps.AppBase

    % ================================================================
    %  ImageProcessingApp - Application de Traitement d'Image
    %  Projet TI - Module ADIA/IISE S2
    % ================================================================

    properties (Access = public)
        UIFigure            matlab.ui.Figure %main app window.

        % --- Panneau gauche : contrôles ---
        PanneauControles    matlab.ui.container.Panel
        BtnCharger          matlab.ui.control.Button
        LabelPhase          matlab.ui.control.Label
        DDPhase             matlab.ui.control.DropDown
        LabelGamma          matlab.ui.control.Label
        SliderGamma         matlab.ui.control.Slider
        LabelGammaVal       matlab.ui.control.Label
        DDTransfo           matlab.ui.control.DropDown
        BtnAppliquer        matlab.ui.control.Button
        BtnReset            matlab.ui.control.Button

        % --- Panneau stats ---
        PanneauStats        matlab.ui.container.Panel
        TextStats           matlab.ui.control.TextArea

        % --- Panneau principal : axes ---
        PanneauImages       matlab.ui.container.Panel
        AxOriginal          matlab.ui.control.UIAxes
        AxResultat          matlab.ui.control.UIAxes
        AxHistoOrig         matlab.ui.control.UIAxes
        AxHistoRes          matlab.ui.control.UIAxes

        % --- Barre de statut ---
        LabelStatut         matlab.ui.control.Label
    end

    properties (Access = private)
        img_color   % image couleur originale
        img_gray    % image niveaux de gris
        img_result  % image résultat courant
        cheminFichier string
    end

    % ================================================================
    %  UTILITAIRES INTERNES
    % ================================================================
    methods (Access = private)

        % ---- Afficher histogramme dans un UIAxes (remplace imhist) ------
        function afficherHisto(app, ax, img, titre)
            % img doit etre uint8 ou double [0,1]
            cla(ax);  % effacer l'axe

            if isa(img, 'double') || isa(img, 'single')
                img = uint8(img * 255);
            end
            counts = histcounts(double(img(:)), 0:256);
            bar(ax, 0:255, counts, 1, 'FaceColor', [0.3 0.6 1], 'EdgeColor', 'none');
            ax.XLim = [0 255];
            ax.Color = [0.10 0.11 0.15];
            ax.XColor = [0.7 0.7 0.7];
            ax.YColor = [0.7 0.7 0.7];
            xlabel(ax, 'Intensité');
            ylabel(ax, 'Pixels');
            title(ax, titre, 'Color', [1 1 1]);
        end

        % ---- Afficher une ligne de seuil sur l'histogramme (Phase 5:OTSU --------------
        function ajouterLigneSeuil(app, ax, seuil_pixel)
            hold(ax, 'on'); % tracé sue l"axe sans effacer l'hist
            xline(ax, seuil_pixel, 'r-', ... % r: rouge 
                sprintf('Seuil=%d', seuil_pixel), ... % affiche "Seuil=128"
                'LineWidth', 2, ...
                'LabelHorizontalAlignment', 'right', ...
                'Color', [1 0.2 0.2]);
            hold(ax, 'off');
        end

        % ---- Mettre à jour le panneau statistiques ----------------------
        function majStats(app, img)
            d = double(img(:));
            txt = { ...
                '=== Statistiques ===', ...
                sprintf('Moyenne   : %.2f', mean(d)), ...
                sprintf('Ecart-type: %.2f', std(d)), ...
                sprintf('Min       : %.0f', min(d)), ...
                sprintf('Max       : %.0f', max(d)), ...
                sprintf('Taille    : %dx%d px', size(img,1), size(img,2)) ... % lignes et colonnes 
            };
            app.TextStats.Value = txt;  % affiche dans le panneau stats
        end

        % ---- Barre de statut -------------------------------------------
        function setStatut(app, msg)
            app.LabelStatut.Text = msg;
        end
    end

    % ================================================================
    %  CALLBACKS
    % ================================================================
    methods (Access = private)

        % ---- Charger une image ------------------------------------------
        function BtnChargerPushed(app, ~)
            [fichier, dossier] = uigetfile( ...
                {'*.jpg;*.jpeg;*.jfif;*.png;*.bmp;*.tif;*.tiff', ...
                 'Images (*.jpg,*.png,*.bmp,*.tif,*.jfif)'}, ...
                'Choisir une image');
            if isequal(fichier, 0), return; end % si l'utilisateur annule → rien

            app.cheminFichier = fullfile(dossier, fichier);
            raw = imread(app.cheminFichier);

            % Gérer les images en niveaux de gris déjà
            if size(raw, 3) == 3
                app.img_color = raw;
                app.img_gray  = rgb2gray(raw);
            else
                app.img_color = cat(3, raw, raw, raw);
                app.img_gray  = raw;
            end
            app.img_result = app.img_gray;

            % Afficher image originale
            imshow(app.img_color, 'Parent', app.AxOriginal);
            title(app.AxOriginal, 'Image Originale', 'Color', [1 1 1]);

            % Histogramme original
            app.afficherHisto(app.AxHistoOrig, app.img_gray, 'Histogramme Original');

            % Vider résultat
            cla(app.AxResultat);
            cla(app.AxHistoRes);

            app.majStats(app.img_gray);
            app.setStatut(sprintf('Image chargée : %s', fichier));
        end

        % ---- Appliquer la phase sélectionnée ----------------------------
        function BtnAppliquerPushed(app, ~)
            if isempty(app.img_gray)
                app.setStatut(' Veuillez d''abord charger une image !!!');
                return;
            end
            phase = app.DDPhase.Value;
            switch phase
                case 'Phase 1 – Analyse'
                    app.appliquerPhase1();
                case 'Phase 2 – Transformations'
                    app.appliquerPhase2();
                case 'Phase 3 – Contraste'
                    app.appliquerPhase3();
                case 'Phase 4 – Contours Sobel'
                    app.appliquerPhase4();
                case 'Phase 5 – Segmentation OTSU'
                    app.appliquerPhase5();
            end
        end

        % ---- Reset ------------------------------------------------------
        function BtnResetPushed(app, ~)
            if isempty(app.img_gray), return; end
            imshow(app.img_gray, 'Parent', app.AxResultat);
            title(app.AxResultat, 'Image Gris (reset)', 'Color', [1 1 1]);
            app.afficherHisto(app.AxHistoRes, app.img_gray, 'Histogramme');
            app.majStats(app.img_gray);
            app.setStatut('Reset effectué.');
        end

        % ---- Slider gamma -----------------------------------------------
        function SliderGammaValueChanged(app, ~)
            app.LabelGammaVal.Text = sprintf('%.2f', app.SliderGamma.Value);
        end

        % ---- Changement de phase ----------------------------------------
        function DDPhaseValueChanged(app, ~)
            visible = strcmp(app.DDPhase.Value, 'Phase 2 – Transformations');
            if visible
                app.LabelGamma.Visible    = 'on';
                app.SliderGamma.Visible   = 'on';
                app.LabelGammaVal.Visible = 'on';
                app.DDTransfo.Visible     = 'on';
            else
                app.LabelGamma.Visible    = 'off';
                app.SliderGamma.Visible   = 'off';
                app.LabelGammaVal.Visible = 'off';
                app.DDTransfo.Visible     = 'off'; 
            end
        end
    end

    % ================================================================
    %  PHASES
    % ================================================================
    methods (Access = private)

        % ---- Phase 1 : Analyse ------------------------------------------
        function appliquerPhase1(app)
            imshow(app.img_gray, 'Parent', app.AxResultat);
            title(app.AxResultat, 'Image en Niveaux de Gris', 'Color', [1 1 1]);
            app.afficherHisto(app.AxHistoRes, app.img_gray, 'Histogramme Gris');
            app.majStats(app.img_gray);
            app.setStatut('Phase 1 : Analyse terminée.');
        end

        % ---- Phase 2 : Transformations non linéaires --------------------
        function appliquerPhase2(app)
            img   = double(app.img_gray) / 255;
            gamma = app.SliderGamma.Value;

            img_gamma = img .^ gamma;
            img_log   = log(1 + img);  img_log = img_log / max(img_log(:));
            img_exp   = exp(img) - 1;  img_exp = img_exp / max(img_exp(:));

            % Résultat = gamma dans l'app

            % Dans appliquerPhase2(), remplace l'imshow par :
            switch app.DDTransfo.Value
                case 'Gamma'
                    imshow(img_gamma, 'Parent', app.AxResultat);
                    app.afficherHisto(app.AxHistoRes, img_gamma, 'Histogramme Gamma');
                    app.img_result = uint8(img_gamma * 255);
                    title(app.AxResultat, sprintf('Gamma (γ = %.2f)', gamma), 'Color', [1 1 1]);

                case 'Log'
                    imshow(img_log, 'Parent', app.AxResultat);
                    app.afficherHisto(app.AxHistoRes, img_log, 'Histogramme Log');
                    app.img_result = uint8(img_log * 255);
                    title(app.AxResultat, 'Transformation Log', 'Color', [1 1 1]);

                case 'Exp'
                    imshow(img_exp, 'Parent', app.AxResultat);
                    app.afficherHisto(app.AxHistoRes, img_exp, 'Histogramme Exp');
                    app.img_result = uint8(img_exp * 255);
                    title(app.AxResultat, 'Transformation Exp', 'Color', [1 1 1]);
            end

            app.majStats(app.img_result); 
            app.setStatut(sprintf('Phase 2 : %s appliqué.', app.DDTransfo.Value));

            % Figure externe : comparaison des 3
            %figure('Name', 'Phase 2 – Transformations', 'NumberTitle', 'off');
            %subplot(1,3,1); imshow(img_gamma); title(sprintf('Gamma (%.2f)', gamma));
            %subplot(1,3,2); imshow(img_log);   title('Log');
            %subplot(1,3,3); imshow(img_exp);   title('Exp');
            %sgtitle('Phase 2 : Transformations Non Linéaires');

        end

        % ---- Phase 3 : Contraste ----------------------------------------
        function appliquerPhase3(app)
            img = double(app.img_gray);
            img_stretched = uint8((img - min(img(:))) / (max(img(:)) - min(img(:))) * 255);
            img_eq = histeq(app.img_gray);

            % Afficher égalisation dans l'app
            imshow(img_eq, 'Parent', app.AxResultat);
            title(app.AxResultat, 'Égalisation d''Histogramme', 'Color', [1 1 1]);
            app.afficherHisto(app.AxHistoRes, img_eq, 'Histogramme Égalisé');

            app.img_result = img_eq;
            app.majStats(img_eq);

            % Figure externe comparative
            %figure('Name', 'Phase 3 – Contraste', 'NumberTitle', 'off');
            %subplot(2,3,1); imshow(app.img_gray);   title('Original');
            %subplot(2,3,2); imshow(img_stretched);   title('Étirement Linéaire');
            %subplot(2,3,3); imshow(img_eq);          title('Égalisation');
            %subplot(2,3,4); imhist(app.img_gray);    title('Histo Original');
            %subplot(2,3,5); imhist(img_stretched);   title('Histo Étiré');
            %subplot(2,3,6); imhist(img_eq);          title('Histo Égalisé');
            %sgtitle('Phase 3 : Amélioration du Contraste');

            app.setStatut('Phase 3 : Contraste amélioré.');
        end

        % ---- Phase 4 : Contours Sobel -----------------------------------
        function appliquerPhase4(app)
            img_sobel = edge(app.img_gray, 'sobel');

            imshow(img_sobel, 'Parent', app.AxResultat);
            title(app.AxResultat, 'Contours – Filtre Sobel', 'Color', [1 1 1]);

            % Histogramme binaire via bar directement
            nb_fond    = sum(~img_sobel(:));
            nb_contour = sum(img_sobel(:));
            cla(app.AxHistoRes);
            bar(app.AxHistoRes, [0 1], [nb_fond nb_contour], ...
                'FaceColor', [0.3 0.6 1], 'EdgeColor', 'none');
            app.AxHistoRes.XTick = [0 1];
            app.AxHistoRes.XTickLabel = {'Fond', 'Contour'};
            app.AxHistoRes.Color  = [0.10 0.11 0.15];
            app.AxHistoRes.XColor = [0.7 0.7 0.7];
            app.AxHistoRes.YColor = [0.7 0.7 0.7];
            ylabel(app.AxHistoRes, 'Nombre de pixels');
            title(app.AxHistoRes, 'Distribution Pixels', 'Color', [1 1 1]);

            app.img_result = uint8(img_sobel * 255);
            app.majStats(app.img_result);
            app.setStatut('Phase 4 : Détection Sobel terminée.');
        end

        % ---- Phase 5 : Segmentation OTSU  (votre partie) ----------------
        function appliquerPhase5(app)
            % Calcul du seuil optimal OTSU
            niveau_otsu = graythresh(app.img_gray);
            seuil_pixel = round(niveau_otsu * 255);

            % Binarisation
            img_binaire = imbinarize(app.img_gray, niveau_otsu);

            % Affichage dans l'app
            imshow(img_binaire, 'Parent', app.AxResultat);
            title(app.AxResultat, ...
                sprintf('Segmentation OTSU  –  Seuil = %d', seuil_pixel), ...
                'Color', [1 1 1]);

            % Histogramme + ligne de seuil
            app.afficherHisto(app.AxHistoRes, app.img_gray, 'Histogramme + Seuil OTSU');
            app.ajouterLigneSeuil(app.AxHistoRes, seuil_pixel);

            % Statistiques OTSU
            nb_total   = numel(img_binaire);
            nb_objets  = sum(img_binaire(:));
            nb_fond    = nb_total - nb_objets;
            pct_objets = nb_objets / nb_total * 100;
            pct_fond   = nb_fond   / nb_total * 100;

            txt = { ...
                '=== Phase 5 – OTSU ===', ...
                sprintf('Seuil OTSU    : %d / 255', seuil_pixel), ...
                sprintf('Niveau normalisé: %.4f', niveau_otsu), ...
                sprintf('Pixels objets : %d', nb_objets), ...
                sprintf('             (%.1f%%)', pct_objets), ...
                sprintf('Pixels fond   : %d', nb_fond), ...
                sprintf('             (%.1f%%)', pct_fond) ...
            };
            app.TextStats.Value = txt;

            % Figure externe détaillée
            %figure('Name', 'Phase 5 – Segmentation OTSU', 'NumberTitle', 'off');

            %subplot(2,3,1);
            %imshow(app.img_gray);
            %title('Original (Gris)');

            %subplot(2,3,2);
            %imshow(img_binaire);
            %title(sprintf('OTSU (seuil=%d)', seuil_pixel));

            %contours = edge(img_binaire, 'sobel');
            %img_overlay = app.img_gray;
            %img_overlay(contours) = 255;
            %subplot(2,3,3);
            %imshow(img_overlay);
            %title('Contours sur Original');

            %subplot(2,3,4);
           % imhist(app.img_gray);
            %hold on;
            %xline(seuil_pixel, 'r-', sprintf('Seuil=%d', seuil_pixel), ...
            %    'LineWidth', 2, 'LabelHorizontalAlignment', 'right');
            %hold off;
            %title('Histogramme + Seuil OTSU');

            %img_objets = app.img_gray; img_objets(~img_binaire) = 0;
            %subplot(2,3,5);
            %imshow(img_objets);
            %title('Région Objets');

            %img_fond_img = app.img_gray; img_fond_img(img_binaire) = 0;
            %subplot(2,3,6);
            %imshow(img_fond_img);
            %title('Région Fond');

            %sgtitle('Phase 5 : Segmentation OTSU', ...
            %    'FontSize', 13, 'FontWeight', 'bold');
%
            app.img_result = uint8(img_binaire * 255);
            app.setStatut(sprintf('Phase 5 : OTSU appliqué – seuil = %d.', seuil_pixel));
        end
    end

    % ================================================================
    %  CREATION DE L'INTERFACE
    % ================================================================
    methods (Access = private)

        function createComponents(app)

            % --- Fenêtre principale ---
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [50 50 1200 700];
            app.UIFigure.Name = 'Traitement d''Image – Projet TI';
            app.UIFigure.Color = [0.13 0.14 0.18];

            % ============================================================
            %  PANNEAU GAUCHE : contrôles (250 px)
            % ============================================================
            app.PanneauControles = uipanel(app.UIFigure);
            app.PanneauControles.Position = [10 10 230 680];
            app.PanneauControles.Title = ' Contrôles';
            app.PanneauControles.BackgroundColor = [0.18 0.20 0.26];
            app.PanneauControles.ForegroundColor = [1 1 1];
            app.PanneauControles.FontSize = 13;
            app.PanneauControles.FontWeight = 'bold';

            % Bouton Charger
            app.BtnCharger = uibutton(app.PanneauControles, 'push');
            app.BtnCharger.Position = [15 620 200 35];
            app.BtnCharger.Text = '📂 Charger une Image';
            app.BtnCharger.FontSize = 12;
            app.BtnCharger.FontWeight = 'bold';
            app.BtnCharger.BackgroundColor = [0.20 0.55 0.90];
            app.BtnCharger.FontColor = [1 1 1];
            app.BtnCharger.ButtonPushedFcn = createCallbackFcn(app, @BtnChargerPushed, true);

            % Label phase
            app.LabelPhase = uilabel(app.PanneauControles);
            app.LabelPhase.Position = [15 578 200 22];
            app.LabelPhase.Text = 'Sélectionner une phase :';
            app.LabelPhase.FontColor = [0.85 0.85 0.85];
            app.LabelPhase.FontSize = 11;

            % Dropdown phases
            app.DDPhase = uidropdown(app.PanneauControles);
            app.DDPhase.Position = [15 548 200 28];
            app.DDPhase.Items = { ...
                'Phase 1 – Analyse', ...
                'Phase 2 – Transformations', ...
                'Phase 3 – Contraste', ...
                'Phase 4 – Contours Sobel', ...
                'Phase 5 – Segmentation OTSU'};
            app.DDPhase.Value = 'Phase 1 – Analyse';
            app.DDPhase.FontSize = 11;
            app.DDPhase.ValueChangedFcn = createCallbackFcn(app, @DDPhaseValueChanged, true);

            % Slider Gamma (visible seulement phase 2)
            app.LabelGamma = uilabel(app.PanneauControles);
            app.LabelGamma.Position = [15 508 120 22];
            app.LabelGamma.Text = 'Gamma (γ) :';
            app.LabelGamma.FontColor = [0.85 0.85 0.85];
            app.LabelGamma.FontSize = 11;
            app.LabelGamma.Visible = 'off';

            app.LabelGammaVal = uilabel(app.PanneauControles);
            app.LabelGammaVal.Position = [155 508 55 22];
            app.LabelGammaVal.Text = '0.50';
            app.LabelGammaVal.FontColor = [1 0.8 0.2];
            app.LabelGammaVal.FontSize = 12;
            app.LabelGammaVal.FontWeight = 'bold';
            app.LabelGammaVal.Visible = 'off';

            app.SliderGamma = uislider(app.PanneauControles);
            app.SliderGamma.Position = [15 495 200 3];
            app.SliderGamma.Limits = [0.1 3.0];
            app.SliderGamma.Value = 0.5;
            app.SliderGamma.MajorTicks = [0.1 1.0 2.0 3.0];
            app.SliderGamma.Visible = 'off';
            app.SliderGamma.ValueChangedFcn = createCallbackFcn(app, @SliderGammaValueChanged, true);

            % Dropdown transformation (visible seulement phase 2)
            app.DDTransfo = uidropdown(app.PanneauControles);
            app.DDTransfo.Position = [15 460 200 28];
            app.DDTransfo.Items = {'Gamma', 'Log', 'Exp'};
            app.DDTransfo.Value = 'Gamma';
            app.DDTransfo.FontSize = 11;
            app.DDTransfo.Visible = 'off';

            % Bouton Appliquer
            app.BtnAppliquer = uibutton(app.PanneauControles, 'push');
            app.BtnAppliquer.Position = [15 420 200 35];
            app.BtnAppliquer.Text = '▶  Appliquer';
            app.BtnAppliquer.FontSize = 13;
            app.BtnAppliquer.FontWeight = 'bold';
            app.BtnAppliquer.BackgroundColor = [0.15 0.72 0.45];
            app.BtnAppliquer.FontColor = [1 1 1];
            app.BtnAppliquer.ButtonPushedFcn = createCallbackFcn(app, @BtnAppliquerPushed, true);

            % Bouton Reset
            app.BtnReset = uibutton(app.PanneauControles, 'push');
            app.BtnReset.Position = [15 375 200 35];
            app.BtnReset.Text = '↺  Reset';
            app.BtnReset.FontSize = 12;
            app.BtnReset.BackgroundColor = [0.70 0.25 0.25];
            app.BtnReset.FontColor = [1 1 1];
            app.BtnReset.ButtonPushedFcn = createCallbackFcn(app, @BtnResetPushed, true);

            % ---- Panneau Statistiques ---
            app.PanneauStats = uipanel(app.PanneauControles);
            app.PanneauStats.Position = [10 10 210 345];
            app.PanneauStats.Title = ' Statistiques';
            app.PanneauStats.BackgroundColor = [0.15 0.16 0.22];
            app.PanneauStats.ForegroundColor = [0.8 0.9 1];
            app.PanneauStats.FontSize = 11;

            app.TextStats = uitextarea(app.PanneauStats);
            app.TextStats.Position = [5 5 200 310];
            app.TextStats.Value = {'Chargez une image', 'puis appliquez', 'une phase.'};
            app.TextStats.FontSize = 11;
            app.TextStats.FontName = 'Courier New';
            app.TextStats.BackgroundColor = [0.12 0.13 0.18];
            app.TextStats.FontColor = [0.5 1 0.6];
            app.TextStats.Editable = 'off';

            % ============================================================
            %  PANNEAU DROITE : 4 axes
            % ============================================================
            app.PanneauImages = uipanel(app.UIFigure);
            app.PanneauImages.Position = [250 40 940 650];
            app.PanneauImages.Title = ' Visualisation';
            app.PanneauImages.BackgroundColor = [0.15 0.16 0.22];
            app.PanneauImages.ForegroundColor = [1 1 1];
            app.PanneauImages.FontSize = 13;
            app.PanneauImages.FontWeight = 'bold';

            % Axe image originale (haut gauche)
            app.AxOriginal = uiaxes(app.PanneauImages);
            app.AxOriginal.Position = [10 330 450 300];
            app.AxOriginal.Color = [0.10 0.11 0.15];
            app.AxOriginal.XColor = [0.6 0.6 0.6];
            app.AxOriginal.YColor = [0.6 0.6 0.6];
            title(app.AxOriginal, 'Image Originale', 'Color', [1 1 1]);

            % Axe image résultat (haut droite)
            app.AxResultat = uiaxes(app.PanneauImages);
            app.AxResultat.Position = [475 330 450 300];
            app.AxResultat.Color = [0.10 0.11 0.15];
            app.AxResultat.XColor = [0.6 0.6 0.6];
            app.AxResultat.YColor = [0.6 0.6 0.6];
            title(app.AxResultat, 'Résultat', 'Color', [1 1 1]);

            % Axe histogramme original (bas gauche)
            app.AxHistoOrig = uiaxes(app.PanneauImages);
            app.AxHistoOrig.Position = [10 20 450 290];
            app.AxHistoOrig.Color = [0.10 0.11 0.15];
            app.AxHistoOrig.XColor = [0.7 0.7 0.7];
            app.AxHistoOrig.YColor = [0.7 0.7 0.7];
            title(app.AxHistoOrig, 'Histogramme Original', 'Color', [1 1 1]);

            % Axe histogramme résultat (bas droite)
            app.AxHistoRes = uiaxes(app.PanneauImages);
            app.AxHistoRes.Position = [475 20 450 290];
            app.AxHistoRes.Color = [0.10 0.11 0.15];
            app.AxHistoRes.XColor = [0.7 0.7 0.7];
            app.AxHistoRes.YColor = [0.7 0.7 0.7];
            title(app.AxHistoRes, 'Histogramme Résultat', 'Color', [1 1 1]);

            % ---- Barre de statut ---
            app.LabelStatut = uilabel(app.UIFigure);
            app.LabelStatut.Position = [10 10 1180 25];
            app.LabelStatut.Text = 'Prêt – Chargez une image pour commencer.';
            app.LabelStatut.FontSize = 11;
            app.LabelStatut.FontColor = [0.7 0.8 1];
            app.LabelStatut.BackgroundColor = [0.15 0.16 0.22];

            app.UIFigure.Visible = 'on';
        end
    end

    % ================================================================
    %  CONSTRUCTEUR
    % ================================================================
    methods (Access = public)
        function app = ImageProcessingApp
            createComponents(app);
            registerApp(app, app.UIFigure);
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure);
        end
    end
end
