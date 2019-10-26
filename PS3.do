//i like your flow--clean, well commented, great job! 
//one thing that breaks it: when you save aloways give ,replace
//otherwhise on second run it breaks
//still, the problem is that the ps asked for 5 merges and you have 4 AND i dont see reshape

/* PS3 Code: More Merge */
/* The purpose of this code is to merge a total of 5 datasets together to form a dataset which can be used to generate some neat data
The reason for combining the following datasets is to identify the effect, if any, of Philadelphia sports team losses and wins on reports
of crime in the City of Philadelphia. The purpose of including complaints against police and weather is to use these datasets for covariates*/
//could add a bit more like in shibin's repo linked from my todays email

*First, the usual: code from PS1

clear         
set matsize 800 
version 16
set more off
cap log close 
set logtype text

cap mkdir ~\Desktop\DataManagementRP
cd ~\Desktop\DataManagementRP

log using PS3.txt, replace

*We're combining the crimes/complaints dataset with three new datasets
*The first new dataset will provide dates and game outcomes (win/loss) for the Philadelphia Eagles
*This data comes from https://www.kaggle.com/maxhorowitz/nflplaybyplay2009to2016
/*Description from the website hosting the data: The dataset made available on Kaggle contains all the regular season plays from the 2009-2016 NFL seasons. 
The dataset has 356,768 rows and 100 columns. Each play is broken down into great detail containing information
on: game situation, players involved, results, and advanced metrics such as expected point and win probability
values. Detailed information about the dataset can be found at the following web page, along with
more NFL data: https://github.com/ryurko/nflscrapR-data. */
//good
/*The following two lines were done to the data prior to uploading it to git, in order to make it smaller. Online file hosting didn't agree with Stata */
*drop if hometeam!="PHI" & awayteam!="PHI"
*keep Date hometeam awayteam home_wp_pre away_wp_pre
//very good!
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
*This data comes from https://data.world/dataquest/mlb-game-logs
/* Description from website hosting the dataset: The game logs contain a record of major league games 
played from 1871-2018. At a minimum, it provides a listing of the date and score of each game. Where our
research is more complete, we include information such as team statistics, winning and losing pitchers, 
linescores, attendance, starting pitchers, umpires and more. There are 161 fields in each record, 
described in more detail in the Guide to Retrosheet Game Logs. */

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
*This data comes from https://wonder.cdc.gov/nasa-nldas.html
/*Description from website hosting the dataset: The North America Land Data Assimilation System (NLDAS) 
data available on CDC WONDER are county-level daily average air temperatures and heat index measures spanning
the years 1979-2011. Temperature data are available in Fahrenheit or Celsius scales. Reported measures are 
the average temperature, number of observations and range for the daily maximum and minimum air temperatures, as 
well as percent coverage for the daily maximum heat index. Data are available by place (combined 48 contiguous 
states, region, division, state, county), time (year, month, day) and specified maximum and minimum air
temperature, and heat index value. */

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

**********
*CODE THAT FOLLOWS IS FROM PS2
**********
*This data is from https://www.opendataphilly.org/dataset/police-complaints
/*Description from website hosting the dataset: As part of the Philadelphia Police
Department's (PPD) accountability processes, PPD publishes two datasets: The Complaints
Against Police (CAP) dataset documents the civilian complaints alleging police misconduct
and the CAP Findings dataset provides demographic details of the police officer involved, 
the allegations, and the status of the PPD's Internal Affairs Division's investigation
of and findings (if available) about the allegation. Includes data from the past five 
years. Updated monthly. */


insheet using https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/PAC_Complaints_2009_2012.csv
drop X y action status
generate date = date(date_, "YMD#hms#")
drop date_
format date %td
gen year=year(date)
gen month=month(date)
gen day=day(date)
encode type, generate(type2)
encode unit, generate(unit2)
drop race sex type unit
drop if type2 >3 & type2 <8
drop if unit2 <3 | unit2 >25
bys year month unit2: egen type2mode=mode(type2), max
keep year month type2 unit2 type2mode
collapse (first) type2mode, by (year month unit2)
label values type2mode type2
recast byte unit2
save complaintsTrim, replace
clear

*This dataset comes from https://www.opendataphilly.org/dataset/crime-incidents
/*Description from website hosting the dataset: Crime incidents from the Philadelphia 
Police Department. Part I crimes include violent offenses such as aggravated assault, 
rape, arson, among others. Part II crimes include simple assault, prostitution, 
gambling, fraud, and other non-violent offenses. This dataset previously had separate
endpoints for various years and types of incidents. These have since been consolidated
into a single dataset. */

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

**********
*END CODE FROM PS2
**********

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
ta year month if _merge==1
ta year month if _merge==2
//The only overlap here exists in 2011, for month 12, 4 cases were unique to using only,
but 0 cases were unique to master only, telling us that these non-merges from using are justified. 
In all other cases, the year and month are not congruent between the two datasets, which explains 
their non-merging. //

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
ta year month if _merge==1
ta year month if _merge==2
//A few instances where year and month overlap, but not day//

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
ta year month if _merge==1
ta year month if _merge==2
//No overlap, datasets have some coverage of different years which explains the non-matched cases
drop if _merge!=3
drop _merge
*Save the final dataset!
save crimeSportsWeatherMerge
