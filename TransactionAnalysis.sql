-- -- Total transaction volume (count + sum of amount) by transaction type (PRIJEM=credit, VYDAJ=debit)
WITH total_transactions AS(
	SELECT 
    COUNT(DISTINCT trans_id) AS tot_trans
    FROM trans)
SELECT 
	type,
	COUNT(DISTINCT trans_id) AS total_transactions,
    ROUND(SUM(amount),2) as total_amount,
    CONCAT(ROUND(COUNT(trans_id)*100.0/total_transactions.tot_trans,2),'%')
	FROM trans,total_transactions
	GROUP BY type
    ORDER BY total_amount DESC;

-- What are all distinct operation types? How many transactions per operation?
SELECT 
	operation,
    COUNT(trans_id) AS total_trans_by_operation
    FROM trans
    GROUP BY operation
    ORDER BY total_trans_by_operation;

-- What is the average, min, max transaction amount overall and per type?
SELECT
	'OVERALL' AS type,
    ROUND(AVG(amount),2) AS avg_amt,
	MIN(amount) AS min_amt,
	MAX(amount) AS max_amt
	FROM trans
UNION ALL
SELECT
	type,
	ROUND(AVG(amount),2) AS avg_amt_by_type,
    MIN(amount) AS min_amt_by_type,
    MAX(amount) AS max_amt_by_type
	FROM trans
    GROUP BY type;

-- Count transactions per year and per month (extract from YYMMDD date)
SELECT
	YEAR(date),
	COUNT(distinct trans_id) as total_trans_per_year
	FROM trans
    GROUP BY YEAR(date);
SELECT
	MONTH(date),
	COUNT(distinct trans_id) as total_trans_per_month
	FROM trans
    GROUP BY MONTH(date);

-- Which accounts have the highest total outflow (VYDAJ)? Show top 20 with account district
SELECT
	t.account_id,
    a.district_id,
    d.district_name,
    COUNT(DISTINCT t.trans_id) AS total_trans,
    ROUND(SUM(t.amount),2) AS total_outflow
	FROM trans t JOIN account a ON t.account_id=a.account_id
    JOIN district d ON d.district_id=a.district_id
    WHERE t.type='VYDAJ'
    GROUP BY t.account_id,a.district_id,d.district_name
    ORDER BY total_outflow DESC
    LIMIT 20;

-- Calculate net cash flow (inflow - outflow) per account per year. Which accounts went negative in any year?
WITH temp AS(
	SELECT
	account_id,
    YEAR(date) as per_year,
    ROUND(SUM(CASE WHEN type='PRIJEM' THEN amount ELSE -amount END),2) AS net_cash_flow
	FROM trans
    GROUP BY account_id,YEAR(date))
SELECT 
    account_id,
    per_year,
    net_cash_flow
    FROM temp
    WHERE net_cash_flow<0
    ORDER BY net_cash_flow ASC;

-- Find accounts where the number of debit transactions exceeds credit transactions in any single year
SELECT 
	account_id,
    YEAR(date),
    SUM(CASE WHEN type='PRIJEM' THEN 1 ELSE 0 END) AS credit_trans,
    SUM(CASE WHEN type='VYDAJ' THEN 1 ELSE 0 END) AS debit_trans
	FROM trans
    GROUP BY account_id,YEAR(date)
    HAVING debit_trans>credit_trans;

-- What is the distribution of transaction amounts? Use CASE to bucket: <500, 500-2000, 2000-10000, 10000+
SELECT 
    SUM(amount < 6000) AS below_avg,
    SUM(amount BETWEEN 6000 AND 30000) AS Middle,
    SUM(amount BETWEEN 30000 AND 75000) AS Higher,
    SUM(amount > 75000) AS Premium
FROM trans;

-- Find the most common k_symbol (transaction purpose) for outgoing transactions per district
SELECT * FROM (SELECT
	COALESCE(NULLIF(t.k_symbol, ''), 'No Symbol') as k_symbol,
    a.district_id,
    COUNT(*) as k_symbol_cnt,
    RANK() OVER(PARTITION BY a.district_id ORDER BY COUNT(*) DESC) AS rnk
	FROM trans t JOIN account a ON t.account_id=a.account_id
    WHERE t.type='VYDAJ'
    GROUP BY t.k_symbol,a.district_id)ranked 
    WHERE rnk=1
    ORDER BY district_id;

-- Identify accounts that received wire transfers from external banks (bank column NOT NULL). How many unique source banks?
SELECT
	account_id,
    COUNT(trans_id) as wire_transfer_cnt,
    ROUND(SUM(amount),2) as total_received,
    COUNT(DISTINCT bank) as unique_src_bank,
    GROUP_CONCAT(DISTINCT bank ORDER BY bank) AS src_bank
    FROM trans
    WHERE bank!='' AND type='PRIJEM'
    GROUP BY account_id
    ORDER BY wire_transfer_cnt DESC;

-- Using LAG(), calculate day-over-day balance change for each account. Flag days where balance dropped more than 20%
WITH flag_check  AS(SELECT 
		account_id,
        date,
        balance,
        LAG(balance) OVER(PARTITION BY account_id ORDER BY date) AS prev_balance 
        FROM trans)
        SELECT * 
        FROM flag_check 
        WHERE prev_balance IS NOT NULL AND balance < prev_balance*0.8;

-- Build a running total of balance per account ordered by date using SUM() OVER (PARTITION BY account_id ORDER BY date)
SELECT account_id,
	date,
    balance,
    SUM(balance) OVER(PARTITION BY account_id ORDER BY date) AS running_total
    FROM trans;

-- Using LEAD(), find accounts where a large debit (>10000) is immediately followed by another large debit within 7 days
WITH subQuery AS(SELECT 
	account_id,
    date,
    balance,
    LEAD(balance) OVER(PARTITION BY account_id ORDER BY date) AS next_amt,
    LEAD(date) OVER(PARTITION BY account_id ORDER BY date) AS next_date
    FROM trans
    WHERE type='VYDAJ' AND balance>10000)
SELECT 
    account_id,
    date,
    next_date,
    balance,
    next_amt,
    DATEDIFF(next_date,date) AS days_between 
    FROM subQuery 
    WHERE DATEDIFF(next_date,date)<=7;

-- Calculate month-over-month transaction volume growth rate per account using LAG(monthly_sum) in a CTE
WITH subQuery AS(
	SELECT 
    account_id,
    YEAR(date) AS year,
	MONTH(date) AS month,
    SUM(amount) as monthly_sum
    FROM trans
    GROUP BY account_id,YEAR(date),MONTH(date))
SELECT
	account_id,
    year,
	month,
    monthly_sum,
	LAG(monthly_sum) OVER(PARTITION BY account_id ORDER BY year,month) AS prev_month_amt,
    ROUND(monthly_sum-LAG(monthly_sum) OVER(PARTITION BY account_id ORDER BY year,month),2) AS growth_rate
	FROM subQuery;

-- Find the rolling 3-month average transaction amount per account using AVG() OVER with ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
SELECT
	account_id,
    YEAR(date) AS year,
    MONTH(date) AS month,
    amount,
    ROUND(AVG(amount) OVER(PARTITION BY account_id ORDER BY YEAR(date),MONTH(date) ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS rolling_3month_avg
	FROM trans
    GROUP BY YEAR(date),MONTH(date),account_id;