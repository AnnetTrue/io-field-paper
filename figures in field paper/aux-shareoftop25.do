*** Calculates what share of total car sales are the sales of top 25 brands

use "/Users/Anna/Documents/IO field paper/Data/quantity/quantity-top25-2013.dta", clear

insobs 1
replace quantity2017=1465000 in 39
replace quantity2016=1308000 in 39
replace quantity2015=1482000 in 39
replace quantity2014=2316000 in 39
replace quantity2013=2584000 in 39
*replace quantity2012=2734000 in  39

** Source - ey

forval i =2013/2017 {
qui sum quantity`i' in 1/38
local top25=r(sum)
qui sum quantity`i'
local tots=r(max)
di `top25'/`tots'
}

*** Results:
*.54365824
*.54658077
*.63738364
*.6482479
*.65583791
