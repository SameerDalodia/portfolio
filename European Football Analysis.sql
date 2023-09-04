use Football


-- Display all the tables to look at the data & identify relationships in tables

select * from appearances;
select * from games;
select * from leagues;
select * from players;
select * from shots;
select * from teams;
select * from teamstats;


-- Display all columns of all tables to enable us to write queries

SELECT
      table_name,  COLUMN_NAME, ORDINAL_POSITION, DATA_TYPE
    FROM
        INFORMATION_SCHEMA.COLUMNS
    

-- Find out how many season's data we have

SELECT
distinct(games.season)
FROM games
ORDER BY season desc;


-- Display all the teams in premier league that played in the Season 2020

SELECT distinct(teams.name)
FROM teams inner join games ON teams.teamID = games.homeTeamID
inner join leagues on games.leagueID = leagues.leagueID
WHERE leagues.leagueID = 1 AND games.season = 2020;
	
-- Create a points table for Premier League Season 2018 using Group By
SELECT distinct(teams.name),
  count(games.gameID) as MP,
  count(case teamstats.result when 'W' then 1 else null end)  as Win,
  count(case teamstats.result when 'D' then 1 else null end)  as Draw,
  count(case teamstats.result when 'L' then 1 else null end)  as Lost,
  sum(teamstats.goals) as 'Goals For',
  (sum(games.awayGoals + games.homeGoals) - sum(teamstats.goals)) as 'Goals Against',
  sum(teamstats.goals) - (sum(games.awayGoals + games.homeGoals) - sum(teamstats.goals) ) as 'Goal Difference',
  (count(case teamstats.result when 'W' then 1 else null end) * 3 + 
    count(case teamstats.result when 'D' then 1 else null end) *1) as Points
  FROM teams
inner join teamstats ON teams.teamID = teamstats.teamID
inner  join games ON games.gameID = teamstats.gameID
inner join leagues ON games.leagueID = leagues.leagueID
WHERE leagues.leagueID = 1 AND games.season = 2018
GROUP BY teams.name
ORDER BY Points desc;


 -- Create a points table for Premier League Season 2018 using Over Partition

 SELECT distinct(teams.name),
  count(games.gameID) over (partition by teams.name) as MP,
  count(case teamstats.result when 'W' then 1 else null end) over (partition by teams.name) as Win,
  count(case teamstats.result when 'D' then 1 else null end) over (partition by teams.name) as Draw,
  count(case teamstats.result when 'L' then 1 else null end) over (partition by teams.name) as Lost,
  sum(teamstats.goals) over (partition by teams.name) as 'Goals For',
  (sum(games.awayGoals + games.homeGoals) over (partition by teams.name) - 
  sum(teamstats.goals) over (partition by teams.name)) as 'Goals Against',
  sum(teamstats.goals) over (partition by teams.name) -
  (sum(games.awayGoals + games.homeGoals) over (partition by teams.name) - 
  sum(teamstats.goals) over (partition by teams.name)) as 'Goal Difference',
  (count(case teamstats.result when 'W' then 1 else null end) over (partition by teams.name) * 3 + 
  count(case teamstats.result when 'D' then 1 else null end) over (partition by teams.name)*1) as Points
  FROM teams
inner join teamstats ON teams.teamID = teamstats.teamID
inner  join games ON games.gameID = teamstats.gameID
inner join leagues ON games.leagueID = leagues.leagueID
WHERE leagues.leagueID = 1 AND games.season = 2018
ORDER BY Points desc;

-- Disply the top 5 teams with most cleansheets in Europe (matches with 0 goals conceded) from 2015 to 2020
-- Using Common Expression Table (CTE) to ease the calculations

WITH CleansheetTable as
(
SELECT teams.name, teams.teamID, teamstats.gameID, teamstats.season,
case when (games.homeGoals + games.awayGoals)=teamstats.goals then 1 else 0 end as 'Cleansheets'
FROM Games
inner join teamstats on games.gameID = teamstats.gameID
inner join Teams on teams.teamID = teamstats.teamID
)
SELECT TOP 5 CleansheetTable.name as 'Team Name', sum(Cleansheets)  as 'Total Cleansheets'
FROM CleansheetTable
WHERE CleansheetTable.season BETWEEN 2015 AND 2020
GROUP BY CleansheetTable.name 
ORDER BY sum(Cleansheets) DESC;


-- Display the top 10 scorers in Europe for the season 2020

SELECT
Top 10 players.name, sum(appearances.goals) as Goals, sum(appearances.assists) as Assists
FROM Players 
inner join appearances ON players.playerID = appearances.playerID
inner join games ON appearances.gameID = games.gameID
WHERE games.season = 2020
GROUP BY players.name
ORDER BY sum(appearances.goals) DESC, sum(appearances.assists) DESC;


-- Display the top scorers in Premier League for the season 2018

SELECT
Top 10 players.name, sum(appearances.goals) as Goals, sum(appearances.assists) as Assists
FROM Players 
inner join appearances ON players.playerID = appearances.playerID
inner join games ON appearances.gameID = games.gameID
WHERE games.season = 2018 AND appearances.leagueID=1
GROUP BY players.name
ORDER BY sum(appearances.goals) DESC, sum(appearances.assists) DESC;

-- Teams with lowest red cards (most disciplined) in Season 2020

SELECT
TOP 10 teams.name, sum(teamstats.redCards) as 'Red Cards', sum(teamstats.yellowCards) as 'Yellow Cards'
FROM Teams
inner join Teamstats ON teamstats.teamID = teams.teamID
WHERE teamstats.season = 2020
GROUP BY teams.name
ORDER BY sum(teamstats.redCards), sum(teamstats.yellowCards);

-- Conversion Percentage of shots across seasons

SELECT
shots.situation, sum(case when shots.shotResult='Goal' then 1 else 0 end) as Goals, COUNT(shots.shotResult) as 'Total Shots', 
round((cast (sum(case when shots.shotResult='Goal' then 1 else 0 end) as float)/ cast(COUNT(shots.shotResult) as float) * 100),2) as 'Conversion Percentage'
FROM
Shots
GROUP BY shots.situation
ORDER BY [Conversion Percentage] DESC;

--  Conversion Percentage of shots for different leagues using PIVOT