*** Description: Nested Logit model.
*** - 1) choose setup (market size, instruments, characteristics)
*** - 2) estimation (only demand side)
*** - 3) MC recovery
*** - 4) prepare data for counterfactual analysis in Matlab

********************************************************************************

cd "/Users/Anna/Dropbox/IO field paper/Data"
use "complete/complete-top25-yearly.dta", clear

*** 1) choose setup

replace price=price/1000
replace price_adj=price_adj/1000

* CHOOSE MARKET SIZE
local yearlist ""
local yearlist "2013 2014 2015 2016 2017"
// M has to be more than 1.5 mil
local M2017=1465000+5300000
local M2016=1308000+5200000
local M2015=1482000+4900000
local M2014=2316000+6000000
local M2013=2584000+5660000

local M=7000000
local M1=6500000
local M2=8000000

local M2017=967820/1465000*(1465000+5300000)
local M2016=849853/1308000*(1308000+5200000)
local M2015=950339/1482000*(1482000+4900000)
local M2014=1278999/2316000*(2316000+6000000)
local M2013=1418948/258400*(2584000+5660000)

gen share=.
foreach year of local yearlist {
qui replace share=quantity/`M`year'' if year==`year'
}
*replace share=quantity/`M'
*replace share=quantity/`M1' if year>=2015
*replace share=quantity/`M2' if year<=2014

// gen logshare
bysort  year:egen sumshare=sum(share)
gen logshare=log(share)-log(1-sumshare)

* CHOOSE PRICE or ADJUSTED PRICE
local price "price"
local price "price_adj"

* CHOOSE GROUPING
local group_var "national"
// generate log-share for nested logit
bysort year `group_var': egen share_group=sum(share)
gen share_ingroup=share/share_group
gen logshare_ingroup=log(share_ingroup)

* CHOOSE EXOGENOUS VARIABLES
* choose exogenous characteristics
local exog_char "body_SUV body_hatch horsepower rating fuelcons wheelbase  height " 
local exog_char "horsepower fuelcons trunk rating body_SUV body_hatch"
*local exog_char "horsepower fuelcons clearance trunk rating wheelbase"
*local exog_char ""


* choose base category for brand
local brand "brand15"
qui ds brand1-brand16
local brandlist=r(varlist)
local brandlist : list brandlist-brand
*local brandlist ""


* choose time trends or time dummies
local time "y2014-y2017"
*local time "time"
*local time ""


local exog "`exog_char' `time' `brandlist'"


** CHOOSE INSTRUMENTS

** CHOOSE TYPE OF INSTRUMENTS
* BLP instruments
* CHOOSE INSTRUMENTAL VARIABLES
local charlist "horsepower fuelcons trunk body_SUV body_hatch"
di "`charlist'"
local iv "russia_prod_alt weight length"
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

* CHOOSE INSTRUMENTS for ingroup shares
local charlist "horsepower fuelcons trunk body_SUV body_hatch"
foreach chara of local charlist {
	capture bysort year: egen `chara'_yr=total(`chara')
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

gen tilde_share=share/(1+tariff)
gen tilde_price=`price'/(1+tariff)


forval j=1/25 {
	qui gen share`j'=.	
	qui by year: replace share`j'=share[`j']
}

*********** CHANGE DELTA MATRIX FOR NESTED LOGIT
forval j=1/25 {
	gen delta`j'=0
	* change brand to firm producing brand
	qui by year: replace delta`j'=(firm==firm[`j'])
	qui replace delta`j'=-`alpha'/(1-`delta')*share*(1-share_ingroup*`delta'- (1-`delta')*share) if id==`j'
	qui replace delta`j'=`alpha'/(1-`delta')*share`j'*(share_ingroup*`delta'+share*(1-`delta')) if delta`j'==1&id!=`j'&`group_var'==`group_var'[`j']
	qui replace delta`j'=`alpha'*share*share`j' if delta`j'==1&`group_var'!=`group_var'[`j']
	*by year: gen el`j'=-delta`j'*price[id==`j']/share
}


forval j=2013/2017 {
	qui {
	putmata Delta=(delta1-delta25) if year==`j', replace
	putmata s=tilde_share if year==`j', replace
	mata res`j'=luinv(Delta)*s
	if `j'==2013 mata res=res`j'
	if `j'>2013 mata res=res\res`j'
	}
}

getmata markup=res, replace
gen mc=tilde_price-markup
gen margins=markup/price
gen lnmc=ln(mc)

*** 4) counterfactual in Matlab

* CHOOSE COUNTERFACTUAL TARIFF
gen counter_tariff=0
replace counter_tariff=0.3 if !russia_prod


*export delimited using "do files/top25-yearly/matlab/top25-yearly.csv", replace



****
ivregress 2sls logshare (`price' logshare_ingroup=`iv') `exog'
