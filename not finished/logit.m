%% preparation
clear;
clc;

global mc Delta_merge1 Delta_merge2 j merger lns alpha p

load('ps2.mat');
load('iv.mat');

ns = 20;       % number of simulated "indviduals" per market %
nmkt = 94;     % number of markets = (# of cities)*(# of quarters)  %
nbrn = 24;     % number of brands per market. if the number differs by market% 
               % this requires some "accounting" vector %
% this vector relates each observation to the market it is in %
market = kron([1:nmkt]',ones(nbrn,1));    
mktindex = [nbrn:nbrn:nbrn*nmkt]';      

% market block-diagonal matrix
A = ones(24);                                         % Original Matrix (Created)
N = 94;                                                  % Number Of Times To Repeat
Ar = repmat(A, 1, N);                                   % Repeat Matrix
Ac = mat2cell(Ar, size(A,1), repmat(size(A,2),1,N));    % Create Cell Array Of Orignal Repeated Matrix
marketMat = blkdiag(Ac{:});  

% compute the outside good market share by market
temp = cumsum(s_jt);
sum1 = temp(mktindex,:);
sum1(2:size(sum1,1),:) = diff(sum1);
outshr = 1.0 - sum1(market,:);

% other variables
X1=full(x1);
p=X1(:,1);
const=ones(2256, 1);
lns=log(s_jt)-log(outshr);

% create auxiliary matrix for computing Delta matrix, that shows which
% products belong to one firm.
firm = (id - mod(id, 10^8)) / 10^8;
firmMat=zeros(2256);
for i=1:6
    firmMat=firmMat+(firm==i)'.*(firm==i);
end
% create auxiliary brand matrix for calculating mean variables over brands
brand=(id - mod(id, 10^5)) / 10^5;
brandMat=kron(ones(94,1), eye(24));
%% OLS and IV
OLS=ols(lns, [p, const], 1);
OLS_brand=ols(lns,[X1, const], 1);
IV=regressIV(lns, p, const,iv(:, 2:21),1);
IV_brand=regressIV(lns, X1(:, 1), X1(:, 2:25),iv(:, 2:21),1);
alpha=-IV_brand.b(1);
est=IV_brand.b;

%% pre merger
Delta_aux1=diag(-alpha*(1-s_jt).*s_jt);
Delta_aux2=alpha*s_jt'.*s_jt;
Delta=-(Delta_aux1+Delta_aux2.*(ones(2256)-eye(2256))); %Delta matrix

Delta_pre=Delta.*firmMat.*marketMat; % Delta matrix for given market structure
markup=inv(Delta_pre)*s_jt;
mc=p-markup;
margin=(p-mc)./p;
markupMat=reshape(markup, [24, 94]);
mcMat=reshape(mc, [24,94]);
marginMat=reshape(margin, [24,94]);
pMat=reshape(p, [24,94]);
table1=latex([(1:24)', mean(pMat*100,2), mean(markupMat*100,2), median(markupMat*100,2), std(markupMat*100,0,2), mean(marginMat*100,2), median(marginMat*100,2), std(marginMat*100,0,2), mean(mcMat*100,2), median(mcMat*100,2), std(mcMat*100,0,2)],'%i', '%.2f', '%.2f','%.2f','%.2f','%.2f','%.2f','%.2f','%.2f','%.2f','%.2f', 'nomath');

%% post merger
% first we recalculate auxilliary matrix for Delta
firm_merge1=firm.*(firm~=6)+3*ones(2256, 1).*(firm==6);
firmMat_merge1=zeros(2256);
for i=1:6
    firmMat_merge1=firmMat_merge1+(firm_merge1==i)'.*(firm_merge1==i); 
end

Delta_merge1=Delta.*firmMat_merge1.*marketMat;

firm_merge2=firm.*(firm~=4)+2*ones(2256, 1).*(firm==4);
firmMat_merge2=zeros(2256);
for i=1:6
    firmMat_merge2=firmMat_merge2+(firm_merge2==i)'.*(firm_merge2==i); 
end

Delta_merge2=Delta.*firmMat_merge2.*marketMat;

%% Now we start predicting post-merger prices and quantities
p_merge1=zeros(2256, 1);
options=optimoptions('fmincon', 'Display', 'notify');
merger=1;
for k=1:94
    k
    j=1+24*(k-1);
p_merge1(j:(j+23), 1)=fmincon(@obj3, p(j:(j+23), 1),[],[],[] ,[],zeros(24,1), ones(24, 1),[], options);
end

change_p1=(p_merge1-p)./p;
change_pMat1=reshape(change_p1, [24, 94]);
share_merge1=share(p_merge1);
change_s1=(share_merge1-s_jt)./s_jt;
change_sMat1=reshape(change_s1, [24, 94]);


