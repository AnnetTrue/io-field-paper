cd "/Users/Anna/Dropbox/IO field paper/Data"
use "complete/complete-top25-yearly.dta", clear

bysort year: egen sumq=total(quantity)
replace sumq=sumq/1000

replace price=price/1000
replace price_adj=price_adj/1000



label var price "Price (in 1000 RUR)"
label var price_adj "Price in 2013 RUR (in 1000 RUR)"
label var horsepower "Horsepower"
label var fuelcons "Fuel consumption (in l/100 km)"
label var trunk "Trunk size (in l)"
label var wheelbase "Wheelbase (in mm)"
label var body_SUV "SUV"
label var body_hatch "Hatchback/wagon"
label var rating "Rating (out of 10)"
label var sumq "Total quantity (in 1000s)"
label var national "Share of national brands"
label var length "Length (in mm)"
label var weight "Weight (in kg)"

local varl "sumq price price_adj national length weight  wheelbase  trunk  body_SUV body_hatch horsepower fuelcons  rating " 

mean `varl' [fweight=quantity] if year==2013
outreg2 using table1.tex, replace eqkeep(mean) stats(coef) label
mean `varl' [fweight=quantity] if year==2014
outreg2 using table1.tex, append eqkeep(mean) stats(coef) label
mean `varl' [fweight=quantity] if year==2015
outreg2 using table1.tex, append eqkeep(mean) stats(coef) label
mean `varl' [fweight=quantity] if year==2016
outreg2 using table1.tex, append eqkeep(mean) stats(coef) ctitle(2016) label
mean `varl' [fweight=quantity] if year==2017
outreg2 using table1.tex, append eqkeep(mean) stats(coef) ctitle(2017) label

*sum price price_adj horsepower fuelcons trunk rating wheelbase body_SUV body_hatch sumq, over(year)
