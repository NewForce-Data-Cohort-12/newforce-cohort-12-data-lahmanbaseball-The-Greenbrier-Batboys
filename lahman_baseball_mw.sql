-- 1. What range of years for baseball games played does the provided database cover?
	-- A: 1871 - 2016
SELECT MIN(year) AS min_year,
	MAX(year) AS max_year
FROM homegames;

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
-- 58 world series winners saw an increase, and 54 saw a decrease.

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

----------

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
WITH lefties AS (
	SELECT *
	FROM people
	WHERE throws = 'L')
SELECT lefties.playerid,throws,awardid
-- SELECT COUNT(lefties)::numeric
FROM lefties
INNER JOIN awardsplayers
USING(playerid)
WHERE awardid='Cy Young Award';
----
