#!/bin/bash


list_dbs() {
  echo "Listing all databases..."
  psql -c "\l"
}

# Prompt user for listing databases
read -p "Do you want to list all databases? (y/n): " LIST_DB

if [[ $LIST_DB == "y" ]]; then
  list_dbs
fi

# Prompt user for database name
read -p "Enter the database name: " DB_NAME

# Prompt user for SQL file path
read -e -p "Enter the path to the SQL file: " SQL_FILE

# Prompt user for confirmation
read -p "Are you sure you want to reset the database $DB_NAME using $SQL_FILE? (y/n): " CONFIRM

if [[ $CONFIRM != "y" ]]; then
  echo "Operation cancelled."
  exit 0
fi

drop_database() {
  echo "Dropping database $DB_NAME..."
  psql -c "DROP DATABASE IF EXISTS $DB_NAME;"
}

create_database() {
  echo "Create database $DB_NAME..."
  psql -c "CREATE DATABASE $DB_NAME;"
}

restore_database() {
  echo "Restoring database $DB_NAME from $SQL_FILE..."
  psql -d $DB_NAME -f $SQL_FILE
}

drop_database
create_database
restore_database

echo "Database $DB_NAME has been reset and restored from $SQL_FILE."
