show tables;


# Create the content for the SQL file based on the 10 questions

-- 1. How many unique post types are found in the 'fact_content' table?
SELECT COUNT(DISTINCT post_type) AS unique_post_types FROM fact_content;
SELECT DISTINCT(post_type) AS post_type,  COUNT(post_type) AS count_post_types from fact_content group by post_type;

-- 2. What are the highest and lowest recorded impressions for each post type?
SELECT post_type, MAX(impressions) AS highest_impressions, MIN(impressions) AS lowest_impressions
FROM fact_content
GROUP BY post_type;

-- 3. Filter all the posts that were published on a weekend in the month of March and April and export them to a separate csv file.
SELECT fc.*
FROM fact_content fc
JOIN dim_dates dd ON fc.date = dd.date
WHERE dd.month_name IN ('March', 'April') AND dd.weekday_or_weekend = 'Weekend';

-- 4. Create a report to get the statistics for the account: month_name, total_profile_visits, total_new_followers
SELECT dd.month_name, 
       SUM(fa.profile_visits) AS total_profile_visits,
       SUM(fa.new_followers) AS total_new_followers
FROM fact_account fa
JOIN dim_dates dd ON fa.date = dd.date
GROUP BY dd.month_name;

-- 5. CTE that calculates the total number of 'likes’ for each 'post_category' during the month of 'July', ordered by total likes descending
WITH likes_cte AS (
    SELECT post_category, SUM(likes) AS total_likes
    FROM fact_content fc
    JOIN dim_dates dd ON fc.date = dd.date
    WHERE dd.month_name = 'July'
    GROUP BY post_category
)
SELECT * FROM likes_cte
ORDER BY total_likes DESC;

-- 6. Unique post_category names alongside their respective counts for each month
SELECT dd.month_name,
       GROUP_CONCAT(DISTINCT fc.post_category ORDER BY fc.post_category) AS post_category_names,
       COUNT(DISTINCT fc.post_category) AS post_category_count
FROM fact_content fc
JOIN dim_dates dd ON fc.date = dd.date
GROUP BY dd.month_name;

-- 7. Percentage breakdown of total reach by post type
WITH reach_cte AS (
    SELECT post_type, SUM(reach) AS total_reach FROM fact_content GROUP BY post_type
),
total AS (
    SELECT SUM(total_reach) AS grand_total FROM reach_cte
)
SELECT r.post_type, r.total_reach,
       ROUND((r.total_reach / t.grand_total) * 100, 2) AS reach_percentage
FROM reach_cte r, total t
order by reach_percentage DESC;

-- 8. Quarter, total comments, and total saves for each post category
SELECT fc.post_category,
       CASE
           WHEN dd.month_name IN ('January', 'February', 'March') THEN 'Q1'
           WHEN dd.month_name IN ('April', 'May', 'June') THEN 'Q2'
           WHEN dd.month_name IN ('July', 'August', 'September') THEN 'Q3'
           ELSE 'Q4'
       END AS quarter,
       SUM(fc.comments) AS total_comments,
       SUM(fc.saves) AS total_saves
FROM fact_content fc
JOIN dim_dates dd ON fc.date = dd.date
GROUP BY fc.post_category, quarter;

-- 9. Top 3 dates in each month with highest new followers
WITH ranked_followers AS (
    SELECT dd.month_name AS month, fa.date, fa.new_followers,
           RANK() OVER (PARTITION BY dd.month_name ORDER BY fa.new_followers DESC) AS rnk
    FROM fact_account fa
    JOIN dim_dates dd ON fa.date = dd.date
)
SELECT month, date, new_followers
FROM ranked_followers
WHERE rnk <= 3;

-- 10. Stored Procedure: total shares for each post_type for a given Week_no
DELIMITER //
CREATE PROCEDURE GetSharesByWeek(IN input_week_no INT)
BEGIN
    SELECT fc.post_type, SUM(fc.shares) AS total_shares
    FROM fact_content fc
    JOIN dim_date dd ON fc.date = dd.date
    WHERE dd.week_no = input_week_no
    GROUP BY fc.post_type;
END //
DELIMITER ;

