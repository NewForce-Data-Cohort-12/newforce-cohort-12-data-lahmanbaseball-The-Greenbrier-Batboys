select * from people;
select * from teams;
select * from appearances;
select * from collegeplaying;
select * from schools;
select * from salaries;
select * from fielding;
select * from schools;



-- 2.  Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
select 
	namefirst,
	namelast,
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



-- 3.  Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
select 
	namefirst || ' ' || namelast as name,
	schools.schoolname,
	sum(salary::numeric::money) as salary
from people
inner join collegeplaying
using(playerid)
inner join schools
using(schoolid)
inner join salaries
using(playerid)
where schools.schoolname = 'Vanderbilt University' and salary is not null
group by namefirst, namelast, schools.schoolname, salary
order by salary desc
limit 1;




-- 4.  Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
	-- Putouts per player and groups in 2016
-- with putouts as (
-- 	select
		-- playerid,
		-- Sum of po because it's returning the putouts to be able to sum in aggregation, not count of'Label of Putout'
		sum(case when pos like 'OF' then po end) as outfield_putouts,
		sum(case when pos in ('SS', '1B', '2B', '3B') then po end) as infield_putouts,
		sum(case when pos in ('P', 'C') then po end) as battery_putouts
	from fielding
	where yearid = 2016
-- 	group by playerid
-- )
-- select
-- 	concat(namefirst, ' ', namelast) as full_name,
-- 	putouts.outfield_putouts,
-- 	putouts.infield_putouts,
-- 	putouts.battery_putouts
-- from fielding
-- left join people
-- using(playerid)
-- left join putouts
-- using(playerid)
-- where yearid = 2016
-- group by namefirst, namelast, putouts.outfield_putouts, putouts.infield_putouts, putouts.battery_putouts;


	-- Total putouts in 2016
-- with putouts as (
-- 	select
-- 		playerid,
-- 		count(case when pos like 'OF' then 'Outfield' end) as outfield_putouts,
-- 		count(case when pos in ('SS', '1B', '2B', '3B') then 'Infield' end) as infield_putouts,
-- 		count(case when pos in ('P', 'C') then 'Battery' end) as battery_putouts
-- 	from fielding
-- 	where yearid = 2016
-- 	group by playerid
-- )
-- select
-- 	count(putouts.outfield_putouts + putouts.infield_putouts + putouts.battery_putouts) as no_of_putouts
-- from fielding
-- left join people
-- using(playerid)
-- left join putouts
-- using(playerid)
-- where yearid = 2016
-- order by no_of_putouts;