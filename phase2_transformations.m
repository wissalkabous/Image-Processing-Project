function phase2_transformations(img_gray)

% convert to double for math operations
img = double(img_gray) / 255;

% gamma correction (gamma < 1 = brighter, gamma > 1 = darker)
gamma = 0.5;
img_gamma = img .^ gamma;

% logarithmic transformation (brightens dark areas)
img_log = log(1 + img);
img_log = img_log / max(img_log(:));

% exponential transformation (darkens bright areas)
img_exp = exp(img) - 1;
img_exp = img_exp / max(img_exp(:));

% show results
figure
subplot(2,2,1)
imshow(img)
title('Original')

subplot(2,2,2)
imshow(img_gamma)
title('Gamma Correction (0.5)')

subplot(2,2,3)
imshow(img_log)
title('Log Transformation')

subplot(2,2,4)
imshow(img_exp)
title('Exp Transformation')

end