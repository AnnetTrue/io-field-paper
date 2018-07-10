function [f,df] = gmmobjg(theta2)
% This function computes the GMM objective function


%%% Description:
%%% - 1) takes parameter values as given
%%% - 2) predicts associated delta 
%%% - 3) IV regresses delta on x1 and gets 
%%% - 4) use contraction mapping to predicts
%%% - 5) calculates GMM objective as xi*instruments.
%%% - 6) if needed uses jacobian to calculate standard errors (?)

% Written by Aviv Nevo, May 1998.
% Modified by Bronwyn Hall, April 2005, to add gradient.
% Modified by Cristian Hernandez, October 2017, to add (back) storage of the GMM residuals


global invA theta1 theti thetj x1 IV
% 2)
delta = meanval(theta2); %%% FUNCTION meanval

% the following deals with cases were the min algorithm drifts into region where the objective is not defined
if max(isnan(delta)) == 1
	f = 1e+10	   
else
    % 3)
    temp1 = x1'*IV;
    temp2 = delta'*IV;
    theta1 = inv(temp1*invA*temp1')*temp1*invA*temp2';
    clear temp1 temp2 
    % 4)
    gmmresid = delta - x1*theta1;
    save gmmresid gmmresid          % Added by Cristian Hernandez
	% 5)
    temp1 = gmmresid'*IV;
	f1 = temp1*invA*temp1';
    f = f1;
    clear temp1
    % 6)
    if nargout>1
        load mvalold
        temp = jacob(mvalold,theta2)'; %%% FUNCTION jacob
        df = 2*temp*IV*invA*IV'*gmmresid
    end
end

disp(['GMM objective:  ' num2str(f1)])





