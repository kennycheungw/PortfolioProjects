SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
ORDER BY 3,4


SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
ORDER BY 1,2


-- Total Cases vs Total Deaths
-- Percentage of Death by Cases for the United States

SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
and continent is not null 
ORDER BY 1,2


-- Total Cases vs Population
-- Percentage of Population Infected

SELECT Location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


-- Countries with Highest Cases compared to Population

SELECT Location, Population, MAX(total_cases) AS TotalCases,  MAX((total_cases/population))*100 AS PercentageInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentageInfected DESC


-- Countries with Highest Death Count


SELECT Location, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
--Total_deaths is an invalid data type, need to switch it for aggregate function
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Continents by Highest Total Deaths

SELECT continent, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- GLOBAL NUMBERS

SELECT location, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, 
SUM(CAST(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
GROUP BY location
ORDER BY 1,2

-- Total Population and Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinated

FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--Now want the RollingTotalVaccinated as Percentage of Population, aliases cannot be used for another equation
--need to create a CTE/Temp Table to do this


-- CTE

With PopvsVac(continent, location, date, population, new_vaccinations, RollingTotalVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (RollingTotalVaccinated/Population) * 100 AS TotalPercentVaccinated
FROM PopvsVac



--Temp Table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingTotalVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingTotalVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 


SELECT *, (RollingTotalVaccinated/Population)*100
FROM #PercentPopulationVaccinated

--Creating View for visualizations
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingTotalVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM PercentPopulationVaccinated