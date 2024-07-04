Create Database Olympics;
Use Olympics;

Create Table Olympics_athlete_events(
      ID INT,
      Name Varchar(250),
      Sex Varchar(25),
      Age Varchar(25),
      Height varchar(25),
      Weight varchar(25),
      Team Varchar(50),
      NOC Varchar(50),
      Games varchar(50),
      Year INT,
      Season Varchar(50),
      City Varchar(50),
      Sport varchar(50),
      Event Varchar(250),
      Medal Varchar(50)
);

Select * from Olympics_athlete_events;
Select Count(*) From Olympics_athlete_events;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/athlete_events.csv" INTO TABLE Olympics_athlete_events
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

Select @@secure_file_priv;
    
Create Table Olympics_Noc_Region(
      NOC Varchar(25),
      Region varchar(100),
      Notes varchar(250)
);

Select * from Olympics_Noc_Region;
Select Count(*) from Olympics_Noc_Region;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/country_definitions.csv" INTO TABLE Olympics_Noc_Region
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;




With CTE1 AS
(Select *,
       Row_Number() Over (Partition by ID,Name,Sex,Age,Height,Weight,Team,NOC,Games,Year,Season,City,Sport,Event,Medal) AS RN
From Olympics_athlete_events)
Select * From CTE1 
Where RN>1;
       
DELETE FROM Olympics_athlete_events
WHERE (ID, Name, Sex, Age, Height, Weight, Team, NOC, Games, Year, Season, City, Sport, Event, Medal) IN (
    SELECT ID, Name, Sex, Age, Height, Weight, Team, NOC, Games, Year, Season, City, Sport, Event, Medal
    FROM (
        SELECT ID, Name, Sex, Age, Height, Weight, Team, NOC, Games, Year, Season, City, Sport, Event, Medal,
               ROW_NUMBER() OVER (PARTITION BY Name, Sex, Age, Height, Weight, Team, NOC, Games, Year, Season, City, Sport, Event, Medal ORDER BY ID) AS RN
        FROM Olympics_athlete_events
    ) AS duplicates
    WHERE RN > 1
);

Set SQL_Safe_Updates = 0;







Select * from Olympics_athlete_events;
-------------------------------------------------------------------------------------------------------------------------------------

-- 1. How many olympics games have been held?
Select
      Count(Distinct Games) AS Total_Olympics_Played
From Olympics_athlete_events;


-- 2. List down all Olympics games held so far.
Select
      distinct Year,
      Season,
      City
From Olympics_athlete_events
Order by year;


-- 3. Mention the total no of nations who participated in each olympics game?
Select 
      Games,
      Count(distinct Region) AS Total_Country
From olympics_athlete_events a Join olympics_noc_region n ON a.NOC = n.NOC
Group By Games
Order by Games ;


-- 4. Which year saw the highest and lowest no of countries participating in olympics.
(Select
      Concat("Highest -",Games) AS Games,
      Count(distinct Region) AS Total_Participants_Countries
From olympics_athlete_events o Join olympics_noc_region n ON o.NOC = n.NOC
Group by Games
Order by Total_Participants_Countries DESC
LIMIT 1)
Union all
(Select
      Concat("Lowest -",Games) AS Games,
      Count(distinct Region) AS Total_Participants_Countries
From olympics_athlete_events o Join olympics_noc_region n ON o.NOC = n.NOC
Group by Games
Order by Total_Participants_Countries ASC
LIMIT 1);


-- 5. Which nation has participated in all of the olympic games.
With CTE1 AS
(Select
      Region as Country,
      Count(distinct Games) AS Total_Participants,
      rank() Over (Order by Count(distinct Games) DESC) AS RN
From olympics_athlete_events o Join olympics_noc_region n ON o.NOC = n.NOC
Group By Region)
Select 
       Country, 
       Total_Participants
From CTE1
Where RN = 1;
     
      
-- 6. Identify the sport which was played in all summer olympics.
Select
       Sport,
       Count(distinct Games) AS Played
From olympics_athlete_events
Where Season = "Summer"
Group By Sport
Order By Played DESC;


-- 7. Which Sports were just played only in one olympics season.
With CTE1 AS
(Select
      Sport,
      Count(distinct Games) AS No_of_season_Played
From olympics_athlete_events
Group By Sport)
Select 
      Sport
from CTE1
Where No_of_season_Played = 1;


-- 8. Fetch the total no of sports played in each olympic games.
Select
      distinct Games,
      count(distinct Sport) AS Total_Sports
From olympics_athlete_events
Group By Games
Order by Games ;



-- 9. Fetch oldest athletes to win a gold medal.
With CTE1 AS
(Select *,
       Case
       when age = 'NA' Then null
       Else age 
       End AS New_Age
From olympics_athlete_events 
Where Medal = "Gold"),
CTE2 AS
(Select *,
       dense_rank() Over (Order by New_age DESC) AS RN
From CTE1)
Select Name,
       Age,
       Games,
       Medal
 FROM CTE2
Where RN = 1;



-- 10. Find the Percent of male and female athletes participated in all olympic games.olympics_athlete_events
SELECT 
    CONCAT(ROUND(SUM(CASE WHEN Sex = 'M' THEN 1 END) / COUNT(*) * 100, 1), '%') AS male_Pct,
    CONCAT(ROUND(SUM(CASE WHEN Sex = 'F' THEN 1 END) / COUNT(*) * 100, 1), '%') AS female_Pct
FROM 
    olympics_athlete_events;
    
    
-- 11. Fetch the top 5 athletes who have won the most gold medals.
With CTE1 AS
(Select
      Name,
      Count(Medal) AS Won,
      Dense_Rank() Over (Order by Count(Medal) DESC) AS RN
From olympics_athlete_events
Where Medal = "Gold" 
Group By Name)
Select * From CTE1
Where RN <=5;



-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
With CTE1 AS
(Select
      Name,
      Count(Medal) AS Total_Medals,
      Dense_Rank() Over (Order by Count(Medal) DESC) AS RN
From olympics_athlete_events
Where Medal IN ("Gold","Silver","Bronze")
Group By Name)
Select
      *
From CTE1
Where RN <= 5;



-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no. of medals won.
With CTE1 AS
(Select
       Region AS Country,
       Count(Medal) AS Won,
       Dense_Rank() Over (Order By Count(Medal) DESC) AS RN
From olympics_athlete_events o Join olympics_noc_region n ON o.NOC = n.NOC
Where Medal IN (select Medal From olympics_athlete_events Where Medal != "NA")
Group By Country)
Select * From CTE1
Where RN <=5;



-- 14. List down total gold, silver and bronze medals won by each country.
Select
      n.Region AS Country,
      Count(Case when Medal = "Gold" Then 1  End) AS Gold,
      Count(Case when Medal = "Silver" Then 1  End) AS Silver,
      Count(Case when Medal = "Bronze" Then 1  End) AS Bronze
From olympics_athlete_events o Join olympics_noc_region n ON o.NOC = n.NOC
Group By Country
Order by Gold DESC, Silver DESC, Bronze DESC;


-- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
Select
      Games,
      Region AS Country,
      Count(Case when Medal = "Gold" Then 1  End) AS Gold,
      Count(Case when Medal = "Silver" Then 1 End) AS Silver,
      Count(Case when Medal = "Bronze" Then 1 End) AS Bronze
From olympics_athlete_events o Join olympics_noc_region n ON o.NOC = n.NOC
Group By Country, Games
Order by Gold DESC, Silver DESC, Bronze DESC;



-- 17. Identify which country won the most gold, most silver, most bronze medals in each olympic games.

WITH cte AS (
SELECT 
	  games,
	  region,
	  medal,
	  COUNT(*) AS medal_count,
	  DENSE_RANK() OVER (PARTITION BY games, medal ORDER BY COUNT(*) DESC) AS _rank
FROM olympics_athlete_events o JOIN olympics_noc_region n ON o.NOC = n.NOC
WHERE medal IN ('Gold', 'Silver', 'Bronze')
GROUP BY games, region, medal)
SELECT 
    games,
    MAX(CASE WHEN medal = 'Gold' AND _rank = 1 THEN CONCAT(region, ' ', medal_count) END) AS max_gold,
    MAX(CASE WHEN medal = 'Silver' AND _rank = 1 THEN CONCAT(region, ' ', medal_count) END) AS max_silver,
    MAX(CASE WHEN medal = 'Bronze' AND _rank = 1 THEN CONCAT(region, ' ', medal_count) END) AS max_bronze
FROM cte
GROUP BY games
ORDER BY games;



-- 18. Which countries have never won gold medal but have won silver/bronze medals?
With CTE1 AS
(Select 
      Region As Country,
      Count(Case when Medal = "Gold" Then 1  End) AS Gold,
      Count(Case when Medal = "Silver" Then 1 End) AS Silver,
      Count(Case when Medal = "Bronze" Then 1 End) AS Bronze
From olympics_athlete_events o Join olympics_noc_region n ON o.NOC = n.NOC
Group By Country)
Select * From CTE1
Where Gold = 0 and (Silver > 0 or Bronze > 0);



-- 19. In which Sport/event, India has won highest medals.
Select
      Region as country,
      Sport,
      Count(Medal) AS Count_Medal
From olympics_athlete_events o Join olympics_noc_region n ON o.NOC = n.NOC
Where Region = "India" and Medal != "NA"
Group By Country, Sport
Order By Count_Medal DESC
Limit 1;



-- 20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games.
Select
      Region AS Country,
      Games,
      Sport,
      Count(medal) AS Hockey_Medal
From olympics_athlete_events o Join olympics_noc_region n ON o.NOC = n.NOC
Where Region = "India" and Sport = "Hockey" and Medal != "NA"
Group By Country, Games
Order by Hockey_Medal DESC;

