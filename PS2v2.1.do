/* PS2 Code: Manipulate and Merge */
/* The purpose of this code is to manipulate and merge two datasets on a common variable */

*First, the usual: code from PS1

/* comments: plot
. use shootTrim,clear

. collapse (sum) event, by(year month)
variable event not found
r(111);

. gen event=1

. collapse (sum) event, by(year month)

. edit

. gen time=_n

. line event time





/*



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
*Cool, now we have dates we can work with
*Transform str variables to labeled integers
encode type, generate(type2)
encode unit, generate(unit2)
drop race sex type unit
drop if type2 >3 & type2 <8
drop if unit2 <3 | unit2 >25
*Cleared out some of the "Unknown" or other non-conforming units/types of complaints (Aiport division: like 5 observations or a similarly small n)
bys year month unit2: egen type2mode=mode(type2), max
*Woah. Sorted by year, month of year, unit (district) of month of year, and grabbed the mode (or most frequent type of complaint) made for each district in each month of each year. DETAILS.


*Brakes screeching, record scratching, totally moving in a different direction with the data now, so sorry if some previous code is obsolete as a result of this but HERE WE GO

keep year month type2 unit2 type2mode

*We're going to collapse this one by date(ish) to merge it with shootTrim.

collapse (first) type2mode, by (year month unit2)
*Okay, so now we're removing any observations from the same district in the same month in the same year. The good news? The mode is the same for all of 'duplicates', hence the (first) in the code, taking the first value. This is sort of a workaround to the fact that stata won't let you collapse on the mode directly, oh well.
label values type2mode type2
*Restore the old value labels to the newly created and collapsed modes.

*COOL. That took way too long. Learning, am I right?
recast byte unit2
save complaintsTrim, replace
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
save shootTrim, replace
*Save your work!

*Okay, pizza time.

merge m:1 year month unit2 using complaintsTrim

*Weird. It doesn't work, 0 matches. Why could that be?
*Oh yeah, that's right. complaints covers 2009-2012 and shootings covers 2015-2019.
*Truly brilliant

*Sigh. Fine, let's do it again with a NEW dataset.

clear
unzipfile https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/crimeShort.zip
use crimeShort
*I manipulated this dataset prior to uploading it to git (to make it small enough to actually upload, even after zipping it) so it's pretty trimmed already. But there's still work to do!
recode dc_dist (1=3)(2=11)(3=17)(4=20)(5=21)(6=22)(7=23)(8=24)(9=25)(10 11 13 = 99)(12=4)(14=5)(15=6)(16=7)(17=8)(18=9)(19=10)(20 21 27 28 29=99)(22=12)(23=13)(24=14)(25=15)(26=16)(30/34=99)(35=18)(36/38=99)(39=19), gen(unit2)
*As with the prior data, recoding this to match the value labels previously generated.
drop dc_dist
*Now that we know it recoded properly, let's get rid of it

*Okay, let's try that merge again!
merge m:1 year month unit2 using complaintsTrim
*How'd we do? We matched 259k observations, which is markedly better than the hot 0 we matched before!
drop if _merge!=3
*Get rid of the stuff that didn't merge!
save crimeShortMerge
*Great! So now what we have is a dataset that maps the most frequent complaint filed against a given police district in a given month of a given year onto the prevalence of a variety of crimes in a given district in a given month of a given year. We could definitely do some goodness of fit testing to see whether the distribution of this data is unexpected!


