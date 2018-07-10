import excel "/Users/Anna/Documents/IO field paper/Data/quantity/monthly/quantity-2016-monthly.xlsx", sheet("2016") firstrow clear

rename Марка brand
rename Модель model
rename C Jan2016
rename D Feb2016
rename E Mar2016
rename F Apr2016
rename G May2016
rename H Jun2016
rename I Jul2016
rename J Aug2016
rename K Sep2016
rename L Oct2016
rename M Nov2016
rename N Dec2016
rename Всего JanDec2016

drop Продажив2015году
drop if brand=="всего по бренду"
drop if model==""

save quantity-2016-monthly, replace
