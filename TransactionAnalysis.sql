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