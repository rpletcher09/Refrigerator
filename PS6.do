/*Plot variables over time! line plots
when you say:
*I manipulated this dataset prior to uploading it to git
say how you manipulated it!
*/

/* PS6 Code: Draft of final project */
/* The purpose of this code is to merge datasets collected from the internet together to form a dataset which can be used to generate meaningful analyses and statistical visualizations.
The reason for combining the following datasets is to identify the effect, if any, of Philadelphia sports team losses and wins on reports of crime in the City of Philadelphia. The purpose of including complaints against police and weather is to use these datasets for covariates. Additional data has been incorporated for the city of Chicago to compare the two cities and determine whether the effects (if any) on crime reports are exclusive to Philadelphia, or are common in all large cities with sports teams. */

*First, the usual: code from PS1
clear         
set matsize 800 
version 16
set more off
cap log close 
set logtype text
cap mkdir ~\Desktop\DataManagementRP
cd ~\Desktop\DataManagementRP
log using PS6.txt, replace

*Macros
global y gen year=year(date)
global m gen month=month(date)
global d gen day=day(date)

**********
*CODE THAT FOLLOWS IS FROM PS3
**********

*We're combining the crimes/complaints dataset with three new datasets
*The first new dataset will provide dates and game outcomes (win/loss) for the Philadelphia Eagles
*This data comes from https://www.kaggle.com/maxhorowitz/nflplaybyplay2009to2016
/*Description from the website hosting the data: The dataset made available on Kaggle contains all the regular season plays from the 2009-2016 NFL seasons. The dataset has 356,768 rows and 100 columns. Each play is broken down into great detail containing information on: game situation, players involved, results, and advanced metrics such as expected point and win probability values. Detailed information about the dataset can be found at the following web page, along with more NFL data: https://github.com/ryurko/nflscrapR-data. */


/*The following lines of code were run prior to uploading it to git, in order to make it smaller */
/*
insheet using NFL.csv, clear

*dropped most of the variables, as they related to individual plays and positions, rather than overall score. But totally neat for like fantasy football or something, if that's a thing you'd like to check out.

drop if time!="00:00"
drop if timesecs!="0"

keep Date hometeam awayteam home_wp_pre

gen keep=0
foreach t of varlist hometeam awayteam {
replace keep=1 if `t'=="PHI" | `t'=="CHI"
}

drop if keep==0
drop keep
save NFL, replace
*/

*NFL.dta was then added to github using gitbash command line. Why? Practice.

use "https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/NFL.dta", clear
drop if home_wp_pre=="NA"
generate date = date(Date, "YMD")
format date %td
$y
$m
$d
destring home_wp_pre, replace
destring away_wp_pre, replace
recode home_wp_pre (.5/1=1 win) (0/.5=0 loss), gen(homeWin)
drop Date home_wp_pre
encode hometeam, g(homeTeam)
*CHI = 5, PHI = 22
encode awayteam, g(awayTeam)
*CHI = 6, PHI = 25
keep if homeTeam==5 | homeTeam==22
gen phiWin=0
gen chiWin=0
replace phiWin=1 if homeTeam==22 & homeWin==1
replace chiWin=1 if homeTeam==5 & homeWin==1
la var phiWin "Binary indicating whether Philadelphia won while playing in Philadelphia"
la var chiWin "Binary indicating whether Chicago won while playing in Chicago"
collapse homeTeam awayTeam phiWin, by(year month day)
label values homeTeam homeTeam
label values awayTeam awayTeam
save eaglesWins, replace
clear
*The second new dataset will supplement the first, providing dates and game outcomes (win/loss) for the Philadelphia Phillies
*This data comes from https://data.world/dataquest/mlb-game-logs
/* Description from website hosting the dataset: The game logs contain a record of major league games played from 1871-2018. At a minimum, it provides a listing of the date and score of each game. Where our research is more complete, we include information such as team statistics, winning and losing pitchers, linescores, attendance, starting pitchers, umpires and more. There are 161 fields in each record, described in more detail in the Guide to Retrosheet Game Logs. */
/*The following line was done to the data prior to uploading it to git, in order to make it smaller. Online file hosting didn't agree with Stata */
*keep date v_name h_name v_score h_score attendance
use https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/MLB.dta
tostring date, replace
generate ndate=date(date, "YMD")
drop date
rename ndate date
format date %td
$y
$m
$d
drop if year<2009
drop if v_name!="PHI" & h_name!="PHI"
encode v_name, g(vis)
encode h_name, g(home)
drop ndate v_name h_name
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
/*Description from website hosting the dataset: The North America Land Data Assimilation System (NLDAS) data available on CDC WONDER are county-level daily average air temperatures and heat index measures spanning the years 1979-2011. Temperature data are available in Fahrenheit or Celsius scales. Reported measures are the average temperature, number of observations and range for the daily maximum and minimum air temperatures, as well as percent coverage for the daily maximum heat index. Data are available by place (combined 48 contiguous states, region, division, state, county), time (year, month, day) and specified maximum and minimum air temperature, and heat index value. */
insheet using https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/weather.csv
generate date = date(monthdayyearcode, "MDY")
format date %td
$y
$m
$d
drop date monthdayyear monthdayyearcode
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
/*Description from website hosting the dataset: As part of the Philadelphia Police Department's (PPD) accountability processes, PPD publishes two datasets: The Complaints Against Police (CAP) dataset documents the civilian complaints alleging police misconduct and the CAP Findings dataset provides demographic details of the police officer involved, the allegations, and the status of the PPD's Internal Affairs Division's investigation of and findings (if available) about the allegation. Includes data from the past five years. Updated monthly. */
insheet using https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/PAC_Complaints_2009_2012.csv
generate date = date(date_, "YMD#hms#")
format date %td
$y
$m
$d
encode type, generate(type2)
encode unit, generate(unit2)
drop if type2 >3 & type2 <8
drop if unit2 <3 | unit2 >25
bys year month unit2: egen type2mode=mode(type2), max
keep year month type2 unit2 type2mode
collapse (first) type2mode, by (year month unit2)
label values type2mode type2

save complaintsTrim, replace
clear
*This dataset comes from https://www.opendataphilly.org/dataset/crime-incidents
/*Description from website hosting the dataset: Crime incidents from the Philadelphia Police Department. Part I crimes include violent offenses such as aggravated assault, rape, arson, among others. Part II crimes include simple assault, prostitution, gambling, fraud, and other non-violent offenses. This dataset previously had separate endpoints for various years and types of incidents. These have since been consolidated into a single dataset. */
unzipfile https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/crimeShort.zip
use crimeShort
*I manipulated this dataset prior to uploading it to git
recode dc_dist (1=3)(2=11)(3=17)(4=20)(5=21)(6=22)(7=23)(8=24)(9=25)(10 11 13 = 99)(12=4)(14=5)(15=6)(16=7)(17=8)(18=9)(19=10)(20 21 27 28 29=99)(22=12)(23=13)(24=14)(25=15)(26=16)(30/34=99)(35=18)(36/38=99)(39=19), gen(unit2)
*As with the prior data, recoding this to match the value labels previously generated.
drop dc_dist
merge m:1 year month unit2 using complaintsTrim
drop if _merge!=3

**********
*END CODE FROM PS2
**********

gen day=day(date)
order year month day unit2
*More date sliding, and generated day (why was that missing from before?? Get it together, me!)
encode text_general_code, g(crime)
recode crime (1/2 19 = 1 Assault)(5/6 = 2 Burglary)(9/12 15 = 3 White_Collar)(13/14 = 4 Homicide)(16 24/25 28/29 = 5 Theft)(3/4 18 30 31 32 = 6 Other)(7/8 22 = 7 Drunk_Disorderly)(17 = 8 Drugs)(20/21 23 = 9 Sex_Crime)(26/27 = 10 Robbery),g(ccrime)
drop text_general_code crime _merge
save crimeShortMerge, replace
/*Deprecate this, maybe?
*Re...shape? It doesn't really need to be done for this dataset, but for the sake of the grade...let's reshape.
bys year month day unit2: egen crime1mode=mode(ccrime), max
collapse crime1mode type2mode date, by(year month day unit2)
label values crime1mode ccrime
label values type2mode type2
reshape wide crime1mode type2mode, i(date) j(unit2)
*So there's a wide dataset with unique dates (that would be [questionably] easier for merging) that has variables for each UNIT containing the most frequent type of crime in that unit on that date and the most frequent complaint made against officers in that unit on that date.
*Is this useful for the rest of the data analysis and mergery? Not really, so I'm saving it as a side note and returning to earlier (long) data for the rest of the assignment
save crimeWide*/
merge m:1 year month day using eaglesWins
*Neat, we matched 6,000 observations (we didn't expect to get too many, considering the relatively smaller number of football games compared to crimes.)
ta year month if _merge==1
ta year month if _merge==2
/*The only overlap here exists in 2011, for month 12, 4 cases were unique to using only, but 0 cases were unique to master only, telling us that these non-merges from using are justified. In all other cases, the year and month are not congruent between the two datasets, which explains their non-merging. */
*Save the new merged data
*DO NOT drop if _merge!=3, football and baseball dates DON'T generally overlap
drop _merge
save crimeEaglesMerge, replace
*Before we merge the next dataset, the variable phiWin needs to be changed, because it exists as the same name in both datasets.
rename phiWin pEWin
merge m:1 year month day using philliesWins
*Wow, we picked up 130,000 observations from the baseball data! Way more than football. More crimes happening in a single day in warmer (baseball) weather than in colder (football) weather, so this isn't too surprising.
*Save the newly merged merge data
ta year month if _merge==1
ta year month if _merge==2
//A few instances where year and month overlap, but not day//
*DO NOT drop if _merge!=3, football and baseball dates DON'T generally overlap
drop _merge
save crimeSportsMerge, replace
*So, now that we have incorporated all the sports data, and we know the weather data is comprehensive (ie, weather happened every day), let's make the dataset a little lighter before the final merge.
*Get rid of observations without any Philly sports outcome data.
drop if pEWin==. & phiWin==.
*We dropped 125,000 observations and have 135,000 left!
*THIS, IN EFFECT, DROPS DATES WHERE THERE ARE NO PHILLY SPORTS, PERFORMING THE FUNCTION OF DROP IF MERGE!=3 FOR THE PAST TWO MERGES
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
save crimeSportsWeatherMerge, replace

**********
*END CODE FROM PS3
**********

**********
*CODE THAT FOLLOWS IS FROM PS4
**********

*Looking at the dataset, avgdailymaxheatindex has a fair amount of missing values. Let's fix that.
drop objectid psa avgdailymaxheatindex
rename avgdailymaxairtemperaturef hitemp
rename avgdailyminairtemperaturef lotemp
*lol yeehaw
*What might some graphs look like? Bar of average crime count for wins and losses, correlation between baseball game attendance and number of crimes, correlation between air temperature and crime (to justify using temperature as a covariate), look for differences in types of crimes when Philly lost or won.
*Bar average crime count
*Need a new var to take the average of, count crimes per day
bys year month day: egen crimeCount=count(ccrime)
label define phiWin 0 "Loss" 1 "Win"
label values phiWin phiWin
save PHIsports, replace
collapse crimeCount phiWin, by (year month day)
label values phiWin phiWin
graph bar (mean) crimeCount, over(phiWin)
graph save crimeBar, replace
*Looks like there are more crimes on average on days where Philadelphia teams WON! Of course, we'll test that with a statistical test to figure out whether it's significant or not.
ttest crimeCount, by(phiWin)
*And it turns out that t(513) = -1.26, p > .05, so there is no significant difference in the amount of crimes reported when Philly teams won or lost.
*Correlation between baseball attendance and number of crimes
use PHIsports, clear
collapse crimeCount attendance, by (year month day)
*not all of these entries are baseball games
drop if attendance==.
scatter crimeCount attendance || lfit crimeCount attendance
graph save attendCrime, replace
*Seems to be a very slightly negative correlation between baseball game attendance and crimes per day, but we'll check that out in more detail in a bit.
cor crimeCount attendance
*With an r = -0.06, the correlation between crime frequency and baseball game attendance is basically negligible.
*Correlation between air temperature and crime
use PHIsports, clear
collapse crimeCount hitemp, by (year month day)
scatter crimeCount hitemp || lfit crimeCount hitemp
graph save tempCrime, replace
*Yes, exactly! A positive correlation between crimes per day and temperature. It should be included as a covariate!
cor crimeCount hitemp
*With an r = 0.14, there is a weak positive correlation between crime frequency and temperature.
*Side by side bar charts to compare crimes when Philadelphia won or lost
use PHIsports, clear
tab ccrime phiWin, chi2
*CHECK THAT OUT. Frequency of different TYPES of crime is not independent of (or in other words, is related to) Philadelphia sports outcomes, with a x^2(9) = 26.58, p = .002
drop if phiWin==0
hist ccrime, freq discrete xla(1/10, valuelabel noticks) barw(0.6)
graph save win, replace
use PHIsports, clear
drop if phiWin==1
hist ccrime, freq discrete xla(1/10, valuelabel noticks) barw(0.6)
graph save loss, replace
gr combine win.gph loss.gph
graph export gameOutcomeCrimeFreq.pdf, as(pdf) name("Graph")
*There do seem to be more crimes, especially thefts, assaults, and others, when Philadelphia teams won! Interesting to note that the number of Drunk and Disorderly offenses remains relatively the same for both wins and losses.
*Do statistical analysis! Are there significantly more crimes on days where Philadelphia teams lost than when they won? Are the crimes significantly different?
*Let's double back and write this code IN the chunks of code where I manipulate the dataset

**********
*END CODE FROM PS4
**********

*So that's all cool and all, but I'm not sure the best/most necessary ways to incorporate loops into this data...
*But here we go anyway
use PHIsports, clear
*Supposing we realized a new angle for the data, that sometimes the games Philly plays in are AWAY, we want a super nuianced portrait of the city...so let's get rid of cases where the home team wasn't Philly for football and baseball.
drop if home!=21 & homeTeam!=23
*Cool, now let's say we want to make new datasets for each opposing team.
drop home homeTeam

codebook vis
levelsof vis, loc(v)
di "`v'"

foreach lev in `v'{
  preserve
  keep if vis==`lev'
save BBvisitor`lev',  replace
  restore
}
ls BB*
*That's cool but a little unhelpful because the labels didn't come across in the macro. What's the best way around that?

*Let's do the same thing for Football. We should be able to merge the datasets together (could probably do this more comprehensively BEFORE running these loops and then just run one instead of two, but that's for next iteration)

codebook awayTeam
levelsof awayTeam, loc(a)
di "`a'"

foreach lev in `a'{
  preserve
  keep if awayTeam==`lev'
save FBvisitor`lev',  replace
  restore
}
ls FB*

*Create a new variable 
gen nightAssault=0
if ccrime==1 & hour_>17 {
replace nightAssault=1
}
else if ccrime==1 & hour_<18 {
replace nightAssault=0
}
ta nightAssault
*This didn't work. That's okay, kind of forced this bit of code. It doesn't need to be in here. I will replace it with something more logical in the next PS, as I intend to bring in more data so I'll have a better/more reasonable place for a branch in my code.