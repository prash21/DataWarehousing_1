-- PRASHANT MURALI   STUDENT ID: 29625564    TEST 1 --

-- Viewing the given data
select * from MClub.Category;
select * from MClub.Club;
select * from MClub.Enrollment;
select * from MClub.Event;
select * from MClub.Student;
select * from MClub.Registration;

-- COMMANDS FOR CREATING THE DATA WAREHOUSE

-- Campus dimension
DROP TABLE campus_dim CASCADE CONSTRAINTS PURGE;
Create table campus_dim as
SELECT distinct Campus
FROM MClub.Event;

-- Course Dimension
DROP TABLE course_dim CASCADE CONSTRAINTS PURGE;
Create table course_dim as
SELECT distinct CourseLevel
FROM MClub.Student;

-- Category Dimension
DROP TABLE category_dim CASCADE CONSTRAINTS PURGE;
Create table category_dim as
SELECT distinct CategoryID, Category
FROM MClub.Category;

-- Semester Dimension
DROP TABLE sem_dim CASCADE CONSTRAINTS PURGE;
Create table sem_dim(
semid VARCHAR(10),
sem_desc VARCHAR(20),
start_date DATE,
end_date DATE );

-- Populate sem_dim
INSERT INTO sem_dim
VALUES ('S1', 'Semester One', TO_DATE('01-MAR', 'DD-MON'),
 TO_DATE('30-JUN', 'DD-MON'));
 
INSERT INTO sem_dim
VALUES ('S2', 'Semester Two', TO_DATE('01-AUG', 'DD-MON'),
 TO_DATE('30-NOV', 'DD-MON'));
 
INSERT INTO sem_dim
VALUES ('S3', 'Winter Semester', TO_DATE('01-JUL', 'DD-MON'),
 TO_DATE('31-JUL', 'DD-MON'));
 
INSERT INTO sem_dim
VALUES ('S4', 'Summer Semester', TO_DATE('01-DEC', 'DD-MON'),
 TO_DATE('28-FEB', 'DD-MON'));
 
 
-- Event Size Dimension
DROP TABLE event_size_dim CASCADE CONSTRAINTS PURGE;
Create table event_size_dim(
size_id VARCHAR(10),
size_description VARCHAR(20));

-- Populate event_size_dim
INSERT INTO event_size_dim
VALUES ('S', 'Small');

INSERT INTO event_size_dim
VALUES ('M', 'Medium');

INSERT INTO event_size_dim
VALUES ('L', 'Large');


-- Create a temp fact table because we cannot directly store the semid and size_id from the
-- initial table.

-- Create Temp Fact
DROP TABLE temp_fact CASCADE CONSTRAINTS PURGE;
Create table temp_fact AS
SELECT r.RegistrationID, to_char(to_date(RegistrationDate, 'YY-MON-DD'),'MMDD') as RegistrationDate,
r.RegistrationFee, e.Campus, e.MaxNumberInvolved
FROM MClub.Registration r, MClub.Event e
WHERE r.EventID = e.EventID;

-- Add column to store semid
ALTER TABLE temp_fact
ADD (semid VARCHAR2(10));

-- Update it with provided values
UPDATE temp_fact
SET semid = 'S1'
WHERE RegistrationDate >= '0301'
AND RegistrationDate <= '0630';

UPDATE temp_fact
SET semid = 'S2'
WHERE RegistrationDate >= '0801'
AND RegistrationDate <= '1130';

UPDATE temp_fact
SET semid = 'S3'
WHERE RegistrationDate >= '0701'
AND RegistrationDate <= '0731';

UPDATE temp_fact
SET semid = 'S4'
WHERE RegistrationDate >= '1201'
AND RegistrationDate <= '0228';

-- Add column to store size id
ALTER TABLE temp_fact
ADD (size_id VARCHAR2(10));

-- Update it with provided values
UPDATE temp_fact
SET size_id = 'S'
WHERE maxnumberinvolved <= 20;

UPDATE temp_fact
SET size_id = 'M'
WHERE maxnumberinvolved >= 21
AND maxnumberinvolved <= 80;

UPDATE temp_fact
SET size_id = 'L'
WHERE maxnumberinvolved > 80;
 

-- Creating the final fact table
DROP TABLE club_fact CASCADE CONSTRAINTS PURGE;
CREATE TABLE club_fact AS
SELECT T.semid, T.size_id, T.campus, s.courselevel, c.categoryID, count(T.RegistrationID) AS number_of_students,
sum(T.RegistrationFee) AS fee_amount
FROM temp_fact T, MClub.Category c, MClub.Student s 
GROUP BY T.semid, T.size_id, T.campus, s.courselevel, c.categoryID;

-- END OF DATA WAREHOUSE CREATION COMMANDS



-- COMMANDS FOR ANSWERING QUERIES

-- Question a
SELECT s.sem_desc, e.size_description, sum(f.number_of_students) as Total_Registered_Students
from club_fact f, sem_dim s, event_size_dim e
WHERE f.semid = s.semid
AND f.size_id = e.size_id
Group by s.sem_desc, e.size_description;

-- Question b
SELECT c.campus, sum(f.Fee_amount) as Total_Event_Fees_Collected
from club_fact f, campus_dim c
WHERE f.campus = c.campus
Group by c.campus
ORDER BY Total_Event_Fees_Collected ASC;

-- Question c
SELECT ca.category, sum(f.number_of_students) as Total_Registered_Students
from club_fact f, category_dim ca, campus_dim c
WHERE f.categoryID = ca.categoryID
AND f.campus = c.campus
AND c.campus = 'Clayton'
Group by ca.category;

-- Question d
SELECT cd.courselevel, sum(f.fee_amount) as Total_Event_Fees_Collected
from club_fact f, course_dim cd, category_dim ca
WHERE f.courselevel = cd.courselevel
AND f.categoryID = ca.categoryID
AND ca.category = 'Special Interest Club'
Group by cd.courselevel;

-- END OF CODE


