import os
import pathlib
import pandas as pd
import pymysql as mq
from getpass import getpass
from sqlalchemy import create_engine
from mysql.connector import Error
from typing import Optional
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    handlers=[  # Log to a file
                        logging.StreamHandler()  # Also log to console
                    ])


class MySQLDatabase:
    """
    A class to handle MySQL database operations, including connection and query execution.
    """

    def __init__(self, host_name: str, user_name: str, user_password: str, port: int, db_name: str) -> None:
        """
        Initializes the MySQLDatabase instance with the given database credentials and creates a connection.

        Args:
            host_name (str): The MySQL server hostname.
            user_name (str): The username for authentication.
            user_password (str): The password for authentication.
            port (int): The port number for the database connection.
            db_name (str): The name of the database to connect to.
        """
        self.host_name = host_name
        self.user_name = user_name
        self.user_password = user_password
        self.port = port
        self.db_name = db_name
        self.connection = self.create_connection()
        self.engine = self.create_engine()

    def create_connection(self) -> Optional[mq.Connection]:
        """
        Creates and returns a connection to the MySQL database.

        Returns:
            Optional[mq.Connection]: The connection object if successful, None if failed.
        """
        try:
            connection = mq.connect(host=self.host_name, user=self.user_name, password=self.user_password, port=self.port)
            logging.info(f"Connected to MySQL database server at {self.host_name}:{self.port}.")
            return connection

        except Error as e:
            logging.error(f"Error occurred while connecting to the database: {e}")
            return None

    def create_engine(self) -> create_engine:
        """
        Creates and returns a SQLAlchemy engine for executing SQL queries.

        Returns:
            create_engine: The SQLAlchemy engine for connecting to MySQL.
        """
        engine_url = f'mysql+pymysql://{self.user_name}:{self.user_password}@{self.host_name}:{self.port}/{self.db_name}'
        # logging.debug(f"Creating SQLAlchemy engine with URL: {engine_url}")
        return create_engine(engine_url)

    def execute_query(self, query: str) -> None:
        """
        Executes a SQL query on the connected MySQL database.

        Args:
            query (str): The SQL query to be executed.
        """
        if not self.connection:
            logging.error("No active connection to the database.")
            return

        cursor = self.connection.cursor()
        try:
            cursor.execute(query)
            self.connection.commit()
            logging.info(f"Query executed successfully: {query}")
        except Error as e:
            logging.error(f"Error occurred during query execution: {e}")

    def create_table_from_csv(self, csv_file_path: str, table_name: str, is_comma_sep: str) -> None:
        """
        Reads data from a CSV file and creates a corresponding table in the MySQL database.

        Args:
            csv_file_path (str): The path to the CSV file.
            table_name (str): The name of the table to be created.
            is_comma_sep (str): Specifies whether the CSV is comma-separated ('y'/'n').
        """
        try:
            delimiter = ',' if is_comma_sep.lower() in ['y', '1', 'yes'] else ';'
            df = pd.read_csv(csv_file_path, delimiter=delimiter)

            # Logging: Preview the DataFrame for debugging
            logging.debug(f"Preview of data for table '{table_name}':\n{df.head()}")

            # Create or replace the table with the DataFrame content
            df.to_sql(table_name, con=self.engine, if_exists='replace', index=False)
            logging.info(f"Table '{table_name}' created from CSV successfully.")
        except pd.errors.ParserError:
            logging.error("Error: CSV file could not be read. Please check the delimiter and file format.")
        except Exception as e:
            logging.error(f"An error occurred: {e}")


class CSVToMySQLImporter:
    """
    A class to handle the import of CSV files into MySQL database tables.
    """

    def __init__(self, db_instance: MySQLDatabase, csv_directory: str, is_comma_sep: str) -> None:
        """
        Initializes the CSVToMySQLImporter instance with a database instance and directory path for CSV files.

        Args:
            db_instance (MySQLDatabase): The MySQLDatabase instance to interact with.
            csv_directory (str): The directory path where CSV files are located.
            is_comma_sep (str): Specifies if the CSV files are comma-separated ('y'/'n').
        """
        self.db_instance = db_instance
        self.csv_directory = pathlib.Path(csv_directory)
        self.is_comma_sep = is_comma_sep

    def import_csv_files(self) -> None:
        """
        Imports all CSV files in the specified directory into the MySQL database.
        """
        if not self.csv_directory.exists():
            logging.error(f"Directory '{self.csv_directory}' does not exist.")
            return

        for filename in os.listdir(self.csv_directory):
            if filename.endswith('.csv'):
                table_name = filename.split('.')[0].lower()  # Table name derived from filename
                csv_file_path = self.csv_directory / filename
                logging.info(f"Importing '{filename}' as table '{table_name}'...")

                # Create table from the CSV file
                self.db_instance.create_table_from_csv(csv_file_path, table_name, self.is_comma_sep)
            else:
                logging.warning(f"Skipping non-CSV file: {filename}")


if __name__ == "__main__":
    # Collecting user input for MySQL credentials and CSV import options
    host = input("Enter host name (e.g., localhost): ").lower()
    username = input("Enter username: ")
    password = getpass("Enter password: ")
    port = int(input("Enter port (e.g., 3306): "))
    db_name = input("Enter database name: ").lower()

    # Initialize MySQLDatabase instance
    db_instance = MySQLDatabase(host, username, password, port, db_name)

    # Ensure database exists or create it
    create_db_query = f"CREATE DATABASE IF NOT EXISTS {db_instance.db_name}"
    db_instance.execute_query(create_db_query)

    # CSV import options
    csv_directory = 'data'

    # Initialize CSV importer and import CSV files into the MySQL database
    importer = CSVToMySQLImporter(db_instance, csv_directory, is_comma_sep='y')
    importer.import_csv_files()
