*** Description: 
*** - sample of links for top 25 cars starting 2013


*** Description:
*** - 1) prepares models from quantity top25 2013 for merge with 1round links.
*** - 2) pairwises joins with 1round-links-all
*** - 3) prepares a sample of links for 2round scraping. Criterions:
*** 		- time-relevant configurations for given model/year.
*** 		* Note: time for link defined as period for model/gen, can generally be not exact period of configuration, need to check it later!
*** 		- base configurations
***			* Manually defined by looking at all configurations for given model (from drom.ru description of model/gen)
***			- manual/automatic transmissions (if exist)
***			- gas only



cd "/Users/Anna/Documents/IO field paper/Data"

*** 1)
use "quantity/quantity-top25-yearly"
drop if year<2013
* leaves only models and brands
drop quantity model_orig brand_orig
duplicates  drop
tempfile `1round-models-top25-yearly'
save "`1round-models-top25'"

*** 2) merging
joinby brand model using "characteristics/1round/1round-links-all.dta"

*** 3) cleaning
sort model brand year
// keep only relevant (with respect to the time) configurations
keep if year<=year_end&year>=year_start
/*
// calculate time frame
gen months_sold=0
replace months_sold=month_end-month_start+1 if year_start==year&year_end==year
replace months_sold=12-month_start +1 if year_start==year&year_end>year
replace months_sold=month_end-1 +1 if year_start<year&year_end==year
replace months_sold=12 if year_start<year&year_end>year
*/

** leaves only one type of body for each generation
egen gen_id=group(model brand gen)

tab body, gen(body)

tempfile aux
save `aux'

keep model brand body gen_id body1-body5
duplicates drop
// to check if there are more than one type of body for this model/gen
bysort gen_id: gen gen_nb=_N
by gen_id: egen sedan=max(body3)
// if these several type of bodies include sedan, choose sedan
drop if !body3&sedan&gen_nb>1

//choose are there model/gens left, that still have several types of body
drop gen_nb
bysort gen_id: gen gen_nb=_N
// I check all cars, and it's always a choice between hatchback and universal, so I drop universal
drop if gen_nb>1&body4

drop body1-body5 sedan gen_nb

merge 1:m brand model body gen_id using `aux', keep(match) nogen
drop body1-body5



*** deciphering "configdesc"

gen version=subinstr(configdesc, ",", "", .)

gen engine=regexs(1) if regexm(version, "(^[0-9].[0-9]+)[D]? (.*)")
gen diesel=regexm(version, "(^[0-9].[0-9])[T ]?D (.*)")
gen hybrid=regexm(version, "PHEV (.*)")
replace version=regexs(2) if regexm(version, "(^[0-9].[0-9]+)[T ]?[D]? (.*)")
replace version=regexs(2) if regexm(version, "(^PHEV [0-9].[0-9]+)[T ]?[D]? (.*)")
destring engine, replace

*by model brand year: egen maxengine=max(engine)
*by model brand year: egen minengine=min(engine)
*drop if maxengine>minengine&engine>minengine+0.01&engine!=.

*save aux, replace
*use aux, clear


gen transmission=regexs(1) if regexm(version, "([A-ZА-Я]+T) (.*)")
replace transmission=regexs(1) if regexm(version, "([A-ZА-Я]+Т) (.*)")
replace transmission="DSG" if regexm(version, "DSG")
replace version=subinstr(version, transmission, "", 1)
// change russian for english letters
replace transmission=subinstr(transmission, "М", "M", 1)
replace transmission=subinstr(transmission, "А", "A", 1)
replace transmission=subinstr(transmission, "Т", "T", 1)

replace diesel=1 if regexm(version, "dCi")|regexm(version, "CRDi")
replace version=subinstr(version, "dCi", "", 1)
replace version=subinstr(version, "CRDi", "", 1) 
replace diesel=0.5 if regexm(version, "CNG")
replace version=subinstr(version, "CNG", "", 1)

gen wheeldrive=regexs(2) if regexm(version, "(.*)([0-9]WD)(.*)")
replace version=subinstr(version, wheeldrive, "", 1)
replace wheeldrive=regexs(1)+"WD" if regexm(version, "4x([0-9])")
replace version=regexs(1) + regexs(3) if regexm(version, "(.*)(4x[0-9])(.*)")

gen package=regexs(2)+" "+ regexs(3) if regexm(version, "(.*)\+ ([A-Za-z ]*) пакет ([A-Za-z ]*)$")
replace version=regexs(1) if regexm(version, "(.*)\+ ([A-Za-z ]*)пакет ([A-Za-z ]*)(.*)$")

gen doors=regexs(1) if regexm(version, "([0-9])dr.$")
replace version=regexs(1) if regexm(version, "(.*) ([0-9])dr.$")

replace version=configdesc if version==""
gen seats=regexs(2) if regexm(version, "(.*) ([0-9]) мест")
replace version=regexs(1) if regexm(version, "(.*) ([0-9]) мест")
gen number=regexs(2) if regexm(version, "(.*) ([A-Z/0-9]+\-[A-Z/0-9\-]+)$")
replace version=subinstr(version, number, "", 1)
replace number=regexs(2) if regexm(version, "(.*) ([0-9]+\-[0-9\-]+)")
replace version=regexs(1)+" "+regexs(3) if regexm(version, "(.*) ([0-9]+\-[0-9\-]+) (.*)")
replace version=trim(version)


*save "version.dta", replace
*use "version.dta", clear

*** Manually choosing base transfigurations for every model
gen sample=0

replace sample=1 if model=="4x4 2121 Нива"&version=="Стандарт"
replace sample=1 if model=="Almera"&version=="Welcome"
replace sample=1 if model=="Astra"&version=="Essentia"
replace sample=1 if model=="Camry"&(regexm(version,"Standard")|regexm(version,"Стандарт"))
replace sample=1 if model=="cee'd"&version=="Classic"

replace sample=1 if model=="Corolla"&version=="Стандарт"
replace sample=1 if model=="Creta"&version=="Start"
replace sample=1 if model=="Cruze"&version=="LS"
replace sample=1 if model=="CX-5"&version=="Drive"
replace sample=1 if model=="Duster"&version=="Authentique"

replace sample=1 if model=="Focus"&version=="Ambiente"
replace sample=1 if model=="Гранта"&(version=="Standard"|version=="Стандарт")
replace sample=1 if model=="Калина"&(version=="Standard"|version=="Стандарт")
replace sample=1 if model=="Kaptur"&version=="Drive"
replace sample=1 if model=="Ларгус"&(version=="Standard"|version=="Стандарт")

replace sample=1 if model=="Logan"&(version=="Access"|version=="Authentique")
replace sample=1 if model=="Nexia"
replace sample=1 if model=="Niva"&version=="L"
replace sample=1 if model=="Octavia"&regexm(version,"Active")
replace sample=1 if model=="Outlander"&version=="Inform"

replace sample=1 if model=="Патриот"&(version=="Classic"|version=="Классик")
replace sample=1 if model=="Polo"&regexm(version, "Trendline")
replace sample=1 if model=="Приора"&(version=="Норма"|version=="Стандарт")
replace sample=1 if model=="Qashqai"&version=="XE"
replace sample=1 if model=="Rapid"&regexm(version,"Entry")

replace sample=1 if model=="RAV4"&version=="Стандарт"
replace sample=1 if model=="Rio"&(version=="Comfort"|version=="Classic")
replace sample=1 if model=="Самара Седан"&version=="Стандарт"
replace sample=1 if model=="Sandero"&(version=="Access"|version=="Authentique")
replace sample=1 if model=="Solaris"&(version=="Classic"|version=="Active")

replace sample=1 if model=="Sportage"&version=="Classic"
replace sample=1 if model=="Tiguan"&regexm(version, "Trendline")&!regexm(version, "4Motion")
replace sample=1 if model=="Веста"&regexm(version,"Classic")
replace sample=1 if model=="X-Trail"&regexm(version,"XE")&!regexm(version, "\+")
replace sample=1 if model=="Х-рей"&version=="Optima"

replace sample=1 if model=="ix35"&(version=="Base"|version=="Start")
replace sample=1 if model=="on-DO"&regexm(version, "Access")


replace sample=0 if package!=""
replace sample=0 if !(transmission=="AT"|transmission=="MT"|transmission=="")
// All outlanders are sold with CVT
replace sample=1 if model=="Outlander"&version=="Inform"
replace sample=0 if diesel>0
replace sample=0 if hybrid


/*
** Check that all cars are represented
keep if sample
keep model brand year
duplicates drop
merge 1:1 model brand year using "`1round-models-top25-yearly'"
pause
*/


*** final touch
keep if sample
keep model brand year gen configdeschref restyle
save "characteristics/2round/1round-top25-yearly", replace
keep configdeschref
duplicates drop
export delimited using "characteristics/2round/1round-links-top25-yearly.txt", delimiter(tab) novarnames replace



************ AUXILIARY ******

/*
replace sample=1 if regexm(version, "Норма")
replace sample=1 if regexm(version, "Стандарт")|regexm(version, "Standard")
replace sample=1 if regexm(version, "Классик")|regexm(version, "Classic")
replace sample=1 if regexm(version, "Base")|regexm(version, "Welcome")|regexm(version, "Start")
replace sample=1 if regexm(version, "Drive")|regexm(version, "Access")|regexm(version, "Optima")
replace sample=1 if version=="XE"&model=="Qashqai"
replace sample=1 if version=="L"&model=="Niva"
replace sample=1 if version=="Inform"
replace sample=1 if version=="Active"&model=="Octavia"
replace sample=1 if regexm(version, "SOHC")

drop if regexm(version, "Люкс")|regexm(version, "Luxe")
drop if regexm(version, "Prestige")|regexm(version, "Престиж")
drop if regexm(version, "Комфорт")|regexm(version, "Comfort")|regexm(version, "Confort")
drop if regexm(version, "Elegance")|regexm(version, "Элеганс")
drop if regexm(version, "Premium")|regexm(version, "Adventure")
drop if regexm(version, "Edition")|regexm(version, "Anniversary")|regexm(version, "Business")
drop if regexm(version, "Active")|regexm(version, "Travel")
drop if regexm(version, "Climate")|regexm(version, "Ambition")|regexm(version, "Norma")
drop if regexm(version, "Trend")|regexm(version, "Sport")
drop if regexm(version, "Tekna")|regexm(version, "Supreme")
drop if regexm(version, "Plus")|regexm(version, "Плюс")
drop if regexm(version, "Рысь")|regexm(version, "Металлик")
drop if regexm(version, "Extreme")|regexm(version, "Titanium")
drop if regexm(version, "Privilege")
drop if regexm(version, "\+")
drop if regexm(version, "II")
*/
