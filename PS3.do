/* PS3 Code: More Merge */
/* The purpose of this code is to merge a total of 5 datasets together */

*First, the usual: code from PS1

//as far as i can tell there 4, not five datasets so need one more

clear         
set matsize 800 
version 16
set more off
cap log close 
set logtype text

cap mkdir ~\Desktop\DataManagementRP
cd ~\Desktop\DataManagementRP

log using PS3.txt, replace
//give fuller descr of what you are doing: specific hypotheses, model, vars
*We're combining the crimes/complaints dataset with three new datasets
*The first new dataset will provide dates and game outcomes (win/loss) for the Philadelphia Eagles

/*The following two lines were done to the data prior to uploading it to git, in order to make it smaller. Online file hosting didn't agree with Stata */
*drop if hometeam!="PHI" & awayteam!="PHI"
*keep Date hometeam awayteam home_wp_pre away_wp_pre

//where exactly the data come from? give exact url and full exact data descr so i can easily find it myself online
//same for other datasets
use https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/NFL.dta
generate date = date(Date, "YMD")
drop Date
format date %td
gen year=year(date)
gen month=month(date)
gen day=day(date)
drop if home_wp_pre=="NA"
destring home_wp_pre, replace
destring away_wp_pre, replace
recode home_wp_pre (.5/1=1 win) (0/.5=0 loss), gen(homeWin)
drop home_wp_pre
recode away_wp_pre (.5/1=1 win) (0/.5=0 loss), gen(awayWin)
drop away_wp_pre
encode hometeam, g(homeTeam)
encode awayteam, g(awayTeam)
gen phiWin=0
replace phiWin=1 if homeTeam==21 & homeWin==1
replace phiWin=1 if homeTeam!=21 & homeWin!=1
collapse homeTeam awayTeam phiWin, by(year month day)
label values homeTeam homeTeam
label values awayTeam awayTeam
save eaglesWins, replace
clear

*The second new dataset will supplement the first, providing dates and game outcomes (win/loss) for the Philadelphia Phillies

/*The following line was done to the data prior to uploading it to git, in order to make it smaller. Online file hosting didn't agree with Stata */
*keep date v_name h_name v_score h_score attendance

use https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/MLB.dta
tostring date, replace
generate ndate=date(date, "YMD")
drop date
format ndate %td
gen year=year(ndate)
gen month=month(ndate)
gen day=day(ndate)
drop ndate
drop if year<2009
drop if v_name!="PHI" & h_name!="PHI"
encode v_name, g(vis)
encode h_name, g(home)
drop v_name h_name
gen phiWin=0
replace phiWin=1 if vis==20 & v_score>h_score
replace phiWin=1 if vis!=20 & v_score<h_score
order year month day
*Super lazy coding follows:
collapse v* h* a* p*, by(year month day)
label values vis vis
label values home home
save philliesWins, replace
clear

//this is awesome to use these data!
*The third dataset is daily weather data for the county of Philadelphia from the CDC.
insheet using https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/weather.csv
generate date = date(monthdayyearcode, "MDY")
*Ew, data in a different format than usual
drop monthdayyear monthdayyearcode
format date %td
gen year=year(date)
gen month=month(date)
gen day=day(date)
drop date
order year month day
*Slide those pesky dates around
save weather, replace
clear

*Okay, merge these datasets
clear
*Department of redundancy department
unzipfile https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/crimeShortMerge.zip
//this breaks on my PC, does it work on yours? but i can do
//copy https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/crimeShortMerge.zip a.zip
//unzipfile  a.zip

use crimeShortMerge
gen day=day(date)
order year month day unit2
*More date sliding, and generated day (why was that missing from before?? Get it together, me!)
encode text_general_code, g(crime)
drop text_general_code
recode crime (1/2 19 = 1 Assault)(5/6 = 2 Burglary)(9/12 15 = 3 White_Collar)(13/14 = 4 Homicide)(16 24/25 28/29 = 5 Theft)(3/4 18 30 31 32 = 6 Other)(7/8 22 = 7 Drunk_Disorderly)(17 = 8 Drugs)(20/21 23 = 9 Sex_Crime),g(ccrime)
drop crime
save crimeShortMerge, replace
*Re...shape? It doesn't really need to be done for this dataset, but for the sake of the grade...let's reshape.
bys year month day unit2: egen crime1mode=mode(ccrime), max
collapse crime1mode type2mode date, by(year month day unit2)
label values crime1mode ccrime
label values type2mode type2

reshape wide crime1mode type2mode, i(date) j(unit2)
*So there's a wide dataset with unique dates (that would be [questionably] easier for merging) that has variables for each UNIT containing the most frequent type of crime in that unit on that date and the most frequent complaint made against officers in that unit on that date.
*Is this useful for the rest of the data analysis and mergery? Not really, so I'm saving it as a side note and returning to earlier (long) data for the rest of the assignment
save crimeWide
clear

use crimeShortMerge
*Oops, get rid of the old _merge first
drop _merge
merge m:1 year month day using eaglesWins
*Neat, we matched 6,000 observations (we didn't expect to get too many, considering the relatively smaller number of football games compared to crimes.)
//right, right, but do check! eg
 ta year month  if _merge ==2
 ta year month  if _merge ==1 //okay seems no overlap
 //and do check for others

*Save the new merged data
save crimeEaglesMerge
drop _merge
*Before we merge the next dataset, the variable phiWin needs to be changed, because it exists as the same name in both datasets.
rename phiWin pEWin
merge m:1 year month day using philliesWins
*Wow, we picked up 130,000 observations from the baseball data! Way more than football. More crimes happening in a single day in warmer (baseball) weather than in colder (football) weather, so this isn't too surprising.
*Save the newly merged merge data
drop _merge
save crimeSportsMerge
*So, now that we have incorporated all the sports data, and we know the weather data is comprehensive (ie, weather happened every day), let's make the dataset a little lighter before the final merge.
*Get rid of observations without any Philly sports outcome data.
drop if pEWin==. & phiWin==.
*We dropped 125,000 observations and have 135,000 left!
*For ease of future analyses, let's make a new variable indicating whether Philadelphia won, period.
rename phiWin pPWin
gen phiWin = 0
replace phiWin=1 if pPWin==1|pEWin==1
save crimeSportsMerge, replace

*Okay, time for the last dataset.
merge m:1 year month day using weather
*We matched 113,000 observations. Seems I might have been wrong about the weather data having EVERY day. Sometimes there are days where there is no weather. Sometimes weather just doesn't happen. Scary.
drop if _merge!=3
drop _merge
*Save the final dataset!
save crimeSportsWeatherMerge
