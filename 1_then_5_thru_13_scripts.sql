select * from people;
select * from teams;
select * from appearances;
select * from collegeplaying;
select * from schools;
select * from salaries;
select * from fielding;
select * from batting;
select * from pitching;
select * from halloffame;
select * from homegames;
select * from awardsmanagers;
select * from managers;
select * from homegames;
select * from parks;
select * from awardsplayers;

-- 1.  What range of years for baseball games played does the provided database cover?
select
    min(yearid) AS first_year,
    max(yearid) AS recent_year
from appearances;



-- 5.  Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
select
	yearid / 10 * 10 || '''s' as decade,
	round(avg(so) / sum(g)::numeric, 2) as strikeouts_per_game,
	round(sum(hr) / sum(g)::numeric / 2, 2) as hr_per_game
from batting
where yearid >= 1920
group by decade
order by decade desc;




-- 6.  Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.
select
	distinct namefirst || ' ' || namelast as player,
	round((sb::numeric / (sb + cs)) * 100, 2) as successful_sb_percent
from people
left join batting 
using(playerid)
where yearid = 2016 and (sb + cs) >= 20
-- having sum(sb) + sum(cs) >= 20
group by player, sb, cs
order by successful_sb_percent desc
limit 1;





-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
select 
	name,
	sum(distinct yearid) as year_sum,
	max(w) as no_ws_wins
from teams
where yearid between 1970 and 2016 and wswin = 'N'
group by name, yearid
order by no_ws_wins desc
limit 1;

select 
	name,
	yearid,
	min(w) as did_win_ws
from teams
where wswin like 'Y'
group by name, yearid, w
order by did_win_ws;

-- select
-- 	min(w)
-- from teams
-- where wswin = 'Y' and yearid between 1970 and 2016 and yearid != 1981;


-- with most_wins as (
-- 	select
-- 		yearid,
-- 		max(w) as most_wins
-- 	from teams
-- 	where yearid between 1970 and 2016 and yearid != 1981 and yearid != 1994
-- 	group by yearid
-- )
-- select
-- 	sum( case when wswin = 'Y' then 1 end) as total_ws_wins,
-- 	round(avg(case when wswin = 'Y' then 1 else 0 end) * 100, 2) as win_pct
-- from most_wins
-- inner join teams
-- using(yearid)
-- where w = most_wins;


with ws_winners as (
		select 			
			yearid,
			max(w) over(partition by yearid) as wins ,
			max(l) over(partition by yearid) as losses
		from teams
		where yearid between 1970 and 2016 and wswin like 'Y'
		group by yearid, teams.w, teams.l
		)
select 
	teams.yearid,
	teams.teamid,
	round(100 * count(ws.wins) / 47, 2)  as w_percent,
	round(100 * count(ws.losses) / 47, 2) as l_percent
from teams
left join ws_winners as ws
using(yearid)
group by teams.yearid, teams.teamid, ws.wins, ws.losses
order by teams.yearid desc;

-- 8.  Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
-- top 5 (desc)
select
	team,
	park,
	round(avg(attendance / games), 2) as avg_attendance
from homegames
where year = 2016 and games >= 10
group by team, park
order by avg_attendance desc
limit 5;

-- bottom 5 (asc)
select
	team,
	park,
	round(avg(attendance / games), 2) as avg_attendance
from homegames
where year = 2016 and games >= 10
group by team, park
order by avg_attendance
limit 5;

-- (select
-- 	teams.park,
-- 	teams.name,
-- 	homegames.attendance/games as avg_attendance, 'Top 5' as attendance_rank
-- from teams
-- inner join	homegames
-- on team = teamid and year = yearid
-- where yearid = 2016 and games >= 10
-- order by avg_attendance desc
-- limit 5)
-- union
-- (select
-- 	teams.park,
-- 	teams.name,
-- 	homegames.attendance/games as avg_attendance, 'Bottom 5' as attendance_rank
-- from teams
-- inner join	homegames
-- on team = teamid and year = yearid
-- where yearid = 2016 and games >= 10
-- order by avg_attendance
-- limit 5)
-- order by avg_attendance desc;



-- 9.  Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
select
	distinct namefirst || ' ' || namelast as manager,
	teams.name as team,
	awardsmanagers.yearid
from awardsmanagers
left join people
using(playerid)
left join appearances
using(playerid)
left join teams
using(teamid)
where awardid = 'TSN Manager of the Year' and awardsmanagers.lgid in ('NL', 'AL');

-- WITH al_nl_tsn_winners AS (
-- 	SELECT playerid
-- 	FROM awardsmanagers
-- 	WHERE awardid = 'TSN Manager of the Year'
-- 		AND lgid = 'AL'
-- 	INTERSECT
-- 	SELECT playerid
-- 	FROM awardsmanagers
-- 	WHERE awardid = 'TSN Manager of the Year'
-- 		AND lgid = 'NL'
-- )

-- SELECT namefirst, namelast, teams.name
-- FROM people
-- INNER JOIN awardsmanagers
-- USING(playerid)
-- INNER JOIN managers
-- USING(playerid, yearid)
-- INNER JOIN teams
-- USING(teamid, yearid)
-- WHERE playerid IN (SELECT * FROM al_nl_tsn_winners)
-- 	AND awardid = 'TSN Manager of the Year';


-- 10.  Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
with years_played as (
	select
		playerid,
		namefirst || ' ' || namelast as player,
		(left(finalgame, 4)::numeric) - (left(debut, 4)::numeric) as years
	from people
)
select
	namefirst || ' ' || namelast as player,
	hr
from people
left join batting
using(playerid)
left join years_played
using(playerid)
where yearid = 2016 and hr >= 1 and hr > (select avg(hr) as avg_hr from batting) and years_played.years > 10;


-- with max_hr as(
-- 	select
-- 		playerid,
-- 		max(hr) as most_hr
-- 	from batting
-- 	group by playerid
-- )
-- select
-- 	namefirst,
-- 	namelast,
-- 	hr
-- from max_hr
-- inner join batting
-- using(playerid)
-- inner join people
-- using(playerid)
-- where hr = most_hr and batting.yearid = 2016 and left(debut, 4)::numeric <=2007 and hr > 0
-- order by hr desc;



				-- Open-ended questions

-- 11.  Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
with avg_salary as (
	select 
		distinct yearid,
		avg(salary) over(partition by yearid) as avg_salary
	from salaries
	where yearid = 2000
	group by yearid, salary
	)
select
	yearid,
	teamid,
	w,
	avg_salary::numeric::money
from teams
inner join avg_salary
using(yearid)
where yearid = 2000;




-- 12.  In this question, you will explore the connection between number of wins and attendance.

	-- i.  Does there appear to be any correlation between attendance at home games and number of wins?
select
	teams.park,
	w,
	coalesce(ghome, 0) as home_games,
	coalesce(attendance, 0) as park_attendance
from teams
left join parks
on teams.park = parks.park_name
where attendance > 1 and ghome > 1
group by teams.park, w, ghome, attendance
order by teams.park;




-- ii.  Do teams that win the world series see a boost in attendance the following year? What about teams 	     	    that made the playoffs? Making the playoffs means either being a division winner or a wild card	winner.
with wswins_number as (
	select
		yearid,
		park,
		case
			when wswin = 'Y' then 1
			when wswin = 'N' then 0
			end as wswins_no
	from teams
	group by yearid, park, wswins_no
)
select
	distinct teams.yearid,
	teams.park,
	coalesce(wswins_no, 0) as ws_wins,
	divwin,
	wcwin,
	coalesce(ghome, 0) as home_games,
	coalesce(attendance, 0) as park_attendance
from teams
left join parks
on teams.park = parks.park_name
left join wswins_number
on parks.park_name = wswins_number.park
where attendance > 1 and ghome > 1
group by teams.yearid, teams.park, ws_wins, divwin, wcwin, ghome, attendance
order by teams.park;

	
-- 13.  It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?
with left_pitchers as (
		select
			playerid,
			throws,
			count(case when throws = 'L' then 1 end) as l
		from people
		group by playerid, throws
)
select
	-- awardid,
	count(left_pitchers.l) as lefties
from people
left join left_pitchers
using(playerid)
left join awardsplayers
using(playerid)
-- where awardid = 'Cy Young Award'
-- group by awardid
order by lefties;




-- SELECT
-- 	COUNT(DISTINCT people.playerid) AS lefties
-- 	, COUNT(CASE WHEN awardid='Cy Young Award' THEN 1 END) AS awarded_lefties
-- 	, ROUND((COUNT(CASE WHEN awardid='Cy Young Award' THEN 1 END)::numeric/COUNT(DISTINCT people.playerid)::numeric*100),2) AS lefty_award_percentage
-- FROM people
-- INNER JOIN awardsplayers
-- USING(playerid)
-- WHERE throws='L';



