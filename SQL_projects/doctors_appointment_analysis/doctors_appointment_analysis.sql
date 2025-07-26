-- Создание таблицы для хранения данных о записи на прием
create table ct_fraction (
    organization  varchar(100),    -- Название медицинской организации
    post  varchar(100),           -- Должность врача
    rate float,                   -- Суммарная ставка  
    required int,                 -- Требуемое количество талонов
    all_coupons int,              -- Всего талонов в расписании
    online int,                   -- Талоны, доступные для онлайн-записи (КТ)
    repeated int,                 -- Талоны, доступные только очно (НКТ)
    fraction float,               -- Доля КТ от требуемого количества
    general_mount int,            -- Общее количество чего-то талонов
    no_schedule int               -- Количество врачей без расписания
);

-- Загрузка данных из CSV-файла в созданную таблицу
copy ct_fraction (organization, post, rate, 
    required, all_coupons, online, repeated, fraction, 
    general_mount, no_schedule )
from 'C:\SQL\ctfraction.csv'
delimiter ';'
csv header;

-- Запрос 1: Выбор медицинских организаций с низкой долей онлайн-записи
-- Где доля конкурентных талонов (КТ) меньше 50%
select distinct organization from ct_fraction cf 
where fraction < 0.5;

-- Запрос 2: Расчет средней ставки по каждой должности
select distinct post, avg(rate) as avg_rate from ct_fraction cf 
group by post;

-- Запрос 3: Топ-5 должностей с наибольшим количеством врачей без расписания
select distinct post, sum(no_schedule) as sum_no_schedule from ct_fraction cf 
group by cf.post 
order by sum_no_schedule desc 
limit 5;

-- Запрос 4: Организации, где для терапевтов доля КТ превышает 90%
select organization, post, fraction from ct_fraction cf 
where post = 'врач-терапевт участковый' and fraction > 0.9;

-- Запрос 5: Разница между требуемым и фактическим количеством талонов по организациям
-- Показывает дефицит/профицит талонов в каждой организации
select organization, (sum(required) - sum(all_coupons)) as difference_coupons from ct_fraction cf 
group by cf.organization 
order by difference_coupons;

-- Запрос 6: Выявление дисбаланса - где онлайн-талонов больше чем очных в 5+ раз
-- Для каждой организации и должности, где соотношение КТ/НКТ > 5
select organization, post, online, repeated, (online - repeated) as exceeding_coupons from ct_fraction cf
group by cf.organization, post, online, repeated
having (online / (case when repeated = 0 then 1 else cf.repeated end)) > 5 
order by exceeding_coupons desc;

-- Запрос 7: Топ-10 медицинских организаций по коэффициенту эффективности
-- Эффективность = общее количество талонов / требуемое количество
select organization, post, (cf.general_mount / (case when cf.required  = 0 then 1 else cf.required  end)) as efficiency_coefficient  from ct_fraction cf
order by efficiency_coefficient desc
limit 10;

-- Запрос 8: Категоризация организаций по средней доле КТ
-- Высокий (>=80%), средний (60-80%), низкий (<60%)
select organization, avg(fraction) as avg_fraction,
case 
    when avg(fraction) >= 0.8 then 'высокий'
    when avg(fraction) < 0.8 and avg(fraction) >= 0.6 then 'средний' 
    else 'низкий'
end as fraction_category
from ct_fraction cf 
group by organization 
order by avg_fraction;

-- Запрос 9: Организации с наибольшим дисбалансом распределения талонов
-- Где есть должности с долей КТ >120% и одновременно <50%
select organization, max(fraction) as max_fraction, min(fraction) as min_fraction from ct_fraction cf 
group by cf.organization 
having max(fraction) > 1.2 and min(fraction) < 0.5;

-- Запрос 10: Рейтинг организаций по средневзвешенной доле КТ
-- С учетом ставки (rate) как весового коэффициента
select organization, (sum(cf.fraction * rate) / sum(case when rate=0.0 then 1.0 else rate end)) as weighted_avg_fraction from ct_fraction cf
group by organization
order by weighted_avg_fraction desc;