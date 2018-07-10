*** Description: Logit model.
*** - 1) choose setup (market size, instruments, characteristics)
*** - 2) estimation (only demand side)
*** - 3) MC recovery
*** INfirmLETE - 4) prepare data for counterfactual analysis in Matlab

********************************************************************************

cd "/Users/Anna/Dropbox/IO field paper"
use "Data/complete/complete-top25-yearly.dta", clear

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

local M=2000000
local M1=6500000
local M2=8000000

local M2017=967820/1465000*(1465000+5300000)
local M2016=849853/1308000*(1308000+5200000)
local M2015=950339/1482000*(1482000+4900000)
local M2014=1278999/2316000*(2316000+6000000)
local M2013=1418948/2584000*(2584000+5660000)

gen share=.
foreach year of local yearlist {
qui replace share=quantity/`M`year'' if year==`year'
}
*replace share=quantity/`M'
*replace share=quantity/`M1' if year>=2015
*replace share=quantity/`M2' if year<=2014

// gen logshare
bysort  year:egen sumshare=sum(share)
gen outshare=1-sumshare
gen logshare=log(share)-log(outshare)

* CHOOSE PRICE or ADJUSTED PRICE
local price "price"
local price "price_adj"

* CHOOSE EXOGENOUS VARIABLES
* choose exogenous characteristics
local exog_char "body_SUV body_hatch horsepower rating fuelcons wheelbase  height " 
local exog_char "body_SUV body_hatch fuelcons horsepower rating"
*local exog_char "engine horsepower fuelcons clearance trunk"
*local exog_char "rating"
*local exog_char "horsepower fuelcons clearance trunk rating wheelbase"
*local exog_char "fuelcons trunk russia horsepower"


* choose base category for brand
local brand "brand15"
qui ds brand1-brand16
local brandlist=r(varlist)
local brandlist : list brandlist-brand
*local brandlist "usa europe japan korea"
local brandlist ""


* choose time trends or time dummies
local time "y2014-y2017"
local time "time"
local time ""


local exog "`exog_char' `time' `brandlist'"

** CHOOSE TYPE OF INSTRUMENTS
* BLP instruments
* CHOOSE INSTRUMENTAL VARIABLES
local charlist "`exog_char'"
local charlist "engine horsepower fuelcons clearance trunk"
local charlist ""
local iv "russia_prod engine weight wheelbase"
*local iv ""
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
/*
local charlist "`exog_char'"
local iv "russia length engine weight"
foreach chara of local charlist {
	bysort year: egen `chara'_sd=sd(`chara')
	gen `chara'1=
	bysort year: gen `chara'_iv=count(`chara'
	qui replace `chara'_fm=`chara'_fm-`chara'
	// choose type of exogenous variables
	local iv "`iv' `chara'_iv"
	*local iv "`iv' `chara'_fm"
}
*/

* cost side instruments (exchange rate, price inflations, characteristics)



//??????
**egen brand_id=group(brand) 


*** 2) estimation

ivregress 2sls logshare (`price'=`iv') `exog'
gen alpha=_b[`price']

// get alpha for 3)
gen a=e(sample)
local alpha=_b[`price']
// get delta0 for counterfactuals in Matlab
predict delta0
// calculate elasticities
gen el=`alpha'*(1-share)*`price'

*reg `price' fuelcons

*** 3) MC recovery


sort year firm brand model

//gen unique id for each model in a year
by year: gen id=[_n]

gen tilde_share=share/(1+tariff_sh)
gen tilde_price=`price'/(1+tariff_sh)
******* What if we were using adjusted prices?

// generate "matrix" of shares
forval j=1/25 {
	qui gen share`j'=.	
	qui by year: replace share`j'=share[`j']
}

// generate Delta "matrix"
forval j=1/25 {
	gen delta`j'=0
	qui by year: replace delta`j'=(firm==firm[`j'])
	qui replace delta`j'=-`alpha'*share*(1-share) if id==`j'
	qui replace delta`j'=`alpha'*share`j'*share if delta`j'==1&id!=`j'
	*by year: gen el`j'=-delta`j'*price[id==`j']/share
	*** IF BACK -- PUT ALPHA BACK
}

// calculates markups in Mata
forval j=2013/2017 {
	qui {
		putmata Delta=(delta1-delta25) if year==`j', replace
		putmata s=tilde_share if year==`j', replace
		mata res`j'=luinv(Delta)*s
		if `j'==2013 mata res=res`j'
		if `j'>2013 mata res=res\res`j'
	}
}

getmata markup_pure=res, replace
*drop delta1-delta25 share1-share25
gen mc=tilde_price-markup
gen margins=markup/`price'
gen lnmc=log(mc)

*export delimited using "Do files/top25-yearly/matlab/top25-yearly.csv", replace

*save "Data/complete/logit-top25-yearly.dta", replace

ivregress 2sls logshare (`price'=`iv') `exog'
