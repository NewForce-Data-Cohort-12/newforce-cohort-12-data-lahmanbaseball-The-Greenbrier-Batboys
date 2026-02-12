-- 1. What range of years for baseball games played does the provided database cover?
	-- A: 1871 - 2016
SELECT MIN(year) AS min_year,
	MAX(year) AS max_year
FROM homegames;

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
SELECT teamid
	, SUM(CASE WHEN lgwin='Y' THEN 1
		WHEN wcwin='Y' THEN 1
		WHEN lgwin='Y' THEN 1
		WHEN divwin='Y' THEN 1
		WHEN wswin='Y' THEN 1 END) AS wins
FROM teams
GROUP BY teamid
ORDER BY wins DESC NULLS LAST;

SELECT teamid, SUM(salary)::numeric::money AS salary
FROM salaries
GROUP BY teamid
ORDER BY salary DESC;

SELECT *
FROM teams;

-- 12. In this question, you will explore the connection between number of wins and attendance.
	-- Does there appear to be any correlation between attendance at home games and number of wins?
	
	-- Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?