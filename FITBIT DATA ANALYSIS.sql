USE BELLADATA;

--GRAPHS IN R-PROJECT ARE CREATED AS TABLES IN SQL

--PROCESSING DATA: 

--1.1 FOR REMOVING DUPLICATES FROM TABLES BASED ON ID,ACTIVITY DATE

--DAILYACTIVITY TABLE

WITH CTE AS (
  SELECT *, 
     row_number() OVER(PARTITION BY Id, ActivityDate ORDER BY ActivityDate desc) AS [rn]
  FROM dailyActivity
)
DELETE FROM CTE WHERE [rn] > 1;

--WEIGHTLOGINFO TABLE

WITH CTE AS (
  SELECT *, 
     row_number() OVER(PARTITION BY Id, Date ORDER BY Date desc) AS [rn]
  FROM weightLogInfo
)
DELETE FROM CTE WHERE [rn] > 1;

--HEARTRATE_SECONDS TABLE

WITH CTE AS (
  SELECT *, 
     row_number() OVER(PARTITION BY Id, Date ORDER BY Date desc) AS [rn]
  FROM heartrate_seconds
)
DELETE FROM CTE WHERE [rn] > 1;


--1.2 VIEWING THE DATA

SELECT * FROM dailyActivity;
SELECT * FROM weightLogInfo;
SELECT * FROM heartrate_seconds;
SELECT * FROM sleepDay;

--1.3 REMOVING SOME VARIABLES

ALTER TABLE dailyActivity
DROP COLUMN loggedActivitiesDistance,TrackerDistance;

ALTER TABLE weightLogInfo
DROP COLUMN Fat, BMI, IsManualReport, LogId;

ALTER TABLE sleepDay
DROP COLUMN TotalSleepRecords;

--1.4 ADDING NEW VARIABLES AND CREATING A VIEW

CREATE VIEW 
daily_activity AS
(SELECT *,
DATENAME(MONTH,ActivityDate) AS "Month Name",
DATENAME(WEEKDAY,ActivityDate) AS "Week Day"
FROM dailyActivity);


CREATE VIEW 
daily_sleep AS
(SELECT *,
DATENAME(MONTH, sleepDay) AS "Month Name",
DATENAME(WEEKDAY, sleepDay) AS "Week Day"
FROM sleepDay)


CREATE VIEW 
weight_info AS
(SELECT *,
DATENAME(MONTH, Date) AS "Month Name",
DATENAME(WEEKDAY, Date) AS "Week Day"
FROM weightLogInfo)


--1.5 STATISTICAL SUMMARY

SELECT 'MEAN' AS 'Summary',
    ROUND(AVG(TotalSteps),0) AS 'TotalSteps',
    ROUND(AVG(TotalDistance),0) AS 'TotalDistance',
	ROUND(AVG(Calories),0) AS 'Calories',
	ROUND(AVG(VeryActiveDistance),0) AS 'VeryActiveDistance',
	ROUND(AVG(ModeratelyActiveDistance),0) AS 'ModeratelyActiveDistance',
	ROUND(AVG(LightActiveDistance),0) AS 'LightActiveDistance',
	MIN(ActivityDate) AS 'ActivityDate'
FROM daily_activity
UNION
SELECT 'MIN',
    MIN(TotalSteps),
    MIN(TotalDistance),
	MIN(Calories),
	MIN(VeryActiveDistance),
	MIN(ModeratelyActiveDistance),
	MIN(LightActiveDistance),
	MIN(ActivityDate)
FROM daily_activity
UNION
SELECT 'MAX',
    ROUND(MAX(TotalSteps),0),
    ROUND(MAX(TotalDistance),0),
	MAX(Calories),
	ROUND(MAX(VeryActiveDistance),0),
	ROUND(MAX(ModeratelyActiveDistance),0),
	ROUND(MAX(LightActiveDistance),0),
	MAX(ActivityDate)
FROM daily_activity

---2. ANALYZE

--2.1 AVERAGE CALORIES BURNT PER MONTH

SELECT [Month Name], ROUND(AVG(Calories),0) AS 'AVG_CAL'
FROM daily_activity
GROUP BY [Month Name]

--2.2 AVERAGE STEPS PER MONTH

SELECT [Month Name], ROUND(AVG(TotalSteps),0) AS 'AVG_STEPS'
FROM daily_activity
GROUP BY [Month Name]
ORDER BY AVG_STEPS


--2.3 AVERAGE STEPS PER WEEK

SELECT [Week Day], ROUND(AVG(TotalSteps),0) AS 'AVG_STEPS'
FROM daily_activity
GROUP BY [Week Day]
ORDER BY AVG_STEPS DESC

--2.4 AVERAGE CALORIES PER WEEK

SELECT [Week Day], ROUND(AVG(Calories),0) AS 'AVG_CAL'
FROM daily_activity
GROUP BY [Week Day]
ORDER BY AVG_CAL DESC

--2.5 AVERAGE CALORIES PER DAY

SELECT ActivityDate, ROUND(AVG(Calories),0) AS 'AVG_CAL'
FROM daily_activity
GROUP BY ActivityDate
ORDER BY AVG_CAL DESC

--2.6 ACTIVE LEVEL BY DISTANCE

SELECT 'Percentage' AS 'Active_Level_Distance',
CONCAT(ROUND((SUM(LightActiveDistance)/SUM(LightActiveDistance + ModeratelyActiveDistance + VeryActiveDistance))*100,0),'%') AS 'LightActiveDistance',
CONCAT(ROUND((SUM(ModeratelyActiveDistance)/SUM(LightActiveDistance + ModeratelyActiveDistance + VeryActiveDistance))*100,0), '%') AS 'ModeratelyActiveDistance',
CONCAT(ROUND((SUM(VeryActiveDistance)/SUM(LightActiveDistance + ModeratelyActiveDistance + VeryActiveDistance))*100,0),'%') AS 'VeryActiveDistance'
FROM daily_activity

--2.7 ACTIVE LEVEL BY MINUTES

SELECT 'Percentage' AS 'Active_Level_Minutes',
CONCAT(ROUND((SUM(LightlyActiveMinutes)/SUM(LightlyActiveMinutes + VeryActiveMinutes + FairlyActiveMinutes))*100,0),'%') AS 'LightlyActiveMinutes',
CONCAT(ROUND((SUM(FairlyActiveMinutes)/SUM(LightlyActiveMinutes + VeryActiveMinutes + FairlyActiveMinutes))*100,0), '%') AS 'FairlyActiveMinutes',
CONCAT(ROUND((SUM(VeryActiveMinutes)/SUM(LightlyActiveMinutes + VeryActiveMinutes + FairlyActiveMinutes))*100,0),'%') AS 'VeryActiveMinutes'
FROM daily_activity

--2.8 TOTAL CALORIES BURNT VS. STEPS

SELECT Id,ROUND(AVG(Calories),0) AS 'AVG_CAL' ,ROUND(AVG(TotalSteps),0) AS 'AVG_STEPS'
FROM daily_activity
GROUP BY Id
ORDER BY AVG_STEPS DESC

--MERGING DATA FROM DAILY_ACTIVITY TABLE AND WEIGHT_LOG TABLE

CREATE VIEW
dist_weight AS
(SELECT A.* ,B.WeightKg FROM daily_activity A
INNER JOIN weight_info B
ON A.Id = B.Id AND A.ActivityDate = B.Date)


--2.9 AVERAGE DISTANCE VS. AVERAGE WEIGHT IN KGS

SELECT Id, ROUND(AVG(TotalDistance),0) AS AVG_DIST,ROUND(AVG(WeightKg),0) AS AVG_WEIGHT
FROM dist_weight
GROUP BY Id
ORDER BY AVG_WEIGHT DESC

--MERGING DATA FROM DAILY_ACTIVITY TABLE AND SLEEPDAY TABLE

CREATE VIEW
dist_sleep AS
(SELECT A.* ,B.TotalMinutesAsleep,B.TotalTimeInBed FROM daily_activity A
INNER JOIN daily_sleep B
ON A.Id = B.Id AND A.ActivityDate = B.SleepDay)


--2.10 AVERAGE DISTANCE VS. AVERAGE SLEEP PER USER

SELECT Id, ROUND(AVG(TotalDistance),0) AS AVG_DIST,ROUND(AVG(TotalMinutesAsleep/60),0) AS AVG_SLEEP_HRS
FROM dist_sleep
GROUP BY Id
ORDER BY AVG_SLEEP_HRS DESC

--AVERAGE HEARTRATE_DAILY

CREATE VIEW
hearrate_daily AS
(SELECT Id,Date,AVG(Value) AS heart_rate,
DATENAME(MONTH, Date) AS "Month Name",
DATENAME(WEEKDAY, Date) AS "Week Day"
 FROM heartrate_seconds
 GROUP BY Date,Id)

--2.11 AVERAGE HEART_RATE PER MONTH

 SELECT [Month Name],ROUND(AVG(heart_rate),0) AS avg_heart_rate
 FROM hearrate_daily
 GROUP BY [Month Name]

--2.12 AVERAGE HEART_RATE PER WEEK

 SELECT [Week Day],ROUND(AVG(heart_rate),0) AS avg_heart_rate
 FROM hearrate_daily
 GROUP BY [Week Day]

--2.13 AVERAGE HEART_RATE PER USER

 SELECT Id,ROUND(AVG(heart_rate),0) AS avg_heart_rate
 FROM hearrate_daily
 GROUP BY Id
 ORDER BY avg_heart_rate DESC

--2.14 SLEEP QUALITY BY STEPS

CREATE VIEW active_level AS
(SELECT TotalMinutesAsleep, TotalSteps,
	(CASE
	WHEN TotalMinutesAsleep<=300 then'less than 5h'
	WHEN TotalMinutesAsleep<=480 then'less than 8h'
	ELSE 'more than 9h'
	END) AS 'Sleeping_hrs',
	(CASE
	WHEN TotalSteps<=5000 then'less than 5000 steps'
	WHEN TotalSteps<=10000 then'5001 to 10000 steps'
	WHEN TotalSteps<=15000 then'10001 to 15000 steps'
	ELSE 'more than 15000 steps'
	END) AS 'steps_taken'
FROM dist_sleep)

--2.15 SLEEP QUALITY BY STEPS TAKEN

SELECT ONE.steps_taken,ONE.[less than 5h],TWO.[less than 8h],THREE.[more than 9h]
FROM (SELECT steps_taken,COUNT(Sleeping_hrs) AS 'less than 5h'
FROM active_level
WHERE Sleeping_hrs = 'less than 5h'
GROUP BY Sleeping_hrs,steps_taken) AS ONE 
JOIN (SELECT steps_taken,COUNT(Sleeping_hrs) AS 'less than 8h'
FROM active_level
WHERE Sleeping_hrs = 'less than 8h'
GROUP BY Sleeping_hrs,steps_taken) AS TWO
ON ONE.steps_taken = TWO.steps_taken
JOIN (SELECT steps_taken,COUNT(Sleeping_hrs) AS 'more than 9h'
FROM active_level
WHERE Sleeping_hrs = 'more than 9h'
GROUP BY Sleeping_hrs,steps_taken) AS THREE
ON TWO.steps_taken = THREE.steps_taken

--2.16 STRUGGLING TO SLEEP VS. STEPS TAKEN

SELECT Id, 
ROUND(AVG(TotalSteps),0) AS 'Avg_steps',
ROUND(AVG(TotalTimeInBed-TotalMinutesAsleep),0) AS 'Struggling_to_sleep(min)'
FROM dist_sleep
GROUP BY Id
ORDER BY 'Struggling_to_sleep(min)' DESC

--2.17 SLEEP PER USER

SELECT TotalMinutesAsleep,TotalSteps,
	(CASE
	WHEN TotalMinutesAsleep<=420 then'less than 7h'
	WHEN TotalMinutesAsleep<=540 then'less than 9h'
	ELSE 'more than 9h'
	END) AS 'Sleeping_hrs'
FROM dist_sleep
ORDER BY Sleeping_hrs
