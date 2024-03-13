--Работа с базой данных "Аэропорты"
--Ознакомиться с описанием БД можно по ссылке https://edu.postgrespro.ru/bookings.pdf
--Какие самолеты имеют более 50 посадочных мест?

select  aircraft_code , count (seat_no)
from seats s
group by aircraft_code
having count (seat_no) >50


--В каких аэропортах есть рейсы, в рамках которых можно добраться бизнес - классом дешевле, чем эконом - классом?
with cte as
    (select flight_id, amount
    from ticket_flights tf
    where fare_conditions = 'Business'),
cte2 as
    (select flight_id, amount
    from ticket_flights tf
    where fare_conditions = 'Economy')
select  f.departure_airport, f.arrival_airport ,  cte2.*, cte.*
from cte2
join cte on cte2.flight_id =cte.flight_id
join flights f on f.flight_id =cte2.flight_id
where cte.amount<cte2.amount

ы
--Есть ли самолеты, не имеющие бизнес - класса?

select *
from
	(select aircraft_code, array_agg(fare_conditions::text) agg_fare
    from seats
    group by aircraft_code)t
where agg_fare<@ array ['Economy', 'Comfort']



--Найдите количество занятых мест для каждого рейса, процентное отношение количества занятых мест к общему количеству мест в самолете, добавьте накопительный итог вывезенных пассажиров по каждому аэропорту на каждый день.

select com.flight_id, com.b as "пассажиры", com.b*100/com.c as "процент занятых", com.departure_airport, com.actual_departure::date,
sum (com.b) over (partition by com.departure_airport, com.actual_departure::date order by com.actual_departure::date) as "сумма"
from (
	select occ.*, f.actual_departure::date, s.aircraft_code ,count (s.seat_no) c , f.departure_airport
	from
		(select flight_id ,count (boarding_no ) b
		from boarding_passes bp
		group by flight_id) occ
    join flights f on f.flight_id = occ.flight_id
	join seats s on s.aircraft_code =f.aircraft_code
	group by s.aircraft_code, occ.flight_id,f.actual_departure::date , occ.b, f.departure_airport) com

--Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов.
--Выведите в результат названия аэропортов и процентное отношение.

select ff.route as "Маршрут", round((ff.com/sum(ff.com) over())*100,2) as "Процент"
from (
	select concat(f.departure_airport,' ',f.arrival_airport) route, count(f.flight_id) com
	from flights f
	group by route) ff




--Выведите количество пассажиров по каждому коду сотового оператора, если учесть, что код оператора - это три символа после +7

select count (pc.passenger_id) , substring(pc.phone,3,3) as code
from(
	select passenger_id, contact_data->>'phone' as phone
	from tickets t ) pc
group by code

--Между какими городами не существует перелетов?

select a.city , a2.city
from airports a, airports a2
where a.city !=a2.city
except
select fv.departure_city, fv.arrival_city
from flights_v fv


--Классифицируйте финансовые обороты (сумма стоимости билетов) по маршрутам:
--До 50 млн - low
--От 50 млн включительно до 150 млн - middle
--От 150 млн включительно - high
--Выведите в результат количество маршрутов в каждом классе.

select count (dd.route) as "Количество маршрутов", класс
from
(select   concat(f.departure_airport,' ',f.arrival_airport) route,
sum (tf.amount)  as сумма,
case  when sum (tf.amount) <50000000 then 'low'
 	  when sum (tf.amount) >=50000000 and sum (tf.amount) < 150000000 then 'middle'
	  else 'high'
 	  end as класс
from flights f
join ticket_flights tf on tf.flight_id =f.flight_id
group by route, tf.amount
order by sum (tf.amount) ) dd
group by класс


--Выведите пары городов между которыми расстояние более 5000 км
--d = arccos {sin(latitude_a)·sin(latitude_b) + cos(latitude_a)·cos(latitude_b)·cos(longitude_a - longitude_b)}, где latitude_a и latitude_b — широты, longitude_a, longitude_b — долготы данных пунктов, d — расстояние между пунктами измеряется в радианах длиной дуги большого круга земного шара.
--Расстояние между пунктами, измеряемое в километрах, определяется по формуле:
--L = d·R, где R = 6371 км — средний радиус земного шара.

with cte1 as
	(select city  as city1 ,longitude , latitude
	from airports a  ),
cte2 as
 	(select city as city2  , longitude,latitude
 	from airports a2 ),
 cte3 as
 	(select *, (acos((sin(radians(cte1.latitude)))*sin(radians(cte2.latitude)) + cos(radians(cte1.latitude))*cos(radians(cte2.latitude))*cos(radians(cte1.longitude - cte2.longitude))))*6371 as dist
 	from cte1, cte2
 	where cte1.city1!=cte2.city2)
 select cte3.city1, cte3.city2, cte3.dist
 from cte3
 where cte3.dist>5000
