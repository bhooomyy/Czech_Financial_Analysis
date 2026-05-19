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