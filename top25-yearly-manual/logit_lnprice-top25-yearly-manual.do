*** Description: Logit model with ln(price)
*** - 1) choose setup (market size, instruments, characteristics)
*** - 2) estimation (only demand side)
*** - 3) MC recovery
*** INCOMPLETE - 4) prepare data for counterfactual analysis in Matlab

********************************************************************************
cd "/Users/Anna/Dropbox/IO field paper/Data/complete"
use "complete-top25-yearly-manual.dta", clear


*** 1) choose setup
* CHOOSE MARKET SIZE
// M has to be more than 1.5 mil
local M=10000000
gen share=quantity/`M'
bysort  year:egen sumshare=sum(share)
gen logshare=log(share)-log(1-sumshare)

* CHOOSE PRICE or ADJUSTED PRICE
local price "price"
*local price "price_adj"
gen logprice=log(`price')

* CHOOSE EXOGENOUS CHARACTERISTICS
local exog "engine horsepower fuelcons clearance trunk russia"

* generate instruments
* BLP instruments
local charlist "engine horsepower fuelcons clearance trunk"
foreach chara of local charlist {
	bysort year: egen `chara'_yr=total(`chara')
	bysort year brand: egen `chara'_bd=total(`chara')
	gen `chara'_iv=`chara'_yr-`chara'_bd
}
* Gandhi-Houde instruments
* cost side instruments (exchange rate, price inflations, characteristics)

* CHOOSE INSTRUMENTS
local iv "engine_iv horsepower_iv fuelcons_iv clearance_iv trunk_iv"


*** 2) estimation


ivregress 2sls logshare (logprice=`iv') `exog'
local alpha=_b[logprice]

predict delta0
gen el=-`alpha'*(1-share)


*** 3) MC recovery   

 
sort year brand model
by year: gen id=[_n]
forval j=1/25 {
	gen share`j'=.	
	qui by year: replace share`j'=share[`j']
}

forval j=1/25 {
	gen delta`j'=0
	* change brand to company producing brand
	by year: replace delta`j'=(brand==brand[`j'])
	qui replace delta`j'=-`alpha'*share*(1-share)/price if id==`j'
	qui replace delta`j'=`alpha'*share`j'*share/price if delta`j'==1&id!=`j'
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
gen lnmc=ln(mc)



