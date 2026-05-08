create database czechDB;
use czechDB;
CREATE TABLE client (client_id INT, birth_number INT, district_id INT);

LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/client.csv'
INTO TABLE client 
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;