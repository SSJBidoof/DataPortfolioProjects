SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4



-- Select data the we're going to be using

SELECT 
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM 
	PortfolioProject..CovidDeaths AS cd
ORDER BY 
	1,2



-- Looking at total cases vs total deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	ROUND((total_deaths/total_cases) * 100,2) as DeathPercentage
FROM 
	PortfolioProject..CovidDeaths AS cd
WHERE 
	location like '%states%'
ORDER BY 
	1,2



-- Looking at the the total cases vs population
-- Shows percentage of population that contracted covid
SELECT 
	location,
	date,
	total_cases,
	population,
	ROUND((total_cases/population) * 100,2) as PercentageOfPopulationInfected
FROM 
	PortfolioProject..CovidDeaths AS cd
WHERE 
	location like '%states%'
ORDER BY 
	1,2



-- Countries with highest infection rate compared to population

SELECT 
	location,
	MAX(total_cases) as HighestInfectionCount,
	population,
	ROUND(MAX((total_cases/population)) * 100,2) as HighestPercentageOfPopulationInfected
FROM 
	PortfolioProject..CovidDeaths AS cd
GROUP BY
	location, population
ORDER BY 
	HighestPercentageOfPopulationInfected DESC



-- Countries with highest death count per population

SELECT 
	location,
	MAX(cast(total_deaths as int)) as totalDeathCount
FROM 
	PortfolioProject..CovidDeaths AS cd
WHERE 
	continent is not NULL
GROUP BY
	location
ORDER BY 
	totalDeathCount DESC



-- Breaking down by continent 

--SELECT 
--	location,
--	MAX(cast(total_deaths as int)) as totalDeathCount
--FROM 
--	PortfolioProject..CovidDeaths AS cd
--WHERE 
--	continent is null
--GROUP BY
--	location
--ORDER BY 
--	totalDeathCount DESC


-- Showing continents with the highest death count

SELECT 
	continent,
	MAX(cast(total_deaths as int)) as totalDeathCount
FROM 
	PortfolioProject..CovidDeaths AS cd
WHERE 
	continent is not NULL
GROUP BY
	continent
ORDER BY 
	totalDeathCount DESC




-- Global numbers

-- by day
SELECT 
	date,
	SUM(new_cases) as totalCases,
	SUM(cast(new_deaths as int)) as totalDeaths,
	ROUND(SUM(cast(new_deaths as int))/SUM(new_cases) * 100,2) as DeathPerc
FROM 
	PortfolioProject..CovidDeaths AS cd
WHERE 
	continent is not null
GROUP BY
	date
ORDER BY 
	1,2

-- total
SELECT 
	SUM(new_cases) as totalCases,
	SUM(cast(new_deaths as int)) as totalDeaths,
	ROUND(SUM(cast(new_deaths as int))/SUM(new_cases) * 100,2) as DeathPerc
FROM 
	PortfolioProject..CovidDeaths AS cd
WHERE 
	continent is not null
ORDER BY 
	1,2



-- total population vs vaccinations


SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as int)) 
		OVER (Partition By dea.location ORDER BY dea.location, dea.date) AS RollingVacCount
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON	
	dea.location = vac.location and dea.date = vac.date
WHERE 
	dea.continent is not null
ORDER BY
	2,3



-- using CTE
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingVacCount)
AS (
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) 
		OVER (Partition By dea.location ORDER BY dea.location, dea.date) AS RollingVacCount
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON	
	dea.location = vac.location and dea.date = vac.date
WHERE 
	dea.continent is not null)

SELECT 
	*,
	ROUND((RollingVacCount/population)*100,2) AS VacCount
FROM 
	PopVsVac



-- temp table

DROP TABLE if exists #PercentPopulationVaccinated

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Locatin nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingVacCount numeric
)

Insert into #PercentPopulationVaccinated
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as bigint)) 
		OVER (Partition By dea.location ORDER BY dea.location, dea.date) AS RollingVacCount
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON	
	dea.location = vac.location and dea.date = vac.date
WHERE 
	dea.continent is not null
ORDER BY
	2,3

SELECT 
	*,
	ROUND((RollingVacCount/population)*100,2) AS VacCount
FROM 
	#PercentPopulationVaccinated




-- Creating view to stroe data for visulizations 

CREATE VIEW PercentPopulationVaccinated as 
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) 
		OVER (Partition By dea.location ORDER BY dea.location, dea.date) AS RollingVacCount
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON	
	dea.location = vac.location and dea.date = vac.date
WHERE 
	dea.continent is not null
-- order by 2,3


SELECT
	*
FROM 
	PercentPopulationVaccinated