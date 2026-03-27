function phase1_analysis(img_color, img_gray)

% show original and grayscale images
figure
subplot(2,2,1)
imshow(img_color)
title('Original Image')

subplot(2,2,2)
imshow(img_gray)
title('Grayscale Image')

% show histogram
subplot(2,2,3)
imhist(img_gray)
title('Histogram')

% calculate basic statistics
mean_val = mean(double(img_gray(:)));
std_val = std(double(img_gray(:)));
min_val = min(double(img_gray(:)));
max_val = max(double(img_gray(:)));

% print statistics
fprintf('Mean : %.2f\n', mean_val)
fprintf('Std  : %.2f\n', std_val)
fprintf('Min  : %.0f\n', min_val)
fprintf('Max  : %.0f\n', max_val)

end