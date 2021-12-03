
--Cleaning The Dataset

-- creating a temp table from the total_taxi_trips table for cleaning
CREATE TABLE temp_total_taxi_trips AS
(SELECT *
FROM  public.total_taxi_trips)

-- removing trips that were sent via ‘store and forward’
DELETE FROM public.temp_total_taxi_trips
WHERE store_and_fwd_flag <> 'N'




-- removing trips that were not street hailed, paid by card or cash with a standard rate
CREATE  TABLE public.temp1_total_taxi_trips AS  -- creates a new table from the temp 1 to store filtered table
(SELECT * FROM public.temp_total_taxi_trips
WHERE trip_type = 1  -- selects only street-hailed trips
AND (payment_type = 1 OR payment_type = 2)  -- only selects trips paid by card or cash
AND "RatecodeID" = 1) -- only selects trips with a standard rate

--  dropping temp table
DROP TABLE public.temp_total_taxi_trips


-- deleting dates before 2017 or after 2020
DELETE FROM public.temp1_total_taxi_trips
WHERE EXTRACT(YEAR FROM lpep_pickup_datetime) < 2017
OR EXTRACT(YEAR FROM lpep_pickup_datetime) > 2020 

DELETE FROM public.temp1_total_taxi_trips
WHERE EXTRACT(YEAR FROM lpep_dropoff_datetime) < 2017
OR EXTRACT(YEAR FROM lpep_dropoff_datetime) > 2020 

-- removes trips with drop of or pickup  in an unknown zone;
DELETE FROM public.temp1_total_taxi_trips
WHERE  "PULocationID"  > 263 
	OR "DOLocationID"  > 263

-- Changing passenger count from 0 to 1
UPDATE public.temp1_total_taxi_trips
SET passenger_count = 1
WHERE passenger_count = 0;
 
-- Verifying if change was implemented successfully
SELECT passenger_count
FROM public.temp1_total_taxi_trips
ORDER BY passenger_count ASC
LIMIT 100;





-- Swapping date/time where pickup time is after drop off time
UPDATE public.temp1_total_taxi_trips
   	SET lpep_pickup_datetime = lpep_dropoff_datetime,
   	       lpep_dropoff_datetime = lpep_pickup_datetime
 WHERE lpep_pickup_datetime > lpep_dropoff_datetime;

-- Verifying if change was implemented successfully it should read 0
SELECT count(*)
FROM public.temp1_total_taxi_trips
 WHERE lpep_pickup_datetime > lpep_dropoff_datetime ;

-- removing trips lasting more than a day
DELETE FROM public.temp1_total_taxi_trips
WHERE (lpep_dropoff_datetime - lpep_pickup_datetime) > '24:00:00';

--removing trips with both distance and fare amount of 0
DELETE FROM public.temp1_total_taxi_trips
WHERE trip_distance = 0 AND fare_amount = 0;

-- converting to positive records where fare, taxes, and surcharges are all negative
UPDATE public.temp1_total_taxi_trips
   	SET fare_amount = abs(fare_amount),
		mta_tax = abs(mta_tax),
		improvement_surcharge = abs(improvement_surcharge)
WHERE 
	fare_amount < 0 
	AND  mta_tax < 0 
	AND improvement_surcharge < 0;

-- Calculating distance for trips with fare amount but have a trip distance of 0	
UPDATE public.temp1_total_taxi_trips
SET trip_distance = (fare_amount - 2.5) / 2.5
WHERE fare_amount > 0 AND trip_distance = 0;

-- Verifying if change was implemented successfully 
SELECT count(*)
FROM public.temp1_total_taxi_trips
WHERE fare_amount > 0 AND  trip_distance = 0;


