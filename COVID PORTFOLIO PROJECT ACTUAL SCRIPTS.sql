SELECT * 
FROM ['covid deaths$']
where continent is not null
order by 3,4


SELECT location, date, total_cases,new_cases, total_deaths,new_deaths,population 
from ['covid deaths$']
order by 1,2

--total cases vs total deaths
-- shows likelihood of dying if covid is contracted in that country
SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) as deathpercent
from ['covid deaths$']
where location like 'india'
and continent is not null
order by 1,2


SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) as deathpercent
from ['covid deaths$']
where location like '%states%'
order by 1,2


-- looking at total cases vs total population

SELECT location, date, population,total_cases,((total_cases/population)*100) as percentofpopulation
from ['covid deaths$']
where location like 'india'
order by 1,2


--Looking at countries with highest infection rate compared to population

SELECT location, population,max(total_cases) as HIGHESTINFECTIONRATE ,max((total_cases/population))*100 as percentpopinfected
from ['covid deaths$']
--where location like 'india'
group by location,population
order by percentpopinfected desc   -- we wish to order by percent of population infected in descending order from highest to lowest

--check only for india
SELECT location, population,max(total_cases) as HIGHESTINFECTIONRATE ,max((total_cases/population))*100 as percentpopinfected
from ['covid deaths$']
where location like 'india'
group by location,population
order by percentpopinfected 

--looking at countries with highest death count with population

SELECT location,max(cast(total_deaths as int)) as TOTALDEATHCOUNT -- since in the excel total_deaths is given as nvarchar we convert it to int
from ['covid deaths$']
--where location like 'india'
where continent is not null
group by location
order by TOTALDEATHCOUNT desc

--looking at continents with highest death count with population

SELECT continent,max(cast(total_deaths as int)) as TOTALDEATHCOUNT -- since in the excel total_deaths is given as nvarchar we convert it to int
from ['covid deaths$']
--where location like 'india'
where continent is not null
group by continent
order by TOTALDEATHCOUNT desc

--looking at countries with highest case count with population
SELECT location,max(cast(total_cases as int)) as TOTALCASECOUNT -- since in the excel total_deaths is given as nvarchar we convert it to int
from ['covid deaths$']
--where location like 'india'
where continent is not null
group by location
order by TOTALCASECOUNT desc


--looking at continents with highest case count with population
SELECT continent,max(cast(total_cases as int)) as TOTALcaseCOUNT -- since in the excel total_deaths is given as nvarchar we convert it to int
from ['covid deaths$']
--where location like 'india'
where continent is not null
group by continent
order by TOTALDEATHCOUNT desc


--GLOBAL NUMBERS

-- sum(new_cases) gives us the sum of all the new cases which adds up to the total cases.
-- this will give us on each day the total across the world bcz we filter by dates only
SELECT  date, sum(new_cases)as totalcases,sum(cast(new_deaths as int))as totaldeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as deathpercent
from ['covid deaths$']
--where location like 'india'
where continent is not null
group by date
order by 1,2

--remove the date column we just get the total cases overall and total deaths overall from 2020 beginning to around march 9 or 10  2022
SELECT  sum(new_cases)as totalcases,sum(cast(new_deaths as int))as totaldeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as deathpercent
from ['covid deaths$']
--where location like 'india'
where continent is not null
order by 1,2                    --based on the table we can see total cases as 450mil and total deaths as 6 million and death percent is around 1.33%


--JOIN TWO TABLES

SELECT * FROM 
[Portfolio Project]..['covid deaths$'] as dea
JOIN 
[Portfolio Project]..['covid vaccinations$'] as vac
on dea.location = vac.location
and dea.date = vac.date

-- LOOKING AT TOTAL POPULATIONS VS TOTAL VACCINATIONS
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
FROM
[Portfolio Project]..['covid deaths$'] as dea                   ---here the new vaccinations are per day
JOIN
[Portfolio Project]..['covid vaccinations$'] as vac
on dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent is not NULL
order by 2,3


--we want to add up the new_vaccinations as it increases per day for a particular location say canada 722+2298+...
--using windows fn over (partition by)i.e partition by location first since canada is a location, so that it(the window fn) runs 
-- only through canada and went it comes to the next location it doesnt keep going.
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date)
as Rollingcountofpeoplevaccinated
FROM
[Portfolio Project]..['covid deaths$'] as dea                  
JOIN
[Portfolio Project]..['covid vaccinations$'] as vac
on dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent is not NULL
order by 2,3

--We look at total population vs vaccinations so we use Rollingcountofpeoplevacinnated i.e the max no of people vaccinated
-- and divide it the total population to know how many people in that country are vaccinated
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date)
as Rollingcountofpeoplevaccinated,
--(Rollingcountofpeoplevaccinated/dea.population)*100  /*we get an error as we can't use a column that you created to get in the next one*/
FROM
[Portfolio Project]..['covid deaths$'] as dea                  
JOIN
[Portfolio Project]..['covid vaccinations$'] as vac
on dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent is not NULL
order by 2,3

-- TO CLEAR THE ERROR WE DO A COMMON TABLE EXPRESSION(CTE) which is temporary
With VACPOP ( continent,location,date,population,new_vaccinations,Rollingcountofpeoplevaccinated)
as (
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location order by dea.location, dea.date)
as Rollingcountofpeoplevaccinated
--(Rollingcountofpeoplevaccinated/dea.population)*100  /*we get an error as we can't use a column that you created to get in the next one*/
FROM
[Portfolio Project]..['covid deaths$'] as dea                  
JOIN
[Portfolio Project]..['covid vaccinations$'] as vac
on dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent is not NULL
--order by 2,3
)
select *,(Rollingcountofpeoplevaccinated/population)*100 as percentpeoplevaccinated from VACPOP



--- TO GET MAX PERCENT PEOPLE VACCINATED
With VACPOP ( location,population,new_vaccinations,Rollingcountofpeoplevaccinated)
as (
SELECT dea.location,dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location order by dea.location, dea.date)
as Rollingcountofpeoplevaccinated
--(Rollingcountofpeoplevaccinated/dea.population)*100  /*we get an error as we can't use a column that you created to get in the next one*/
FROM
[Portfolio Project]..['covid deaths$'] as dea                  
JOIN
[Portfolio Project]..['covid vaccinations$'] as vac
on dea.location=vac.location
WHERE dea.continent is not NULL
group by dea.location
--order by 2,3
)
select *,MAX((Rollingcountofpeoplevaccinated/population))*100 as percentpeoplevaccinated from VACPOP

--we'll do that later

--now temp table

Drop table if exists  #PERCENTVACCINATEDPOPULATION
CREATE TABLE #PERCENTVACCINATEDPOPULATION
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
Rollingcountofpeoplevaccinated numeric
)


Insert into #PERCENTVACCINATEDPOPULATION
 SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location order by dea.location, dea.date)
as Rollingcountofpeoplevaccinated
--(Rollingcountofpeoplevaccinated/dea.population)*100  /*we get an error as we can't use a column that you created to get in the next one*/
FROM
[Portfolio Project]..['covid deaths$'] as dea                  
JOIN
[Portfolio Project]..['covid vaccinations$'] as vac
on dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent is not NULL

select *,(Rollingcountofpeoplevaccinated/population)*100 as percentpeoplevaccinated from #PERCENTVACCINATEDPOPULATION


--CREATING VIEWS TO STORE DATA FOR LATER VISUALIZATION
CREATE VIEW PERCENTVACCINATEDPOPULATION AS
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location order by dea.location, dea.date)
as Rollingcountofpeoplevaccinated
--(Rollingcountofpeoplevaccinated/dea.population)*100  /*we get an error as we can't use a column that you created to get in the next one*/
FROM
[Portfolio Project]..['covid deaths$'] as dea                  
JOIN
[Portfolio Project]..['covid vaccinations$'] as vac
on dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent is not NULL


--WE CAN NOW QUERY OFF OF PERCENTVACCINATEDPOPULATION SINCE IT IS A VIEW AND IT IS PERMANENT





