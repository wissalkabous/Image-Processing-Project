function phase3_contrast(img_gray)

% convert to double
img = double(img_gray);

% linear stretching (spreads pixel values from 0 to 255)
img_stretched = (img - min(img(:))) / (max(img(:)) - min(img(:))) * 255;
img_stretched = uint8(img_stretched);

% histogram equalization (auto improves contrast)
img_eq = histeq(img_gray);

% show results
figure
subplot(2,3,1)
imshow(img_gray)
title('Original')

subplot(2,3,2)
imshow(img_stretched)
title('Linear Stretching')

subplot(2,3,3)
imshow(img_eq)
title('Histogram Equalization')

subplot(2,3,4)
imhist(img_gray)
title('Original Histogram')

subplot(2,3,5)
imhist(img_stretched)
title('Stretched Histogram')

subplot(2,3,6)
imhist(img_eq)
title('Equalized Histogram')

end