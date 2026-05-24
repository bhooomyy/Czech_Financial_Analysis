-- Find accounts with more than 5 transactions on a single day (velocity check)
SELECT
	account_id,
    COUNT(DISTINCT trans_id) AS num_trans,
    DATE(date) AS per_day
	FROM trans
    GROUP BY account_id,per_day
    HAVING num_trans>5;