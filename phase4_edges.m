function phase4_edges(img_gray)

% apply sobel edge detection
img_sobel = edge(img_gray, 'sobel');

% show results
figure
subplot(1,2,1)
imshow(img_gray)
title('Original')

subplot(1,2,2)
imshow(img_sobel)
title('Sobel Edge Detection')

end