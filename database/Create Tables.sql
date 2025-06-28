
-- Clean up data if needed    
  
DROP DATABASE IF EXISTS project_1_banking_db;

CREATE DATABASE IF NOT EXISTS project_1_banking_db;

USE project_1_banking_db;



-- ALL TABLES 

-- Customers table

CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    email VARCHAR(100) NOT NULL ,
    phone CHAR(14) NOT NULL ,
    created_at DATETIME DEFAULT NOW(),
    
    CONSTRAINT chk_phone_length CHECK(CHAR_LENGTH(phone) = 14),
    CONSTRAINT chk_phone_digits CHECK( phone REGEXP '^\\+91\\s[0-9]{10}$' ),
    CONSTRAINT chk_email CHECK( email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' ),
    
    UNIQUE INDEX idx_unique_email(email),
    UNIQUE INDEX idx_unique_phone(phone)
)
ENGINE = InnoDB;


-- Accounts table

CREATE TABLE accounts (
    account_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    account_type ENUM('Savings', 'Current') NOT NULL,   
    balance DECIMAL(12, 2) NOT NULL,
    created_at DATETIME DEFAULT NOW(),
    
    CONSTRAINT chk_min_bal CHECK(balance >= 100),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
		
        ON UPDATE CASCADE
) 
ENGINE = InnoDB;




--   ---------------------- Transactions ----------------------------

-- Transactions

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    self_account_id INT NOT NULL,
    other_account_id INT,  -- for self transfers , we take Other_account_id as NULL
    transfer_type ENUM('Self Transfer', 'Account to Account Transfer') NOT NULL,  
    deposit_withdrawal ENUM('Self Deposit', 'Self Withdrawal', 'Transfer In', 'Transfer Out') NOT NULL,  
    transfer_amt DECIMAL(12, 2) NOT NULL,
    transaction_date DATETIME DEFAULT NOW(),
    transaction_description VARCHAR(255),
    
    FOREIGN KEY (self_account_id) REFERENCES accounts(account_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
		
   FOREIGN KEY (other_account_id) REFERENCES accounts(account_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE
) 
ENGINE = InnoDB;



-- Creating the Table to store Deleted accounts : Need all customers columns and account_id

CREATE TABLE closed_account_log_table (
    customer_id INT ,
    account_id INT ,
    name VARCHAR(100),
    email VARCHAR(100) NOT NULL ,
    phone CHAR(14) NOT NULL ,
    deleted_at DATETIME DEFAULT NOW()
    
)
ENGINE = InnoDB;



-- Creating the Table to store Deleted Customer Records : Need customers columns 

CREATE TABLE closed_customer_acc_log_table (
    customer_id INT ,
    name VARCHAR(100),
    email VARCHAR(100) NOT NULL ,
    phone CHAR(14) NOT NULL ,
    deleted_at DATETIME DEFAULT NOW()
    
)
ENGINE = InnoDB;

SHOW TABLES;
