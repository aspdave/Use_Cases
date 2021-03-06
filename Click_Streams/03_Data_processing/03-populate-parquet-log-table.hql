ADD JAR /usr/lib/hive/lib/hive-contrib.jar;

SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.dynamic.partition=true;

set parquet.compression=GZIP;

-- Important to set memory parameters like this  mapreduce.map.java.opts = -Xmx4G; mapreduce.reduce.java.opts = -Xmx4G
INSERT INTO TABLE apache_log_parquet
PARTITION(year, month, day)
SELECT ip,ts, url, referrer, user_agent, unix_ts,
COALESCE(SUM(CASE WHEN new='Y' THEN 1 END) OVER (PARTITION BY ip ORDER BY unix_ts), 0) session_id
, YEAR(FROM_UNIXTIME(unix_ts)) year, MONTH(FROM_UNIXTIME(unix_ts)) month, DAY(FROM_UNIXTIME(unix_ts)) day
FROM
(SELECT ip, ts, url, referrer, user_agent, unix_ts, CASE WHEN unix_ts-LAG(unix_ts, 1) OVER (PARTITION BY ip ORDER BY unix_ts) > 30*60 THEN 'Y' ELSE 'N' END new
FROM (
        SELECT ip, ts, url, referrer, user_agent, UNIX_TIMESTAMP(ts,'dd/MMM/yyyy:HH:mm:ss') AS unix_ts
        FROM raw_log
        WHERE ip NOT IN ('209.85.238.11')
) t) s; 
 
-- SELECT * FROM apache_log_parquet LIMIT 5;