/*
Считаем общее количество покупателей из таблицы customers
*/

select count(*) as customers_count
from customers;

/*
 Считаем 10 лучших продавцов по суммарной выручке
*/

select e.first_name || ' ' || coalesce(e.middle_initial || ' ', '') || e.last_name as seller,
	   -- учитываем случаи, когда middle_initial имеет значение NULL 
	   count(*) as operations,
	   floor(sum(p.price * s.quantity)) as income
	   -- отбрасываем дробную часть
from sales s
join products p using (product_id)
join employees e on s.sales_person_id = e.employee_id
group by seller
order by income desc
limit 10;

/*
Выводим информацию о продавцах, чья выручка за сделку меньше средней выручки за сделку по всем продавцам
*/

with average_incomes as (
    select e.first_name || ' ' || coalesce(e.middle_initial || ' ', '') || e.last_name as seller,
           -- учитываем случаи, когда middle_initial имеет значение NULL
		   coalesce(avg(p.price * s.quantity), 0) as average_income
		   -- учитываем случаи, когда продавец не совершил ни одной сделки
    from employees e
    left join sales s on s.sales_person_id = e.employee_id
    left join products p on s.product_id = p.product_id
    group by e.first_name, e.middle_initial, e.last_name
)
select seller,
       floor(average_income) as average_income
	   -- отбрасываем дробную часть
from average_incomes
where average_income < (select avg(average_income) from average_incomes)
order by average_income;

/*
Выводим информацию о выручке по дням недели.
*/

select 
    e.first_name || ' ' || coalesce(e.middle_initial || ' ', '') || e.last_name as seller,
    to_char(s.sale_date, 'FMday') as day_of_week,
    floor(sum(p.price * s.quantity)) as income
from employees e
join sales s on s.sales_person_id = e.employee_id
join products p on s.product_id = p.product_id
group by
    e.first_name, e.middle_initial, e.last_name,
    to_char(s.sale_date, 'FMday'),
    extract(isodow from s.sale_date)
order by 
    extract(isodow from s.sale_date),  -- monday = 1, sunday = 7
    seller;

/*
Выводим количество покупателей в разных
возрастных группах: 16-25, 26-40 и 40+.
*/

with customers_age as (
  select distinct on (customer_id) customer_id, age
  from customers
)
select
  case
    when age between 16 and 25 then '16-25'
    when age between 26 and 40 then '26-40'
    when age > 40 then '40+'
  end as age_category,
  count(*) as age_count
from customers_age
group by age_category
order by age_category;

/*
Выводим данные по количеству уникальных
покупателей и выручке, которую они принесли.
*/

select
  to_char(sale_date, 'YYYY-MM') as selling_month,
  count(distinct customer_id) as total_customers,
  sum(price * quantity) as income
from sales
join products using (product_id)
group by selling_month
order by selling_month;
