//This code is to pull and clean COVID-19 data from the JHU github and stuff//

*First, the usual: code from PS1
clear         
set matsize 800 
version 16
set more off
cap log close 
set logtype text
cap mkdir ~\Desktop\DataManagementRP
cd ~\Desktop\DataManagementRP
log using COVID.txt, replace

*Macros

*Probably gonna need a current date code-thing

*CODE
insheet using "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/03-10-2020.csv", clear
drop if countryregion!="US"
gen prov=subinstr(provincestate," ","",.)
split prov, parse(,) gen(location)
drop if location2!="NJ"
drop location2 latitude longitude recovered countryregion