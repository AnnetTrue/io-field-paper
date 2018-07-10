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

* CHOOSE GROUPING
local group_var "national"
// generate log-share for nested logit
bysort year `group_var': egen share_group=sum(share)
gen share_ingroup=share/share_group
gen logshare_ingroup=log(share_ingroup)

* CHOOSE EXOGENOUS VARIABLES
* choose exogenous characteristics
local exog_char "body_SUV body_hatch horsepower rating fuelcons wheelbase  height " 
local exog_char "body_SUV body_hatch horsepower rating fuelcons trunk "
** had wheelbase before
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
local iv "russia_prod transmission drive2 length weight engine"
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
label var price "Price"
label var price_adj "Price in 2013 RUR"
label var horsepower "Horsepower"
label var fuelcons "Fuel consumption"
label var trunk "Trunk size"
label var wheelbase "Wheelbase"
label var body_SUV "SUV"
label var body_hatch "Hatchback/wagon"
label var rating "Rating"
label var national "Share of national brands"
label var length "Length"
label var weight "Weight"
label var logshare_ingroup "ln(share in group)"


ivregress 2sls logshare (`price' logshare_ingroup=`iv') `exog_char'
est store NLogit
outreg2 `exog_char' [NLogit] using NLogit.tex, replace drop(brand1-brand16) label

ivregress 2sls logshare (`price' logshare_ingrou=`iv') `exog_char' `brandlist'
est store NLogitbrand
outreg2 `exog_char' [NLogitbrand] using NLogit.tex, append drop(brand1-brand16) label

ivregress 2sls logshare (`price' logshare_ingrou=`iv') `exog_char' `brandlist' `time'
est store NLogittime
outreg2 `exog_char' [NLogittime] using NLogit.tex, append drop(brand1-brand16) label

*ivregress gmm logshare (`price' logshare_ingrou=`iv') `exog_char' `brandlist' `time'
*est store NLogitbrand
*outreg2 `exog_char' [NLogitbrand] using NLogit.tex, append drop(brand1-brand16 y2013-y2017) label

*export delimited using "do files/top25-yearly/matlab/top25-yearly.csv", replace



****
