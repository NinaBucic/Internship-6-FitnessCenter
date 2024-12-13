CREATE TABLE Countries (
    CountryID SERIAL PRIMARY KEY,
    Name VARCHAR(100) UNIQUE NOT NULL,
    Population INTEGER NOT NULL CHECK (Population >= 0),
    AverageSalary DECIMAL(10,2) NOT NULL CHECK (AverageSalary >= 0)
);

CREATE TABLE FitnessCenters (
    FitnessCenterID SERIAL PRIMARY KEY,
    Name VARCHAR(100) UNIQUE NOT NULL,
    WorkingHours VARCHAR(50),
    CountryID INTEGER NOT NULL REFERENCES Countries(CountryID)
);

CREATE TABLE Trainers (
    TrainerID SERIAL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    BirthDate DATE NOT NULL,
    Gender VARCHAR(10) NOT NULL CHECK (Gender IN ('MALE', 'FEMALE', 'UNKNOWN', 'OTHER')),
    FitnessCenterID INTEGER NOT NULL REFERENCES FitnessCenters(FitnessCenterID)
);

CREATE TABLE Activities (
    ActivityID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Type VARCHAR(50) NOT NULL CHECK (Type IN ('STRENGTH TRAINING', 'CARDIO', 'YOGA', 'DANCE', 'INJURY REHABILITATION')),
    PricePerSession DECIMAL(10,2) NOT NULL CHECK (PricePerSession >= 0)
);

CREATE TABLE TrainerActivities (
    TrainerID INTEGER NOT NULL REFERENCES Trainers(TrainerID),
    ActivityID INTEGER NOT NULL REFERENCES Activities(ActivityID),
    Role VARCHAR(10) NOT NULL CHECK (Role IN ('MAIN', 'ASSISTANT')),
	PRIMARY KEY (TrainerID, ActivityID)
);

CREATE TABLE Schedule (
    ScheduleID SERIAL PRIMARY KEY,
    ActivityID INTEGER NOT NULL REFERENCES Activities(ActivityID),
    SessionDate DATE NOT NULL,
    SessionTime TIME NOT NULL,
    MaxParticipants INTEGER NOT NULL CHECK (MaxParticipants > 0),
    CurrentParticipants INTEGER DEFAULT 0 CHECK (CurrentParticipants >= 0)
);

CREATE TABLE Participants (
    ParticipantID SERIAL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    BirthDate DATE NOT NULL
);

CREATE TABLE Enrollments (
    ScheduleID INTEGER NOT NULL REFERENCES Schedule(ScheduleID),
    ParticipantID INTEGER NOT NULL REFERENCES Participants(ParticipantID),
	PRIMARY KEY (ScheduleID,ParticipantID)
);


CREATE OR REPLACE FUNCTION CheckMainTrainerLimit()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) 
        FROM TrainerActivities 
        WHERE TrainerID = NEW.TrainerID AND Role = 'MAIN') >= 2 THEN
        RAISE EXCEPTION 'A trainer can only be the main trainer for up to 2 activities.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TrgCheckMainTrainerLimit
BEFORE INSERT ON TrainerActivities
FOR EACH ROW
WHEN (NEW.Role = 'MAIN')
EXECUTE FUNCTION CheckMainTrainerLimit();


CREATE OR REPLACE FUNCTION CheckTrainersFitnessCenter()
RETURNS TRIGGER AS $$
DECLARE
    ActivityFitnessCenterID INTEGER;
    TrainerFitnessCenterID INTEGER;
BEGIN
    SELECT FitnessCenterID INTO TrainerFitnessCenterID
    FROM Trainers
    WHERE TrainerID = NEW.TrainerID;

    SELECT t.FitnessCenterID INTO ActivityFitnessCenterID
    FROM TrainerActivities ta
    JOIN Trainers t ON ta.TrainerID = t.TrainerID
    WHERE ta.ActivityID = NEW.ActivityID
    LIMIT 1;

    IF ActivityFitnessCenterID IS NOT NULL AND ActivityFitnessCenterID != TrainerFitnessCenterID THEN
        RAISE EXCEPTION 'All trainers for the same activity must belong to the same fitness center.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TrgCheckTrainersFitnessCenter
BEFORE INSERT ON TrainerActivities
FOR EACH ROW
EXECUTE FUNCTION CheckTrainersFitnessCenter();


CREATE OR REPLACE FUNCTION UpdateParticipantsOnEnroll()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Schedule
    SET CurrentParticipants = CurrentParticipants + 1
    WHERE ScheduleID = NEW.ScheduleID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TrgEnrollParticipant
AFTER INSERT ON Enrollments
FOR EACH ROW
EXECUTE FUNCTION UpdateParticipantsOnEnroll();


CREATE OR REPLACE FUNCTION PreventOverCapacity()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT CurrentParticipants FROM Schedule WHERE ScheduleID = NEW.ScheduleID) >= 
       (SELECT MaxParticipants FROM Schedule WHERE ScheduleID = NEW.ScheduleID) THEN
        RAISE EXCEPTION 'Session is full. Enrollment not allowed.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TrgPreventOverCapacity
BEFORE INSERT ON Enrollments
FOR EACH ROW
EXECUTE FUNCTION PreventOverCapacity();
