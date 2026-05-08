create database czechDB;
use czechDB;
CREATE TABLE client (client_id INT, birth_number INT, district_id INT);

LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/client.csv'
INTO TABLE client 
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

CREATE TABLE card (card_id INT, disp_id INT, type VARCHAR(25),issued varchar(50));
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/card.csv'
INTO TABLE card 
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

CREATE TABLE account (account_id INT,district_id INT, frequency VARCHAR(30),date VARCHAR(7));
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/account.csv'
INTO TABLE account 
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;
