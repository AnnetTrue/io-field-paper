function f = mktsh(mval, expmu)
% This function computes the market share for each product

%%% Description:
%%% - calculates individual shares implied by mu_jt, u_ijt
%%% - averages across individuals

% Written by Aviv Nevo, May 1998.

global ns 
f = sum((ind_sh(mval,expmu))')/ns; % FUNCTION ind_sh
f = f';