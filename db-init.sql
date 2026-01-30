USE master;
GO

-- Create database if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'RealRelianceBankDB')
BEGIN
    CREATE DATABASE [RealRelianceBankDB];
    PRINT 'Database RealRelianceBankDB created.';
END
ELSE
BEGIN
    PRINT 'Database RealRelianceBankDB already exists.';
END
GO

-- Switch to the database
USE [RealRelianceBankDB];
GO

-- Create SQL Server Login for bob.builder@example.com (for external connections)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'bob.builder@example.com')
BEGIN
    CREATE LOGIN [bob.builder@example.com] 
    WITH PASSWORD = 'pass1',
         DEFAULT_DATABASE = [RealRelianceBankDB],
         CHECK_EXPIRATION = OFF,
         CHECK_POLICY = OFF;
    PRINT 'Login bob.builder@example.com created.';
END
ELSE
BEGIN
    PRINT 'Login bob.builder@example.com already exists.';
END
GO

-- Create User in the database
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'bob.builder')
BEGIN
    CREATE USER [bob.builder] 
    FOR LOGIN [bob.builder@example.com]
    WITH DEFAULT_SCHEMA = dbo;
    
    -- Grant permissions
    ALTER ROLE db_owner ADD MEMBER [bob.builder];
    PRINT 'User bob.builder created with db_owner permissions.';
END
ELSE
BEGIN
    PRINT 'User bob.builder already exists.';
END
GO

-- Person table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Person')
BEGIN
    CREATE TABLE Person (
        PersonId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        IdNumber INT,
        FirstName NVARCHAR(100) NOT NULL,
        LastName NVARCHAR(100) NOT NULL,
        Email NVARCHAR(100) NOT NULL UNIQUE,
        PhoneNumber NVARCHAR(15),
        Address NVARCHAR(255),
        DateOfBirth DATE,
        ActiveInd BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE()
    );
    PRINT 'Person table created.';
END
ELSE
BEGIN
    PRINT 'Person table already exists.';
END
GO

-- Account table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Account')
BEGIN
    CREATE TABLE Account (
        AccountId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        PersonId UNIQUEIDENTIFIER NOT NULL,
        AccountNumber NVARCHAR(20) NOT NULL UNIQUE,
        AccountType NVARCHAR(50),
        Balance DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
        IsClosed BIT NOT NULL DEFAULT 0,
        ActiveInd BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (PersonId) REFERENCES Person(PersonId) ON DELETE CASCADE
    );
    PRINT 'Account table created.';
END
ELSE
BEGIN
    PRINT 'Account table already exists.';
END
GO

-- Transactions table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Transactions')
BEGIN
    CREATE TABLE Transactions (
        TransactionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        AccountId UNIQUEIDENTIFIER NOT NULL,
        Amount DECIMAL(18, 2) NOT NULL,
        TransactionType VARCHAR(10) NOT NULL CHECK (TransactionType IN ('Debit', 'Credit')),
        TransactionDate DATETIME NOT NULL DEFAULT GETDATE(),
        Description NVARCHAR(255),
        ActiveInd BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (AccountId) REFERENCES Account(AccountId) ON DELETE CASCADE
    );
    PRINT 'Transactions table created.';
END
ELSE
BEGIN
    PRINT 'Transactions table already exists.';
END
GO

-- Users table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE Users (
        UserId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        FirstName NVARCHAR(100) NOT NULL,
        LastName NVARCHAR(100) NOT NULL,
        Email NVARCHAR(100) NOT NULL UNIQUE,
        Password NVARCHAR(100) NOT NULL,
        Role NVARCHAR(50) NOT NULL,
        RefreshToken NVARCHAR(512) NULL,
        RefreshTokenExpires DATETIME2 NULL,
        ActiveInd BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE()
    );
    PRINT 'Users table created.';
END
ELSE
BEGIN
    PRINT 'Users table already exists.';
END
GO

-- Ensure refresh token columns exist on Users table
IF COL_LENGTH('Users', 'RefreshToken') IS NULL
BEGIN
    ALTER TABLE Users ADD RefreshToken NVARCHAR(512) NULL;
    PRINT 'Users.RefreshToken column added.';
END
GO

IF COL_LENGTH('Users', 'RefreshTokenExpires') IS NULL
BEGIN
    ALTER TABLE Users ADD RefreshTokenExpires DATETIME2 NULL;
    PRINT 'Users.RefreshTokenExpires column added.';
END
GO

-- Insert sample data into Person
IF NOT EXISTS (SELECT 1 FROM Person)
BEGIN
    INSERT INTO Person (PersonId, IdNumber, FirstName, LastName, Email, PhoneNumber, Address, DateOfBirth, ActiveInd)
    VALUES
        ('C399843A-B0F9-4432-A70E-2BAECCE7619F', 123456, 'John', 'Doe', 'john.doe@example.com', '555-1234', '123 Elm Street', '1980-01-01', 1),
        ('5E516D14-1732-40BB-AC52-4294E7E685A6', 234567, 'Jane', 'Smith', 'jane.smith@example.com', '555-5678', '456 Oak Avenue', '1990-02-02', 1),
        ('23C43FE1-0B33-4530-B045-47B4CFEF230D', 345678, 'Bob', 'Johnson', 'bob.johnson@example.com', '555-9876', '789 Pine Road', '1975-03-03', 0);
    
    PRINT 'Test data inserted into Person table.';
END
ELSE
BEGIN
    PRINT 'Person table already has data.';
END
GO

-- Insert sample data into Account
IF NOT EXISTS (SELECT 1 FROM Account)
BEGIN
    INSERT INTO Account (AccountId, PersonId, AccountNumber, AccountType, Balance, IsClosed, ActiveInd)
    VALUES
        ('D0300D5A-52FE-4B02-8844-78E9CC69769A', 'C399843A-B0F9-4432-A70E-2BAECCE7619F', 'ACC1234567890', 'Checking', 1000.00, 0, 1),
        ('D9771B65-BCE2-47C7-B611-A0C30FEDCF68', '5E516D14-1732-40BB-AC52-4294E7E685A6', 'ACC2345678901', 'Savings', 2500.50, 0, 1),
        ('C11B7553-085C-4126-A128-F083E887A087', '23C43FE1-0B33-4530-B045-47B4CFEF230D', 'ACC3456789012', 'Checking', 500.75, 1, 0);
    
    PRINT 'Test data inserted into Account table.';
END
ELSE
BEGIN
    PRINT 'Account table already has data.';
END
GO

-- Insert sample data into Transactions
IF NOT EXISTS (SELECT 1 FROM Transactions)
BEGIN
    INSERT INTO Transactions (TransactionId, AccountId, Amount, TransactionType, TransactionDate, Description, ActiveInd)
    VALUES
        (NEWID(), 'D0300D5A-52FE-4B02-8844-78E9CC69769A', 100.00, 'Credit', '2024-07-01 09:00:00', 'Initial deposit', 1),
        (NEWID(), 'D9771B65-BCE2-47C7-B611-A0C30FEDCF68', 50.75, 'Debit', '2024-07-02 14:30:00', 'Grocery shopping', 1),
        (NEWID(), 'C11B7553-085C-4126-A128-F083E887A087', 200.00, 'Credit', '2024-07-03 10:15:00', 'Salary deposit', 1);
    
    PRINT 'Test data inserted into Transactions table.';
END
ELSE
BEGIN
    PRINT 'Transactions table already has data.';
END
GO

-- Insert sample data into Users
IF NOT EXISTS (SELECT 1 FROM Users)
BEGIN
    INSERT INTO Users (UserId, FirstName, LastName, Email, Password, Role, ActiveInd)
    VALUES
        (NEWID(), 'Bob', 'Builder', 'bob.builder@example.com', '$2a$11$YourHashedPasswordHere', 'Admin', 1),
        (NEWID(), 'Jane', 'Smith', 'jane.smith@example.com', '$2a$11$AnotherHashedPassword', 'Customer', 1),
        (NEWID(), 'System', 'Admin', 'admin@realreliance.com', '$2a$11$AdminHashedPassword123', 'Admin', 1);
    
    PRINT 'Test data inserted into Users table.';
END
ELSE
BEGIN
    PRINT 'Users table already has data.';
END
GO

PRINT '============================================';
PRINT ' Database initialization COMPLETE!';
PRINT '============================================';
PRINT 'Database: RealRelianceBankDB';
PRINT 'Tables created: Person, Account, Transactions, Users';
PRINT 'Login created: bob.builder@example.com';
PRINT 'User created: bob.builder (with db_owner permissions)';
PRINT 'Sample data inserted into all tables';
PRINT '============================================';
GO
