% Copyright 2016 Elgiz Baskaya

% This file is part of curedRone.

% curedRone is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% curedRone is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with curedRone.  If not, see <http://www.gnu.org/licenses/>.

% This code reduces the dimension of the feature space to selected reduced
% dimension utilizing PCA (Principle Componenent Analysis)

% Number of class
K = 2;

feature_vec = sensor_sim_out';
output_vec = faultLabel;

X = feature_vec;

% Subtract the mean to use PCA
[X_norm, mu, sigma] = featureNormalize(X);

% PCA and project the data to 2D
[U, S] = pca(X_norm);
Z = projectData(X_norm, U, 2);

% %  Setup Color Palette
% palette = hsv(K);
% colors = palette(output_vec, :);

gscatter(Z(:,1), Z(:,2),output_vec)
legend('normal','fault')
xlabel('z_1')
ylabel('z_2')
set(gca,'FontSize',16)
print -depsc2 reduceDimMeasurements.eps