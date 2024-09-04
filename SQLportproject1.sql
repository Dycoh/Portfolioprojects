SELECT *
FROM PortfolioProject..[covid deaths]
ORDER BY 3,4

SELECT *
FROM PortfolioProject..[covid vaccinations]
ORDER BY 3,4

SELECT location, date,total_cases, new_cases,total_deaths,population
FROM PortfolioProject..[covid deaths]
ORDER BY 1,2

---TOTAL CASES VS TOTAL DEATHS AS PERCENTAGE
SELECT location, date,total_cases, total_deaths,COALESCE(total_deaths/ NULLIF(total_cases,0),0)*100 as Deathpercentage
FROM PortfolioProject..[covid deaths]
WHERE location like '%states'
ORDER BY 1,2

---TOTAL CASES VS POPULATION AS PERCENTAGE
SELECT location, date,population,total_cases,COALESCE(total_cases/ NULLIF(population,0),0)*100 as Covidpercentage
FROM PortfolioProject..[covid deaths]
WHERE location like '%states'
ORDER BY 1,2

---COUNTRIES WITH HIGHEST INFECTION RATE AS PER POPULATION
SELECT continent,location, population,   MAX(total_cases)as max_infections, MAX(total_cases/ population)*100 as Infectionpercentage
FROM PortfolioProject..[covid deaths]
GROUP BY continent,location ,population
--WHERE location like '%states'
ORDER BY Infectionpercentage desc

---COUNTRIES WITH HIGHEST DEATH COUNT AS PER POPULATION
SELECT continent,location, population,   MAX(total_deaths)as max_deaths, MAX(total_deaths/ population)*100 as deathperpopulation
FROM PortfolioProject..[covid deaths]
GROUP BY continent,location ,population
--WHERE location like '%states'
ORDER BY  deathperpopulation desc

---CONTINENTS WITH HIGHEST DEATH COUNT

SELECT continent,   MAX(total_deaths)as Totaldeathcount
FROM PortfolioProject..[covid deaths]
WHERE continent is not null
GROUP BY continent
ORDER BY  Totaldeathcount desc

---GLOBAL NUMBERS IN TERMS COMPARING THOSE INFECTED AND THOSE THAT DIED AS A PERCENTAGE 

SELECT 
    continent,location, date,
    SUM(new_cases) AS Continentcases, 
    SUM(new_deaths) AS Continentdeaths, 
    (SUM(new_deaths) / NULLIF(SUM(new_cases), 0)) * 100 AS Deathpercentage
FROM 
    PortfolioProject..[covid deaths]
WHERE continent IS NOT NULL
GROUP BY 
    continent, location,date
ORDER BY date


--------LOOKING AT TOTAL POPULATION VS VACCINATION

	---USING A COMMON TABLE EXPRESSION (CTE) to do this 

with popvsvac (continent, location ,date,population,new_vaccinations,rolling_vaccinations)
as
(SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    CASE 
        WHEN SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        ) > dea.population THEN dea.population
        ELSE SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        )
    END AS rolling_vaccinations
FROM  
    PortfolioProject..[covid deaths] dea
JOIN
    PortfolioProject..[covid vaccinations] vac
    ON dea.continent = vac.continent
    AND dea.date = vac.date
--ORDER BY  dea.location, dea.date;
)

	SELECT *,( rolling_vaccinations/population)*100 as vaccination_percentage
	FROM popvsvac


	----USING A TEMPORARY(TEMP) TABLE  to do this

DROP TABLE if exists  #Percent_vaccinated
CREATE TABLE  #Percent_vaccinated
(
continent nvarchar (255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinations numeric
)
insert into #Percent_vaccinated
   SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    CASE 
        WHEN SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        ) > dea.population THEN dea.population
        ELSE SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        )
    END AS rolling_vaccinations
FROM  
    PortfolioProject..[covid deaths] dea
JOIN
    PortfolioProject..[covid vaccinations] vac
    ON dea.continent = vac.continent
    AND dea.date = vac.date
--ORDER BY  dea.location, dea.date;

	SELECT *,( rolling_vaccinations/population)*100 as vaccination_percentage
	FROM  #Percent_vaccinated


-----Creating views to store data for later visualizations

Create view  Percent_vaccinated as

	SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    CASE 
        WHEN SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        ) > dea.population THEN dea.population
        ELSE SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        )
    END AS rolling_vaccinations
FROM  
    PortfolioProject..[covid deaths] dea
JOIN
    PortfolioProject..[covid vaccinations] vac
    ON dea.continent = vac.continent
    AND dea.date = vac.date
---ORDER BY dea.location, dea.date;

SELECT * FROM Percent_vaccinated

---- Another   CREATE VIEW example

CREATE VIEW  percentofpplevacinnated as

    SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT( bigint,vac.new_vaccinations )) OVER (Partition by dea.location Order by dea.location) as rolling_vaccinations
	FROM  PortfolioProject..[covid deaths] dea
	join
	 PortfolioProject..[covid vaccinations]vac
	 on
	 dea.continent = vac.continent
  and
	 dea.date = vac.date
---	ORDER BY location 

------ALTERNATE SOLUTION TO SEE IF ROLLING COUNT WILL CAP AT POPULATION

	WITH VaccinationCounts AS (
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS cumulative_vaccinations
    FROM  
        PortfolioProject..[covid deaths] dea
    JOIN
        PortfolioProject..[covid vaccinations] vac
        ON dea.continent = vac.continent
        AND dea.date = vac.date
)
SELECT 
    continent,
    location,
    date,
    population,
    new_vaccinations,
    CASE 
        WHEN cumulative_vaccinations > population THEN population
        ELSE cumulative_vaccinations
    END AS rolling_vaccinations
FROM 
    VaccinationCounts
ORDER BY   location, date;
	SELECT *,( rolling_vaccinations/population)*100 as vaccination_percentage
	FROM VaccinationCounts 

