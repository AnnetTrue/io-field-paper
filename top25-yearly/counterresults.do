cd "/Users/Anna/Dropbox/IO field paper/Data/"

import delimited "complete/counter_results.txt", delimiter(comma) encoding(utf8) clear 
 merge 1:1 _n using "complete/logit-top25-yearly.dta"
 
 rename v1 counter_price
 rename v2 change_price
 rename v3 counter_share
 rename v4 change_share
 
 bysort  year:egen counter_outshare=sum(counter_share)
 replace counter_outshare=1-counter_outshare
 
 bysort firm: sum share counter_share change_share
 
 
 
 ******
 bysort model brand: egen ever_foreign_prod=max(1-russia_prod)
 bysort model brand: egen lastyear=max(year)
 gen change_prod=ever_foreign_prod&
