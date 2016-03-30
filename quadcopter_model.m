clear;
load 'references.mat';

% Data
m = 0.5;
L = 0.25;
k = 3 * 10^(-6);
b = 1 * 10^(-7);
g = 9.81;
k_d = 0.25;
Ixx = 5 * 10^(-3);
Iyy = 5 * 10^(-3);
Izz = 1 * 10^(-2);
c_m = 1 * 10^(4);

% System Sizes
nx = 12;    % Nb of states
nu = 4;     % Nb of inputs
ny = 6;     % Nb of outputs

% Inputs at equilbrium point (all states 0)
u_eq = g*m/(4*k*c_m);

%**********************************************
% Construction of the linear state space model
%***********************************************
% Given 12 functions f_i in nx + nu variables
% The entries of A are the derivatives of these functions in state
% variables x_i and the entries of B are the derivatives of f_i in the input
% variables u_i

% symbolic variables
syms x y z v_x v_y v_z phi theta psi w_x w_y w_z u1 u2 u3 u4
% state vector
state = [x y z v_x v_y v_z phi theta psi w_x w_y w_z];

% The functions f:
f1 = v_x;
f2 = v_y;
f3 = v_z;

f4 = -k_d/m * v_x + k*c_m/m *(sin(psi)*sin(phi)+cos(psi)*cos(phi)*sin(theta))*(u1+u2+u3+u4);
f5 = -k_d/m * v_y + k*c_m/m *(cos(phi)*sin(psi)*sin(theta)-cos(psi)*sin(phi))*(u1+u2+u3+u4);
f6 = -k_d/m * v_z - g + k*c_m/m *(cos(theta)*cos(phi))*(u1+u2+u3+u4);

f7 = w_x + w_y*(sin(phi)*tan(theta)) + w_z*(cos(phi)*tan(theta));
f8 = w_y*cos(phi) - w_z*sin(phi);
f9 = sin(phi)/cos(theta) *w_y + cos(phi)/cos(theta) * w_z;

f10 = L*k*c_m/Ixx * (u1-u3) - (Iyy-Izz)/Ixx * w_y*w_z;
f11 = L*k*c_m/Iyy * (u2-u4) - (Izz-Ixx)/Iyy * w_x*w_z;
f12 = b*c_m/Izz * (u1-u2+u3-u4) - (Ixx-Iyy)/Izz * w_y*w_x;

% Deriving the functions in the state variables (Jacobian)
J = jacobian([f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12]', state);
 
% Evaluating the jacobian in the equilibrium values: the result is A
A = subs(J,[x,y,z,v_x,v_y,v_z,phi,theta,psi,w_x,w_y,w_z,u1,u2,u3,u4],[0,0,0, 0,0,0, 0,0,0, 0,0,0, u_eq, u_eq, u_eq, u_eq]);
A = double(A);


% Deriving the functions in the input variables
J = jacobian([f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12]', [u1 u2 u3 u4]);

% Evaluating the derivatives in the equilibrium values: the result is B
B = subs(J, [x,y,z,v_x,v_y,v_z,phi,theta,psi,w_x,w_y,w_z,u1,u2,u3,u4],[0,0,0, 0,0,0, 0,0,0, 0,0,0, u_eq,u_eq,u_eq,u_eq ]);
B = double(B);

% The output consists of states 1 to 3 and 7 to 9, so C selects these and D
% is zero
C = [eye(3), zeros(3,9);
     zeros(3,6), eye(3), zeros(3,3)];
D = zeros(ny,nu);

% Creating the continuous time system
c_sys = ss(A,B,C,D);

%************************
%Checking the stability
%************************
disp('Poles:')
disp(eig(A))

% Plotting the location of the poles
pzmap(c_sys);

% Step response
figure;
step(c_sys,Tmax)

% Impulse response
figure;
impulse(c_sys,Tmax)

%****************************************************
% Checking whether the system is controlable or not.
%****************************************************

disp ('Controllability matrix');

CO = ctrb(A,B);

disp('Rank of the controllability matrix:');
rank(CO)

%****************************************************
% Checking whether the system is observable or not.
%****************************************************

disp ('Observability matrix');

OB = obsv(A,C);

disp('Rank of the observability matrix:');
rank(OB)

%****************************************************
% Transmission zeros
%****************************************************
disp(tzero(c_sys))
