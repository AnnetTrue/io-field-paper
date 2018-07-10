*** Description: Logit model.
*** - 1) choose setup (market size, instruments, characteristics)
*** - 2) estimation (only demand side)
*** - 3) MC recovery
*** INfirmLETE - 4) prepare data for counterfactual analysis in Matlab

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
gen logshare=log(share)-log(1-sumshare)

* CHOOSE PRICE or ADJUSTED PRICE
local price "price"
local price "price_adj"

* CHOOSE EXOGENOUS VARIABLES
* choose exogenous characteristics
local exog_char "body_SUV body_hatch horsepower rating fuelcons wheelbase  height " 
local exog_char "body_SUV body_hatch horsepower rating fuelcons"
*local exog_char "body_SUV body_hatch fuelcons horsepower trunk size2"
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
local charlist "horsepower fuelcons trunk body_SUV body_hatch"
di "`charlist'"
local iv "russia_prod weight engine"
foreach chara of local charlist {
	bysort year: egen `chara'_yr=total(`chara')
	bysort year firm: egen `chara'_fm=total(`chara')
	gen `chara'_iv=`chara'_yr-`chara'_fm
	qui replace `chara'_fm=`chara'_fm-`chara'
	// choose type of exogenous variables
	local iv "`iv' `chara'_iv"
	*local iv "`iv' `chara'_fm"
}


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


ivregress 2sls logshare (`price'=`iv') `exog_char'
est store Logit
outreg2 `exog_char' [Logit] using Logit.tex, replace drop(brand1-brand16) label

ivregress 2sls logshare (`price'=`iv') `exog_char' `brandlist'
est store Logitbrand
outreg2 `exog_char' [Logitbrand] using Logit.tex, append drop(brand1-brand16) label

ivregress 2sls logshare (`price'=`iv') `exog_char' `brandlist' `time'
est store Logitbrand
outreg2 `exog_char' [Logitbrand] using Logit.tex, append drop(brand1-brand16 y2013-y2017) label



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

