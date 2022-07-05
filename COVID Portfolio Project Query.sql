SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 3,4


SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
WHERE continent is not null
ORDER BY 3,4


-- Select Data that we are going to be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1,2 -- 1,2 means the first two columns we are selecting (location and date)


-- Looking at the Total Cases vs Total Deaths (we want to know how many people are dying that are also reporting that they are infected
-- Shows likelihood of dying if you have covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE Location = 'United States' AND continent is not null
ORDER BY 1,2 


-- Looking at the Total Cases vs Population
-- Shows percentage of population got Covid
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS CasePercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE Location = 'United States' AND continent is not null
ORDER BY 1,2 


-- Looking at countries with the highest infection rate compared to population
SELECT Location, population, MAX(total_cases) AS HighestIngectionCount, MAX((total_cases/population))*100 AS CasePercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY Location, population -- look into why we need group by here, I kinda know why but not really
ORDER BY CasePercentage DESC


-- Showing total deaths by continent
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Showing Countries with highest death count per population
-- casting TotalDeathCount as int because the nvarchar(255) format was causing data to display incorectly
SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is null -- location sometimes had continents even though continents has its own column
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Global Numbers by date
SELECT 
	date, 
	SUM(new_cases) AS Total_Cases, 
	SUM(cast(new_deaths as int)) AS Total_Deaths,
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


-- Global Numbers in total
SELECT
	SUM(new_cases) AS Total_Cases,
	SUM(cast(new_deaths as int)) AS Total_Deaths,
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null



--Total Population vs Vaccination (CTE)
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Incrementing_Vaccinations)
AS
(
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as bigint)) OVER 
		(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Incrementing_Vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location AND
	dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (Incrementing_Vaccinations/population)*100 AS Vaccince_Percentage
FROM PopvsVac



--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Incrementing_Vaccinations numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as bigint)) OVER 
		(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Incrementing_Vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location AND
	dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
SELECT *, (Incrementing_Vaccinations/population)*100 AS Vaccince_Percentage
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as bigint)) OVER 
		(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Incrementing_Vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location AND
	dea.date = vac.date
WHERE dea.continent is not null

Select *
FROM PercentPopulationVaccinated