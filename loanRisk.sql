-- Count loans by status. Decode: A=finished/OK, B=finished/default, C=running/OK, D=running/default
SELECT
	status,
    CASE WHEN status="A" THEN "finished/OK"
		 WHEN status="B" THEN "finished/default"
		 WHEN status="C" THEN "running/OK"
		 WHEN status='D' THEN "running/default"
		 END as decoded_status,
    COUNT(*) AS status_cnt
    FROM loan
    GROUP BY status
    ORDER BY status_cnt DESC;

-- What is the total loan amount, avg loan amount, and avg duration by status?
SELECT
	status,
	ROUND(SUM(amount),2) AS total_amt,
    ROUND(AVG(amount),2) AS avg_loan_amt,
    ROUND(AVG(duration),2) AS avg_duration
    FROM loan
    GROUP BY status
    ORDER BY avg_duration ASC;