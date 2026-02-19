-- 1. What range of years for baseball games played does the provided database cover?
	-- A: 1871 - 2016
SELECT MIN(year) AS min_year,
	MAX(year) AS max_year
FROM homegames;

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
-- Noah
select 
	CONCAT(namefirst,' ',namelast) AS full_name,
	min(height) as short_king,
	count(playerid) as games_played,
	teams.name as team
from people
left join appearances
using(playerid)
left join teams
using(teamid)
group by namefirst, namelast, team
order by short_king
limit 1;

-- Max
WITH eddy AS (SELECT playerid,namefirst,namelast,height
	FROM people
	ORDER BY height ASC
	LIMIT 1)
SELECT playerid
	, CONCAT(namefirst, ' ',namelast) AS full_name
	, CONCAT(height::text,' in')AS height
	, teams.name
	, CASE when playerid='gaedeed01' THEN G_all END AS games_played
FROM eddy
INNER JOIN appearances
USING(playerid)
INNER JOIN teams
USING(teamid)
GROUP BY playerid,full_name,height,teamid,name,games_played;


-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
-- Noah
select 
	namefirst,
	namelast,
	schools.schoolname,
	salary::numeric::money
from people
left join collegeplaying
using(playerid)
left join schools
using(schoolid)
left join salaries
using(playerid)
where schools.schoolname = 'Vanderbilt University' and salary is not null
group by namefirst, namelast, schools.schoolname, salary
order by salary desc
limit 1;


-- Max
SELECT playerid
	, CONCAT(namefirst,' ',namelast)AS full_name
	, SUM(salary)::numeric::money AS total_salary
FROM collegeplaying
INNER JOIN people
USING(playerid)
INNER JOIN salaries
USING(playerid)
WHERE schoolid='vandy'
GROUP BY playerid, full_name
ORDER BY total_salary DESC;


-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
-- Noah
select
	namefirst,
	namelast,
	count(case when pos like 'OF' then 'Outfield' end) as outfield_putouts,
	count(case when pos in ('SS', '1B', '2B', '3B') then 'Infield' end) as infield_putouts,
	count(case when pos in ('P', 'C') then 'Battery' end) as battery_putouts
from fielding
left join people
using(playerid)
where yearid = 2016
group by namefirst, namelast;
-- Max
SELECT playerid
	, CONCAT(namefirst,' ',namelast) AS name
	, yearid
	, (CASE WHEN pos='OF' THEN 'Outfield'
		WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
		WHEN pos IN ('P','C') THEN 'Battery' END) AS position
FROM fielding
INNER JOIN people
USING(playerid);
-- * position total putouts *
SELECT (CASE WHEN pos='OF' THEN 'Outfield'
		WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
		WHEN pos IN ('P','C') THEN 'Battery' END) AS position
	, SUM(po) AS total_putouts
FROM fielding
WHERE yearid='2016'
GROUP BY position
ORDER BY total_putouts DESC;
-- * COMBINED *
SELECT 
    f.playerid
    , CONCAT(p.namefirst, ' ', p.namelast) AS name
    , f.yearid
    , (CASE WHEN pos='OF' THEN 'Outfield'
          WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
          WHEN pos IN ('P','C') THEN 'Battery' END) AS position
    , SUM(po) OVER (PARTITION BY CASE WHEN pos='OF' THEN 'Outfield'
             WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
             WHEN pos IN ('P','C') THEN 'Battery' END) AS total_position_putouts
FROM fielding AS f
INNER JOIN people AS p
USING(playerid)
WHERE f.yearid = '2016'
ORDER BY f.playerid;

-- Thomas
SELECT
	CASE
	WHEN pos LIKE 'OF' THEN 'Outfield'
	WHEN pos IN('SS','1B','2B','3B') THEN 'Infield'
	WHEN pos IN('P','C') THEN 'Battery'
	END AS position_group,
	SUM(PO) as total_put_outs
FROM fielding 
WHERE yearid = 2016
GROUP BY
	CASE
	WHEN pos LIKE 'OF' THEN 'Outfield'
	WHEN pos IN('SS','1B','2B','3B') THEN 'Infield'
	WHEN pos IN('P','C') THEN 'Battery'
	END 
ORDER BY total_put_outs DESC;


-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
-- Leo
SELECT
(yearid / 10) *10 AS decade, 
ROUND (SUM (so)::numeric / (SUM (g) /2), 2) AS strikeouts_per_game,
ROUND (SUM(hr)::numeric / (SUM(g) /2), 2) AS home_runs_per_game
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;

-- Max
SELECT CONCAT(LEFT(yearid::text,3),'0s') AS decade
	, ROUND((SUM(so)::numeric/SUM(g)::numeric),2) AS strikeouts_per
	, ROUND((SUM(hr)::numeric/SUM(g)::numeric),2) AS homeruns_per
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;


-- 6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.
-- Leo
SELECT 
    p.namefirst,
    p.namelast,
    b.sb,
    b.cs,
    ROUND(b.sb::numeric / (b.sb + b.cs), 3) AS success_rate
FROM batting b
JOIN people p 
    ON b.playerid = p.playerid
WHERE b.yearid = 2016
    AND (b.sb + b.cs) >= 20
ORDER BY success_rate DESC
LIMIT 1;

-- Max
SELECT namefirst
	, namelast
	, (sb + cs) AS attempts
	, sb AS stolen
	, CONCAT(ROUND((sb::numeric/(sb::numeric+cs::numeric))*100,2)::TEXT,'%') AS success_rate
FROM batting
INNER JOIN people
USING(playerid)
WHERE (sb::numeric + cs::numeric) >= 20
	AND yearid = '2016'
ORDER BY success_rate DESC;


-- 7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
-- Leo

-- Max
-- most wins for non-world-series winner
SELECT name,SUM(w) AS wins,COUNT(CASE WHEN wswin='Y' THEN 1 END) AS ws_wins
FROM teams
WHERE yearid BETWEEN 1970 and 2016
	AND yearid <> 1994
GROUP BY name
HAVING COUNT(CASE WHEN wswin='Y' THEN 1 END)=0
ORDER BY wins DESC;

-- least wins for world-series-winner
SELECT name,SUM(w) AS wins,COUNT(CASE WHEN wswin='Y' THEN 1 END) AS ws_wins
FROM teams
WHERE yearid BETWEEN 1970 and 2016
	AND yearid <> 1994
GROUP BY name
HAVING COUNT(CASE WHEN wswin='Y' THEN 1 END)>0
ORDER BY wins ASC;

-- frequency of most-frequent winner winning the world series (lol wording)
SELECT name,yearid,wswin,w
FROM teams
ORDER BY w DESC;

SELECT name, yearid, wswin, w
FROM teams
WHERE yearid BETWEEN 1980 AND 1982;


-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance. 
-- Thomas
SELECT 
	park,
	team,
	ROUND(SUM(attendance)::numeric/SUM(games),-2) AS avg_attendance
FROM homegames
WHERE year =2016
GROUP BY park,team
HAVING sum(games) >= 10
ORDER BY avg_attendance DESC 
LIMIT 5;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
-- Thomas
SELECT p.namefirst, p.namelast
FROM awardsmanagers a
INNER JOIN people p
ON p.playerid = a.playerid
WHERE a.awardid = 'TSN Manager of the Year'
  AND a.lgid IN ('AL','NL')
GROUP BY p.namefirst, p.namelast, a.playerid
HAVING COUNT(DISTINCT a.lgid) = 2
ORDER BY p.namelast, p.namefirst;


-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
-- Thomas
SELECT p.namefirst,
       p.namelast,
       h.hr_2016
FROM
  (SELECT playerid,
          SUM(HR) AS hr_2016
   FROM batting
   WHERE yearid = 2016
   GROUP BY playerid) h
INNER JOIN
  (SELECT playerid,
          MAX(HR) AS career_high_hr
   FROM batting
   GROUP BY playerid) c
  ON h.playerid = c.playerid
INNER JOIN
  (SELECT playerid,
          COUNT(DISTINCT yearid) AS seasons_played
   FROM batting
   GROUP BY playerid) s
  ON h.playerid = s.playerid
INNER JOIN people p
  ON h.playerid = p.playerid
WHERE h.hr_2016 = c.career_high_hr
  AND h.hr_2016 > 0
  AND s.seasons_played >= 10
ORDER BY h.hr_2016 DESC, p.namelast, p.namefirst;


-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
	-- Yes! I think so!
-- * JUST WINS *
SELECT teamid
	, SUM(w) AS total_wins
FROM teams
WHERE yearid > 2000
GROUP BY teamid
ORDER BY total_wins DESC NULLS LAST;
-- * JUST SALARIES *
SELECT teamid, SUM(salary)::numeric::money AS salary
FROM salaries
GROUP BY teamid
ORDER BY salary DESC;
-- * WINS & SALARIES *
WITH wins_per_team AS (
	SELECT teamid
		, SUM(w) AS total_wins
	FROM teams
	WHERE yearid > 2000
	GROUP BY teamid
	ORDER BY total_wins DESC NULLS LAST
)
SELECT wins_per_team.teamid, total_wins, SUM(salary)::numeric::money AS team_salary
FROM wins_per_team
INNER JOIN salaries
	ON wins_per_team.teamid = salaries.teamid
WHERE salaries.yearid > 2000
GROUP BY wins_per_team.teamid, total_wins
ORDER BY total_wins DESC;


-- 12. In this question, you will explore the connection between number of wins and attendance.
	-- Does there appear to be any correlation between attendance at home games and number of wins?
WITH wins_per_team AS (
	SELECT teamid
		, SUM(w) AS total_wins
	FROM teams
	WHERE yearid > 2000
	GROUP BY teamid
	ORDER BY total_wins DESC NULLS LAST
)
SELECT wins_per_team.teamid, total_wins, SUM(attendance) AS total_attend
FROM wins_per_team
INNER JOIN homegames
	ON wins_per_team.teamid = homegames.team
WHERE year > 2000
GROUP BY wins_per_team.teamid, total_wins
ORDER BY total_wins DESC;


	-- Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- * 58 world series winners saw an increase, and 54 saw a decrease. *

SELECT 
    t.teamid AS team
    , t.yearid AS wswin_year
    , t.attendance AS attendance
    , t_next.attendance AS attendance_next_year
	, (t_next.attendance - t.attendance) AS attendance_diff
FROM teams AS t
LEFT JOIN teams AS t_next 
    ON t.teamid = t_next.teamid 
    AND t_next.yearid = t.yearid + 1
    AND t_next.attendance > 0
WHERE t.wswin = 'Y' 
    AND t.attendance > 0
ORDER BY attendance_diff;

-- * 162 playoff makers saw an increase and 117 saw a decrease. *
SELECT 
    t.teamid AS team
    , t.yearid AS playoff_year
    , t.attendance AS attendance
    , t_next.attendance AS attendance_next_year
	, (t_next.attendance - t.attendance) AS attendance_diff
FROM teams AS t
LEFT JOIN teams AS t_next 
    ON t.teamid = t_next.teamid 
    AND t_next.yearid = t.yearid + 1
    AND t_next.attendance > 0
WHERE t.divwin='Y' 
	OR t.wcwin='Y'
    AND t.attendance > 0
ORDER BY attendance_diff;



-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?
SELECT ROUND(COUNT(CASE WHEN throws='L' THEN 1 END)::numeric/(COUNT(CASE WHEN throws='R' THEN 1 END)::numeric+COUNT(CASE WHEN throws='L' THEN 1 END)::numeric)*100, 4) AS left_percent
, ROUND(COUNT(CASE WHEN throws='R' THEN 1 END)::numeric/(COUNT(CASE WHEN throws='R' THEN 1 END)::numeric+COUNT(CASE WHEN throws='L' THEN 1 END)::numeric)*100, 4) AS right_percent
FROM people;
----- 
-- * Percentage of Cy Awarded Lefties - 14.80% * 
SELECT
	COUNT(DISTINCT people.playerid) AS lefties
	, COUNT(CASE WHEN awardid='Cy Young Award' THEN 1 END) AS awarded_lefties
	, ROUND((COUNT(CASE WHEN awardid='Cy Young Award' THEN 1 END)::numeric/COUNT(DISTINCT people.playerid)::numeric*100),2) AS lefty_award_percentage
FROM people
INNER JOIN awardsplayers
USING(playerid)
WHERE throws='L';

-- * Percentage of Cy Awarded Righties - 6.87% * 
SELECT
	COUNT(DISTINCT people.playerid) AS righties
	, COUNT(CASE WHEN awardid='Cy Young Award' THEN 1 END) AS awarded_righties
	, ROUND((COUNT(CASE WHEN awardid='Cy Young Award' THEN 1 END)::numeric/COUNT(DISTINCT people.playerid)::numeric*100),2) AS righty_award_percentage
FROM people
INNER JOIN awardsplayers
USING(playerid)
WHERE throws='R';
-- 
SELECT *
FROM halloffame;

-- * Percentage of Hall of Fame Lefties - 20.88% * 
SELECT
	COUNT(DISTINCT people.playerid) AS lefties
	, COUNT(CASE WHEN inducted='Y' THEN 1 END) AS hof_lefties
	, ROUND((COUNT(CASE WHEN inducted='Y' THEN 1 END)::numeric/COUNT(DISTINCT people.playerid)::numeric*100),2) AS lefty_hof_percentage
FROM people
INNER JOIN halloffame
USING(playerid)
WHERE throws='L';

-- * Percentage of Hall of Fame Righties - 23.67% * 
SELECT
	COUNT(DISTINCT people.playerid) AS righties
	, COUNT(CASE WHEN inducted='Y' THEN 1 END) AS hof_righties
	, ROUND((COUNT(CASE WHEN inducted='Y' THEN 1 END)::numeric/COUNT(DISTINCT people.playerid)::numeric*100),2) AS righty_hof_percentage
FROM people
INNER JOIN halloffame
USING(playerid)
WHERE throws='R';