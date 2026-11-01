WITH trs AS (
  SELECT * FROM UNNEST([
    STRUCT('u1' AS `user`, 't1' AS trs_id, 's' AS sts),
    ('u1','t2','s'), ('u1','t3','f'),
    ('u3','t4','s'), ('u3','t5','s'),('u3','t6','s') ,('u3','t7','f') ,
    ('u4','t8','s'), ('u4','t9','f')
  ])
)
select user ,
(
SELECT trim(SUBSTR(trs_id, 2)) as trans_id
, *,row_number() over( partition by user  order by trs_id asc) rnk
, cast(trim(SUBSTR(trs_id, 2)) as int)  - row_number() over( partition by user  order by trs_id asc) as row_group1
, sum ( case when sts <> 's' then 1 else 0 end) over( partition by user  order by trs_id asc) as row_group
from trs
)
group by user ,row_group
having count(*)>3

---- to the consicutive or consecutive succesfull transactions then use the group pattern


						
trans_id	user	trs_id	sts	rnk	row_group1	row_group
1	u1	t1	s	1	0	0
2	u1	t2	s	2	0	0
3	u1	t3	f	3	0	1
4	u3	t4	s	1	3	0
5	u3	t5	s	2	3	0
6	u3	t6	s	3	3	0
7	u3	t7	f	4	3	1
8	u4	t8	s	1	7	0
9	u4	t9	f	2	7	1
