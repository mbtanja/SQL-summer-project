/*Tanja Mickovska Bojadjiski SQL summer Project*/

USE master;
go

-- Check --

IF exists (
select * from sys.databases
where name='SummerProject')
drop database SummerProject;
GO

-- Create and use the database --

create database SummerProject;
go
use SummerProject;
GO


--*************************
--Create tables
--*************************

---------------------------
--Table SeniorityLevel
---------------------------

CREATE TABLE dbo.SeniorityLevel (
Id int IDENTITY (1,1) not null,
Name nvarchar (100) not null,
CONSTRAINT PK_SeniorityLevel PRIMARY KEY CLUSTERED ([ID] ASC)
);
GO

---------------------------
--Table Location
---------------------------

CREATE TABLE dbo.Location (
Id int IDENTITY (1,1) not null,
CountryName nvarchar (100) null,
Continent nvarchar (100) null,
Region nvarchar (100) null,
CONSTRAINT PK_Location PRIMARY KEY CLUSTERED ([ID] ASC)
);
GO

---------------------------
--Table Department
---------------------------

CREATE TABLE dbo.Department (
Id int IDENTITY (1,1) not null,
Name nvarchar (100) not null,
CONSTRAINT PK_Department PRIMARY KEY CLUSTERED ([ID] ASC)
);
GO

---------------------------
--Table Employee
---------------------------

CREATE TABLE dbo.Employee (
Id int IDENTITY (1,1) not null,
FirstName nvarchar (100) not null,
LastName nvarchar (100) not null,
LocationId int not null,
SeniorityLevelId int not null,
DepartmentId int not null,
CONSTRAINT PK_Employee PRIMARY KEY CLUSTERED ([ID] ASC)
);
GO

---------------------------
--Table Salary
---------------------------

CREATE TABLE dbo.Salary (
Id int IDENTITY (1,1) not null,
EmployeeId int not null,
Month smallint not null,
Year smallint not null,
GrossAmount decimal(18,2) not null,
NetAmount decimal(18,2) not null,
RegularWorkAmount decimal(18,2) not null,
BonusAmount decimal(18,2) not null,
OvertimeAmount decimal(18,2) not null,
VacationDays smallint not null,
SickLeaveDays smallint not null,
CONSTRAINT PK_Salary PRIMARY KEY CLUSTERED ([ID] ASC)
);
GO


--**********************
--Add foreign keys
--***********************

-----------------------------
--FK_Employee_SeniorityLevel 
------------------------------

ALTER TABLE dbo.Employee WITH CHECK 
ADD CONSTRAINT FK_Employee_SeniorityLevel 
FOREIGN KEY (SeniorityLevelId) REFERENCES dbo.SeniorityLevel (Id);
go

ALTER TABLE dbo.Employee 
CHECK CONSTRAINT FK_Employee_SeniorityLevel;
go

-----------------------------
--FK_Employee_Location
------------------------------

ALTER TABLE dbo.Employee WITH CHECK
ADD CONSTRAINT FK_Employee_Location 
FOREIGN KEY (LocationId) REFERENCES dbo.Location (Id);
go

ALTER TABLE dbo.Employee 
CHECK CONSTRAINT FK_Employee_Location;
go

-----------------------------
--FK_Employee_Department 
------------------------------

ALTER TABLE dbo.Employee WITH CHECK
ADD CONSTRAINT FK_Employee_Department 
FOREIGN KEY (DepartmentId) REFERENCES dbo.Department (Id);
go

ALTER TABLE dbo.Employee 
CHECK CONSTRAINT FK_Employee_Department;
go

-----------------------------
--FK_Salary_Employee 
------------------------------

ALTER TABLE dbo.Salary WITH CHECK
ADD CONSTRAINT FK_Salary_Employee 
FOREIGN KEY (EmployeeId) REFERENCES dbo.Employee (Id);
go

ALTER TABLE dbo.Salary 
CHECK CONSTRAINT FK_Salary_Employee;
go


--***************************
--Load Data
--****************************

---------------------------
--Table SeniorityLevel
---------------------------

INSERT INTO dbo.SeniorityLevel (Name)
VALUES ('Junior')
		, ('Intermediate')
		, ('Senior')
		, ('Lead')
		, ('Project Manager')
		, ('Division Manager')
		, ('Office Manager')
		, ('CEO')
		, ('CTO')
		, ('CIO');
go

-----------------------
-- Table Location
-----------------------

INSERT INTO dbo.Location (CountryName,Continent,Region)
select CountryName,Continent,Region 
from WideWorldImporters.Application.Countries;
go

-------------------------
--Table Department
------------------------

INSERT INTO dbo.Department (Name)
VALUES ('Personal Banking & Operations')
		, ('Digital Banking Department')
		, ('Retail Banking & Marketing Department')
		, ('Wealth Management & Third Party Products')
		, ('International Banking Division & DFB')
		, ('Treasury')
		, ('Information Technology')
		, ('Corporate Communications')
		, ('Support Services & Branch Expansion')
		, ('Human Resources');
go

--------------------------
--Table Employee
---------------------------

-- 1. Get the Employees FistName and LastName from WWI into table @FullName 

declare @FullName table (FirstName nvarchar(50),LastName nvarchar(50))
insert into @FullName
select LEFT(FullName,(charindex(' ',FullName)-1)) as FirstName, 
      RIGHT(FullName,(LEN(FullName)-charindex(' ',FullName))) as LastName
from WideWorldImporters.Application.People
--select * from @FullName

-- 2. Load data into Employee

INSERT INTO dbo.Employee (FirstName, LastName, SeniorityLevelId, LocationId, DepartmentId)
select	
		FirstName
		, LastName
		, 1 as SeniorityLevelId
		, 1 as LocationId
		, 1 as DepartmentId
from @FullName;
go

-- 3. Update SeniorityLevelId, LocationId, DepartmentId

-- Update SeniorityLevelId

UPDATE e 
set  SeniorityLevelId=sl.Id
from dbo.Employee e
inner join dbo.SeniorityLevel as sl on sl.id=(e.Id %10 + 1);
go

-- Update LocationId

UPDATE e 
set  LocationId=l.Id
from dbo.Employee e
inner join dbo.Location as l on l.id=(e.Id %6+1);
go

-- Update DepartmentId

UPDATE e 
set  DepartmentId=d.Id
from dbo.Employee e
inner join dbo.Department as d on d.id=(e.Id %10+1);
go

----------------------
--Table Salary
-------------------

-- 1. Generate the salary data for the past 20 years

DECLARE @StartDate DATE = '2001-01-01';
DECLARE @EndDate DATE = '2020-12-31';
DECLARE @CurrentDate DATE = @StartDate;

WHILE @CurrentDate <= @EndDate
BEGIN

-- Insert the data into the Salary table

    INSERT INTO Salary 
				( EmployeeId, Month, Year, GrossAmount
				, NetAmount, RegularWorkAmount, BonusAmount, OvertimeAmount, VacationDays, SickLeaveDays)
    SELECT 
		id as EmployeeId
		, MONTH(@CurrentDate) as Month
		, YEAR(@CurrentDate) as Year
		, ABS(CHECKSUM(NEWID()))%30000 + 30001 as GrossAmount -- Random GrossAmount between 30.000 and 60.000
		, 0 as NetAmount
		, 0 as RegularWorkAmount
		, 0 as BonusAmount
		, 0 as OvertimeAmount
		, 0 as VacationDays
		, 0 as SickLeaveDays
     from dbo.Employee
	 --where id=1
     SET @CurrentDate = DATEADD(MONTH, 1, @CurrentDate)
END;
go

-- 2. Update NetAmount, RegularWorkAmount, BonusAmount, and OvertimeAmount:

--Update NetAmount (90% of GrossAmount)

UPDATE Salary
SET NetAmount = 0.9 * GrossAmount;
go

-- Update RegularWorkAmount (80% of NetAmount )

UPDATE Salary
SET RegularWorkAmount = 0.8 * NetAmount;
go

-- Update BonusAmount for Odd months (January, March, ...)

UPDATE Salary
SET BonusAmount = NetAmount - RegularWorkAmount
WHERE Month % 2 = 1;
go

-- Update OvertimeAmount for Even months (February, April, ...)

UPDATE Salary
SET OvertimeAmount = NetAmount - RegularWorkAmount
WHERE Month % 2 = 0;
go

-- 3. Update VacationDays and SickLeaveDays

-- Update VacationDays -> 10 vacation days in July and 10 Vacation days in December 

UPDATE Salary
SET VacationDays = 
	CASE WHEN Month = 7 OR Month = 12 THEN 10
    ELSE 0
END;
go

-- Update VacationDays for random vacation days

update dbo.salary 
set VacationDays = VacationDays + (EmployeeId % 2) 
where  (EmployeeId + MONTH+ year)%5 = 1 ;
go 

-- Update SickLeaveDays + VacationDays

update dbo.salary 
set SickLeaveDays = EmployeeId%8
	, VacationDays = VacationDays + (EmployeeId % 3) 
where  (EmployeeId + MONTH+ year)%5 = 2 ;
go

/*
select * from SeniorityLevel
select * from Location
select * from Department
select * from Employee
select * from Salary

---- NetAmount Check ----
select * 
from dbo.salary  
where NetAmount <> (regularWorkAmount + BonusAmount + OverTimeAmount) 

---- GrossAmount Check ----
select * 
from dbo.Salary
where GrossAmount<30000 or GrossAmount>60000 

---- VacationDays Check ---
select sum(VacationDays) as Num
from dbo.Salary
group by EmployeeId,Year
having sum(VacationDays)<20 or sum(VacationDays)>30 


*/



