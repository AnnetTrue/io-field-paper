*** 4) counterfactual in Matlab

* CHOOSE COUNTERFACTUAL TARIFF
gen counter_tariff=0
replace counter_tariff=0.3 if !russia


*export delimited using "do files/top25-yearly-manual/matlab/top25-yearly-manual.csv", replace

***** Just for now, for easy reporting


*gmm (demand: logshare - {demand:`price' `exog' _cons}), instruments(`exog' `iv') derivative(/demand=-1) 
*gmm (demand: logshare - {demand:`price' `exog' _cons}), instruments(`exog' `iv') 
*gmm	(supply: price - {supply:`exog' _cons} - markup_pure/{a=100000}), derivative(/supply=-1) derivative(/a=markup_pure/{a}^2) instruments(`exog' `iv')
*gmm	(supply: price - {supply:`exog' _cons} - markup_pure*{a}), derivative(/supply=-1) derivative(/a=markup_pure) instruments(`exog' `iv')

*gmm	(supply: log(price - markup_pure*{a=-1}) - {supply:`exog' _cons} ), derivative(/supply=-1) derivative(/a=markup_pure) instruments(`exog' `iv')


gmm	(supply: price - {supply:`exog' _cons} - ss*exp(-{a=1})), derivative(/supply=-1) derivative(/a=-ss*exp({a})) instruments(`exog' `iv')
*gmm	(supply: price - {supply:`exog' _cons} - ss*{a}), derivative(/supply=-1) derivative(/a=-ss) instruments(`exog' `iv')
	
	
*gmm	(demand: logshare - [a]*price - {demand: `exog' _cons}) ///
*	(supply: price - {supply: `exog' _cons}- [a=-1]/(1-share))) ///
*	, instruments(`exog' `iv') 
	
	
local llist "`price' `exog' _cons"
local paramlist ""
foreach ll of local llist{
local paramlist "`paramlist' demand:`ll'"
}

*gmm demand, neq(1) param(`paramlist') instruments(`exog' `iv') haslfderivatives twostep

	
 *ivregress 2sls logshare (`price'=`iv') `exog'

 
 
 /*
local exog_ss "russia_prod_alt weight length engine horsepower fuelcons trunk rating wheelbase body_SUV body_hatch"
local charlist "horsepower fuelcons trunk wheelbase body_SUV body_hatch"
di "`charlist'"
local iv "russia_prod_alt weight length engine"
foreach chara of local charlist {
	// choose type of exogenous variables
	local iv_ss "`iv' `chara'_iv"
	*local iv "`iv' `chara'_fm"
}
gmm	(supply: tilde_price - {supply:`exog_ss' _cons} + markup_pure/{a=0.005}), derivative(/supply=-1) derivative(/a=ss/{a}^2) instruments(`exog_ss' `iv_ss')

gmm	(supply: tilde_price + markup_pure/{a=0.005}- {supply:`exog_ss' _cons} ) ///
	(demand: logshare - {demand:`exog_dm' _cons} + {a=0.005}*`price') ///
	, instruments(demand:`exog' `iv') instruments(supply:`exog_ss' `iv_ss') ///
    derivative(supply /supply=-1) derivative(supply /a=markup_pure/{a}^2) ///
	 derivative(demand /demand=-1) derivative(demand /a=price) ///
	 winitial(identity)
