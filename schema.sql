create database czechDB;
use czechDB;
CREATE TABLE client (
    client_id INT, 
    birth_number INT, 
    district_id INT);
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/client.csv'
INTO TABLE client 
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;
ALTER TABLE client ADD COLUMN gender VARCHAR(1);
ALTER TABLE client ADD dateofbirth DATE;

SET SQL_SAFE_UPDATES=0;
UPDATE client
	SET gender = CASE WHEN (birth_number/100)%100 > 50 THEN 'F' ELSE 'M' END;
UPDATE client
SET dateofbirth = CONCAT(
    IF(FLOOR(birth_number/10000) >= 0, '19', '20'),
    LPAD(FLOOR(birth_number/10000), 2, '0'), '-',
    LPAD(CASE 
        WHEN (birth_number/100)%100 > 50 
        THEN (birth_number/100)%100 - 50 
        ELSE (birth_number/100)%100 
    END, 2, '0'), '-',
    LPAD(birth_number%100, 2, '0')
);
SET SQL_SAFE_UPDATES=1;

CREATE TABLE card (
    card_id INT, 
    disp_id INT, 
    type VARCHAR(25),
    issued varchar(50));
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/card.csv'
INTO TABLE card 
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

CREATE TABLE account (
    account_id INT,
    district_id INT,
    frequency VARCHAR(30),
    date VARCHAR(7));
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/account.csv'
INTO TABLE account 
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;
ALTER TABLE account MODIFY `date` DATE;

CREATE TABLE disp (
    disp_id INT,
    client_id INT,
    account_id INT,
    `type` VARCHAR(12));
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/disp.csv'
INTO TABLE disp
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

CREATE TABLE loan (
    loan_id INT,
    account_id INT, 
    date VARCHAR(7),
    amount INT, 
    duration INT, 
    payments FLOAT(8,2), 
    `status` VARCHAR(1));
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/loan.csv'
INTO TABLE loan
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;
ALTER TABLE loan MODIFY `date` DATE;

CREATE TABLE `order`(
    order_id INT, 
    account_id INT, 
    bank_to VARCHAR(2),
    account_to INT, 
    amount FLOAT(7,2),
    k_symbol VARCHAR(8));
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/order.csv'
INTO TABLE `order`
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

CREATE TABLE trans(
    trans_id INT,
    account_id INT,
    `date` DATE,
    `type` VARCHAR(10),
    operation VARCHAR(100),
    amount FLOAT,
    balance FLOAT,
    k_symbol VARCHAR(20),
    bank VARCHAR(5),
    account VARCHAR(20));
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/trans.csv'
INTO TABLE `trans`
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;
ALTER TABLE trans MODIFY `date` DATE;

CREATE TABLE district(
    district_id INT,
    district_name VARCHAR(50),
    region VARCHAR(50),
    `population` INT,
    num_municipalities_lt_499 INT,
    num_municipalities_500_1999 INT,
    num_municipalities_2000_9999 INT,
    num_municipalities_gt_10000 INT,
    num_cities INT,
    ratio_urban_inhabitants FLOAT,
    avg_salary INT,
    unemployment_rate_95 FLOAT,
    unemployment_rate_96 FLOAT,
    num_entrepreneurs_per_1000 INT,
    num_crimes_95 INT,
    num_crimes_96 INT);
LOAD DATA INFILE '/Users/bhoomi/Downloads/BerkaCzechFinancialDataset/district.csv'
INTO TABLE distict
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

-- 2 columns of district_id 69 is set to '?' -> change it with NULL
SET SQL_SAFE_UPDATES =0;
SELECT * FROM district WHERE district_id = 69;
UPDATE district 
SET unemployment_rate_95 = NULL,
    num_crimes_95 = NULL
WHERE district_id = 69;
SET SQL_SAFE_UPDATES=1;



