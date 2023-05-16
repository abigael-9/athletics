SELECT *
FROM OLYMPICS_HISTORY

SELECT *
FROM noc_regions

--How many olympics games have been held?

SELECT COUNT( distinct Games) as total_olympic_games
FROM OLYMPICS_HISTORY

--List down all Olympics games held so far.


SELECT  distinct Year, City, Season
FROM OLYMPICS_HISTORY
order by Year


--Mention the total no of nations who participated in each olympics game?

SELECT Games, COUNT(distinct region) as total_countries
FROM OLYMPICS_HISTORY oh
join noc_regions nr
on  oh.NOC = nr.NOC
group by Games
order by Games



--Which year saw the highest and lowest no of countries participating in olympics?

With All_countries as
(
	SELECT Games,region
	FROM OLYMPICS_HISTORY oh
	join noc_regions nr
	on  oh.NOC = nr.NOC
	group by Games, region
	--order by Games	
),
  Tot_countries as
(
	SELECT Games, count(1) as total_countries
	FROM All_countries
	group by Games
)

SELECT DISTINCT
	CONCAT(First_value(Games) OVER (ORDER BY Total_countries), '-',
    First_value(Total_countries) OVER(ORDER BY Total_countries)) as Lowest_Countries,
    CONCAT(First_value(Games) OVER(ORDER BY total_countries desc) , ' - ',
    First_value(Total_countries) OVER(ORDER BY total_countries desc)) as Highest_Countries
      from tot_countries
      ORDER BY 1;


--Which nation has participated in all of the olympic games?

WITH tot_games as
	(
		SELECT count(distinct Games) as total_games
		FROM OLYMPICS_HISTORY 
	),
	countries as
	(
		SELECT Games, region as country
		FROM OLYMPICS_HISTORY oh
		JOIN noc_regions nr
		ON oh.NOC = nr.NOC
		group by Games, region
	),
	countries_participated as
	(
		SELECT country, count(1) as total_participated_games
        from countries
        group by country
	)

	SELECT *
	FROM countries_participated cp
	join tot_games tg 
	on tg.total_games = cp.total_participated_games
	order by 1;


--Identify the sport which was played in all summer olympics.


WITH t1 AS
	(
		SELECT  COUNT (distinct Games) as total_games
		FROM OLYMPICS_HISTORY
		WHERE Season =  'summer'
	),
	t2 AS
	(
	SELECT  distinct Games, Sport, Season
	FROM OLYMPICS_HISTORY
	WHERE Season =  'summer'
	),
	t3 AS
	(
	SELECT Sport, count(1) as no_of_games
	FROM t2
	WHERE Season =  'summer'
	group by Sport
	)
   select *
   from t3
   join t1 on t1.total_games = t3.no_of_games;


--Which Sports were just played only once in the olympics?
WITH T1 AS
	(
		SELECT DISTINCT Games, Sport 
		FROM OLYMPICS_HISTORY
		group by Sport, Games
		
	),
	T2 AS
	(
		SELECT Sport, count(1) as no_of_games
		FROM T1
		group by Sport
	)
SELECT T2.*, T1.Games
FROM T2
JOIN T1 ON T1.Sport = T2.Sport
WHERE T2.no_of_games = 1
ORDER BY T1.Sport;


--Fetch the total no of sports played in each olympic games.

	with t1 as
		(
		SELECT DISTINCT Games, Sport 
		FROM OLYMPICS_HISTORY
		group by Games,Sport
		),
		t2 as
		(
		select Games, COUNT(1) as no_of_games
		from t1
		group by Games
		)
SELECT *
FROM t2
order by no_of_games desc

--Fetch details of the oldest athletes to win a gold medal.

SELECT TOP 2 Name,Sex,Age,Team,Games,Sport,Medal
FROM OLYMPICS_HISTORY
where Medal = 'gold'
order by Age  desc



--Find the Ratio of male and female athletes participated in all olympic games.

------------SELECT CAST(COUNT(CASE WHEN Sex = 'M' THEN 1 END)/ COUNT(CASE WHEN Sex = 'F' THEN 1 END)AS float)
------------as gender_ratio
------------FROM OLYMPICS_HISTORY

--------------SELECT CAST(COUNT(CASE WHEN Sex = 'M' THEN 1 else 0 END)/COUNT(*) as decimal) AS male_ratio,
--------------		CAST(COUNT(CASE WHEN Sex = 'F' THEN 1 else 0 END)/COUNT(*) as decimal) AS female_ratio
--------------FROM OLYMPICS_HISTORY
 

--Fetch the top 5 athletes who have won the most gold medals.

	with t1 as
		 (
		   select  name,   count(1) as total_gold_medals
		   from olympics_history
		   where medal = 'Gold'
		   group by name
            --order by COUNT(1) desc
		 ),
		t2 as
		(
		   select *, dense_RANK() over(order by total_gold_medals desc) as rnk
		   from t1
		 )
select *
from t2




--Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

select  name, team, count(1) as total_gold_medals
            from olympics_history
            where medal in ( 'Gold', 'silver', 'bronze')
            group by name, team
            order by total_gold_medals desc



--Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

select   top 5 region, count(1) as total_gold_medals
            from olympics_history oh
			join noc_regions nr
			on oh.NOC = nr.NOC 
            where medal in ( 'Gold', 'silver', 'bronze')
            group by region
            order by total_gold_medals desc



--List down total gold, silver and bronze medals won by each country.


   SELECT 
		 Country,
    	 coalesce(gold, 0) as gold,
    	 coalesce(silver, 0) as silver,
    	 coalesce(bronze, 0) as bronze
	FROM	 
				(SELECT  nr.region as Country, medal, count(1) as total_medals
    			FROM olympics_history oh
    			JOIN noc_regions nr 
				ON nr.noc = oh.noc
    			where medal <> 'NA'
    			GROUP BY nr.region,Medal) as source_table
		PIVOT
		(sum (total_medals)
		FOR			 
		medal in ([Bronze], [Gold], [Silver]))
		AS FINAL_RESULT
		order by  gold desc, silver desc , bronze desc ;



--List down total gold, silver and broze medals won by each country corresponding to each olympic games.


with temp as
		(
		   SELECT Games,
				  Country,
    			 coalesce(gold, 0) as gold,
    			 coalesce(silver, 0) as silver,
    			 coalesce(bronze, 0) as bronze
			FROM	 
						(SELECT Games, region as Country, medal, count(1) as total_medals
    					FROM olympics_history oh
    					JOIN noc_regions nr 
						ON nr.noc = oh.noc
    					where medal <> 'NA' 
    					GROUP BY Games, nr.region,Medal) as source_table
				PIVOT
				(sum (total_medals)
				FOR			 
				medal in ([Bronze], [Gold], [Silver]))
				AS FINAL_RESULT
				)
select  distinct games,
concat(first_value(country) over(partition by games order by gold desc)
			, ' - '
			,first_value(gold) over(partition by games order by gold desc)) as gold,
			
concat(first_value(country) over(partition by games order by silver desc)
			, ' - '
			,first_value(silver) over(partition by games order by silver desc)) as silver,
			
concat(first_value(country) over(partition by games order by bronze desc)
			, ' - '
			,first_value(bronze) over(partition by games order by bronze desc))as bronze
from temp
order by games


--List down total gold, silver and broze medals won by kenya corresponding to each olympic games.


	SELECT Games,
		  Country,
    	 coalesce(gold, 0) as gold,
    	 coalesce(silver, 0) as silver,
    	 coalesce(bronze, 0) as bronze
	FROM	 
				(SELECT Games, region as Country, medal, count(1) as total_medals
    			FROM olympics_history oh
    			JOIN noc_regions nr 
				ON nr.noc = oh.noc
    			where medal <> 'NA' and region = 'kenya'
    			GROUP BY Games, nr.region,Medal) as source_table
		PIVOT
		(sum (total_medals)
		FOR			 
		medal in ([Bronze], [Gold], [Silver]))
		AS FINAL_RESULT
		order by  Games, Country, gold desc, silver desc , bronze desc ;

--Identify which country won the most gold, most silver and most bronze medals in each olympic games.


  





--Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.




--Which countries have never won gold medal but have won silver/bronze medals?




--In which Sport/event, kenya has won highest medals.
	with t1 as
		(
		SELECT  Sport, COUNT(1)as total_medals
		FROM OLYMPICS_HISTORY
		where Team = 'kenya' and Medal <> 'NA'
		GROUP BY  Sport
		
		)
		
select sport, MAX(total_medals)as medals
from t1
group by Sport, total_medals
		


