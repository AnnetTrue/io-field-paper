*** Description: Logit model with ln(price)
*** - 1) choose setup (market size, instruments, characteristics)
*** - 2) estimation (only demand side)
*** - 3) MC recovery
*** INCOMPLETE - 4) prepare data for counterfactual analysis in Matlab

********************************************************************************
cd "/Users/Anna/Dropbox/IO field paper/Data/complete"
use "complete-top25-yearly.dta", clear


*** 1) choose setup
local yearlist "2013 2014 2015 2016 2017"
* CHOOSE MARKET SIZE
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
gen logprice=log(`price')

* CHOOSE EXOGENOUS CHARACTERISTICS
* choose exogenous characteristics
local exog "engine horsepower fuelcons clearance trunk russia"
local exog_char "body_SUV body_hatch fuelcons horsepower trunk rating"

* choose base category for brand
local brand "brand15"
qui ds brand1-brand16
local brandlist=r(varlist)
local brandlist : list brandlist-brand
*local brandlist "usa europe japan korea"
*local brandlist ""

* choose time trends or time dummies
local time "y2014-y2017"
local time "time"
*local time ""

local exog "`exog_char' `time' `brandlist'"



** CHOOSE TYPE OF INSTRUMENTS
* BLP instruments
* CHOOSE INSTRUMENTAL VARIABLES
local charlist "`exog_char'"
local charlist "engine horsepower fuelcons clearance trunk"
*local charlist ""
local iv "russia length engine weight"
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
* cost side instruments (exchange rate, price inflations, characteristics)


*** 2) estimation


ivregress 2sls logshare (logprice=`iv') `exog'
local alpha=_b[logprice]

predict delta0
gen el=-`alpha'*(1-share)


*** 3) MC recovery   

gen tilde_share=share/(1+tariff_sh)
gen tilde_price=`price'/(1+tariff_sh)

 
sort year brand model
by year: gen id=[_n]
forval j=1/25 {
	qui gen share`j'=.	
	qui by year: replace share`j'=share[`j']
}

forval j=1/25 {
	qui gen delta`j'=0
	* change brand to company producing brand
	qui by year: replace delta`j'=(brand==brand[`j'])
	qui replace delta`j'=-`alpha'*share*(1-share)/`price' if id==`j'
	qui replace delta`j'=`alpha'*share`j'*share/`price' if delta`j'==1&id!=`j'
	*by year: gen el`j'=-delta`j'*price[id==`j']/share
}

forval j=2013/2017 {
	qui {
	putmata Delta=(delta1-delta25) if year==`j', replace
	putmata s=share if year==`j', replace
	mata res`j'=luinv(Delta)*s
	if `j'==2013 mata res=res`j'
	if `j'>2013 mata res=res\res`j'
	}
}

getmata markup=res, replace
gen mc=tilde_price-markup
gen margins=markup/`price'
gen lnmc=ln(mc)




