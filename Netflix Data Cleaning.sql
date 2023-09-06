USE NetflixData;

-- 1. Display the complete table to look at the data

SELECT * FROM Netflix;

-- 2. Extracting Column information to understand data further

SELECT
table_name, column_name, data_type, ordinal_position
FROM
INFORMATION_SCHEMA.COLUMNS


-- 3. Since release_year column has a float datatype, transforming it into INT

SELECT release_year,
CONVERT(INT,release_year)
FROM
Netflix;

ALTER TABLE Netflix
ADD Release_Year_Updated INT

UPDATE Netflix
SET Release_Year_Updated = CONVERT(int,release_year)

ALTER TABLE Netflix
DROP COLUMN release_year

sp_rename 'Netflix.release_year_updated','release_year','column'

-- 4. checking to see if there are any Null in director column

SELECT title FROM netflix WHERE director is NULL;
-- since there are no null values, checking to see if any other word has been used for not available data
SELECT director,count(director)
FROM Netflix
GROUP by director
ORDER by count(director) DESC;
-- 2588 rows have 'Not Given' in the director column
-- Updating the 'Not Given' in director to 'Not Known'
UPDATE Netflix
Set director = 'Not Known'
where director = 'Not Given'


-- 5. duration column consists data like '126 min' in case of Movies & '3 seasons' in case of TV Show
-- will create two columns with duration_movie & seasons_tvshow with interger values so that it can be queried based on requirements

SELECT title,type,duration,
case when type = 'movie' then convert(INT, SUBSTRING(duration,1,CHARINDEX(' ', duration))) else Null end as duration_movie,
case when type = 'tv show' then convert(INT, SUBSTRING(duration,1,CHARINDEX(' ', duration))) else Null end as season_tvshow
FROM Netflix;

ALTER TABLE Netflix
ADD duration_movie INT, season_tvshow INT

UPDATE Netflix
SET duration_movie = case when type = 'movie' then convert(INT, SUBSTRING(duration,1,CHARINDEX(' ', duration))) else Null end,
season_tvshow = case when type = 'tv show' then convert(INT, SUBSTRING(duration,1,CHARINDEX(' ', duration))) else Null end

-- 6. Finding the year & month of addition on Netflix
-- Adding them as columns in the table
ALTER TABLE Netflix
ADD year_added INT, month_added INT

UPDATE Netflix
SET year_added = YEAR(date_added), month_added = MONTH(date_added)

-- 7. Finding duplicates from show_id
SELECT show_id, count(show_id)
FROM Netflix
GROUP BY show_id
ORDER BY count(show_id) DESC;
-- no duplicates found
-- finding duplicates with a combination of columns(title,type & country)

WITH CTE as (
SELECT show_id,title, type, country, ROW_NUMBER() OVER (PARTITION BY title,type,country ORDER BY title) 'Duplicate'
FROM Netflix)

SELECT * FROM CTE WHERE Duplicate>1;

-- 6 duplicates found. We will now remove these duplicates

WITH CTE as (
SELECT show_id,title, type, country, ROW_NUMBER() OVER (PARTITION BY title,type,country ORDER BY title) 'Duplicate'
FROM Netflix)

DELETE FROM CTE WHERE Duplicate>1;

-- the duplicates have been removed. Now we can check again to find no duplicates.

-- 8. Find out how many different tags are there in listed_in column
-- 'listed_in' is in the form of 'Action & Adventure, Comedies, International Movies'
-- Idenity the max no of tags in one cell
SELECT TOP 10 listed_in, len(listed_in) - len(REPLACE(listed_in, ',',''))+1 as No_of_Tags
FROM Netflix
ORDER BY len(listed_in) - len(REPLACE(listed_in, ',',''))+1 DESC ;
-- There are max 3 tags in one cell
-- To find out the Unique Tags
WITH CTE as 
(SELECT PARSENAME(REPLACE(listed_in,',','.'),1) Tags
FROM Netflix
Union
SELECT PARSENAME(REPLACE(listed_in,',','.'),2)
FROM Netflix
Union
SELECT PARSENAME(REPLACE(listed_in,',','.'),3)
FROM Netflix)

SELECT Distinct(Tags) FROM CTE;
-- There are 74 different Tags. However, some of them are repeating with spaces in front

WITH CTE as 
(SELECT PARSENAME(REPLACE(listed_in,',','.'),1) Tags
FROM Netflix
Union
SELECT PARSENAME(REPLACE(listed_in,',','.'),2)
FROM Netflix
Union
SELECT PARSENAME(REPLACE(listed_in,',','.'),3)
FROM Netflix)

SELECT Distinct(TRIM(Tags)) FROM CTE;
-- There are ONLY 43 Unique Tags with no duplicates


-- 9. Check Missing Values in show_id, title, type, duration_movie, season_tvshow
SELECT
 COUNT(*)-COUNT(show_id),
 COUNT(*)-COUNT(title),
 COUNT(*)-COUNT(type),
 COUNT(*)-COUNT(duration_movie),
 COUNT(*)-COUNT(season_tvshow)
  FROM
  Netflix;
  -- there are no missing values in show_id, title or type
  -- There are 2662 missing values in duration_movie & 6122 in season_tvshow which totals to 8784, the total no of records