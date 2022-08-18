-- For each athlete, select their first name, last name, and the information for how much younger (in days) they are from the oldest athlete. Name the last column days_difference. For the oldest athlete, the days_difference should be 0.

select first_name, last_name, birth_date - min(birth_date) over () as days_difference 
from athlete;

-- For each final race, display the round_id, race_number, race_date, wind, and the maximal wind points in the finals (as max_wind). Sort the rows by the wind in descending order, and by the ID of the race in ascending order.

select id, race_number, race_date, wind, max(wind) over() as max_wind
from round
order by wind desc, id;

-- For each race in the Rio de Janeiro Olympic Games, display the following columns:discipline_name – the name of the discipline.The round name.The race number.The wind level. The race date. days_since_start – the number of days between the race date and the date of the first race in this competition. Sort the rows by the last column, and the ID of the race.

SELECT discipline.name, round.round_name, race.race_number, race.wind, race.race_date,
race.race_date - min(race_date) over () as days_since_start
FROM competition
JOIN event
  ON competition.id = event.competition_id
JOIN discipline
  ON discipline.id = event.discipline_id
JOIN round
  ON event.id = round.event_id
JOIN race
  ON round.id = race.round_id
where competition.name = 'Rio de Janeiro Olympic Games'
order by days_since_start, race.id;

-- For each date in which there was a race, display the race_date, the average wind on this date rounded to three decimal points, and the difference between the average wind on this date and the average wind on the date before, also rounded to three decimal points. The columns should be named race_date, avg_wind, and avg_wind_delta.

select race_date, 
round(avg(wind), 3) as avg_wind,
round(avg(wind) - lag(avg(wind)) over (order by race_date), 3) as avg_wind_delta
from race
group by race_date;

-- For each woman who ran in the final round of the women's marathon in Rio, display: the place they achieved in the race. their first name. their last name. comparison_to_best – the difference between their time and the best time in this final. comparison_to_previous – the difference between their time and the result for the athlete who got the next better place. Sort the rows by the place column.

SELECT result.place, athlete.first_name, athlete.last_name, result - first_value(result)
over(order by result) as comparison_to_best,
result- lag(result) over(order by result) as comparison_to_previous
FROM competition
JOIN event
  ON competition.id = event.competition_id
JOIN discipline
  ON discipline.id = event.discipline_id
JOIN round
  ON event.id = round.event_id
JOIN race
  ON round.id = race.round_id
JOIN result
  ON result.race_id = race.id 
JOIN athlete
  ON athlete.id = result.athlete_id
where round.is_final is True
order by place;

-- For each competition and discipline, show the competition name (as competition_name), the number of rounds in the competition (as rounds_in_competition), the discipline name (as discipline_name), and the number of rounds in the given discipline in this competition (as rounds_in_discipline).

SELECT DISTINCT competition.name as competition_name,
count(round.id) over (partition by competition.id) as rounds_in_competition,
discipline.name as discipline_name,
count(round.id) over (partition by discipline.id, competition.id) as round_in_discipline
FROM round
JOIN event
  ON round.event_id = event.id
JOIN competition
  ON event.competition_id = competition.id
JOIN discipline
  ON event.discipline_id = discipline.id;
  
  -- For each result achieved in the 10,000 meter runs, show the ID of the race (race_id), the date of the race, the first name of each athlete who ran in this race, their last name, the result they achieved in this race, the best result in this race (as min_for_race), and the best result the athlete ever had (as min_for_athlete). Sort the rows by the ID of the race and the ID of the athlete.
  
  SELECT race_id, race_date, first_name, last_name,
result, min(result) over (partition by race_id) as min_for_race,
min(result) over (partition by athlete_id)
FROM result
JOIN race
  ON result.race_id = race.id
JOIN round
  ON race.round_id = round.id
JOIN athlete
  ON result.athlete_id = athlete.id
JOIN event
  ON round.event_id = event.id
JOIN discipline
  ON event.discipline_id = discipline.id
where distance = 10000
order by race_id, athlete_id;

-- For each race, show the round_id, the race_date, the average wind in this round (as average_wind), and the average wind across all races (as average_wind_overall). The last two columns should be rounded to two decimal points. Don't show the duplicated rows.

select round_id, race_date, round(avg(wind) over (partition by round_id), 2) as average_wind,
round(avg(wind) over (), 2) as average_wind_overall
from race;

-- For each result, show: discipline – the discipline name. the last name of the athlete. the first name of the athlete. the athlete's result. average_per_athlete – the average result for this athlete in this discipline. average_in_discipline – the average result in this discipline. better_than_average_per_athlete – a boolean value. TRUE if the result is better than the average result for this athlete in this discipline, and FALSE otherwise. better_than_average_in_discipline – a boolean value. TRUE if the result is better than the average result in this discipline, and FALSE otherwise.

select distinct discipline, last_name, first_name, result, 
avg(result) over (partition by athlete_id, discipline_id) as average_per_athlete,
avg(result) over (partition by discipline_id) as average_in_discipline,
result < avg(result) over (partition by athlete_id, discipline_id) as better_than_average_per_athlete,
result < avg(result) over(partition by discipline_id) as better_than_average_in_discipline
FROM athlete
JOIN result
  ON athlete.id = athlete_id
JOIN race
  ON race.id = race_id
JOIN round
  ON round.id = round_id
JOIN event
  ON event.id = round.event_id
JOIN discipline
  ON discipline.id = discipline_id;

-- For each country, find the average place achieved by the athletes from this country in a given discipline and competition. Display the following columns: competition_name – the competition name. discipline_name – the discipline name. the country name. The first names of the athletes running in this discipline in this competition. Their last names. Their places in the race. national_place – the average place in this competition, discipline, and country, rounded to a one decimal point.  

select competition.name as competition_name, discipline.name as discipline_name, country_name, first_name, last_name, place,
ROUND(avg(place) over(partition by competition.id, discipline.id, nationality.id), 1) as national_place
from athlete
JOIN nationality
  ON nationality.id = athlete.nationality_id
LEFT JOIN result
  ON athlete.id = result.athlete_id
LEFT JOIN race
  ON race.id = result.race_id
LEFT JOIN round
  ON round.id = race.round_id
LEFT JOIN event
  ON event.id = round.event_id
LEFT JOIN discipline
  ON discipline.id = event.discipline_id
LEFT JOIN competition
  ON competition.id = event.competition_id
where round.is_final is true;  

