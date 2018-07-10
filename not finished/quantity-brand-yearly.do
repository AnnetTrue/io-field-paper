cd "/Users/Anna/Documents/IO field paper/Data/quantity/yearly"

********* NOT FINISHED!!!!

*** import all brands
local filelist: dir "." files "20*.xlsx"

local brand_2010 "A65:G121"
local brand_2011 "A66:G119"
local brand_2012 "A70:H137"
local brand_2013 "A60:G129"
local brand_2014 "A59:G139"
local brand_2015 "A60:G136"
local brand_2016 "A62:G137"
local brand_2017 "A55:G127"

local drop_2012 "38/47"
local drop_2013 "34/43"
local drop_2014 "32/47"
local drop_2015 "32/43"
local drop_2016 "32/44"
local drop_2017 "34/45"

foreach file of local filelist {
	local cell = subinstr("`file'", ".xlsx", "",1)
	* cell contains year
	di "`cell'"
	import excel "`file'", sheet("Sheet1") cellrange("`brand_`cell''") firstrow clear
	
	* drop unneeded text in the middle of the table
	if `"`drop_`cell''"' !="" drop in `drop_`cell''
	
	* need to rename variables that don't have proper names
	if "`cell'"=="2010"|"`cell'"=="2011"|"`cell'"=="2012"|"`cell'"=="2013" {
		local varl "_all"
	}
	if  "`cell'"=="2014"|"`cell'"=="2015"|"`cell'"=="2016"|"`cell'"=="2017" {
		local varl "A E-G"
	}
	
	local i=1
	foreach v of varlist `varl' {
		if `i'==1 capture rename `v' brand
		else {
			local x : variable label `v'
			capture rename `v' `x'
			if _rc!=0 {
				capture rename `v' JanDec`x'
			}
		}
		local i=`i'+1
	}	
	
*	replace brand=substr(brand, 1, 1)+ lower(substr(brand, 2, .))
*	replace brand="Skoda" 	if substr(brand, 3, .)=="koda"
	
	keep brand JanDec`cell'
	
	capture confirm string variable JanDec`cell'
	if !_rc {
		replace JanDec`cell'=. if JanDec`cell'=="-"
		destring JanDec`cell', replace
	}
	
	rename JanDec* quantity*
	
	capture confirm file "quantity-brand-yearly.dta"
	if _rc==0 {
		merge 1:1 brand using "quantity-brand-yearly", nogenerate
	}
	
	save quantity-brand-yearly, replace
}
