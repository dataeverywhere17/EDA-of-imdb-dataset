USE imdb; 

/* Now that we have imported the data sets, let’s explore some of the tables. 
 To begin with, Let's know the shape of the tables and whether any column has null values.
*/


-- Finding the total number of rows in each table of the schema

select count(*) from director_mapping;
select count(*) from genre;
select count(*) from movie;
select count(*) from names;
select count(*) from ratings;
select count(*) from role_mapping;

-- Checking the movie table--
Select*
from movie;
-- Checking columns in the movie table for null values
-- we use case statements here
select sum( CASE
             WHEN 'id' IS NULL THEN 1
             ELSE 0
           END) AS ID_NULL_COUNT,
Sum(CASE
             WHEN title IS NULL THEN 1
             ELSE 0
           END) AS title_NULL_COUNT,
       Sum(CASE
             WHEN year IS NULL THEN 1
             ELSE 0
           END) AS year_NULL_COUNT,
       Sum(CASE
             WHEN date_published IS NULL THEN 1
             ELSE 0
           END) AS date_published_NULL_COUNT,
       Sum(CASE
             WHEN duration IS NULL THEN 1
             ELSE 0
           END) AS duration_NULL_COUNT,
       Sum(CASE
             WHEN country IS NULL THEN 1
             ELSE 0
           END) AS country_NULL_COUNT,
       Sum(CASE
             WHEN worlwide_gross_income IS NULL THEN 1
             ELSE 0
           END) AS worlwide_gross_income_NULL_COUNT,
       Sum(CASE
             WHEN languages IS NULL THEN 1
             ELSE 0
           END) AS languages_NULL_COUNT,
       Sum(CASE
             WHEN production_company IS NULL THEN 1
             ELSE 0
           END) AS production_company_NULL_COUNT
From movie;

-- We can see four columns of the movie table has null values. Let's look at the at the movies released each year. 
-- Finding the total number of movies released each year and also the trend month wise.

select year, count(title) as 'number_of_movies'
from movie
group by year;

select month(date_published) as month_num, count(title) as number_of_movies 
from movie
group  by month_num
order by month_num;

/*The highest number of movies is produced in the month of March

Finding the number of movies produced by USA or India for 2019.*/

select count(distinct id) as number_of_movies, year
from movie
where (country Like '%USA%' OR country like '%India%')
and year = 2019;

-- Finding the unique list of the genres present in the data set

select distinct( genre)
from genre;

-- Finding Which genre had the highest number of movies produced overall

select genre, count(m.id) as number_of_movies
from movie as m
inner join genre as g
on m.id=g.movie_id
group by genre
order by number_of_movies desc limit 1;

-- Drama is the most common genre--

/* A movie can belong to two or more genres. 
let’s find out the count of movies that belong to only one genre.*/

select count(movie_id) from
(select movie_id
from genre
group by movie_id
having count(distinct genre)=1) as genre_movies;


-- checking the  average duration of movies in each genre 

select genre, round(avg(duration),2) as avg_duration
from movie as m
inner join genre as g
on g.movie_id=m.id
group by genre
order by avg_duration Desc;


-- Let's find the rank of the ‘thriller’ genre of movies among all the genres in terms of number of movies produced? 

select genre, count(movie_id) as movie_count,
rank() over (order by count(movie_id) Desc) as genre_rank
from genre
group by genre;


-- let's find the minimum and maximum values in  each column of the ratings table except the movie_id column?

select max(avg_rating) as max_avg_rating, min(avg_rating) as min_avg_rating, max(total_votes) as max_total_votes, min(total_votes) as min_total_votes, max(median_rating) as min_median_rating, max(median_rating) as max_median_rating
from ratings;

/* So, the minimum and maximum values in each column of the ratings table are in the expected range. 
This implies there are no outliers in the table. 
Now, let’s find out the top 10 movies based on average rating.*/

select title, avg_rating, 
rank() over(order by avg_rating DESC) as movie_rank
from ratings as r
inner join movie as m
on r.movie_id-m.id limit 10;


-- Summarizing the ratings table based on the movie counts by median ratings.

select median_rating, count(movie_id) as movie_count
from ratings
group by median_rating
order by median_rating;

/* Movies with a median rating of 7 is highest in number. 
let's find out  Which production house has produced the most number of hit movies (average rating > 8)??*/
select production_company, count(id) as movie_count,
dense_rank() over(order by count(id) desc) as product
from movie as m 
inner join ratings as r on m.id=r.movie_id
where avg_rating>8 and production_company is not null
group by production_company
order by movie_count desc;

-- Dream Warrior Pictures  and National Theatre Live are the joint top production companies--

-- Find movies of each genre that start with the word ‘The’ and which have an average rating > 8?

SELECT  title,
       avg_rating,
       genre
FROM   movie AS M
       INNER JOIN genre AS G
               ON G.movie_id = M.id
       INNER JOIN ratings AS R
               ON R.movie_id = M.id
WHERE  avg_rating > 8
       AND title LIKE 'THE%'
GROUP BY title
ORDER BY avg_rating DESC;

--  trying our hand at median rating and checking whether the ‘median rating’ column gives any significant insights.
-- Let's find out the movies released between 1 April 2018 and 1 April 2019, how many were given a median rating of 8?
SELECT median_rating, Count(*) AS movie_count
FROM   movie AS M
       INNER JOIN ratings AS R
               ON R.movie_id = M.id
WHERE  median_rating = 8
       AND date_published BETWEEN '2018-04-01' AND '2019-04-01'
GROUP BY median_rating;


/* Now that we have analysed the movies, genres and ratings tables, let us now analyse another table, the names table. 
Let’s begin by searching for null values in the tables.*/


SELECT 
		SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS name_nulls, 
		SUM(CASE WHEN height IS NULL THEN 1 ELSE 0 END) AS height_nulls,
		SUM(CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END) AS date_of_birth_nulls,
		SUM(CASE WHEN known_for_movies IS NULL THEN 1 ELSE 0 END) AS known_for_movies_nulls
		
FROM names;

/* 
The director is the most important person in a movie crew. 
Let’s find out the top three directors in the top three genres */


WITH top_3_genres AS
(
           SELECT     genre,
                      Count(m.id)                            AS movie_count ,
                      Rank() OVER(ORDER BY Count(m.id) DESC) AS genre_rank
           FROM       movie                                  AS m
           INNER JOIN genre                                  AS g
           ON         g.movie_id = m.id
           INNER JOIN ratings AS r
           ON         r.movie_id = m.id
           WHERE      avg_rating > 8
           GROUP BY   genre limit 3 )
SELECT     n.NAME            AS director_name ,
           Count(d.movie_id) AS movie_count,
           genre
FROM       director_mapping  AS d
INNER JOIN genre G
using     (movie_id)
INNER JOIN names AS n
ON         n.id = d.name_id
INNER JOIN top_3_genres
using     (genre)
INNER JOIN ratings
using      (movie_id)
WHERE      avg_rating > 8
GROUP BY   NAME
ORDER BY   movie_count DESC limit 3 ;

-- James Mangold is the director on the top of the list--

--  Finding who are the top two actors whose movies have a median rating >= 8?

SELECT N.name          AS actor_name,
       Count(movie_id) AS movie_count
FROM   role_mapping AS RM
       INNER JOIN movie AS M
               ON M.id = RM.movie_id
       INNER JOIN ratings AS R USING(movie_id)
       INNER JOIN names AS N
               ON N.id = RM.name_id
WHERE  R.median_rating >= 8
AND category = 'ACTOR'
GROUP  BY actor_name
ORDER  BY movie_count DESC
LIMIT  2; 
-- No surprise that these two rule the mollywood industry--

/*Let’s find out the top three production houses in the world.*/

SELECT     production_company,
           Sum(total_votes)                            AS vote_count,
           Rank() OVER(ORDER BY Sum(total_votes) DESC) AS prod_comp_rank
FROM       movie                                       AS m
INNER JOIN ratings                                     AS r
ON         r.movie_id = m.id
GROUP BY   production_company limit 3;

/*Now let's find some data strictly from India.*/

-- Let's Rank actors with movies released in India based on their average ratings. 
-- Note: The actor should have acted in at least five Indian movies. 


WITH actor_summary
     AS (SELECT N.NAME                                                     AS
                actor_name
                ,
                total_votes,
                Count(R.movie_id)                                          AS
                   movie_count,
                Round(Sum(avg_rating * total_votes) / Sum(total_votes), 2) AS
                   actor_avg_rating
         FROM   movie AS M
                INNER JOIN ratings AS R
                        ON M.id = R.movie_id
                INNER JOIN role_mapping AS RM
                        ON M.id = RM.movie_id
                INNER JOIN names AS N
                        ON RM.name_id = N.id
         WHERE  category = 'ACTOR'
                AND country = "india"
         GROUP  BY NAME
         HAVING movie_count >= 5)
SELECT *,
       Rank()
         OVER(
           ORDER BY actor_avg_rating DESC) AS actor_rank
FROM   actor_summary; 

-- Let's Find out the top five actresses in Hindi movies released in India based on their average ratings? 
-- Note: The actresses should have acted in at least three Indian movies. 

WITH actress_summary AS
(
           SELECT     n.NAME AS actress_name,
                      total_votes,
                      Count(r.movie_id)                                     AS movie_count,
                      Round(Sum(avg_rating*total_votes)/Sum(total_votes),2) AS actress_avg_rating
           FROM       movie                                                 AS m
           INNER JOIN ratings                                               AS r
           ON         m.id=r.movie_id
           INNER JOIN role_mapping AS rm
           ON         m.id = rm.movie_id
           INNER JOIN names AS n
           ON         rm.name_id = n.id
           WHERE      category = 'ACTRESS'
           AND        country = "INDIA"
           AND        languages LIKE '%HINDI%'
           GROUP BY   NAME
           HAVING     movie_count>=3 )
SELECT   *,
         Rank() OVER(ORDER BY actress_avg_rating DESC) AS actress_rank
FROM     actress_summary LIMIT 5;

/* let's Select thriller movies as per avg rating and classify them in the following category: 

			Rating > 8: Superhit movie
			Rating between 7 and 8: Hit movie
			Rating between 5 and 7: One-time-watch movie
			Rating < 5: Flop movie
--------------------------------------------------------------------------------------------*/

WITH thriller_movies
     AS (SELECT DISTINCT title,
                         avg_rating
         FROM   movie AS M
                INNER JOIN ratings AS R
                        ON R.movie_id = M.id
                INNER JOIN genre AS G using(movie_id)
         WHERE  genre LIKE 'THRILLER')
SELECT *,
       CASE
         WHEN avg_rating > 8 THEN 'Superhit movie'
         WHEN avg_rating BETWEEN 7 AND 8 THEN 'Hit movie'
         WHEN avg_rating BETWEEN 5 AND 7 THEN 'One-time-watch movie'
         ELSE 'Flop movie'
       END AS avg_rating_category
FROM   thriller_movies; 



-- Let's check what is the genre-wise running total and moving average of the average movie duration? 

SELECT genre,
		ROUND(AVG(duration),2) AS avg_duration,
        SUM(ROUND(AVG(duration),2)) OVER(ORDER BY genre ROWS UNBOUNDED PRECEDING) AS running_total_duration,
        AVG(ROUND(AVG(duration),2)) OVER(ORDER BY genre ROWS 10 PRECEDING) AS moving_avg_duration
FROM movie AS m 
INNER JOIN genre AS g 
ON m.id= g.movie_id
GROUP BY genre
ORDER BY genre;



-- Let us find top 5 movies of each year with top 3 genres.

WITH top_genres AS
(
           SELECT     genre,
                      Count(m.id)                            AS movie_count ,
                      Rank() OVER(ORDER BY Count(m.id) DESC) AS genre_rank
           FROM       movie                                  AS m
           INNER JOIN genre                                  AS g
           ON         g.movie_id = m.id
           INNER JOIN ratings AS r
           ON         r.movie_id = m.id
           WHERE      avg_rating > 8
           GROUP BY   genre limit 3 ), movie_summary AS
(
           SELECT     genre,
                      year,
                      title AS movie_name,
                      CAST(replace(replace(ifnull(worlwide_gross_income,0),'INR',''),'$','') AS decimal(10)) AS worlwide_gross_income ,
                      DENSE_RANK() OVER(partition BY year ORDER BY CAST(replace(replace(ifnull(worlwide_gross_income,0),'INR',''),'$','') AS decimal(10))  DESC ) AS movie_rank
           FROM       movie                                                                     AS m
           INNER JOIN genre                                                                     AS g
           ON         m.id = g.movie_id
           WHERE      genre IN
                      (
                             SELECT genre
                             FROM   top_genres)
            GROUP BY   movie_name
           )
SELECT *
FROM   movie_summary
WHERE  movie_rank<=5
ORDER BY YEAR;




-- Let's find out who are the top 3 actresses based on number of Super Hit movies (average rating >8) in drama genre?

WITH actress_summary AS
(
           SELECT     n.NAME AS actress_name,
                      SUM(total_votes) AS total_votes,
                      Count(r.movie_id)                                     AS movie_count,
                      Round(Sum(avg_rating*total_votes)/Sum(total_votes),2) AS actress_avg_rating
           FROM       movie                                                 AS m
           INNER JOIN ratings                                               AS r
           ON         m.id=r.movie_id
           INNER JOIN role_mapping AS rm
           ON         m.id = rm.movie_id
           INNER JOIN names AS n
           ON         rm.name_id = n.id
           INNER JOIN GENRE AS g
           ON g.movie_id = m.id
           WHERE      category = 'ACTRESS'
           AND        avg_rating>8
           AND genre = "Drama"
           GROUP BY   NAME )
SELECT   *,
         Rank() OVER(ORDER BY movie_count DESC) AS actress_rank
FROM     actress_summary LIMIT 3;



-- The indian film industry is a coaagulation of talented artists which are there right at the top with the much popular hollywood industry-- 



