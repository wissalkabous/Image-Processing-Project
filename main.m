clear all;
close all;
clc;
% load the image
img_color = imread('images/view.jfif');
img_gray = rgb2gray(img_color);

% run phase 1
phase1_analysis(img_color, img_gray);

% run phase 2
phase2_transformations(img_gray);

% run phase 3
phase3_contrast(img_gray);

% run phase 4
phase4_edges(img_gray);