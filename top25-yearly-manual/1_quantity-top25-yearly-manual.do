*** Description: 
*** - 1) imports xlsx files with yearly quantities from 2010 to 2017.

********************************************************************************
* Choose if you want all cars or starting from 2013
* 0 - all
* 1 - starting 2013
local choose=0
********************************************************************************

cd "/Users/Anna/Documents/IO field paper/Data/quantity"
capture erase quantity-top25-yearly-manual.dta
if `choose'==1 capture erase quantity-top25-2013.dta

*** 1) importing xlsx files
local filelist: dir "yearly" files "20*.xlsx"

local top25range_2010 "B243:I268"
local top25range_2011 "B241:I266"
local top25range_2012 "B254:I279"
local top25range_2013 "B254:K279"
local top25range_2014 "B293:L318"
local top25range_2015 "B278:L303"
local top25range_2016 "B289:L314"
local top25range_2017 "B278:L303"


foreach file of local filelist {
	local cell = subinstr("`file'", ".xlsx", "",1)
	di "`cell'"
	import excel "yearly/`file'", sheet("Sheet1") cellrange("`top25range_`cell''") firstrow clear
	
	* need to rename variables that don't have proper names
	if "`cell'"=="2010"|"`cell'"=="2011"|"`cell'"=="2012"|"`cell'"=="2013" {
		local varl "_all"
	}
	if  "`cell'"=="2014"|"`cell'"=="2015"|"`cell'"=="2016"|"`cell'"=="2017" {
		local varl "H-L"
	}
	
	local i=1
	foreach v of varlist `varl' {
		if `i'==1 capture rename `v' model
		else if `i'==2 capture rename `v' brand
		else {
			local x : variable label `v'
			capture rename `v' `x'
			if _rc!=0 {
				capture rename `v' JanDec`x'
			}
		}
		local i=`i'+1
	}	
	
	** Clearing for merge across different years
	replace model=regexs(1) if regexm(model, "New (.*)")
	replace model=substr(model, 1, 1)+ lower(substr(model, 2, .))
	replace model="2014/2015/2017" if model=="2015/2017"
	replace model="Astra" if regexm(model, "Astra(.*)")
	
	replace brand=substr(brand, 1, 1)+ lower(substr(brand, 2, .))
	replace brand="Skoda" 	if substr(brand, 3, .)=="koda"
	replace brand="Volkswagen" if brand=="Vw"
	
	keep model brand JanDec`cell'
	rename JanDec* quantity*
	
	capture confirm file "quantity-top25-yearly-manual.dta"
	if _rc==0 {
		merge 1:1 model brand using "quantity-top25-yearly-manual", nogenerate
	}
	
	save quantity-top25-yearly-manual, replace
}

** not necessary
/*
if `choose'==1 {
	drop quantity2012-quantity2010
	drop if quantity2017==.&quantity2016==.&quantity2015==.&quantity2014==.&quantity2013==.
	save "quantity-top25-2013", replace

}
*/
