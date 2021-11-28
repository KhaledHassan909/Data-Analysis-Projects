SELECT continent, location, population, total_cases, total_deaths
FROM Portifolio_project..Covid_death
WHERE continent IS NULL
ORDER BY 4 DESC

-- Total Cases vs Total Deaths per countery along date --
SELECT date, continent, location, population, total_cases, total_deaths, ROUND((total_deaths / total_cases)*100, 2) AS death_percentage
FROM Portifolio_project..Covid_death
WHERE continent IS NOT NULL
ORDER BY 3,1

-- When did 1st Case appeared in each country?
WITH t1 AS (SELECT MIN(date) AS date, location
FROM Portifolio_project..Covid_death
WHERE new_cases IS NOT NULL AND continent IS NOT NULL AND new_cases != 0
GROUP BY location)

SELECT t1.date, t1.location, dea.new_cases
FROM t1
JOIN Portifolio_project..Covid_death AS dea
ON dea.date = t1.date AND dea.location = t1.location
ORDER BY t1.date

-- When did 1st Death appeared in each country?
WITH t1 AS (SELECT MIN(date) AS date, location
FROM Portifolio_project..Covid_death
WHERE new_deaths IS NOT NULL AND continent IS NOT NULL AND new_deaths != 0
GROUP BY location)

SELECT t1.date, t1.location, dea.new_deaths
FROM t1
JOIN Portifolio_project..Covid_death AS dea
ON dea.date = t1.date AND dea.location = t1.location
ORDER BY t1.date


-- Total Cases vs Population (Percentage of population got COVID-19) --
SELECT location, date, population, total_cases, (total_cases / population)*100 AS cases_percentage
FROM Portifolio_project..Covid_death
WHERE continent IS NOT NULL
-- WHERE location LIKE '%france%'
ORDER BY 1,2

-- Highest Infection Rate for each country --

SELECT location, population, MAX(total_cases) AS max_tot_cases, MAX((total_cases / population))*100 AS max_cases_per_pop_percentage
FROM Portifolio_project..Covid_death
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY max_cases_per_pop_percentage DESC

-- Higest Infection Rate for each country with corresponding year --

/*
WITH t1 AS( SELECT location, population, MAX(total_cases) AS max_tot_cases, MAX((total_cases / population))*100 AS max_cases_percentage
FROM dbo.Covid_death
GROUP BY location, population
)

SELECT c.date, t1.location, t1.population, t1.max_tot_cases, t1.max_cases_percentage
FROM t1
JOIN dbo.Covid_death AS c
ON c.total_cases = t1.max_tot_cases AND ((c.total_cases / c.population)*100) = t1.max_cases_percentage
ORDER BY 4 DESC
*/


-- Countries with highest death rate per population --
SELECT  location, MAX(CAST(total_deaths AS INT)) AS max_tot_deaths
FROM Portifolio_project..Covid_death
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

-- Contenints with highest death rate per population --
SELECT  location AS contenint , MAX(CAST(total_deaths AS INT)) AS max_tot_deaths
FROM Portifolio_project..Covid_death
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC

--Total cases, Total deaths, Death Percentage in World till now
SELECT SUM(total_cases) AS total_cases, SUM(CAST(total_deaths AS BIGINT)) AS total_deaths, (SUM(CAST(total_deaths AS BIGINT)) / SUM(total_cases))*100 AS death_percentage
FROM Portifolio_project..Covid_death
WHERE continent IS NULL

--Total cases, Total deaths, Death Percentage in World per date
SELECT date, SUM(total_cases) AS total_cases, SUM(CAST(total_deaths AS BIGINT)) AS total_deaths, (SUM(CAST(total_deaths AS BIGINT)) / SUM(total_cases))*100 AS death_percentage
FROM Portifolio_project..Covid_death
WHERE continent IS NULL
GROUP BY date
ORDER BY date

-- Total population vs Rolling Vaccinations
SELECT v.date, d.continent, d.location, d.population, v.new_vaccinations,
	   SUM(CAST(v.new_vaccinations AS BIGINT))
	   OVER(PARTITION BY d.location	ORDER BY d.population, v.date) total_rolling_vaccinations
FROM Portifolio_project..Covid_death AS d
JOIN Portifolio_project..Covid_vaccination AS v
ON v.date = d.date AND v.iso_code = d.iso_code
WHERE d.continent IS NOT NULL
ORDER BY 3,1

-- % of Population vaccinated

WITH vacc_vs_pop AS
(
SELECT v.date, d.continent, d.location, d.population, v.new_vaccinations,
	   SUM(CAST(v.new_vaccinations AS BIGINT))
	   OVER(PARTITION BY d.location	ORDER BY d.population, v.date) tot_rolling_vaccinations
FROM Portifolio_project..Covid_death AS d
JOIN Portifolio_project..Covid_vaccination AS v
ON v.date = d.date AND v.iso_code = d.iso_code
WHERE d.continent IS NOT NULL
)
SELECT *, (tot_rolling_vaccinations / population)*100 AS vacc_perc_per_pop
FROM vacc_vs_pop

-- ############################################################################################# --


-- Creating Tables --

-- Table 1 (Vaccination_Percent_Per_Population)
 
USE Visuals
--DROP TABLE IF EXISTS Vaccination_Percent_Per_Population
--DROP TABLE Vaccination_Percent_Per_Population
CREATE TABLE dbo.Vaccination_Percent_Per_Population
(
date datetime,
continent nvarchar(255),
location nvarchar(255),
population numeric,
new_vaccinations numeric,
tot_rolling_vaccinations numeric
)

INSERT INTO Vaccination_Percent_Per_Population

SELECT v.date, d.continent, d.location, d.population, v.new_vaccinations,
	   SUM(CAST(v.new_vaccinations AS BIGINT))
	   OVER(PARTITION BY d.location	ORDER BY d.population, v.date) tot_rolling_vaccinations
FROM Portifolio_project..Covid_death AS d
JOIN Portifolio_project..Covid_vaccination AS v
ON v.date = d.date AND v.iso_code = d.iso_code
WHERE d.continent IS NOT NULL

SELECT *, (tot_rolling_vaccinations / population)*100 AS vacc_perc_per_pop
FROM Vaccination_Percent_Per_Population
ORDER BY location, date


-----------------------------------------------

-- Table 2 (Global numbers)

USE Visuals
CREATE TABLE dbo.global_numbers
--DROP TABLE global_numbers
(
	total_cases numeric,
	total_deaths numeric,
	death_percentage float
)

INSERT INTO global_numbers

SELECT SUM(total_cases) AS total_cases, SUM(CAST(total_deaths AS BIGINT)) AS total_deaths, (SUM(CAST(total_deaths AS BIGINT)) / SUM(total_cases))*100 AS death_percentage
FROM Portifolio_project..Covid_death
WHERE continent IS NULL

SELECT *
FROM global_numbers

-----------------------------------------------

-- Table 3(max_deaths_per_country)

USE Visuals
CREATE TABLE dbo.max_deaths_per_country
--DROP TABLE max_deaths_per_country
(
	location nvarchar(255),
	max_tot_deaths numeric
)

INSERT INTO max_deaths_per_country

SELECT  location, MAX(CAST(total_deaths AS INT)) AS max_tot_deaths
FROM Portifolio_project..Covid_death
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

SELECT *
FROM max_deaths_per_country
ORDER BY 2 DESC

-----------------------------------------------

-- Table 4 (max_deaths_per_continent)

USE Visuals
CREATE TABLE dbo.max_deaths_per_continent
--DROP TABLE max_deaths_per_continent
(
	contenint nvarchar(255),
	max_tot_deaths numeric
)

INSERT INTO max_deaths_per_continent

SELECT  location AS contenint , MAX(CAST(total_deaths AS INT)) AS max_tot_deaths
FROM Portifolio_project..Covid_death
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC

SELECT *
FROM max_deaths_per_continent

--------------------------------------------------------

-- Table 6 (countries_max_cases_per_pop)

CREATE TABLE countries_max_cases_per_pop
-- DROP TABLE countries_max_cases_per_pop
(
	location varchar(255),
	population numeric,
	max_tot_cases numeric,
	max_cases_per_pop_percentage float
)

INSERT INTO countries_max_cases_per_pop

SELECT location, population, MAX(total_cases) AS max_tot_cases, MAX((total_cases / population))*100 AS max_cases_per_pop_percentage
FROM Portifolio_project..Covid_death
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY max_cases_per_pop_percentage DESC

SELECT *
FROM countries_max_cases_per_pop

---------------------------------------------------------------

-- Table 7 (first_death_per_country)
CREATE TABLE first_death_per_country
-- DROP TABLE first_death_per_country
(
	date datetime,
	location nvarchar(255),
	first_death numeric
);
WITH t1
(
	date,
	location
)
AS (SELECT MIN(d.date) AS date, d.location
FROM Portifolio_project..Covid_death as d
WHERE new_deaths IS NOT NULL AND continent IS NOT NULL AND new_deaths != 0
GROUP BY location)

INSERT INTO first_death_per_country

SELECT t1.date, t1.location, dea.new_deaths
FROM t1
JOIN Portifolio_project..Covid_death AS dea
ON dea.date = t1.date AND dea.location = t1.location
ORDER BY t1.date

SELECT *
FROM first_death_per_country

---------------------------------------------------

-- Table 8 (first_case_per_country)
USE Visuals
CREATE TABLE first_case_per_country
--DROP TABLE first_case_per_country
(
	date datetime,
	location nvarchar(255),
	first_case numeric
);
WITH t1
(
	date,
	location
)
AS (SELECT MIN(date) AS date, location
FROM Portifolio_project..Covid_death
WHERE new_cases IS NOT NULL AND continent IS NOT NULL AND new_cases != 0
GROUP BY location)

INSERT INTO first_case_per_country

SELECT t1.date, t1.location, dea.new_cases
FROM t1
JOIN Portifolio_project..Covid_death AS dea
ON dea.date = t1.date AND dea.location = t1.location
ORDER BY t1.date

SELECT *
FROM first_case_per_country

-------------------------------------------------------------------

--Table 9 (new_cases)
USE Visuals
CREATE TABLE new_cases
-- DROP TABLE new_cases
(
	date datetime,
	continent nvarchar(255),
	location nvarchar(255),
	population numeric,
	new_cases numeric
)

INSERT INTO new_cases

SELECT date, continent, location, population, new_cases
FROM Portifolio_project..Covid_death
WHERE continent IS NOT NULL

-------------------------------------------------------------------

--Table 9 (new_deaths)
USE Visuals
CREATE TABLE new_deaths
-- DROP TABLE new_cases
(
	date datetime,
	continent nvarchar(255),
	location nvarchar(255),
	population numeric,
	new_deaths numeric
)

INSERT INTO new_deaths

SELECT date, continent, location, population, new_deaths
FROM Portifolio_project..Covid_death
WHERE continent IS NOT NULL AND location IS NOT NULL
------------------------------------------------------------

-- Table 10 (continent_death_perc_per_pop)
CREATE TABLE continent_death_perc_per_pop
-- DROP TABLE continent_death_perc_per_pop
(
	location nvarchar(255),
	tot_deaths numeric,
	population numeric
)

INSERT INTO continent_death_perc_per_pop

SELECT  location AS contenint , SUM(CAST(new_deaths AS NUMERIC)) AS tot_deaths, 
	    SUM(population) AS population
FROM Portifolio_project..Covid_death
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC
----------------------------------------------------------------

--Table 12 (vacc_per_pop)
--DROP TABLE vacc_per_pop
USE Visuals
CREATE TABLE vacc_per_pop
(
	location nvarchar(255),
	total_population numeric,
	total_vaccinated numeric
);

WITH vacc
(
	location ,
	total_vaccinated
)
AS
(
	SELECT location, total_vaccinations
	FROM Portifolio_project..Covid_vaccination
	WHERE continent IS NULL
	--GROUP BY location
)

INSERT INTO vacc_per_pop

SELECT vacc.location AS location, MAX(dea.population) AS total_population, MAX(vacc.total_vaccinated) AS total_vaccinated
FROM vacc
JOIN Portifolio_project..Covid_death AS dea
ON dea.location = vacc.location
GROUP BY vacc.location


SELECT *
FROM vacc_per_pop