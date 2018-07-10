*** Description:
*** - imports 1round links (scraped by webscraper)
*** - deciphers description of generation (generation)
*** - cleans sample:
***			- only cars for Russian market sold after 2010

*******************
cd "/Users/Anna/Documents/IO field paper/Data/characteristics/1round"

import delimited "1round-links.csv", bindquote(strict) encoding(utf8) varnames(1) clear

** Clearing the data
// drops if no configurations are available
drop if configdeschref==""
// ?
* drop if configdesc=="null"
// only cars on Russian market
drop if !regexm(market, "Россия")


*** process variable generation
gen gen_aux=strtrim(generation)
gen insale=regexm(gen_aux, "продается официально")
replace gen_aux=subinstr(gen_aux, "продается официально", "",1)
gen insale_soon=regexm(generation, "скоро в продаже")
replace gen_aux=subinstr(gen_aux, "скоро в продаже", "",1)

replace gen_aux=subinstr(gen_aux, brand, "", 1)
replace gen_aux=subinstr(gen_aux, model, "", 1)

gen gen_name=regexs(1) if regexm(gen_aux, "(\([а-яА-Яa-zA-Z0-9,\-\ ]*\))")
replace gen_aux=subinstr(gen_aux, gen_name, "", 1)

gen period=regexs(2) if regexm(generation, "(.*)([0-9][0-9]\.[0-9][0-9][0-9][0-9] - [0-9][0-9]\.[0-9][0-9][0-9][0-9])(.*)")
replace period=regexs(2) if regexm(generation, "(.*)([0-9][0-9]\.[0-9][0-9][0-9][0-9] -  н\.в\.)(.*)")
replace gen_aux=subinstr(gen_aux, period, "", 1)


gen gen=regexs(1) if regexm(gen_aux, "([0-9]) поколение")
replace gen_aux=subinstr(gen_aux, gen+" поколение", "", 1)
destring gen, replace
gen restyle=1 if regexm(gen_aux, "рестайлинг")
replace restyle=0 if restyle==.
replace gen_aux=subinstr(gen_aux, "рестайлинг", "", 1)

gen gen_name2=regexs(1) if regexm(gen_aux, "([A-Z0-9,\ ]*)")

gen body=""
replace body="Седан" if regexm(gen_aux, "Седан")
replace body="Хэтчбек" if regexm(gen_aux, "Хэтчбек")
replace body="Универсал" if regexm(gen_aux, "Универсал")
replace body="SUV" if regexm(gen_aux, "SUV")
replace body="Купе" if regexm(gen_aux, "Купе")

replace body="Грузовик" if regexm(gen_aux, "Грузовик")
replace body="Минивэн" if regexm(gen_aux, "Минивэн")
replace body="Открытый кузов" if regexm(gen_aux, "Открытый кузов")
replace body="Пикап" if regexm(gen_aux, "Пикап")
replace gen_aux=subinstr(gen_aux, body, "", 1)

egen body_id=group(body)


// leave only cars produced after 2010

gen year_start=substr(period, 4, 4)
gen year_end=substr(period, -4, .)
replace year_end="" if year_end==".в."
destring year_start year_end, replace
drop if year_end<2010

/*
** Don't need it at this point
gen month_start=substr(period, 1, 2)
gen month_end=substr(period, -7, 2)
replace month_end="" if !regexm(month_end, "[0-9]")
destring month_start month_end, replace
*/



compress
sort brand model
save 1round-links-all.dta, replace

** all links
*if `choose'==1 {
*	keep configdeschref
*	export delimited using "all_links", delimiter(tab) novarnames replace
*}








