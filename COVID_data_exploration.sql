SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 3,4


-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2

-- Looking at Total Cases Vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate_percent
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
--WHERE location='country_name'
ORDER BY 1,2

-- Looking at Total Cases Vs Population
-- Shows Infected Population

SELECT location, date, population, total_cases, round((total_cases/population)*100, 2) as percent_infected_population
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
--WHERE location='country_name'
ORDER BY 1,2

-- Looking at Coutries with Highest Infection Rates compared to Population

SELECT location, population, MAX(total_cases) as highest_infection_count, round(MAX((total_cases/population)*100), 2) as percent_infected_population
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
--WHERE location='country_name'
GROUP BY population, location
ORDER BY percent_infected_population desc

-- Looking at Coutries with Highest Death Rates compared to Population

SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
--WHERE location='country_name'
GROUP BY location
ORDER BY total_death_count desc

-- Breaking it down by Larger Groups

SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL
--WHERE location='country_name'
GROUP BY location
ORDER BY total_death_count desc

--	Looking at Continents with Highest Death Rates

SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
--WHERE location='country_name'
GROUP BY continent
ORDER BY total_death_count desc


-- GLOBAL NUMBERS

SELECT SUM(new_cases) as global_cases, SUM(CAST(new_deaths as int)) as global_deaths, ROUND(SUM(CAST(new_deaths as int))/SUM(new_cases)*100, 2) as global_death_rate_percent
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
-- WHERE location='country_name'
-- GROUP BY date
ORDER BY 1,2



-- Looking at Total Population Vs Vaccination
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(numeric,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_people_vaccinated
--, (rolling_people_vaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_vaccinations, rolling_people_vaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(numeric,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_people_vaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, ROUND((rolling_people_vaccinated/Population)*100, 2) as population_vaccinated_percentage
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(numeric,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as population_vaccinated_percentage
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 