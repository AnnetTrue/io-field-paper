program demand
	version 15
	syntax varlist if, at(name) [derivatives(varlist)]
	
	qui{
		tempvar coef
		
		*gen `coef'=price*`at'[1,1]+engine*`at'[1,2]
		matrix score `coef'=`at' `if', eq(#1)
		replace `varlist'=logshare-`coef' `if'
	
	
		if "`derivatives'" == "" {
			exit                    // no, so we are done
		}
		
		replace `derivatives'=-1 `if'
	}
	
	
end
	
