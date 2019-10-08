/* PS2 Code: Manipulate and Merge */
/* The purpose of this code is to manipulate and merge two datasets on a common variable */

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!//
//CODE THAT FOLLOWS IS FROM PS1//

/* Load data from online */

*First, the usual

clear         
set matsize 800 
version 16
set more off
cap log close 
set logtype text

cap mkdir ~\Desktop\DataManagementRP
cd ~\Desktop\DataManagementRP

log using PS2.txt, replace

insheet using https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/PAC_Complaints_2009_2012.csv
drop X y action status
*Ew, look at that gross string date. Let's break that out for later merging
generate date = date(date_, "YMD#hms#")
drop date_
format date %td
gen year=year(date)
gen month=month(date)
gen day=day(date)
*Transform str variables to labeled integers
encode type, generate(type2)
encode unit, generate(unit2)
drop race sex type unit
drop if type2 >3 & type2 <8
drop if unit2 <3 | unit2 >25
bys year month unit2: egen type2mode=mode(type2), max

/* Your services are no longer needed
bys year month: egen unit2mode=mode(unit2), max */

*Brakes screeching, record scratching, totally moving in a different direction with the data now, so sorry if some code is obsolete as a result of this but HERE WE GO

keep year month type2 unit2 type2mode

*We're going to collapse this one by date(ish) to merge it with shootTrim.

collapse (first) type2mode, by (year month unit2)
label values type2mode type2

*COOL. That took way too long. Learning, am I right?

outsheet using complaintsTrim.csv, replace
clear

*Alrighty, let's merge this with shootTrim
insheet using https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/shootings.csv
drop the_geom dc_key the_geom_webmercator point_x point_y code year
generate date = date(date_, "YMD")
drop date_
format date %td
gen year=year(date)
gen month=month(date)
gen day=day(date)
recode dist (1 = 3)(2=11)(3=17)(4=20)(5=21)(6=22)(7=23)(8=24)(9=25)(10 11 13 = 99)(12=4)(14=5)(15=6)(16=7)(17=8)(18=9)(19=10)(20 21 27 28 29=99)(22=12)(23=13)(24=14)(25=15)(26=16)(30/34=99)(35=18)(36/38=99)(39=19), gen(unit2)
*Neat, recoded districts in this dataset to comply with value labels in the complaints dataset (so now I can just apply that label to these after I merge them because I'm lazy)
drop dist
outsheet using shootTrim.csv, replace
*Save your work!

*Okay, pizza time.

merge m:1 year month unit2 using complaintsTrim.csv

