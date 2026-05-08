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

CREATE TABLE disp (disp_id INT,client_id INT,account_id INT,`type` VARCHAR(12));
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/disp.csv'
INTO TABLE disp
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

CREATE TABLE loan (loan_id INT,account_id INT, date VARCHAR(7),amount INT, duration INT, payments FLOAT(8,2), `status` VARCHAR(1));
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/loan.csv'
INTO TABLE loan
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS

CREATE TABLE `order`(order_id INT, account_id INT, bank_to VARCHAR(2),account_to INT, amount FLOAT(7,2),k_symbol VARCHAR(8));
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/order.csv'
INTO TABLE `order`
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

CREATE TABLE trans(trans_id INT,account_id INT,`date` DATE,`type` VARCHAR(10),operation VARCHAR(100),amount FLOAT,balance FLOAT,k_symbol VARCHAR(20),bank VARCHAR(5),account VARCHAR(20));
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/trans.csv'
INTO TABLE `trans`
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;
