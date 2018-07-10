%% preparation
clear;
clc;

%cd '/Users/Anna/Documents/IO field paper/raw'
%addpath('do files/top25-yearly-manual')

raw = readtable('top25-yearly-manual.csv');

%% Setup and raw
N=size(raw, 1);
n.brn = 25;
n.mkt = 5;     


const=ones(N, 1);

share=raw.share;
logshare=raw.logshare;
price=raw.price;
logshare_ingroup=raw.logshare_ingroup;
share_ingroup=raw.share_ingroup;

exogvars={'engine', 'horsepower', 'fuelcons', 'clearance', 'trunk', 'russia'};
brandlist={'brand1', 'brand2', 'brand3', 'brand4', 'brand5','brand7', 'brand8', 'brand9', 'brand10', 'brand11', 'brand12', 'brand13', 'brand14', 'brand15', 'brand16'};

exog=[raw{:,exogvars}, raw{:,brandlist}];

ivvars={'engine_iv', 'horsepower_iv', 'fuelcons_iv', 'clearance_iv', 'trunk_iv'};
ivvars2={'engine_gp', 'horsepower_gp', 'fuelcons_gp', 'clearance_gp', 'trunk_gp'};
iv=[raw{:, ivvars},raw{:, ivvars2}];


IV=regressIV(logshare, [price, logshare_ingroup], [const, exog],iv,0);
alpha=-IV.b(1);
delta=IV.b(2);
cntr.alpha=-IV.b(1);

%% calculate mc

A = ones(n.brn);                                         % Original Matrix (Created)                                             % Number Of Times To Repeat
Ar = repmat(A, 1, n.mkt);                                   % Repeat Matrix
Ac = mat2cell(Ar, size(A,1), repmat(size(A,2),1,n.mkt));    % Create Cell Array Of Orignal Repeated Matrix
Mat_market = blkdiag(Ac{:}); 

firm=raw.firm_id;
Mat_firm=zeros(N);
for i=1:max(firm)
    Mat_firm=Mat_firm+(firm==i)'.*(firm==i);
end

group=raw.national;
Mat_group=zeros(N);
for i=1:max(group)
    Mat_group=Mat_group + (group==i)'.*(group==i);
end

Delta_aux1=diag(-alpha/(1-delta)*share.*(1-share_ingroup*delta-(1-delta)*share));
Delta_aux2=alpha/(1-delta)*share'.*(share_ingroup*delta+(1-delta)*share);
Delta_aux3=alpha*share'.*share;
Delta=-(Delta_aux1+Delta_aux2.*(ones(N)-eye(N)).*Mat_group + Delta_aux3.*(ones(N)-Mat_group)); %Delta matrix

Delta=Delta.*Mat_firm.*Mat_market; % Delta matrix for given market structure

clear A Ar Ac Delta_aux1 Delta_aux2 Delta_aux3

tariff=raw.tariff;
share_tilde=share./(1+tariff);
price_tilde=price./(1+tariff);

markup=inv(Delta)*share_tilde;
mc=price_tilde-markup;
margin=(price-mc)./price;

markupMat=reshape(markup, [n.brn, n.mkt]);
mcMat=reshape(mc, [n.brn,n.mkt]);
marginMat=reshape(margin, [n.brn,n.mkt]);
pMat=reshape(price, [n.brn,n.mkt]);
%table1=latex([(1:n.brn)', mean(pMat,2), mean(markupMat*100,2), median(markupMat*100,2), std(markupMat*100,0,2), mean(marginMat*100,2), median(marginMat*100,2), std(marginMat*100,0,2), mean(mcMat*100,2), median(mcMat*100,2), std(mcMat*100,0,2)],'%i', '%.2f', '%.2f','%.2f','%.2f','%.2f','%.2f','%.2f','%.2f','%.2f','%.2f', 'nomath');


%% counterfactual

price_counter=zeros(N, 1);
%options=optimoptions('fmincon', 'Display', 'notify');

options=optimoptions('fsolve', 'Display', 'iter')
for k=1:n.mkt
    k
    j=1+n.brn*(k-1);
    jend=j+n.brn-1;
    
    cntr.mc=mc(j:jend,1);
    cntr.Delta=Delta(j:jend, j:jend);
    cntr.delta0=logshare(j:jend, 1);
    cntr.tariff=zeros(n.brn,1);
    %cntr.tariff=tariff(j:jend, 1);
    cntr.price0=price(j:jend,1);
    cntr.share=share(j:jend,1);
    
    f=@(x)obj3(x, cntr);

    %price_counter(j:jend, 1)=fmincon(f, ones(n.brn,1)*10000, [],[],[],[],zeros(n.brn,1), [],[], options);
    price_counter(j:jend, 1)=fsolve(f, ones(n.brn,1), options);
    
    f_opt(j:jend, 1)=f(price_counter(j:jend,1));
end


change_p=(price_counter-price)./price;
change_pMat=reshape(change_p, [n.brn, n.mkt]);

expdelta=exp(logshare+alpha*(price_counter-price));
summ=expdelta'*kron(eye(n.mkt), ones(n.brn, 1));
share_merge=expdelta./(ones(N, 1)+kron(summ', ones(n.brn, 1)));


change_s=(share_merge-share)./share;
change_sMat=reshape(change_s, [n.brn, n.mkt]);



