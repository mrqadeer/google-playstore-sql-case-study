# Mobile App Market Analysis

## Overview
This project performs a detailed analysis of mobile app data stored in a MySQL database. The analysis answers a variety of business and data-related questions through SQL queries. A Python script is used to connect to the database and populate the data from a CSV file into MySQL tables.

## Features
- **SQL Queries**: Analyze mobile app market categories based on ratings, revenue, and pricing.
- **Dynamic Tool**: A stored procedure to fetch underperforming apps by category.
- **Data Integrity**: Logging price changes for better data security.
- **Pearson Correlation**: Find the correlation between app ratings and reviews.
- **Database Triggers**: Record price changes in a changelog table.
- **Data Cleaning**: Split genres into two columns for better analysis.

## Installation

```bash
git clone https://github.com/mrqadeer/google-playstore-sql-case-study.git
```
Then run

```bash
cd google-playstore-sql-case-study
pip install -r requirements.txt
```

## Usage
Download Google Play Store data from Kaggle 
[Goolge Play Store Dataset](https://drive.google.com/file/d/1ESRpOWgtrrc4FJ_3CTjCh9jowbosEwhl/view?usp=sharing) and copy it to project `data` folder.


Then run the following commands in the terminal:

```bash
python main.py
```
### Run SQL Queries
After setting up the database, run the SQL queries present in the db/analysis.sql file to perform the data analysis.

Use MySQL Workbench or any MySQL client to execute the queries.
The queries will answer various business and data-related questions, log price changes, clean up the genre column, and more.

### References
For more detail please check [analysis](docs/analysis.md) file.

License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

### Let's Get in Touch
Feel free to reach out to me on any of the following social media platforms:

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/qadeer-ahmad-3499a4205/)
[![Facebook](https://img.shields.io/badge/Facebook-1877F2?style=for-the-badge&logo=facebook&logoColor=white)](https://web.facebook.com/mrqadeerofficial/)

