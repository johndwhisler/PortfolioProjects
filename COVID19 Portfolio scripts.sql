SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

/*SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4*/

--Data type fix

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN total_deaths FLOAT;


--Select data we're going to look at

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE total_deaths >0
ORDER BY Location, Date

--How many cases in COUNTRY and deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Rate
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'

--Chances of contracting COVID in COUNTRY by population

SELECT location, date, total_cases, population, (total_cases/population)*100 AS ContractRatio
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'

--Highest contraction ratio by country

SELECT location, population, MAX(total_cases) AS MostCases, MAX((total_cases/population))*100 as ContractRatio
FROM PortfolioProject..CovidDeaths
GROUP BY population, location
ORDER BY ContractRatio DESC

--Highest death ratio by country

SELECT location, population, MAX(total_deaths) AS MostDeaths, MAX((total_deaths/population))*100 AS DeathRatio
From PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY population, location
ORDER BY DeathRatio DESC

--Notice that continents are included;  add where clause to exclude null data in each query

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

--Evaluate deaths by continent

SELECT continent, MAX(total_deaths) AS DeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY DeathCount DESC


--Highest death ratio by continent

SELECT continent, MAX((total_deaths/population))*100 AS DeathRatio
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY DeathRatio DESC

--Data type fix

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN new_deaths FLOAT;

--Data type fix

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN new_cases FLOAT;
--Cases by date

SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathRatio
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date ASC

--Look at the vaccination data

SELECT TOP 10 *
FROM PortfolioProject..CovidVaccinations
WHERE continent IS NULL

--Join data on location and date
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, SUM(vacc.new_vaccinations) OVER(Partition BY deaths.location ORDER BY deaths.location, deaths.date) AS DailyVacc
FROM PortfolioProject..CovidDeaths AS deaths
INNER JOIN PortfolioProject..CovidVaccinations AS vacc
ON deaths.location = vacc.location
and deaths.date =  vacc.date
WHERE deaths.continent IS NOT NULL

--Change data type for population
ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN population FLOAT;

--Create a CTE to use new column in calculation

WITH PopVSVacc (continent, location, date, population, new_vaccinations, DailyVacc)
AS (
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, SUM(vacc.new_vaccinations) OVER(Partition BY deaths.location ORDER BY deaths.location, deaths.date) AS DailyVacc
FROM PortfolioProject..CovidDeaths AS deaths
INNER JOIN PortfolioProject..CovidVaccinations AS vacc
ON deaths.location = vacc.location
and deaths.date =  vacc.date
WHERE deaths.continent IS NOT NULL
)
SELECT *, (DailyVacc/population)*100 AS VaccRatio
FROM PopVSVacc
WHERE location = 'United States'

--Alternately, using a temp table
DROP TABLE IF EXISTS #percentpopvaccinated

CREATE TABLE #percentpopvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
DailyVacc numeric,
)
INSERT INTO #percentpopvaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, SUM(vacc.new_vaccinations) OVER(Partition BY deaths.location ORDER BY deaths.location, deaths.date) AS DailyVacc
FROM PortfolioProject..CovidDeaths AS deaths
INNER JOIN PortfolioProject..CovidVaccinations AS vacc
ON deaths.location = vacc.location
and deaths.date =  vacc.date
WHERE deaths.continent IS NOT NULL

SELECT *, (DailyVacc/population)*100 AS VaccRatio
FROM #percentpopvaccinated

--Store data in view for later use

CREATE VIEW percentpopvaccinated AS 
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, SUM(vacc.new_vaccinations) OVER(Partition BY deaths.location ORDER BY deaths.location, deaths.date) AS DailyVacc
FROM PortfolioProject..CovidDeaths AS deaths
INNER JOIN PortfolioProject..CovidVaccinations AS vacc
ON deaths.location = vacc.location
and deaths.date =  vacc.date
WHERE deaths.continent IS NOT NULL


--Test use of view
SELECT TOP 10 *
FROM PortfolioProject..percentpopvaccinated
WHERE location = 'France'
AND new_vaccinations IS NOT NULL