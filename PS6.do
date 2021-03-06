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
global clean keep year month day City phiWin chiWin

**********
*CODE THAT FOLLOWS IS MODIFIED FROM PS3
**********

*We're combining the crimes/complaints dataset with new datasets
*The first new dataset will provide dates and game outcomes (win/loss) for Philadelphia and Chicago football teams
*This data comes from https://www.kaggle.com/maxhorowitz/nflplaybyplay2009to2016
/*Description from the website hosting the data: The dataset made available on Kaggle contains all the regular season plays from the 2009-2016 NFL seasons. The dataset has 356,768 rows and 100 columns. Each play is broken down into great detail containing information on: game situation, players involved, results, and advanced metrics such as expected point and win probability values. Detailed information about the dataset can be found at the following web page, along with more NFL data: https://github.com/ryurko/nflscrapR-data. */


/*The following lines of code were run prior to uploading it to git, in order to make it smaller */
/*
insheet using NFL.csv, clear

drop if time!="00:00"
drop if timesecs!="0"

keep Date hometeam awayteam home_wp_pre away_wp_pre
*dropped most of the variables, as they related to individual plays and positions, rather than overall score. But totally neat for like fantasy football or something, if that's a thing you'd like to check out.

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
recode home_wp_pre (.5/1=1 win) (0/.5=0 loss), gen(homeWin)
encode hometeam, g(homeTeam)
*CHI = 5, PHI = 22
encode awayteam, g(awayTeam)
*CHI = 6, PHI = 25
keep if homeTeam==5 | homeTeam==22
gen phiWin=0
gen chiWin=0
gen City=0
replace City=1 if homeTeam==5
replace phiWin=1 if homeTeam==22 & homeWin==1
replace chiWin=1 if homeTeam==5 & homeWin==1
collapse homeTeam awayTeam phiWin chiWin, by(year month day City)
lab values homeTeam homeTeam
lab values awayTeam awayTeam
la var phiWin "Binary indicating whether Philadelphia won while playing in Philadelphia"
la var chiWin "Binary indicating whether Chicago won while playing in Chicago"
$clean
save NFLwins, replace
	
*The second new dataset will supplement the first, providing dates and game outcomes (win/loss) for Philadelphia and Chicago baseball teams
*This data comes from https://data.world/dataquest/mlb-game-logs
/* Description from website hosting the dataset: The game logs contain a record of major league games played from 1871-2018. At a minimum, it provides a listing of the date and score of each game. Where our research is more complete, we include information such as team statistics, winning and losing pitchers, linescores, attendance, starting pitchers, umpires and more. There are 161 fields in each record, described in more detail in the Guide to Retrosheet Game Logs. */

/*The following lines of code were run prior to uploading it to git, in order to make it smaller */

/*
insheet using MLB.csv, clear
keep date v_name h_name v_score h_score attendance
save MLB, replace
*/

use "https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/MLB.dta", clear
tostring date, replace
generate ndate=date(date, "YMD")
drop date
rename ndate date
format date %td
$y
$m
$d
*Earliest NFL records are from 2009, so we don't need baseball data from 1871...
drop if year<2009
*Chicago = CHN (WHY?)
keep if h_name=="PHI" | h_name=="CHN"
encode v_name, g(vis)
encode h_name, g(home)
*CHN = 1, PHI = 2
gen phiWin=0
gen chiWin=0
replace phiWin=1 if home==2 & v_score<h_score
replace chiWin=1 if home==1 & v_score<h_score
gen City=0
replace City=1 if home==1
order year month day
collapse home vis phiWin chiWin, by(year month day City)
lab values vis vis
lab values home home
la var phiWin "Binary indicating whether Philadelphia won while playing in Philadelphia"
la var chiWin "Binary indicating whether Chicago won while playing in Chicago"
$clean
save MLBwins, replace

append using NFLwins
save MASTERwins, replace

*This dataset will supplement the previous datasets, providing dates and game outcomes (win/loss) for Philadelphia and Chicago hockey teams
*This data comes from https://www.kaggle.com/martinellis/nhl-game-data/data#game.csv
/* Description from website hosting the dataset: This is not just the results and player stats of NHL games but also details on individual plays such as shots, goals and stoppages including date & time and x,y coordinates. The dataset is incomplete, there are some games where no plays information is available on NHL.com. It is rare and I do not know the reasons. */

insheet using "https://github.com/rpletcher09/Refrigerator/raw/master/NHL.csv", clear
generate date = date(date_time, "YMD")
format date %td
$y
$m
$d
drop game_id season type venue* date_t*
order year month day
rename home_team_id team_id
*Okay, great. Where's the team ID data?!
save NHL, replace

insheet using "https://github.com/rpletcher09/Refrigerator/raw/master/NHLkey.csv", clear
keep team_id shortname abbreviation
save NHLkey, replace

use NHL, clear
merge m:1 team_id using NHLkey
drop if abbreviation!="CHI" & abbreviation!="PHI"
encode shortname, g(City)
recode City (1=1)(2=0)
gen phiWin=0
gen chiWin=0
replace phiWin=1 if team_id==4 & away_goals<home_goals
replace chiWin=1 if team_id==16 & away_goals<home_goals
$clean
save NHLwins, replace

use MASTERwins, clear
append using NHLwins
save MASTERwins, replace

*This dataset will supplement the previous datasets, providing dates and game outcomes (win/loss) for Philadelphia and Chicago basketball teams
*This data comes from https://www.kaggle.com/pablote/nba-enhanced-stats
/* Description from website hosting the dataset: Dataset is based on box score and standing statistics from the NBA. */

insheet using "https://github.com/rpletcher09/Refrigerator/raw/master/NBA.csv", clear
keep gmdate teamabbr teamloc teamrslt
generate date = date(gmdate, "YMD")
format date %td
$y
$m
$d
drop if teamabbr!="CHI" & teamabbr!="PHI"
drop if teamloc!="Home"
gen City=0
replace City=1 if teamabbr=="CHI"
gen phiWin=0
gen chiWin=0
replace phiWin=1 if teamabbr=="PHI" & teamrslt=="Win"
replace chiWin=1 if teamabbr=="CHI" & teamrslt=="Win"
$clean
save NBAwins, replace

use MASTERwins, clear
append using NBAwins
collapse phiWin chiWin, by(year month day City)
replace phiWin=round(phiWin, 1)
replace chiWin=round(chiWin, 1)
save MASTERwins, replace

//this is awesome to use these data!
*The third dataset is daily weather data for the county of Philadelphia and city of Chicago from the CDC.
*This data comes from https://wonder.cdc.gov/nasa-nldas.html
/*Description from website hosting the dataset: The North America Land Data Assimilation System (NLDAS) data available on CDC WONDER are county-level daily average air temperatures and heat index measures spanning the years 1979-2011. Temperature data are available in Fahrenheit or Celsius scales. Reported measures are the average temperature, number of observations and range for the daily maximum and minimum air temperatures, as well as percent coverage for the daily maximum heat index. Data are available by place (combined 48 contiguous states, region, division, state, county), time (year, month, day) and specified maximum and minimum air temperature, and heat index value. */

insheet using "https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/weather.csv", clear
generate date = date(monthdayyearcode, "MDY")
format date %td
$y
$m
$d
rename avgdailymaxairtemperaturef hitemp
*lol yeehaw
order year month day
gen City=0
replace City=1 if statecode==17
drop notes monthd* state* date
collapse hitemp, by(year month day City)
*Slide those pesky dates around
save weather, replace

*Department of redundancy department

**********
*CODE THAT FOLLOWS IS MODIFIED FROM PS2
**********

*This data is from https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-present/ijzp-q8t2
/*Description from website hosting the dataset: This dataset reflects reported incidents of crime (with the exception of murders where data exists for each victim) that occurred in the City of Chicago from 2001 to present, minus the most recent seven days. Data is extracted from the Chicago Police Department's CLEAR (Citizen Law Enforcement Analysis and Reporting) system. In order to protect the privacy of crime victims, addresses are shown at the block level only and specific locations are not identified. Should you have questions about this dataset, you may contact the Research & Development Division of the Chicago Police Department at PSITAdministration@ChicagoPolice.org. */

/*The following lines of code were run prior to uploading it to git, in order to make it smaller */

/*
insheet using crimeCHI.csv, clear
drop if year<2009
keep date primarytype arrest latitude longitude
save CHIcrime, replace
*/

*CHIcrime.zip was then added to github using gitbash command line.

unzipfile https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/CHIcrime.zip
use CHIcrime, clear
gen ndate=substr(date,1,10)
split ndate, parse(/) gen(date1)
replace ndate=date11+date12+date13
drop date
generate date = date(ndate, "MDY")
format date %td
$y
$m
$d
drop ndate date1*
rename primarytype crime
drop if missing(crime)
gen City = 1

save CHIcrime, replace

*This dataset comes from https://www.opendataphilly.org/dataset/crime-incidents
/*Description from website hosting the dataset: Crime incidents from the Philadelphia Police Department. Part I crimes include violent offenses such as aggravated assault, rape, arson, among others. Part II crimes include simple assault, prostitution, gambling, fraud, and other non-violent offenses. This dataset previously had separate endpoints for various years and types of incidents. These have since been consolidated into a single dataset. */

/*The following lines of code were run prior to uploading it to git, in order to make it smaller */
/*
insheet using crimePHI.csv, clear
keep dispatch_date text_general_code lat lng
save crimeShort, replace
*/

unzipfile https://raw.githubusercontent.com/rpletcher09/Refrigerator/master/crimeShort.zip
use crimeShort, clear
generate date = date(dispatch_date, "YMD")
format date %td
$y
$m
$d
drop dispatch_date lat lng
order year month day
/*
replace lat = round(lat,.001)
replace lng = round(lng,.001)
*Commenting these out because this merge (coming up) isn't working out the way that I hoped it would. It's fine, it's really outside the scope. Other daily datasets would be more useful here. Oh well.
*/
save crimePHI, replace
*Rounded lat and long to three decimal places (apparently accurate to 110 meters, so that's pretty detailed) in the hopes that more coordinates will merge.

**********
*END CODE FROM PS2
**********

/*
*Census tract data from opendataphilly*
insheet using "https://github.com/rpletcher09/Refrigerator/raw/master/CensusT.csv", clear
rename geoid10 geoid
save census, replace

insheet using "https://github.com/rpletcher09/Refrigerator/raw/master/ZIP.csv", clear
keep if state==42
keep zcta5 state county tract geoid zpop
merge m:1 geoid using census
*We only merged 583 census tract IDs, which we should expect because the census data was for Philadelphia specifically, where the zip code to census tract data was statewide.
drop if _merge!=3
save ZIP, replace
*collapse (first) zcta5 zpop intptlat10 intptlon10, by (geoid)
rename intptlat10 lat
rename intptlon10 lng
replace lat = round(lat,.001)
replace lng = round(lng,.001)
*Rounded lat and long to three decimal places (again, accurate to 110 meters).
save zipCen, replace

use crimePHI, clear
merge m:1 lat lng using zipCen

*This merge is not going to provide the level of detail that I hoped it would. Maybe in GIS software, this would be plottable or usable, but it's not for these hypotheses and this data, so...oh well.

*/

rename text_general_code crime
drop if missing(crime)
gen City = 0

append using CHIcrime

encode crime, g(ccrime)
drop crime arrest latitude longitude

*PROBABLY REGEX HERE*

recode ccrime (1 6 = 100 "Arson")(2/4 45 = 200 "Assault")(7=205 "Battery")(5 40 28/29 30 43 36/38 = 400 "Other")(8/10 = 500 "Burglary")(11 65/66 = 300 "Weapons violation")(12 24 46/47 50 53 58 59 = 900 "Sex crime")(13 64 = 101 "Vandalism/criminal mischief")(14 63 = 102 "Vagrancy/loitering")(15 18/20 = 103 "Deceptive practices")(16/17 40 48/49 51 = 104 "Drunk and disorderly")(21/22 = 105 "Gambling violations")(23 25/27 = 106 "Homicide")(31/32 = 108 "Liquor law violations")(33/34 54/55 60/62 = 201 "Theft")(35 39 42 = 202 "Drug violations")(41 44 = 203 "Domestic offense")(52 56/57 = 204 "Robbery"),g(crime)
drop ccrime
label variable crime "Type of crime"
label define City 0 "Philadelphia" 1 "Chicago"
label values City City

save crimeLong, replace

merge m:1 year month day City using MASTERwins

*Neat, we matched 1.6 million observations! What didn't match? Only dates in the master (crime) dataset, which we expected because the date range of the crime datasets far exceed the date range of the sports data.

keep if _merge==3
drop _merge

save crimeSports, replace

*So, now that we have incorporated all the sports data, it's time for the weather.

merge m:1 year month day City using weather

*We matched 508,000 observations. Seems I might have been wrong about the weather data having EVERY day. Sometimes there are days where there is no weather. Sometimes weather just doesn't happen. Scary.
ta year month if _merge==2
*There are days in each month where no sports games occurred, hence the (relatively few) non-merges from using
drop _merge
*Save the final dataset!
save CSW, replace

**********
*END CODE FROM PS3
**********

**********
*CODE THAT FOLLOWS IS MODIFIED FROM PS4
**********

*What might some graphs look like? Bar of average crime count for wins and losses, correlation between baseball game attendance and number of crimes, correlation between air temperature and crime (to justify using temperature as a covariate), look for differences in types of crimes when Philly lost or won.
*Bar average crime count
*Need a new var to take the average of, count crimes per day
bys year month day City: egen crimeCount=count(crime)
drop if missing(crime)
*Get rid of observations with no crime data...
*HEY WOAH WE HAVE values for win and loss that are NON INTEGERS. What gives?
replace phiWin = round(phiWin,1)
replace chiWin = round(chiWin,1)
*Okay, fixed it
*ALSO: Do we care about Chicago sports outcomes for Philadelphia crime? NO. Could we have fixed this earlier in the code? YES. Are we going to rewrite the code? AGAIN, NO.
gen outcome=0
replace outcome=1 if City==0 & phiWin==1
replace outcome=1 if City==1 & chiWin==1
label define outcome 0 "Loss" 1 "Win"
label values outcome outcome
decode crime, gen(cr)
drop phiWin chiWin crime

save Sports, replace
collapse crimeCount outcome, by (year month day City)
label values outcome outcome

graph bar (mean) crimeCount, over(outcome) over(City) stack ytitle(Average frequency of crime) title(Frequency of crimes by city and game outcome)
graph export "crimeBar.pdf", as(pdf) name("Graph") replace
*Looks like crime counts are similar for Philadelphia team wins and losses, but slightly lower for Chicago team wins! Of course, we'll test that with a statistical test to figure out whether it's significant or not.
anova crimeCount outcome City outcome#City
*And it turns out that F(1) = 3888.40, p < .001, so there is a significant effect of city on the amount of crimes reported. This is the only significant effect; there is no main effect of game outcome, nor is there an interaction effect between city and game outcome.

*MAKE THESE DOTS SMALLER OR HOLLOW

*Correlation between temperature and crime frequency
use Sports, clear
collapse crimeCount hitemp, by (year month day City)
twoway (scatter crimeCount hitemp) (lfit crimeCount hitemp), ytitle(Frequency of crime per day) xtitle(Temperature in Fahrenheit) xlabel(#10) title(Frequency of crime by temperature) legend(order(1 "Daily average" 2 "Fitted values"))
graph export "tempCrime.pdf", as(pdf) name("Graph") replace
*Yes, exactly! A positive correlation between crimes per day and temperature. It should be included as a covariate!
cor crimeCount hitemp
*With an r = 0.16, there is a weak positive correlation between crime frequency and temperature.

*Side by side bar charts to compare crimes when the home team won or lost at home
use Sports, clear
tab cr outcome, chi2
*CHECK THAT OUT. Frequency of different TYPES of crime is not independent of (or in other words, is related to) sports outcomes, with a x^2(17) = 649.44, p < .001

*CONSIDER CHART FOR EACH CRIME, RATHER THAN WIN/LOSS, AND THEN OUTPUT ALL THOSE; POSSIBLY OPTIMIZE*

encode cr, gen(crime)
histogram crime if outcome==0, discrete percent xtitle(Type of crime) xlabel(1(1)18, labsize(small) angle(forty_five) valuelabel) title(Home team loss)
graph save loss, replace
histogram crime if outcome==1, discrete percent yscale(alt) xtitle(Type of crime) xlabel(1(1)18, labsize(small) angle(forty_five) valuelabel) title(Home team win)
graph save win, replace
gr combine loss.gph win.gph, title(Distribution of crimes when home teams lost and won at home)
graph export "gameOutcomeCrimeFreq.pdf", as(pdf) name("Graph") replace
*The distribution of crimes remains largely the same for wins and losses, with two exceptions: when the home team wins at home, there are more instances of battery, and more instances of liqour law violations!

*Let's look at this on a city level. WITH A LOOP.
levelsof City, local(levels)
local vlname: value label City
foreach L of local levels {
	local vl: label `vlname' `L'
	display "`vl'"
	display "`L'"
	preserve
	keep if City==`L'
	histogram crime if outcome==0, discrete percent xtitle(Type of crime) xlabel(1(1)18, labsize(small) angle(forty_five) valuelabel) title(Home team loss)
	graph save "`vl'loss", replace
	histogram crime if outcome==1, discrete percent yscale(alt) xtitle(Type of crime) xlabel(1(1)18, labsize(small) angle(forty_five) valuelabel) title(Home team win)
	graph save "`vl'win", replace
	gr combine "`vl'loss.gph" "`vl'win.gph", ycommon title("`vl'" crimes)
	graph export "`vl'OutcomeCrimeFreq.pdf", as(pdf) name("Graph") replace
	restore
}
*In Philadelphia, the only notable change is a decrease in deceptive practices when the home team has won at home. For Chicago, the only notable difference is a slight decrease in burglary when the home team has won at home.

*Plots over time!

*MAKE THESE LINES THINNER and dates smaller and formatted!*
*ALSO CONSIDER TRENDLINES FOR EACH CITY*

collapse crimeCount, by (date City)
twoway (line crimeCount date if City==0, lcolor(orange_red) lpattern(solid)) (line crimeCount date if City==1, lcolor(navy) lpattern(dash)), ytitle(Frequency of crime per day) xtitle(Date) xlabel(#20, angle(forty_five)) legend(order(1 "Philadelphia" 2 "Chicago"))
graph export "CrimeFreqOverTime.pdf", as(pdf) name("Graph") replace
*It looks like there is a noticeable downward trend in crimes, let's see how strong that downward trend is?

cor crimeCount date
*With an r = -0.42, there is a moderate negative correlation between crime frequency and date. In other words, crime seems to be on the decline!

*Do statistical analysis! Are there significantly more crimes on days where home teams lost at home than when they won at home? Are the crimes significantly different?
*Let's double back and write this code IN the chunks of code where I manipulate the dataset

**********
*END CODE FROM PS4
**********
