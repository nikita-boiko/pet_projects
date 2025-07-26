--создаем таблицу для датасета
create table ct_fraction (
	organization  varchar(100),
	post  varchar(100),
	rate float, 
	required int,
	all_coupons int,
	online int, 
	repeated int,
	fraction float,
	general_mount int,
	no_schedule int);
	
	copy ct_fraction (organization, post, rate, 
	required, all_coupons, online,repeated, fraction, 
	general_mount, no_schedule )
	from 'C:\SQL\ctfraction.csv'
	delimiter ';'
	csv header;
	
select distinct organization from ct_fraction cf 
where fraction <= 0.5

select distinct post, avg(rate) as avg_rate from ct_fraction cf 
group by post

select distinct post, sum(no_schedule) as sum_no_schedule from ct_fraction cf 
group by cf.post 
order by sum_no_schedule desc 
limit 5

select organization, post, fraction from ct_fraction cf 
where post = 'врач-терапевт участковый' and fraction > 0.9

select organization, (sum(required) - sum(all_coupons)) as difference_coupons from ct_fraction cf 
group by cf.organization 
order by difference_coupons 

select organization, post, online, repeated, (online - repeated) as exceeding_coupons from ct_fraction cf
group by cf.organization, post, online, repeated
having (online / (case when repeated = 0 then 1 else cf.repeated end)) > 5 
order by exceeding_coupons desc

select organization, post, (cf.general_mount / (case when cf.required  = 0 then 1 else cf.required  end)) as efficiency_coefficient  from ct_fraction cf
order by efficiency_coefficient desc
limit 10

select organization, avg(fraction) as avg_fraction,
case 
	when avg(fraction) >= 0.8 then 'высокий'
	when avg(fraction) < 0.8 and avg(fraction) >= 0.6 then 'средний' 
	else 'низкий'
end
from ct_fraction cf 
group by organization 
order by avg_fraction 
 
select organization, max(fraction) as max_frction, min(fraction) as min_frction from ct_fraction cf 
group by cf.organization 
having max(fraction) > 1.2 and min(fraction) < 0.5

select organization, (sum(cf.fraction * rate) / sum(case when rate=0.0 then 1.0 else rate end)) as weighted_avg_fraction from ct_fraction cf
group by organization
order by weighted_avg_fraction desc


















