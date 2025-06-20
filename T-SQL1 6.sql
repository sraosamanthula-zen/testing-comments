-- Drop existing table if it exists
IF OBJECT_ID('dbo.Employees', 'U') IS NOT NULL
    DROP TABLE dbo.Employees;

-- Create Table (DDL)
CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    DOB DATE NOT NULL,
    HireDate DATETIME DEFAULT GETDATE(),
    Salary DECIMAL(10,2) CHECK (Salary > 0)
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
    RETURN DATEDIFF(YEAR, @DOB, GETDATE()) 
           - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, @DOB, GETDATE()), @DOB) > GETDATE() THEN 1 ELSE 0 END;
END;

-- Utility Function: Get Full Name
CREATE FUNCTION dbo.GetFullName(@FirstName NVARCHAR(50), @LastName NVARCHAR(50))
RETURNS NVARCHAR(101)
AS
BEGIN
    RETURN TRIM(@FirstName) + ' ' + TRIM(@LastName);
END;

-- Stored Procedure: Get Employee by ID
CREATE PROCEDURE GetEmployeeByID
    @EmpID INT
AS
BEGIN
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
            RAISERROR('Employee does not exist.', 16, 1);
            ROLLBACK;
            RETURN;
        END
        
        -- Update salary
        UPDATE Employees
        SET Salary = @NewSalary
        WHERE EmployeeID = @EmpID;

        COMMIT;
        PRINT 'Salary updated successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK;
        PRINT 'Error: Salary update failed.';
    END CATCH;
END;

-- Control Flow: Print Employee List
DECLARE @Counter INT = 1, @Max INT;

SELECT @Max = COUNT(*) FROM Employees;

WHILE @Counter <= @Max
BEGIN
    PRINT 'Processing Employee ' + CAST(@Counter AS NVARCHAR);
    SET @Counter = @Counter + 1;
END;

--  CTE (Common Table Expression): Employees with Salary > 60000
WITH HighEarners AS (
    SELECT EmployeeID, FirstName, LastName, Salary 
    FROM Employees WHERE Salary > 60000
)
SELECT * FROM HighEarners;

--  Trigger: Log Employee Salary Changes
CREATE TRIGGER trg_SalaryUpdate
ON Employees
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Salary)
    BEGIN
        PRINT 'Employee salary updated!';
    END;
END;

--  Execute Stored Procedure: Get Employee by ID
EXEC GetEmployeeByID @EmpID = 1;

--  Execute Function: Get Employee Full Name
SELECT dbo.GetFullName('John', 'Doe') AS FullName;

--  Execute Salary Update with Error Handling
EXEC UpdateEmployeeSalary @EmpID = 1, @NewSalary = 70000;

