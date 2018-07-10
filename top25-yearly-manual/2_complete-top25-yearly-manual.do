*** Description:
*** - 1) imports char-top25-yearly-manual.xlsx
*** - 2) merges with quantity-top25-yearly-manual.dta
*** - 3) preparing for future analysis

********************************************************************************

cd "/Users/Anna/Documents/IO field paper/Data"
capture erase "complete/complete-top25-yearly-manual.dta"

*** 1) importing characteristics files


import excel "characteristics/char-top25-yearly-manual.xlsx", sheet("characteristics") cellrange(A2:BV48) firstrow clear
drop K T AC AL AU BD BM BV

* rename variables
local varvarlist "price-country L-S U-AB AD-AK AM-AT AV-BC BE-BL BN-BU"
local i=2017
foreach vlist of local varvarlist {
	foreach var of varlist `vlist' {
		local lab: var lab `var'
		local lab=subinstr("`lab'"," ","",.)
		rename `var' `lab'`i'
	}
	local i=`i'-1
}



*** 2) merging with quantity data


merge 1:1 model brand using "quantity/quantity-top25-yearly-manual.dta"
reshape long price enginecapacity horsepower fuelconsumption clearance trunk body country quantity, i(model brand) j(year)
drop _merge

*** 3) preparing for future analysis
* vars renaming 
rename enginecapacity engine
rename fuelconsumption fuelcons


* drop
drop if year<2013
drop if price==.

* variable changes
quietly tabulate body, generate(body)
gen russia=country=="Russia"


* price adjusted for inflation (source, gks)
gen price_adj=price
qui replace price_adj=price_adj/1.023 if year==2017
qui replace price_adj=price_adj/1.068 if year>=2016
qui replace price_adj=price_adj/1.145 if year>=2015
qui replace price_adj=price_adj/1.08 if year>=2014
order price_adj, after(price)

* tariffs
gen tariff=0
replace tariff=0.25 if country!="Russia"

** Brands/firms
* companies/alliances
gen firm=""
replace firm="Renault Group" if brand=="Renault"|brand=="Lada"|brand=="Nissan"|brand=="Datsun"
replace firm="Toyota Group" if brand=="Toyota"|brand=="Lexus"|brand=="Scion"|brand=="Daihatsu"|brand=="Hino"
replace firm="General Motors" if brand=="Chevrolet"|brand=="Opel"|brand=="Daewoo"
replace firm="Ford Motor firm" if brand=="Ford"
replace firm="Hyundai Motor" if brand=="Hyundai"|brand=="Kia"
replace firm="Mazda Motor Corporation" if brand=="Mazda"
replace firm="Mitshubishi Group" if brand=="Mitsubishi"
replace firm="Groupe PSA" if brand=="Peugeot"|brand=="Citroen"
replace firm="Volkswagen AG" if brand=="Volkswagen"|brand=="Audi"|brand=="Skoda"
replace firm="Suzuki Motor Corporation" if brand=="Suzuki"
replace firm="UAZ" if brand=="Uaz"

egen firm_id=group(firm)
quietly tabulate firm, generate(firm)

* national brands
gen national=brand=="Lada"|brand=="Uaz"|model=="Niva"

* gen dummies for brands
qui tabulate brand, gen(brand)
order model brand firm

** Accounting for time
* time dummies
qui levelsof year, local (year)
foreach y of local year {
	gen y`y'=year==`y'
}
* time trends
qui sum year
gen time=year-`r(min)'



save "complete/complete-top25-yearly-manual.dta", replace
