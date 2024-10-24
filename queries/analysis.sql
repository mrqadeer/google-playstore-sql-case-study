-- Set SQL mode to ignore ONLY_FULL_GROUP_BY for ease of aggregation
SET sql_mode = (
    SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', '')
);

-- Question 1:
-- Identify the top 5 most promising categories for launching new free apps based on their average ratings.
SELECT
    Category,
    ROUND(AVG(Rating), 2) AS Rating,   -- Calculate the average rating and round to 2 decimals
    `Type`
FROM
    google_ps
WHERE
    `Type` = 'Free'                    -- Only consider free apps
GROUP BY
    `Category`
ORDER BY
    Rating DESC                        -- Order by the highest average ratings
LIMIT
    5;                                 -- Limit results to top 5 categories

-- Question 2:
-- Pinpoint the top 3 categories generating the most revenue from paid apps, calculated as Price * Installs.
SELECT
    Category,
    `Type`,
    ROUND(AVG(`Price` * `Installs`)) AS revenue  -- Calculate average revenue for each category
FROM
    google_ps
WHERE
    `Type` = 'Paid'                               -- Only consider paid apps
GROUP BY
    `Category`
ORDER BY
    revenue DESC                                  -- Order by highest revenue
LIMIT
    3;                                            -- Limit results to top 3 categories

-- Display all distinct types of apps (Free, Paid, etc.)
SELECT DISTINCT `Type`
FROM google_ps;

-- Question 3:
-- Calculate the percentage of games within each category to understand the distribution of gaming apps.
SET @total_count = (
    SELECT COUNT(*) FROM google_ps               -- Get total number of apps
);

SELECT
    Category,
    COUNT(App) / @total_count * 100 AS percentage -- Calculate percentage for each category
FROM
    google_ps
GROUP BY
    `Category`;

-- Question 4:
-- Recommend whether to develop paid or free apps for each category based on their average ratings.
WITH free_rating AS (
    SELECT
        Category,
        ROUND(AVG(`Rating`), 2) AS 'free'          -- Get average ratings for free apps
    FROM
        google_ps
    WHERE
        `Type` = 'Free'
    GROUP BY
        `Category`
),
paid_rating AS (
    SELECT
        Category,
        ROUND(AVG(`Rating`), 2) AS 'paid'          -- Get average ratings for paid apps
    FROM
        google_ps
    WHERE
        `Type` = 'Paid'
    GROUP BY
        `Category`
)
SELECT
    *,
    IF (t2.paid > t1.free, "Develop paid apps", "Develop free apps") AS decision -- Compare ratings and decide
FROM
    free_rating t1
NATURAL JOIN paid_rating t2;

-- Question 5:
-- Create a log to record price changes to monitor unauthorized changes by hackers.
CREATE TABLE IF NOT EXISTS price_changelog(
    app VARCHAR(255),
    old_price DECIMAL(10, 2),
    new_price DECIMAL(10, 2),
    operation_type VARCHAR(255),
    operation_date TIMESTAMP
);

-- Create a backup table
CREATE TABLE play
SELECT * FROM google_ps;

-- Create a trigger to log price changes after any update
DELIMITER //
CREATE TRIGGER price_change_log
AFTER UPDATE ON play
FOR EACH ROW
BEGIN
    INSERT INTO price_changelog(
        app,
        old_price,
        new_price,
        operation_type,
        operation_date
    )
    VALUES (
        NEW.App,
        OLD.Price,
        NEW.Price,
        'UPDATE',
        CURRENT_TIMESTAMP()
    );
END //
DELIMITER ;

-- Test updating prices to trigger the log
UPDATE play SET `Price` = 4 WHERE `App` = 'Infinite Painter';
UPDATE play SET `Price` = 6 WHERE `App` = 'Coloring book moana';

-- Remove specific entries from price change log
DELETE FROM price_changelog WHERE new_price = 6;

-- View the log
SELECT * FROM price_changelog;

-- Question 6:
-- Restore the correct prices using the log after the hacking issue.
-- Drop the trigger before updating prices
DROP TRIGGER price_change_log;

-- Restore old prices by joining with the price_changelog table
UPDATE play AS a
JOIN price_changelog AS b ON a.App = b.app
SET a.`Price` = b.old_price;

-- Verify the update for a specific app
SELECT * FROM play WHERE `App` = 'Infinite Painter';

-- Question 7:
-- Investigate the correlation between app ratings and the number of reviews using Pearson correlation.
-- Set the average Rating and Reviews
SET @x = (SELECT ROUND(AVG(Rating), 2) FROM google_ps);
SET @y = (SELECT ROUND(AVG(Reviews), 2) FROM google_ps);

-- Calculate Pearson correlation
WITH Calc AS (
    SELECT
        Rating,
        @x AS AvgRating,
        ROUND((Rating - @x), 2) AS rat, -- Difference from average rating
        Reviews,
        @y AS AvgReviews,
        ROUND((Reviews - @y), 2) AS rev -- Difference from average reviews
    FROM
        google_ps
)
SELECT
    ROUND(SUM(rat * rev) / SQRT(SUM(rat * rat) * SUM(rev * rev)), 2) AS Cor -- Calculate correlation
FROM
    Calc;

-- Question 8:
-- Split the 'Genres' column into two columns: 'Genres_1' and 'Genres_2' to address multiple genres.
ALTER TABLE google_ps DROP COLUMN Genres_1;
ALTER TABLE google_ps ADD COLUMN `Genres_1` VARCHAR(255) AFTER `Genres`;
ALTER TABLE google_ps ADD COLUMN `Genres_2` VARCHAR(255) AFTER `Genres_1`;

-- Populate the new genre columns
UPDATE google_ps SET `Genres_1` = SUBSTRING_INDEX(`Genres`, '&', 1);
UPDATE google_ps SET `Genres_2` = SUBSTRING_INDEX(`Genres`, '&', -1);

-- Handle cases where genres are separated by semicolons
UPDATE google_ps SET `Genres_1` = CASE
    WHEN `Genres` LIKE '%;%' THEN SUBSTRING_INDEX(`Genres`, ';', 1)
    ELSE `Genres`
END;

UPDATE google_ps SET `Genres_2` = CASE
    WHEN `Genres` LIKE '%;%' THEN SUBSTRING_INDEX(`Genres`, ';', -1)
    ELSE NULL
END;

-- Verify the result
SELECT * FROM google_ps;

-- Question 9:
-- Create a dynamic tool that displays apps in a category with ratings lower than the category average.
DELIMITER //
CREATE PROCEDURE check_cat(IN cat VARCHAR(255))
BEGIN
    SET @average = (
        SELECT average
        FROM (
            SELECT Category, AVG(`Rating`) AS average
            FROM google_ps
            GROUP BY `Category`
        ) m
        WHERE `Category` = cat
    );

    -- Select apps in the category with lower than average ratings
    SELECT * FROM google_ps WHERE Category = cat AND Rating < @average;
END //
DELIMITER ;

-- Test the procedure with a specific category
CALL check_cat('Business');

-- Question 10:
-- Explanation of Duration Time and Fetch Time:
-- Duration Time: The time taken for SQL to understand and parse the query instructions (e.g., query complexity, keyword analysis).
-- Fetch Time: The time taken to retrieve and present the results (depends on data size and query complexity).

-- EXAMPLE:
-- Duration Time: The time it takes to process and analyze your request, such as identifying and preparing to fetch the relevant data.
-- Fetch Time: The time it takes to retrieve and return the results after understanding the query, like fetching all fiction books in a library.
