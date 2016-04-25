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

% FORCE AND MOMENT CALCULATION

function force_moment = calcForceMoment(state, control_deflections, eng_speed, wind_ned)

global g_e mass wing_tot_surf wing_span m_wing_chord prop_dia cl_alpha1 cl_ele1 cl_p 
global cl_r cl_beta cm_1 cm_alpha1 cm_ele1 cm_q cm_alpha cn_rud_contr cn_r_tilda cn_beta cx1 
global cx_alpha cx_alpha2 cx_beta2 cz_alpha cz1 cy1 cft1 cft2 cft3
% q .:. quaternion
% q = q0 + q1 * i + q2 * j + q3 * k;  
q0 = state(1);
q1 = state(2);
q2 = state(3);
q3 = state(4);

% w .:. angular velocity vector with components p, q, r
% w = [p q r]' 
% w describes the angular motion of the body frame b with respect to
% navigation frame ned, expressed in body frame.
p = state(5);
q = state(6);
r = state(7);

% x .:. position of the drone in North East Down reference frame
% x = [x_n y_e z_d]';
% x_n = state_init(8);
% y_e = state_init(9);
% z_d = state_init(10);

% v .:. translational velocity of the drone
% v = [u_b v_b w_b]
u_b = state(11);
v_b = state(12);
w_b = state(13);

con_ail1 = control_deflections(1);
con_ail2 = control_deflections(2);
con_ele1 = control_deflections(3);
con_ele2 = control_deflections(4);
con_rud  = control_deflections(5);

% Flight condition 
altitude = state(10); % altitude

% Direction cosine matrix C^b_n representing the transformation from
% the navigation frame to the body frame
c_n_to_b = [1 - 2 * (q2^2 + q3^2) 2 * (q1 * q2 + q0 * q3) 2 * (q1 * q3 - q0 * q2); ...
2 * (q1 * q2 - q0 * q3) 1 - 2 * (q1^2 + q3^2) 2 * (q2 * q3 + q0 * q1); ...
2 * (q1 * q3 + q0 * q2) 2 * (q2 * q3 - q0 * q1) 1 - 2 * (q1^2 + q2^2)];

vel_t = [u_b; v_b; w_b] - c_n_to_b * wind_ned;

% Total airspeed of drone
vt = sqrt(vel_t(1)^2 + vel_t(2)^2 + vel_t(3)^2);

% alph .:. angle of attack
alph = atan2(vel_t(3),vel_t(1));

% bet .:. side slip angle
bet  = asin(vel_t(2)/vt);

% Low altitude atmosphere model (valid up to 11 km)
% t0 = 288.15; % Temperature [K]
% a_ = - 6.5e-3; % [K/m]
% r_ = 287.3; % [m^2/K/s^2] 
% p0 = 1013e2; %[N/m^2]
% t_= t0 * (1 + a_ * altitude / t0);
% ro = p0 * (1 + a_ * altitute /t0)^5.2561 / r_ / t_;
t_ = 288.15 * (1 - 6.5e-3 * altitude / 288.15);
ro = 1013e2 * (1 - 6.5e-3 * altitude / 288.15)^5.2561 / 287.3 / t_;
dyn_pressure = ro * vt^2 / 2;

p_tilda = wing_span * p / 2 / vt;
r_tilda = wing_span * r / 2 / vt;
q_tilda = m_wing_chord * q / 2 / vt;

% calculation of aerodynamic derivatives
% (In the equations % CLalpha2 = - CLalpha1 and so on used not to inject new names to namespace)
cl = cl_alpha1 * con_ail1 - cl_alpha1 * con_ail2 + cl_ele1 * con_ele1 - cl_ele1 * con_ele2 ...
+ cl_p * p_tilda + cl_r * r_tilda + cl_beta * bet;
cm = cm_1 + cm_alpha1 * con_ail1 + cm_alpha1 * con_ail2 + cm_ele1 * con_ele1 + cm_ele1 * con_ele2 ...
+ cm_q * q_tilda + cm_alpha * alph;
cn = cn_rud_contr * con_rud + cn_r_tilda * r_tilda + cn_beta * bet;

l = dyn_pressure * wing_tot_surf * wing_span * cl;
m = dyn_pressure * wing_tot_surf * m_wing_chord * cm;
n = dyn_pressure * wing_tot_surf * wing_span * cn;

moment = [l m n]';

[pisi teta fi] = quat2angle([q0 q1 q2 q3]);

% ft .:. thrust force 
ft = ro * eng_speed^2 * prop_dia^4 * (cft1 + cft2 * vt / prop_dia / pi / eng_speed + ...
									  cft3 * vt^2 / prop_dia^2 / pi^2 / eng_speed^2);
% Model of the aerodynamic forces in wind frame
% xf_w .:. drag force in wind frame
xf_w = dyn_pressure * wing_tot_surf * (cx1 + cx_alpha * alph + cx_alpha2 * alph^2 + ...
									   cx_beta2 * bet^2);
% yf_w .:. lateral force in wind frame
yf_w = dyn_pressure * wing_tot_surf * (cy1 * bet);
% zf_w .:. lift force in wind frame
zf_w = dyn_pressure * wing_tot_surf * (cz1 + cz_alpha * alph);

% describe forces in body frame utilizing rotation matrix c^w_b
% A^w = C^w_b * A^b     OR     A^b = C^b_w * A^w = (C^w_b)' * A^w  here
% c_b_to_w = C^w_b
c_b_to_w = [cos(alph)* cos(bet) sin(bet) sin(alph) * cos(bet);...
-sin(bet) * cos(alph) cos(bet) -sin(alph) * sin(bet); -sin(alph) 0 cos(alph)];

force = mass * [- g_e * sin(teta); g_e * sin(fi) * cos(teta); g_e * cos(fi) * cos(teta)] +...
    ([ft; 0; 0] + c_b_to_w' * [xf_w; yf_w; zf_w]);
force_moment = [force; moment];
