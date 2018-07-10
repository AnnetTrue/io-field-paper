*** Description: Logit model.
*** - 1) choose setup (market size, instruments, characteristics)
*** - 2) estimation (only demand side)
*** - 3) MC recovery
*** INfirmLETE - 4) prepare data for counterfactual analysis in Matlab

********************************************************************************

cd "/Users/Anna/Documents/IO field paper/Data"
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

* CHOOSE EXOGENOUS VARIABLES
* choose exogenous characteristics
local exog_char "body_SUV body_hatch horsepower rating fuelcons wheelbase  height " 
local exog_char "horsepower fuelcons trunk rating wheelbase body_SUV body_hatch"
*local exog_char "horsepower fuelcons clearance trunk rating wheelbase"
*local exog_char "fuelcons trunk russia horsepower"


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

** CHOOSE TYPE OF INSTRUMENTS
* BLP instruments
* CHOOSE INSTRUMENTAL VARIABLES
local charlist "horsepower fuelcons trunk wheelbase body_SUV body_hatch"
di "`charlist'"
local iv "russia_prod_alt weight length engine"
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

ivregress gmm logshare (`price'=`iv') `exog'
// get alpha for 3)
gen a=e(sample)
local alpha=_b[`price']
// get delta0 for counterfactuals in Matlab
predict delta0
// calculate elasticities
gen el=`alpha'*(1-share)*`price'

*reg `price' `iv' `exog'
*** 3) MC recovery


sort year firm brand model

//gen unique id for each model in a year
by year: gen id=[_n]

gen tilde_share=share/(1+tariff)
gen tilde_price=`price'/(1+tariff)
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
	qui replace delta`j'=-share*(1-share) if id==`j'
	qui replace delta`j'=share`j'*share if delta`j'==1&id!=`j'
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
drop delta1-delta25 share1-share25
gen mc=tilde_price-markup
gen margins=markup/price
gen lnmc=log(mc)

gen markup_2=-markup_pure

gen ss=1/(1-share)

local exog_ss "russia_prod_alt weight length engine horsepower fuelcons trunk body_SUV body_hatch"
local charlist "horsepower fuelcons trunk wheelbase body_SUV body_hatch"
di "`charlist'"
local iv ""
foreach chara of local charlist {
	// choose type of exogenous variables
	local iv "`iv' `chara'_iv"
	*local iv "`iv' `chara'_fm"
}
local iv_ss "`iv'"
di "`iv_ss'"
gmm	(supply: tilde_price - {supply:`exog_ss' _cons} - markup_pure*{a}), derivative(/supply=-1) derivative(/a=-markup_pure) instruments(`exog_ss' `iv_ss')

/*
gmm	(supply: tilde_price + markup_pure/{a=0.005}- {supply:`exog_ss' _cons} ) ///
	(demand: logshare - {demand:`exog_dm' _cons} + {a=0.005}*`price') ///
	, instruments(demand:`exog' `iv') instruments(supply:`exog_ss' `iv_ss') ///
    derivative(supply /supply=-1) derivative(supply /a=markup_pure/{a}^2) ///
	 derivative(demand /demand=-1) derivative(demand /a=price) ///
	 winitial(identity)
*/
