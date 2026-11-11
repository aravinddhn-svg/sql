
CREATE OR REPLACE TEMPORARY VIEW txns AS
SELECT * FROM VALUES
  ('T01','C1',TIMESTAMP '2026-11-01 09:00:00','SUCCESS', 100.0),
  ('T02','C1',TIMESTAMP '2026-11-01 09:10:00','SUCCESS',  50.0),
  ('T03','C1',TIMESTAMP '2026-11-01 09:20:00','FAILED',   70.0),
  ('T04','C1',TIMESTAMP '2026-11-01 09:25:00','SUCCESS',  20.0),
  ('T05','C1',TIMESTAMP '2026-11-01 10:05:00','SUCCESS',  30.0),
  ('T06','C1',TIMESTAMP '2026-11-02 08:00:00','SUCCESS',  15.0),
  ('T07','C1',TIMESTAMP '2026-11-03 08:30:00','SUCCESS',  25.0),
  ('T08','C1',TIMESTAMP '2026-11-03 08:50:00','FAILED',   40.0),
  ('T09','C1',TIMESTAMP '2026-11-05 12:00:00','SUCCESS',  60.0),
  ('T10','C1',TIMESTAMP '2026-11-06 12:15:00','SUCCESS',  10.0),
  ('T11','C2',TIMESTAMP '2026-11-01 08:00:00','SUCCESS',   5.0),
  ('T12','C2',TIMESTAMP '2026-11-01 08:15:00','SUCCESS',   5.0),
  ('T13','C2',TIMESTAMP '2026-11-01 09:00:00','SUCCESS',   5.0),
  ('T14','C2',TIMESTAMP '2026-11-01 10:30:00','SUCCESS',   5.0),
  ('T15','C2',TIMESTAMP '2026-11-01 11:00:00','SUCCESS',   5.0),
  ('T16','C2',TIMESTAMP '2026-11-01 12:00:00','SUCCESS',   5.0),
  ('T17','C2',TIMESTAMP '2026-11-01 13:00:00','SUCCESS',   5.0),
  ('T18','C2',TIMESTAMP '2026-11-01 14:00:00','SUCCESS',   5.0),
  ('T19','C2',TIMESTAMP '2026-11-01 15:00:00','SUCCESS',   5.0),
  ('T20','C2',TIMESTAMP '2026-11-01 16:00:00','SUCCESS',   5.0),
  ('T21','C2',TIMESTAMP '2026-11-01 18:00:00','SUCCESS',   5.0),
  ('T22','C2',TIMESTAMP '2026-11-01 20:00:00','SUCCESS',   5.0),
  ('T23','C3',TIMESTAMP '2026-11-01 10:00:00','SUCCESS',  12.0),
  ('T24','C3',TIMESTAMP '2026-11-01 10:05:00','SUCCESS',  12.0),
  ('T25','C3',TIMESTAMP '2026-11-01 10:10:00','SUCCESS',  12.0),
  ('T26','C3',TIMESTAMP '2026-11-01 10:15:00','FAILED',   12.0),
  ('T27','C3',TIMESTAMP '2026-11-01 10:20:00','SUCCESS',  12.0),
  ('T28','C3',TIMESTAMP '2026-11-01 10:25:00','SUCCESS',  12.0)
AS t(txn_id, customer_id, txn_ts, status, amount);


----- select txn_ts,from_unixtime(unix_timestamp(txn_ts)) from txns;

q1 --- Consectivie trans -

  select customer_id,gap,count(*) cnt
from
(
select 
customer_id,txn_ts,date_sub(txn_ts,row_number() over(partition by customer_id order by txn_ts)) as gap
from
(select  distinct customer_id, to_date(txn_ts) as txn_ts from txns)

)
group by customer_id,gap

q2:
  
  

Q3: consecutive transaction and no of trans it should not cross over 30 min

select customer_id,min(txn_ts) as st_ts, max(txn_ts) as end_ts,session_id,count(*) as session_trans
from
(

select  customer_id,txn_ts,SUM(sess1) OVER (PARTITION BY customer_id ORDER BY txn_ts) AS session_id from
(
select customer_id,txn_ts,case when gap is null or gap > 30 then 1 else 0 end sess1 from
(
select *, lag(txn_ts) over(partition by customer_id order by txn_ts ) as rnk,
timestampdiff(minute,lag(txn_ts) over(partition by customer_id order by txn_ts ),txn_ts) as gap
from txns
)
)
)
group by customer_id,session_id
order by customer_id,session_trans  desc

O/p:
cus  st                 end_ts    session_id  seesion_tran
C1	2026-11-01 09:00:00	2026-11-01 09:25:00	1	4
C1	2026-11-03 08:30:00	2026-11-03 08:50:00	4	2
C1	2026-11-01 10:05:00	2026-11-01 10:05:00	2	1
C1	2026-11-02 08:00:00	2026-11-02 08:00:00	3	1
C1	2026-11-05 12:00:00	2026-11-05 12:00:00	5	1
C1	2026-11-06 12:15:00	2026-11-06 12:15:00	6	1
C2	2026-11-01 08:00:00	2026-11-01 08:15:00	1	2
C2	2026-11-01 10:30:00	2026-11-01 11:00:00	3	2
C2	2026-11-01 09:00:00	2026-11-01 09:00:00	2	1
C2	2026-11-01 12:00:00	2026-11-01 12:00:00	4	1
C2	2026-11-01 13:00:00	2026-11-01 13:00:00	5	1
C2	2026-11-01 14:00:00	2026-11-01 14:00:00	6	1
C2	2026-11-01 15:00:00	2026-11-01 15:00:00	7	1
C2	2026-11-01 16:00:00	2026-11-01 16:00:00	8	1
C2	2026-11-01 18:00:00	2026-11-01 18:00:00	9	1
C2	2026-11-01 20:00:00	2026-11-01 20:00:00	10	1
C3	2026-11-01 10:00:00	2026-11-01 10:25:00	1	6


q3: -- 3 consecutive sucess tarsn


select customer_id, min(txn_ts) as st_dt, max(txn_ts) as end_ts,count(txn_id)
from
(
select txn_id,customer_id,txn_ts, status,sum(rnk) over (partition by customer_id order by txn_ts ) cons_trans
from
(
select txn_id,customer_id,status, txn_ts,case when status <> 'SUCCESS' then 1 else 0 end rnk
from txns
)
)
where status ='SUCCESS'
group by customer_id,cons_trans



q4:

