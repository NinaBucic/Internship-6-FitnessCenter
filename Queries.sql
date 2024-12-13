-- First name, last name, gender, country name, and average salary in that country for each trainer.
SELECT 
    t.FirstName AS "First Name",
    t.LastName AS "Last Name",
    t.Gender AS "Gender",
    c.Name AS "Country Name",
    c.AverageSalary AS "Average Salary"
FROM Trainers t
JOIN FitnessCenters fc ON t.FitnessCenterID = fc.FitnessCenterID
JOIN Countries c ON fc.CountryID = c.CountryID;


-- Name and scheduled time of each sports activity along with the names of main trainers 
-- (in the format "Last Name, F." e.g., "Horvat, M.; Petrović, T.").
SELECT
    a.Name AS "Activity Name",
    CONCAT(s.SessionDate, ' ', s.SessionTime) AS "Scheduled Time",
    STRING_AGG(CONCAT(t.LastName, ', ', SUBSTRING(t.FirstName, 1, 1), '.'), '; ') AS "Main Trainers"
FROM Activities a
JOIN Schedule s ON a.ActivityID = s.ActivityID
JOIN TrainerActivities ta ON a.ActivityID = ta.ActivityID
JOIN Trainers t ON ta.TrainerID = t.TrainerID
WHERE ta.Role = 'MAIN'
GROUP BY a.Name, s.SessionDate, s.SessionTime;


-- Top 3 fitness centers with the highest number of activities in the schedule.
SELECT 
    fc.Name AS "Fitness Center",
    COUNT(s.ScheduleID) AS "Number of Scheduled Activities"
FROM FitnessCenters fc
JOIN Trainers t ON fc.FitnessCenterID = t.FitnessCenterID
JOIN TrainerActivities ta ON t.TrainerID = ta.TrainerID
JOIN Schedule s ON ta.ActivityID = s.ActivityID
GROUP BY fc.Name
ORDER BY COUNT(s.ScheduleID) DESC
LIMIT 3;


-- For each trainer, display how many activities they currently have; 
-- if no activities, display "AVAILABLE", if up to 3 activities, display "ACTIVE", 
-- and if more, display "FULLY OCCUPIED".
SELECT 
	t.TrainerID AS "ID",
    CONCAT(t.FirstName,' ',t.LastName) AS "Trainer",
    COUNT(ta.ActivityID) AS "Number of Activities",
    CASE
        WHEN COUNT(ta.ActivityID) = 0 THEN 'AVAILABLE'
        WHEN COUNT(ta.ActivityID) <= 3 THEN 'ACTIVE'
        ELSE 'FULLY OCCUPIED'
    END AS "Status"
FROM Trainers t
LEFT JOIN TrainerActivities ta ON t.TrainerID = ta.TrainerID
GROUP BY t.TrainerID, t.FirstName, t.LastName
ORDER BY t.LastName, t.FirstName;


-- List the names of all participants currently enrolled in any activity.
SELECT
	p.ParticipantID AS "ID",
    CONCAT(p.FirstName,' ',p.LastName) AS "Participant"
FROM Participants p
JOIN Enrollments e ON p.ParticipantID = e.ParticipantID
JOIN Schedule s ON e.ScheduleID = s.ScheduleID
WHERE s.SessionDate >= CURRENT_DATE
GROUP BY p.ParticipantID, p.FirstName, p.LastName;


-- List all trainers who have led at least one activity between 2019 and 2022.
SELECT DISTINCT t.TrainerID AS "ID",t.FirstName AS "First Name",t.LastName AS "Last Name"
FROM Trainers t
JOIN TrainerActivities ta ON t.TrainerID = ta.TrainerID
JOIN Schedule s ON ta.ActivityID = s.ActivityID
WHERE DATE_PART('YEAR',s.SessionDate) BETWEEN 2019 AND 2022
ORDER BY t.LastName, t.FirstName;


-- Calculate the average number of participations per activity type for each country
SELECT 
    c.Name AS "Country Name",
    a.Type AS "Activity Type",
    ROUND(AVG(s.CurrentParticipants),2) AS "Average Participants"
FROM Countries c
JOIN FitnessCenters fc ON c.CountryID = fc.CountryID
JOIN Trainers t ON fc.FitnessCenterID = t.FitnessCenterID
JOIN TrainerActivities ta ON t.TrainerID = ta.TrainerID
JOIN Activities a ON ta.ActivityID = a.ActivityID
JOIN Schedule s ON a.ActivityID = s.ActivityID
GROUP BY c.Name, a.Type
ORDER BY c.Name, a.Type;


-- Select top 10 countries with the highest number of participations in the 'INJURY REHABILITATION' activity type
SELECT 
    c.Name AS "Country Name",
    SUM(s.CurrentParticipants) AS "Total Participants"
FROM Countries c
JOIN FitnessCenters fc ON c.CountryID = fc.CountryID
JOIN Trainers t ON fc.FitnessCenterID = t.FitnessCenterID
JOIN TrainerActivities ta ON t.TrainerID = ta.TrainerID
JOIN Activities a ON ta.ActivityID = a.ActivityID
JOIN Schedule s ON a.ActivityID = s.ActivityID
WHERE a.Type = 'INJURY REHABILITATION'
GROUP BY c.Name
ORDER BY "Total Participants" DESC
LIMIT 10;


-- Get activity names and their current status ('AVAILABLE' or 'FULL')
SELECT 
    a.Name AS "Activity Name",
    s.SessionDate AS "Session Date",
    s.SessionTime AS "Session Time",
    CASE 
        WHEN s.CurrentParticipants < s.MaxParticipants THEN 'AVAILABLE' 
        ELSE 'FULL' 
    END AS "Activity Status"
FROM Schedule s
JOIN Activities a ON s.ActivityID = a.ActivityID
WHERE s.SessionDate >= CURRENT_DATE
ORDER BY s.SessionDate, s.SessionTime;


-- Top 10 highest-paid trainers based on their activity income
SELECT
	t.TrainerID AS "ID",
    t.FirstName AS "First Name",
	t.LastName AS "Last Name", 
    SUM(s.CurrentParticipants * a.PricePerSession) AS "Total Income"
FROM Trainers t
JOIN TrainerActivities ta ON t.TrainerID = ta.TrainerID
JOIN Activities a ON ta.ActivityID = a.ActivityID
JOIN Schedule s ON a.ActivityID = s.ActivityID
GROUP BY t.TrainerID, t.FirstName, t.LastName
ORDER BY "Total Income" DESC
LIMIT 10;




