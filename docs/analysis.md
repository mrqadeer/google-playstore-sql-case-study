# Data Cleaning and Analysis - Chain of Thought

This document provides an in-depth explanation of each step and concept used in both `cleaning.sql` and `analysis.sql` files. The objective is to offer a clear understanding of how the data is processed, cleaned, and analyzed to derive valuable insights.


### 1. **Cleaning and Preprocessing in `cleaning.sql`**

-  **Removing Unnecessary Characters from the `Installs` Column**
   - **Purpose**: The `Installs` column contains comma-separated values and a "+" sign which are non-numeric and need to be cleaned for further analysis.
   - **Action**: We remove these characters to convert the column into a numeric format.
   ```sql
   UPDATE google_ps
   SET Installs = REPLACE(REPLACE(Installs, '+', ''), ',', '');
   ```
   - **Explanation**: This step ensures that we can use the Installs column for numeric operations like aggregation or multiplication in revenue calculations.
-  **Converting Data Types**
   - **Purpose**: The Installs column is initially stored as a string, but numeric operations require it to be of integer type.
    - **Action**: We cast the cleaned Installs data into an integer.
    ```sql 
    ALTER TABLE google_ps
    MODIFY Installs BIGINT;
   ```
   - **Explanation**: By converting Installs to a BIGINT, we enable proper mathematical operations such as multiplication when calculating revenue.
-  **Cleaning the Price Column**
    - **Purpose**: The Price column contains "$" signs that need to be removed to convert the values into numeric format.
    - **Action**: Remove the dollar sign and convert the column into a decimal format.
    ```sql
    UPDATE google_ps
    SET Price = REPLACE(Price, '$', '');
    ```
    - **Explanation**: This step ensures that we can use the Price column for numeric operations like aggregation or multiplication in revenue calculations.
- **Filtering Invalid Rows**
    - **Purpose**: Some rows in the dataset might contain invalid or missing data for key columns such as Rating or Installs.
    - **Action**: Delete rows with invalid values.
    ```sql
    DELETE FROM google_ps WHERE Rating IS NULL OR Installs = '0';
    ```
    - **Explanation**:  Rows with missing or irrelevant values could skew the analysis, so filtering them ensures the integrity of our data.
## 2. **Analysis in `analysis.sql`**

- **Removing SQL Mode ONLY_FULL_GROUP_BY**
    - **Purpose**: Some queries involving GROUP BY clauses could throw an error if ONLY_FULL_GROUP_BY mode is enabled.
    - **Action**: Modify the SQL mode to remove this restriction.
    ```sql
    SET sql_mode = (SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', ''));
    ```
    - **Explanation**: Disabling this mode allows us to run queries without having to explicitly list all non-aggregated columns in the GROUP BY clause.
- **Top 5 Categories for Launching Free Apps**
    - **Purpose**: Identify the top 5 app categories with the highest average ratings for free apps.
    - **Action**: Aggregate the Rating column and group by Category.
    ```sql
    SELECT Category, ROUND(AVG(Rating), 2) AS Rating
    FROM google_ps
    WHERE Type = 'Free'
    GROUP BY Category
    ORDER BY Rating DESC
    LIMIT 5;
    ```
    - **Explanation**: Grouping by Category and averaging the Rating helps us identify which categories perform best for free apps.
- **Top 3 Categories by Revenue from Paid Apps**
    - **Purpose**: Find the categories that generate the most revenue based on the product of Price and Installs.
    - **Action**: Calculate average revenue for each category.
  ```sql
    SELECT Category, ROUND(AVG(Price * Installs)) AS revenue
    FROM google_ps
    WHERE Type = 'Paid'
    GROUP BY Category
    ORDER BY revenue DESC
    LIMIT 3;
    ```
    - **Explanation**: Multiplying Price by Installs gives us the revenue for each app. By aggregating and sorting by Category, we find the most profitable categories for paid apps.
- **Percentage of Gaming Apps in Each Category**
    - **Purpose**: Calculate the percentage of apps within each category that are gaming apps.
    - **Action**: Compute the ratio of apps in each category to the total number of apps.
    ```sql
    SET @total_count = (SELECT COUNT(*) FROM google_ps);
    SELECT Category, COUNT(App) / @total_count * 100 AS Percentage
    FROM google_ps
    GROUP BY Category;
    ```
    - **Explanation**: This query shows the distribution of gaming apps across various categories, giving insights into how popular gaming apps are.
-  **Should the Company Develop Paid or Free Apps?**
    - **Purpose**: Based on ratings, determine if the company should focus on developing free or paid apps for each category.
    - **Action**: Use a WITH clause to create temporary tables for free and paid app ratings, and then compare them.
    ```sql
    WITH free_rating AS (
        SELECT Category, ROUND(AVG(Rating), 2) AS free FROM google_ps WHERE Type = 'Free' GROUP BY Category
    ),
    paid_rating AS (
        SELECT Category, ROUND(AVG(Rating), 2) AS paid FROM google_ps WHERE Type = 'Paid' GROUP BY Category
    )
    SELECT *, IF(t2.paid > t1.free, "Develop paid apps", "Develop free apps") AS decision
    FROM free_rating t1
    NATURAL JOIN paid_rating t2;
    ```
    - **Explanation**: This decision-making tool compares the average ratings of free and paid apps within each category to suggest the best development approach.
- **Logging Price Changes with Triggers**
    - **Purpose**: Record any changes to app prices due to data manipulation or hacking.
    - **Action**: Create a trigger that logs price changes into a price_changelog table.
    ```sql
    CREATE TRIGGER price_change_log AFTER UPDATE ON play
    FOR EACH ROW
    BEGIN
        INSERT INTO price_changelog(app, old_price, new_price, operation_type, operation_date)
        VALUES (NEW.App, OLD.Price, NEW.Price, 'UPDATE', CURRENT_TIMESTAMP());
    END;
    ```
    - **Explanation**: The trigger captures the old and new prices whenever an update is made, ensuring a log of any changes for auditing purposes.
- **Restoring App Prices after Data Breach**
    - **Purpose**: After recording changes in app prices, this query restores the original prices from the price_changelog.
    - **Action**: Use an UPDATE JOIN query to replace the updated price with the old price from the changelog.
    ```sql
    UPDATE play AS a
    JOIN price_changelog AS b ON a.App = b.app
    SET a.Price = b.old_price;
    ```
    - **Explanation**: The UPDATE JOIN query compares the app records in both tables and restores the original price from the changelog.
- **Calculating Pearson Correlation Between Ratings and Reviews**
    - **Purpose**: Investigate the correlation between app ratings and the number of reviews.
    - **Action**: Use the Pearson correlation formula to find the correlation coefficient.
    ```sql
    WITH Calc AS (
        SELECT Rating, Reviews, ROUND((Rating - @x), 2) AS rat, ROUND((Reviews - @y), 2) AS rev FROM google_ps
    )
    SELECT ROUND(SUM(rat * rev) / SQRT(SUM(rat * rat) * SUM(rev * rev)), 2) AS Cor FROM Calc;
    ```
    - **Explanation**: This query calculates how strongly the number of reviews is correlated with app ratings, providing insights into customer engagement and app quality.
- **Splitting the Genres Column**
    - **Purpose**: Clean up the Genres column to split it into two separate columns where multiple genres exist.
    - **Action**: Use SUBSTRING_INDEX to split the genres based on delimiters like & and ;.
    ```sql
    UPDATE google_ps SET Genres_1 = SUBSTRING_INDEX(Genres, '&', 1), Genres_2 = SUBSTRING_INDEX(Genres, '&', -1);
    UPDATE google_ps SET Genres_1 = CASE WHEN Genres LIKE '%;%' THEN SUBSTRING_INDEX(Genres, ';', 1) ELSE Genres END;
    UPDATE google_ps SET Genres_2 = CASE WHEN Genres LIKE '%;%' THEN SUBSTRING_INDEX(Genres, ';', -1) ELSE NULL END;
    ```
    - **Explanation**: By splitting the Genres column into two, we can perform more granular analyses on multi-genre apps and handle the data more effectively.
- **Dynamic Tool for Underperforming Apps**
    - **Purpose**: Build a stored procedure that dynamically takes a category as input and returns apps that are underperforming compared to the category’s average rating.
    - **Action**: Use a stored procedure to compare each app's rating with the category's average rating.
    ```sql
    DELIMITER // 
    CREATE PROCEDURE check_cat(IN cat VARCHAR(255))
    BEGIN 
        SET @average = (SELECT average FROM (SELECT Category, AVG(Rating) AS average FROM google_ps GROUP BY Category) m WHERE Category = cat);
        SELECT * FROM google_ps WHERE Category = cat AND Rating < @average;
    END // 
    DELIMITER;
    ```
    - **Explanation**: This procedure provides a real-time tool for managers to investigate underperforming apps in any specified category.
