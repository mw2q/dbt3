-- @(#)11.sql	2.1.8.1
-- TPC-H/TPC-R Pricing Summary Report Query (Q11)
-- Functional Query Definition
-- Approved February 1998
:b
:x
:o
select
	ps_partkey,
	sum(ps_supplycost * ps_availqty) as value
from
	partsupp,
	supplier,
	nation
where
	ps_suppkey = s_suppkey
	and s_nationkey = n_nationkey
	and n_name = ':1'
group by
	ps_partkey having
		sum(ps_supplycost * ps_availqty) > (
			select
				sum(ps_supplycost * ps_availqty) * :2
			from
				partsupp,
				supplier,
				nation
			where
				ps_suppkey = s_suppkey
				and s_nationkey = n_nationkey
				and n_name = ':1'
		)
order by
	value desc;
:e
