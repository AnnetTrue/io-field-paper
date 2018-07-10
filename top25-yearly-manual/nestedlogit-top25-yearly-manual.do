*** Description: Nested Logit model.
*** - 1) choose setup (market size, instruments, characteristics)
*** - 2) estimation (only demand side)
*** - 3) MC recovery
*** - 4) prepare data for counterfactual analysis in Matlab

********************************************************************************

cd "/Users/Anna/Documents/IO field paper/Data"
use "complete/complete-top25-yearly-manual.dta", clear

*** 1) choose setup

* CHOOSE PERIOD
drop if year<2013
drop if price==.

* CHOOSE MARKET SIZE
// M has to be more than 1.5 mil
local M=10000000
gen share=quantity/`M'
bysort  year:egen sumshare=sum(share)
gen logshare=log(share)-log(1-sumshare)

* CHOOSE PRICE or ADJUSTED PRICE
local price "price"
*local price "price_adj"

* CHOOSE GROUPING
local group_var "national"
// generate log-share for nested logit
bysort year `group_var': egen share_group=sum(share)
gen share_ingroup=share/share_group
gen logshare_ingroup=log(share_ingroup)

* CHOOSE EXOGENOUS VARIABLES
* choose exogenous characteristics
local exog_char "engine horsepower fuelcons clearance trunk russia" 

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


** CHOOSE INSTRUMENTS

* CHOOSE TYPE OF INSTRUMENTS for prices
* BLP instruments
* CHOOSE INSTRUMENTAL VARIABLES
local charlist "engine horsepower fuelcons clearance trunk"
local iv ""
foreach chara of local charlist {
	bysort year: egen `chara'_yr=total(`chara')
	bysort year firm: egen `chara'_fm=total(`chara')
	gen `chara'_iv=`chara'_yr-`chara'_fm
	qui replace `chara'_fm=`chara'_fm-`chara'
	local iv "`iv' `chara'_iv"
}

* Gandhi-Houde instruments
* cost side instruments (exchange rate, price inflations, characteristics)

* CHOOSE INSTRUMENTS for ingroup shares
local charlist "engine horsepower fuelcons clearance trunk"
foreach chara of local charlist {
	bysort year `group_var': egen `chara'_gp=total(`chara')
	gen `chara'_iv_gp=`chara'_yr-`chara'_gp-`chara'
	qui replace `chara'_gp=`chara'_gp-`chara'
	local iv "`iv' `chara'_gp"
}

*** 2) estimation
ivregress 2sls logshare (`price' logshare_ingroup=`iv') `exog'
local alpha=_b[`price']
local delta=_b[logshare_ingroup]
gen el=-`alpha'*(1-share)*`price' // CHANGE

*** 3) MC recovery
sort year firm brand model

by year: gen id=[_n]
forval j=1/25 {
	gen share`j'=.	
	qui by year: replace share`j'=share[`j']
}

*********** CHANGE DELTA MATRIX FOR NESTED LOGIT
forval j=1/25 {
	gen delta`j'=0
	* change brand to firm producing brand
	by year: replace delta`j'=(firm==firm[`j'])
	qui replace delta`j'=-`alpha'/(1-`delta')*share*(1-share_ingroup*`delta'- (1-`delta')*share) if id==`j'
	qui replace delta`j'=`alpha'/(1-`delta')*share`j'*(share_ingroup*`delta'+share*(1-`delta')) if delta`j'==1&id!=`j'&`group_var'==`group_var'[`j']
	qui replace delta`j'=`alpha'*share*share`j' if delta`j'==1&`group_var'!=`group_var'[`j']
	*by year: gen el`j'=-delta`j'*price[id==`j']/share
}


forval j=2013/2017 {
	putmata Delta=(delta1-delta25) if year==`j', replace
	putmata s=share if year==`j', replace
	mata res`j'=luinv(Delta)*s
	if `j'==2013 mata res=res`j'
	if `j'>2013 mata res=res\res`j'
}

getmata markup=res, replace
gen mc=price-markup
gen margins=markup/price

*** 4) counterfactual in Matlab

* CHOOSE COUNTERFACTUAL TARIFF
gen counter_tariff=0
replace counter_tariff=0.3 if !russia


*export delimited using "do files/top25-yearly-manual/matlab/top25-yearly-manual.csv", replace



****
ivregress 2sls logshare (`price' logshare_ingroup=`iv') `exog'
