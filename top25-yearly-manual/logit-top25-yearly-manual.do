*** Description: Logit model.
*** - 1) choose setup (market size, instruments, characteristics)
*** - 2) estimation (only demand side)
*** - 3) MC recovery
*** INCOMPLETE - 4) prepare data for counterfactual analysis in Matlab

********************************************************************************

cd "/Users/Anna/Dropbox/IO field paper/Data"
use "complete/complete-top25-yearly-manual.dta", clear


*** 1) choose setup


* CHOOSE PERIOD
drop if year<2013
drop if price==.
replace price=price/1000

* CHOOSE MARKET SIZE
// M has to be more than 1.5 mil
local M=7000000
gen share=quantity/`M'
bysort  year:egen sumshare=sum(share)
gen logshare=log(share)-log(1-sumshare)

* CHOOSE PRICE or ADJUSTED PRICE
local price "price"
*local price "price_adj"

* CHOOSE EXOGENOUS VARIABLES
* choose exogenous characteristics
local exog_char "engine horsepower fuelcons clearance trunk russia" 
*local exog_char "fuelcons trunk russia horsepower"
local brandlist ""
* choose base category for brand
local brand "brand7"
qui ds brand1-brand16
local brandlist=r(varlist)
local brandlist : list brandlist-brand


local time ""
* choose time trends or time dummies
*local time "y2014-y2017"
*local time "time"



local exog "`exog_char' `time' `brandlist'"

** CHOOSE TYPE OF INSTRUMENTS
* BLP instruments
* CHOOSE INSTRUMENTAL VARIABLES
local charlist "engine horsepower fuelcons clearance trunk"
local iv ""
foreach chara of local charlist {
	bysort year: egen `chara'_yr=total(`chara')
	bysort year firm: egen `chara'_fm=total(`chara')
	gen `chara'_iv=`chara'_yr-`chara'_fm
	qui replace `chara'_fm=`chara'_fm-`chara'
	// choose type of exogenous variables
	local iv "`iv' `chara'_iv"
	*local iv "`iv' `chara'_fm"
}


* Gandhi-Houde instruments
* cost side instruments (exchange rate, price inflations, characteristics)



//??????
**egen brand_id=group(brand) 


*** 2) estimation

ivregress 2sls logshare (`price'=`iv') `exog'
// get alpha for 3)
local alpha=_b[`price']
// get delta0 for counterfactuals in Matlab
predict delta0
// calculate elasticities
gen el=`alpha'*(1-share)*`price'


*** 3) MC recovery


sort year firm brand model

//gen unique id for each model in a year
by year: gen id=[_n]

gen tilde_share=share/(1+tariff)
gen tilde_price=`price'/(1+tariff)
******* What if we were using adjusted prices?

// generate "matrix" of shares
forval j=1/25 {
	gen share`j'=.	
	qui by year: replace share`j'=share[`j']
}

// generate Delta "matrix"
forval j=1/25 {
	gen delta`j'=0
	by year: replace delta`j'=(firm==firm[`j'])
	qui replace delta`j'=-`alpha'*share*(1-share) if id==`j'
	qui replace delta`j'=`alpha'*share`j'*share if delta`j'==1&id!=`j'
	*by year: gen el`j'=-delta`j'*price[id==`j']/share
	*** IF BACK -- PUT ALPHA BACK
}

// calculates markups in Mata
forval j=2013/2017 {
	putmata Delta=(delta1-delta25) if year==`j', replace
	putmata s=tilde_share if year==`j', replace
	mata res`j'=luinv(Delta)*s
	if `j'==2013 mata res=res`j'
	if `j'>2013 mata res=res\res`j'
}

getmata markup_pure=res, replace
drop delta1-delta25 share1-share25
gen mc=tilde_price-markup
gen margins=markup/price
gen lnmc=log(mc)


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


*gmm	(supply: price - {supply:`exog' _cons} - ss*exp(-{a=1})), derivative(/supply=-1) derivative(/a=-ss*exp({a})) instruments(`exog' `iv')
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

