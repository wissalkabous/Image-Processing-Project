function phase5_segmentation(img_gray)
% PHASE 5 - Segmentation et Seuillage par la méthode OTSU
% La méthode OTSU calcule automatiquement le seuil optimal
% qui maximise la variance inter-classes (objets vs fond).

% --- Calcul du seuil OTSU ---
% graythresh retourne un seuil normalisé entre 0 et 1
niveau_otsu = graythresh(img_gray);
seuil_pixel = round(niveau_otsu * 255);

fprintf('=== Segmentation OTSU ===\n');
fprintf('Seuil OTSU calcule : %.4f (valeur pixel : %d)\n', niveau_otsu, seuil_pixel);

% --- Application du seuil : binarisation ---
img_binaire = imbinarize(img_gray, niveau_otsu);

% --- Calcul des statistiques de segmentation ---
nb_pixels_total  = numel(img_binaire);
nb_pixels_objets = sum(img_binaire(:));              % pixels blancs (objets)
nb_pixels_fond   = nb_pixels_total - nb_pixels_objets; % pixels noirs (fond)
pct_objets = nb_pixels_objets / nb_pixels_total * 100;
pct_fond   = nb_pixels_fond   / nb_pixels_total * 100;

fprintf('Pixels objets (blancs) : %d (%.1f%%)\n', nb_pixels_objets, pct_objets);
fprintf('Pixels fond   (noirs)  : %d (%.1f%%)\n', nb_pixels_fond,   pct_fond);

% --- Affichage des résultats ---
figure('Name', 'Phase 5 - Segmentation OTSU', 'NumberTitle', 'off');

% Image originale
subplot(2, 3, 1);
imshow(img_gray);
title('Image Originale (Niveaux de gris)', 'FontWeight', 'bold');

% Image binarisée OTSU
subplot(2, 3, 2);
imshow(img_binaire);
title(sprintf('Segmentation OTSU (seuil = %d)', seuil_pixel), 'FontWeight', 'bold');

% Superposition : contours sur l'image originale
contours = edge(img_binaire, 'sobel');
img_overlay = img_gray;
img_overlay(contours) = 255;   % marquer les contours en blanc
subplot(2, 3, 3);
imshow(img_overlay);
title('Contours sur Image Originale', 'FontWeight', 'bold');

% Histogramme avec ligne de seuil OTSU
subplot(2, 3, 4);
imhist(img_gray);
hold on;
xline(seuil_pixel, 'r-', sprintf('Seuil = %d', seuil_pixel), ...
      'LineWidth', 2, 'LabelHorizontalAlignment', 'right');
hold off;
title('Histogramme + Seuil OTSU', 'FontWeight', 'bold');
xlabel('Intensite'); ylabel('Nombre de pixels');

% Région objets uniquement
subplot(2, 3, 5);
img_objets = img_gray;
img_objets(~img_binaire) = 0;
imshow(img_objets);
title('Region Objets (avant-plan)', 'FontWeight', 'bold');

% Région fond uniquement
subplot(2, 3, 6);
img_fond = img_gray;
img_fond(img_binaire) = 0;
imshow(img_fond);
title('Region Fond (arriere-plan)', 'FontWeight', 'bold');

sgtitle('Phase 5 : Segmentation et Seuillage - Methode OTSU', ...
        'FontSize', 13, 'FontWeight', 'bold');

end
