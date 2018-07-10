*** Description:
*** - imports 2round scraping results (scraped by Python)
*** - clears vars
*** - merges it back with round 1-configdeschrefs
*** - leaves 1 configuration for each model/year
*** - merges with quantity
*** - prepares for future analysis

*******************
cd "/Users/Anna/Dropbox/IO field paper/Data"

import delimited "characteristics/2round/2round-links-top25-yearly.txt", bindquote(strict) encoding(utf-8) delimiter(";") clear

rename v1 configdeschref
rename v2 rating
rename v3 price
rename v4 configuration
rename v5 period
rename v6 drive
rename v7 body
rename v8 transmission
rename v9 engine_sm
rename v10 acceleration

rename v11 clearance
rename v12 maxspeed
rename v13 country
rename v14 seats
rename v15 size
rename v16 wheelbase
rename v17 weight
rename v18 trunk
rename v19 horsepower

rename v20 fuelcons_city
rename v21 fuelcons_rural 
rename v22 fuelcons_mix
rename v23 ac

** Clears data and prepares for future analysis
* period clearing
gen month_start=regexs(1) if regexm(period, "^(.*)\-")
gen month_end=regexs(1) if regexm(period, "\-(.*)$")

local ll "start end"
foreach l of local ll {
	gen year_`l'=regexs(1) if regexm(month_`l', "([0-9]+)")
	replace month_`l'=subinstr(month_`l', year_`l', "",1)
	
	replace month_`l'="1" if regexm(month_`l', "январь")
	replace month_`l'="2" if regexm(month_`l', "февраль")
	replace month_`l'="3" if regexm(month_`l', "март")
	replace month_`l'="4" if regexm(month_`l', "апрель")
	replace month_`l'="5" if regexm(month_`l', "май")
	replace month_`l'="6" if regexm(month_`l', "июнь")
	replace month_`l'="7" if regexm(month_`l', "июль")
	replace month_`l'="8" if regexm(month_`l', "август")
	replace month_`l'="9" if regexm(month_`l', "сентябрь")
	replace month_`l'="10" if regexm(month_`l', "октябрь")
	replace month_`l'="11" if regexm(month_`l', "ноябрь")
	replace month_`l'="12" if regexm(month_`l', "декабрь")
	destring month_`l' year_`l', replace
}

* the rest
quietly tabulate drive, generate(drive)
quietly tabulate body, generate(body)
gen body_SUV=body1
gen body_hatch=body3+body4

gen trans=!regexm(transmission, "МКПП")
drop transmission
rename trans transmission
gen extra=transmission|drive2

gen engine=round(engine_sm/1000, .1)

gen russia_prod=regexm(country, "Россия")|regexm(country, "Российская Федерация")
gen russia_prod_alt=russia_prod&!regexm(country, ",")


gen length= regexs(1) if regexm(size, "^([0-9]+) x")
gen width= regexs(1) if regexm(size, "x ([0-9]+) x")
gen height=regexs(1) if regexm(size, "x ([0-9]+)$")

gen fuelcons=subinstr(fuelcons_mix, ",", ".", 1)

rename trunk trunk_old
gen trunk=regexs(1) if regexm(trunk_old, "^([0-9]+)")
rename horsepower horsepower_old
gen horsepower=regexs(1) if regexm(horsepower_old, "^([0-9]+)")

destring length width height trunk horsepower fuelcons, replace
gen size2=length*width/1000000
drop trunk_old horsepower_old




** imputing missing data from other sources
//7.4 is average rating for Лада
replace rating=7.4 if regexm(configdeschref, "samara")
// information from wikipedia
replace acceleration=13 if regexm(configdeschref, "samara")&acceleration==.
replace wheelbase=2460 if regexm(configdeschref, "samara")&wheelbase==.
replace weight=1000 if regexm(configdeschref, "samara")&weight==.
replace clearance=165 if regexm(configdeschref, "samara")&clearance==.
replace acceleration=14.5 if regexm(configdeschref, "largus")&acceleration==.

replace fuelcons=7.6 if regexm(configdeschref, "daewoo")&fuelcons==.
replace fuelcons=7.6 if regexm(configdeschref, "samara")&fuelcons==.
replace fuelcons=12.5 if regexm(configdeschref, "patriot")&fuelcons==.

replace price=334000 if configdeschref=="https://www.drom.ru/catalog/lada/priora/92891/"

replace ac=0 if ac==.

***  3) merge back to 1round-configdeschrefs
merge 1:m configdeschref using "characteristics/2round/1round-top25-yearly", nogen
order model brand year

gen russia = russia_prod
replace russia=0 if model=="RAV4"&year==2016
replace russia=0 if model=="Sportage"&year<=2015



*** 4) choose 1 configuration for each model/year
// calculate time frame
gen months_sold=0
replace months_sold=month_end-month_start+1 if year_start==year&year_end==year
replace months_sold=12-month_start +1 if year_start==year&year_end>year
replace months_sold=month_end-1 +1 if year_start<year&year_end==year
replace months_sold=12 if year_start<year&year_end>year


// cars have to be sold for at least 6 months
gen sample=months_sold>=6
// check that there exist cars sold for at least 6 months, otherwise anything would work
egen mainid=group(brand model year)
bysort mainid: egen s=total(sample)
replace sample=1 if s==0&months_sold>0
keep if sample

// choose specification with min price, checking that horsepower is all the worst
bysort mainid: egen minprice=min(price)
by mainid: egen minhorsepower=min(horsepower)

gen choose=0
replace choose=1 if price==minprice
gen hp_check=horsepower==minhorsepower

/*
// additional checks
list model brand year if  !hp_check&choose
list model brand year ch if ch!=1
pause
*/

// have to manually choose configuration for Priora, due to !hp_check&choose
replace choose=0 if model=="Приора"&year==2015&configuration!="Норма 21703-32-054"
replace choose=1 if model=="Приора"&year==2015&configuration=="Норма 21703-32-054"
drop if !choose

drop choose ch hp_check s sample minhorsepower minprice

*** final merge
duplicates drop model brand year, force
isid model brand year

merge 1:1 model brand year using "quantity/quantity-top25-yearly"
// assert that all cars from quantity data are matched 
bysort _merge: assert _N==0 if _merge==1
drop if year<2013
drop _merge

*** 
save "complete/complete-top25-yearly", replace




use "complete/complete-top25-yearly", replace


*** preparing for future analysis
* price adjusted for inflation (source, gks)
gen price_adj=price
qui replace price_adj=price_adj/1.023 if year==2017
qui replace price_adj=price_adj/1.068 if year>=2016
qui replace price_adj=price_adj/1.145 if year>=2015
qui replace price_adj=price_adj/1.08 if year>=2014
order price_adj, after(price)



** Brands/firms
* companies/alliances
gen firm=""
replace firm="Renault Group" if brand=="Renault"|brand=="Лада"|brand=="Nissan"|brand=="Datsun"
replace firm="Toyota Group" if brand=="Toyota"|brand=="Lexus"|brand=="Scion"|brand=="Daihatsu"|brand=="Hino"
replace firm="General Motors" if brand=="Chevrolet"|brand=="Opel"|brand=="Daewoo"
replace firm="Ford Motor firm" if brand=="Ford"
replace firm="Hyundai Motor" if brand=="Hyundai"|brand=="Kia"
replace firm="Mazda Motor Corporation" if brand=="Mazda"
replace firm="Mitshubishi Group" if brand=="Mitsubishi"
replace firm="Groupe PSA" if brand=="Peugeot"|brand=="Citroen"
replace firm="Volkswagen AG" if brand=="Volkswagen"|brand=="Audi"|brand=="Skoda"
replace firm="Suzuki Motor Corporation" if brand=="Suzuki"
replace firm="УАЗ" if brand=="УАЗ"

egen firm_id=group(firm)
quietly tabulate firm, generate(firm)

* national brands
gen national=brand=="Лада"|brand=="УАЗ"|model=="Niva"
gen europe=brand=="Renault"|brand=="Chevrolet"|brand=="Daewoo"|brand=="Opel"|brand=="Skoda"|brand=="Volkswagen"
gen japan=brand=="Nissan"|brand=="Datsun"|brand=="Mazda"|brand=="Mitsubishi"|brand=="Toyota"
gen usa=brand=="Ford"
gen korea=brand=="Hyundai"|brand=="Kia"

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

** Tariffs
* tariffs
local russia "russia_prod_alt"
local russia "russia_prod"
local russia "russia"

gen tariff_sh=0
replace tariff_sh=0.25 if !`russia'
gen tax_var=tariff_sh*price

gen euro=1
qui {
replace euro=31.848 if year==2013
replace euro=38.4217 if year==2014
replace euro=60.9579 if year==2015
replace euro=67.0349 if year==2016
replace euro=65.83529 if year==2017
}

gen price_euro=price/euro

gen tax_fixed=0
qui {
replace tax_fixed=1*price_euro if engine_sm <=1000
replace tax_fixed=1.1 *price_euro if engine_sm <=1500 & engine_sm>=1001
replace tax_fixed= 1.25*price_euro if engine_sm <=1800 & engine_sm>=1501
replace tax_fixed= 1.8*price_euro if engine_sm <=2300 & engine_sm>=3001
replace tax_fixed= 2.35*price_euro if engine_sm>=3001
}
replace tax_fixed =tax_fixed*euro
* http://kurs-dollar-euro.ru/srednegodovoj-kurs.html
replace tax_fixed=0 if `russia'
gen tariff_min=min(tax_fixed, tax_var)



save "complete/complete-top25-yearly", replace
