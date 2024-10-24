-- Active: 1722176549371@@127.0.0.1@3307@case_study_02
SELECT
    *
FROM
    google_ps;

CREATE TABLE google_ps_bkp AS
SELECT
    *
FROM
    google_ps;

ALTER TABLE
    google_ps DROP COLUMN `Unnamed: 0`;

ALTER TABLE
    google_ps
ADD
    COLUMN `Size_in_mbs` INTEGER
AFTER
    `Size`;

UPDATE
    google_ps
SET
    `Size_in_mbs` = CASE
        WHEN `Size` = 'Varies with device' THEN -1
        ELSE CAST(REPLACE(`Size`, 'M', '') AS DECIMAL(10, 2))
    END DELIMITER $ $ CREATE PROCEDURE drop_column_if_exists(
        IN table_name VARCHAR(64),
        IN column_name VARCHAR(64)
    ) BEGIN -- DECLARE column_exists INT;
    -- SET column_exists = (SELECT COUNT(1) FROM information_schema.columns WHERE table_name = table_name AND column_name = column_name);
    -- If the column exists, drop it
SET
    @sql = CONCAT(
        'ALTER TABLE ',
        table_name,
        ' DROP COLUMN ',
        column_name
    );

PREPARE stmt
FROM
    @sql;

EXECUTE stmt;

DEALLOCATE PREPARE stmt;

END $ $ DELIMITER;

CALL drop_column_if_exists('google_ps', 'Size');

DROP PROCEDURE drop_column_if_exists;

UPDATE
    google_ps
SET
    `Installs` =CASE
        WHEN `Installs` = 'Free' THEN 0
        ELSE CAST(
            REPLACE(REPLACE(`Installs`, '+', ''), ',', '') AS DOUBLE
        )
    END;

ALTER TABLE
    google_ps
MODIFY
    COLUMN Installs BIGINT;

DELIMITER $$ 
CREATE PROCEDURE show_all(IN offset INT, IN limit_count INT) BEGIN
SELECT
    *
FROM
    google_ps
LIMIT
    offset,
    limit_count;

END $$ DELIMITER;

DROP PROCEDURE show_all;

CALL show_all(1, 100);

SELECT
    *
FROM
    google_ps;

SELECT
    DISTINCT `Type`
FROM
    google_ps;

SELECT
    COUNT(*)
FROM
    google_ps
WHERE
    `Type` IS NULL;

SELECT
    COLUMN_NAME
FROM
    information_schema.COLUMNS
WHERE
    TABLE_NAME = 'google_ps';

DELIMITER $ $ CREATE PROCEDURE show_null_col_count() BEGIN
SELECT
    COLUMN_NAME,
    COUNT(*) AS null_count
FROM
    information_schema.COLUMNS
WHERE
    TABLE_NAME = 'google_ps'
    AND IS_NULLABLE = 'YES'
GROUP BY
    COLUMN_NAME;

END $ $ DELIMITER;

CALL show_null_col_count();

DROP PROCEDURE show_null_col_count;

DELIMITER $$ 
CREATE PROCEDURE show_null_col_count() BEGIN
SELECT
    COLUMN_NAME,
    SUM(
        CASE
            WHEN COLUMN_NAME IS NULL THEN 1
            ELSE 0
        END
    ) AS null_count
FROM
    (
        SELECT
            COLUMN_NAME
        FROM
            information_schema.COLUMNS
        WHERE
            TABLE_NAME = 'google_ps'
    ) AS cols
    JOIN google_ps gp ON TRUE
GROUP BY
    COLUMN_NAME;

END $$ DELIMITER;

CALL show_null_col_count();

DELETE FROM
    google_ps
WHERE
    `Type` IS NULL;

DELETE FROM
    google_ps
WHERE
    `App` IS NULL;

SELECT
    COUNT(*)
FROM
    google_ps;

CALL show_all(1, 9367);

SELECT
    *
FROM
    google_ps;

ALTER TABLE
    google_ps RENAME COLUMN `Last Updated` TO `Last_Updated`;

ALTER TABLE
    google_ps RENAME COLUMN `Content Rating` TO `Content_Rating`;

ALTER TABLE
    google_ps RENAME COLUMN `Content Rating` TO `Content_Rating`;

ALTER TABLE
    google_ps RENAME COLUMN `Current Ver` TO `Content_Ver`;

ALTER TABLE
    google_ps RENAME COLUMN `Android Ver` TO `Android_Ver`;

SELECT
    *
FROM
    google_ps;

SELECT
    `Last Updated`
FROM
    google_ps;

SELECT
    COLUMN_NAME,
    CONCAT(
        SUBSTRING_INDEX(COLUMN_NAME, ' ', 1),
        '_',
        SUBSTRING_INDEX(COLUMN_NAME, ' ', -1)
    )
FROM
    information_schema.COLUMNS
WHERE
    TABLE_NAME = 'google_ps'
    AND `COLUMN_NAME` LIKE '% %';

SELECT
    *
FROM
    google_ps;

-- Date
UPDATE
    google_ps
SET
    Last_Updated =CASE
        WHEN Last_Updated REGEXP '^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2}$' THEN STR_TO_DATE(Last_Updated, '%d-%b-%y')
        ELSE NULL
    END;

SELECT
    `Last_Updated`
FROM
    google_ps
WHERE
    `Last_Updated` IS NULL;

SELECT
    *
FROM
    google_ps;

-- Show only numberic values in `Android_Ver` 
UPDATE
    google_ps
SET
    `Android_Ver` =(
        SELECT
            CASE
                WHEN Android_Ver LIKE '%Varies%' THEN -1
                ELSE SUBSTRING_INDEX(Android_Ver, ' ', 1)
            END
    );

UPDATE
    google_ps
SET
    `Content_Ver` =(
        SELECT
            CASE
                WHEN Content_Ver LIKE '%Varies%' THEN -1
                ELSE SUBSTRING_INDEX(Android_Ver, ' ', 1)
            END
    );

-- Fixing price column to remove $sign
UPDATE
    google_ps
SET
    Price = CAST(REPLACE(Price, '$', '') AS DECIMAL(10, 2));

SELECT
    *
FROM
    google_ps;
