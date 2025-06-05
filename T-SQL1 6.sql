-- This SQL script is designed to manage employee data within a database. 
-- It includes functionality for creating and populating an employee table, 
-- calculating employee ages, retrieving employee information, updating salaries, 
-- and logging salary changes. It fulfills business requirements for employee data management and reporting.

-- Drop existing table if it exists
IF OBJECT_ID('dbo.Employees', 'U') IS NOT NULL
    DROP TABLE dbo.Employees;

-- Create Table (DDL)
CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY, -- Auto-incrementing primary key for employee identification
    FirstName NVARCHAR(50) NOT NULL,          -- Employee's first name, cannot be null
    LastName NVARCHAR(50) NOT NULL,           -- Employee's last name, cannot be null
    Email NVARCHAR(100) UNIQUE,               -- Unique email address for each employee
    DOB DATE NOT NULL,                        -- Date of birth, cannot be null
    HireDate DATETIME DEFAULT GETDATE(),      -- Hire date, defaults to current date and time
    Salary DECIMAL(10,2) CHECK (Salary > 0)   -- Salary with a constraint to ensure it is positive
);

-- Insert Sample Data (DML)
INSERT INTO Employees (FirstName, LastName, Email, DOB, Salary) VALUES 
('Alice', 'Johnson', 'alice.johnson@example.com', '1990-05-15', 65000.00),
('Bob', 'Smith', 'bob.smith@example.com', '1985-08-20', 72000.00),
('Charlie', 'Brown', 'charlie.brown@example.com', '1995-11-25', 54000.00);

-- Utility Function: Calculate Employee Age
CREATE FUNCTION dbo.CalculateAge(@DOB DATE)
RETURNS INT
AS
BEGIN
    -- Calculate the age based on the difference in years, adjusting if the birthday hasn't occurred this year
    RETURN DATEDIFF(YEAR, @DOB, GETDATE()) 
           - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, @DOB, GETDATE()), @DOB) > GETDATE() THEN 1 ELSE 0 END;
END;

-- Utility Function: Get Full Name
CREATE FUNCTION dbo.GetFullName(@FirstName NVARCHAR(50), @LastName NVARCHAR(50))
RETURNS NVARCHAR(101)
AS
BEGIN
    -- Concatenate first and last names with a space in between, trimming any extra spaces
    RETURN TRIM(@FirstName) + ' ' + TRIM(@LastName);
END;

-- Stored Procedure: Get Employee by ID
CREATE PROCEDURE GetEmployeeByID
    @EmpID INT
AS
BEGIN
    -- Retrieve employee details by ID, including calculated full name and age
    SELECT EmployeeID, dbo.GetFullName(FirstName, LastName) AS FullName, Email, 
           dbo.CalculateAge(DOB) AS Age, HireDate, Salary
    FROM Employees
    WHERE EmployeeID = @EmpID;
END;

-- Transactions & Error Handling: Salary Update
CREATE PROCEDURE UpdateEmployeeSalary
    @EmpID INT,
    @NewSalary DECIMAL(10,2)
AS
BEGIN
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Check if employee exists
        IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @EmpID)
        BEGIN
            RAISERROR('Employee does not exist.', 16, 1); -- Raise an error if employee is not found
            ROLLBACK; -- Rollback transaction if employee does not exist
            RETURN;
        END
        
        -- Update salary
        UPDATE Employees
        SET Salary = @NewSalary
        WHERE EmployeeID = @EmpID;

        COMMIT; -- Commit transaction if update is successful
        PRINT 'Salary updated successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK; -- Rollback transaction in case of an error
        PRINT 'Error: Salary update failed.';
    END CATCH;
END;

-- Control Flow: Print Employee List
DECLARE @Counter INT = 1, @Max INT;

SELECT @Max = COUNT(*) FROM Employees; -- Get the total number of employees

WHILE @Counter <= @Max
BEGIN
    PRINT 'Processing Employee ' + CAST(@Counter AS NVARCHAR); -- Print processing message for each employee
    SET @Counter = @Counter + 1; -- Increment counter
END;

-- CTE (Common Table Expression): Employees with Salary > 60000
WITH HighEarners AS (
    SELECT EmployeeID, FirstName, LastName, Salary 
    FROM Employees WHERE Salary > 60000 -- Filter employees with salary greater than 60000
)
SELECT * FROM HighEarners; -- Select all high earners

-- Trigger: Log Employee Salary Changes
CREATE TRIGGER trg_SalaryUpdate
ON Employees
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Salary) -- Check if the salary column was updated
    BEGIN
        PRINT 'Employee salary updated!'; -- Print a message when salary is updated
    END;
END;

-- Execute Stored Procedure: Get Employee by ID
EXEC GetEmployeeByID @EmpID = 1; -- Retrieve details for employee with ID 1

-- Execute Function: Get Employee Full Name
SELECT dbo.GetFullName('John', 'Doe') AS FullName; -- Get full name for given first and last names

-- Execute Salary Update with Error Handling
EXEC UpdateEmployeeSalary @EmpID = 1, @NewSalary = 70000; -- Update salary for employee with ID 1 to 70000