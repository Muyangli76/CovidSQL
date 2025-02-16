--LOAD DATA AND EXPLORE
SELECT * 
FROM [Covid Portfolio] .. CovidDeaths
ORDER BY 3,4

SELECT * 
FROM [Covid Portfolio] .. CovidVaccinations
ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [Covid Portfolio]..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs. Total Deaths: Showing the likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (Total_deaths/total_cases)*100 as DeathPercentage_contracted
FROM [Covid Portfolio]..CovidDeaths
WHERE LOCATION like 'CANADA'
ORDER BY 5 DESC

-- Looking at Total Cases vs. population
-- Shows what percentage of population got Covid
SELECT Location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM [Covid Portfolio]..CovidDeaths
WHERE LOCATION like 'CANADA'
ORDER BY 5 DESC

-- Looking at Countries with Highest Infection Rate compared to population
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)) *100 as PercentPopulationInfected
FROM [Covid Portfolio]..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with Highest Death Count per Population
SELECT Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM [Covid Portfolio]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY TotalDeathCount DESC

-- Showing Countries with Highest Death Count per Population; group by continent
SELECT Continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM [Covid Portfolio]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC

--JOIN TWO TABLES
--LOOKING AT TOTAL POPULATION VS. VACCINATION
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
FROM [Covid Portfolio]..CovidDeaths dea
JOIN [Covid Portfolio]..CovidVaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
FROM [Covid Portfolio]..CovidDeaths dea
JOIN [Covid Portfolio]..CovidVaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
)

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- USE TEMP TABLE-
-- DROP TABLE IF EXISTS #PercentPopulationVaccinated;FOR NEWER VERSION
IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
FROM [Covid Portfolio]..CovidDeaths dea
JOIN [Covid Portfolio]..CovidVaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date

SELECT *,(RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Create view to store data for later data visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, 
	dea.location, 
	dea.date, dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(INT, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
FROM [Covid Portfolio]..CovidDeaths dea
JOIN [Covid Portfolio]..CovidVaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated

-- Tableau 1

SELECT SUM(new_cases) as total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_death, 
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM [Covid Portfolio]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Tableau 2
SELECT location,SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM [Covid Portfolio]..CovidDeaths
WHERE continent IS NULL
AND location NOT IN ('World','European Union','International')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Tableau 3
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM [Covid Portfolio]..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Tableau 4
SELECT Location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM [Covid Portfolio]..CovidDeaths
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC

