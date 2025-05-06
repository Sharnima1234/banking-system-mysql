-- Clean up data if needed
   DROP DATABASE IF EXISTS project_1_banking_db;
  
CREATE DATABASE IF NOT EXISTS project_1_banking_db;
USE project_1_banking_db;

-- Customers
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    email VARCHAR(100) NOT NULL ,
    phone CHAR(10) NOT NULL ,
    created_at DATETIME DEFAULT NOW(),
    
    CONSTRAINT chk_phone_length CHECK(CHAR_LENGTH(phone) = 10),
    CONSTRAINT chk_phone_digits CHECK( phone REGEXP '^[0-9]{10}$' ),
    CONSTRAINT chk_email CHECK( email LIKE '%@%'),
    
    UNIQUE INDEX idx_unique_email(email),
    UNIQUE INDEX idx_unique_phone(phone)
)
ENGINE = InnoDB;

-- Accounts
CREATE TABLE accounts (
    account_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    account_type VARCHAR(100) NOT NULL,
    balance DECIMAL(12, 2) NOT NULL,
    status VARCHAR(100) NOT NULL DEFAULT 'Active',
    
    CONSTRAINT chk_min_bal CHECK(balance >= 200),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
		-- ON DELETE CASCADE     Dont enable it, else triggers wont run on Child Table 
        ON UPDATE CASCADE
) 
AUTO_INCREMENT = 101
ENGINE = InnoDB;

-- Transactions
-- One for Deposit and Withdrawal
CREATE TABLE transaction_depo_with (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    account_id INT NOT NULL,
    type VARCHAR(100) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    transaction_date DATETIME DEFAULT NOW(),
    description VARCHAR(255),
    
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE
) 
AUTO_INCREMENT = 1001
ENGINE = InnoDB;

-- One for Transactions between 2 accounts
CREATE TABLE transaction_transfer (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    from_account_id INT NOT NULL,
    to_account_id INT NOT NULL,
    type VARCHAR(100) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    transaction_date DATETIME DEFAULT NOW(),
    description VARCHAR(255),
    
    FOREIGN KEY (from_account_id) REFERENCES accounts(account_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
        
	FOREIGN KEY (to_account_id) REFERENCES accounts(account_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE
) 
AUTO_INCREMENT = 2001
ENGINE = InnoDB;

-- Creating the Table to store Deleted accounts : Need all customers columns and account_id
CREATE TABLE account_log_table (
    customer_id INT ,
    account_id INT ,
    name VARCHAR(100),
    email VARCHAR(100) NOT NULL ,
    phone CHAR(10) NOT NULL ,
    deleted_at DATETIME DEFAULT NOW()
    
)
ENGINE = InnoDB;


-- Inserting sample Data
-- Customers
INSERT INTO customers (name, email, phone, created_at) 
VALUES
('Sharnima Mallik', 'sharnima@email.com', '9876543210', '2023-01-10'),
('Arjun Mehta', 'arjun@email.com', '9123456780', '2022-12-01'),
('Priya Nair', 'priya@email.com', '9012345678', '2023-03-15'),
('Rohan Das', 'rohan@email.com', '9988776655', '2023-04-01'),
('Nisha Verma', 'nisha@email.com', '9001122334', '2023-02-20');



-- Accounts
INSERT INTO accounts (customer_id, account_type, balance, status) 
VALUES
(1, 'Savings', 15000.00, 'Active'), 
(1, 'Current', 32000.00, 'Active'),
(2, 'Savings', 2500.00, 'Active'),
(3, 'Savings', 7500.00, 'Active'),
(4, 'Current', 18000.00, 'Active'),
(5, 'Savings', 9500.00, 'Active'),
(3, 'Current', 10500.00, 'Active'),
(4, 'Savings', 4000.00, 'Active'),
(5, 'Savings', 8200.00, 'Active'), 
(1, 'Current', 12500.00, 'Active'),
(2, 'Savings', 9100.00, 'Active'),
(2, 'Savings', 3600.00, 'Active');


-- Transactions
INSERT INTO transaction_depo_with (account_id, type, amount, description, transaction_date) 
VALUES
(101, 'Deposit', 5000, 'Initial Deposit', '2023-01-10 09:00:00'),
(102, 'Withdrawal', 1000, 'ATM Withdrawal', '2023-01-12 14:00:00'),
(102, 'Deposit', 2500, 'Opening Deposit', '2022-12-01 10:00:00'),
(103, 'Deposit', 7500, 'Gift Money', '2023-03-15 11:00:00'),
(104, 'Deposit', 18000, 'Salary', '2023-04-01 09:30:00'),
(104, 'Withdrawal', 2000, 'Rent Payment', '2023-04-05 10:30:00'),
(105, 'Deposit', 9500, 'Bonus', '2023-02-20 08:45:00'),
(106, 'Deposit', 10500, 'Freelance Income', '2023-01-22 13:00:00'),
(107, 'Withdrawal', 1500, 'Electric Bill', '2022-11-20 15:00:00');


INSERT INTO transaction_transfer (from_account_id, to_account_id, type, amount, description, transaction_date) 
VALUES
(101, 103, 'Transfer', 5000, 'Initial Deposit',     '2023-01-10 09:00:00'),
(102, 104, 'Transfer', 1000, 'ATM Withdrawal',      '2023-01-12 14:00:00'),
(102, 101, 'Transfer',    2500, 'Opening Deposit',  '2022-12-01 10:00:00'),
(103, 106, 'Transfer',    7500, 'Gift Money',        '2023-03-15 11:00:00'),
(104, 107, 'Transfer',   18000, 'Salary',            '2023-04-01 09:30:00'),
(102, 101, 'Transfer', 1500, 'Sent to friend',        '2023-02-01 12:00:00'),
(104, 102, 'Transfer', 3000, 'Transferred to savings', '2023-04-07 14:00:00'),
(105, 103, 'Transfer', 2000, 'Gifted money',         '2023-03-01 09:00:00');

-- To see All Tables
-- SHOW TABLES;

SELECT * FROM customers;
SELECT * FROM accounts;
SELECT * FROM transaction_depo_with;
SELECT * FROM transaction_transfer;



-- ----------------- Creating the TRIGGERS ----------------------------------------
-- --------------------------------------------------------------------------------

-- 1. To Check for Minimum balance in 'accounts' table
DELIMITER $$
	CREATE TRIGGER trigger_check_neg_bal
		BEFORE UPDATE
		ON accounts
	FOR EACH ROW
		BEGIN
			IF NEW.balance < 200 THEN
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient Balance!';
			END IF;
		END $$
DELIMITER ;		
	
-- 2. To log down records for any 'account_id' deleted :
DELIMITER $$
  CREATE TRIGGER trigger_log_deleted_account
		AFTER DELETE
		ON accounts     -- For 'accounts' table
  FOR EACH ROW
		BEGIN
			INSERT INTO account_log_table(
						customer_id,
						account_id,   
						name,
						email,
						phone,
						deleted_at)
			SELECT 
				OLD.customer_id, 
                OLD.account_id,
				c.name,
                c.email,
                c.phone,
                NOW()
			FROM customers AS c
            WHERE c.customer_id = OLD.customer_id;
	 END $$
DELIMITER ;
  
-- 3. To log down All the related 'account_ids' for a 'customer_id'
DELIMITER $$
	CREATE TRIGGER trigger_log_deleted_customer
		AFTER DELETE
		ON customers     -- For 'customers' table
	FOR EACH ROW
		BEGIN
			INSERT INTO account_log_table(
						customer_id,
						account_id,   -- we don’t know any account_id here
						name,
						email,
						phone,
						deleted_at)
			VALUES( 
				OLD.customer_id, 
                NULL,    -- coz 'customers' table has no 'account_id'
				OLD.name,
                OLD.email,
                OLD.phone,
                NOW()
			 );
		END $$
DELIMITER ;      
	
-- To see All Triggers :
 SHOW TRIGGERS ;

-- ----------------- Creating the PROCEDURES --------------------------------------
-- --------------------------------------------------------------------------------


-- Procedure 1 : A new record in 'accounts' table
DELIMITER $$
    CREATE PROCEDURE proc_new_account(
		IN cust_id INT,
        IN account_type VARCHAR(10),
        IN amount DECIMAL(10,2)
        )
      BEGIN
		 DECLARE v_msg TEXT;
		 DECLARE EXIT HANDLER FOR SQLEXCEPTION
         BEGIN
			 GET DIAGNOSTICS CONDITION 1
             v_msg = MESSAGE_TEXT;
             SELECT CONCAT('Error in Insert New Record : ', v_msg) AS new_account_error;
         END;
		-- For Insert New Records in 'accounts' :
        INSERT INTO accounts(customer_id, account_type, balance, status)
		VALUES(cust_id, account_type, amount, 'Active');
		             
	END $$
DELIMITER ;

/* Procdure 2 :
    This Inserts New Records in 'customers' and CALLs proc_new_account(),
    as Every new customer_id should have atleast 1 new account_id
*/
DELIMITER $$
    CREATE PROCEDURE proc_new_customer(
		IN cust_name VARCHAR(100),
        IN cust_email VARCHAR(100),
        IN cust_phone CHAR(10),
        IN account_type VARCHAR(10),
        IN amount DECIMAL(10,2)
    )
    BEGIN    
		DECLARE cust_id INT;
		DECLARE v_msg TEXT ;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
            SELECT CONCAT('Error in Insert New Record : ', v_msg) AS new_customer_error;
        END;
        -- Inserting New records in 'customers' table
        INSERT INTO customers(name, email, phone, created_at)
        VALUES(cust_name, cust_email, cust_phone, NOW());
        
        -- We need the LAST_INSERT_ID() to get the recent new_customer_id
        SET cust_id = LAST_INSERT_ID();
        
        -- A CALL to proc_new_account()
        CALL proc_new_account(cust_id, account_type, amount);
    END $$
DELIMITER ;
 
 
-- Procedure 3 : For Transactions

-- For 'Withdrawal' and 'Deposit'
DELIMITER $$
	CREATE PROCEDURE proc_depo_with(
		IN account_id INT,
        IN trans_type VARCHAR(100),
		IN trans_amt INT,
        IN description VARCHAR(100)
	)
	BEGIN
		DECLARE acc_id INT;
		
		DECLARE v_msg TEXT;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
			SELECT CONCAT('Error Occured on Deposit/Withdrawal : ', v_msg) AS depo_with_error;
            ROLLBACK;
		END;
		
        SET acc_id = account_id;
		
        IF trans_type NOT IN ('Withdrawal', 'Deposit') THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not Deposit/Withdrwal Transaction Type !';
		END IF;
        
        CASE trans_type
            WHEN trans_type = 'Withdrawal' THEN 
								START TRANSACTION;
									UPDATE accounts  
									   USE INDEX (PRIMARY)  -- Note this 
									   SET balance = balance - trans_amt
									WHERE account_id = acc_id 
									LIMIT 1;      -- Note This
								COMMIT;
                                
		   WHEN trans_type = 'Deposit' THEN 
                               START TRANSACTION;
								   UPDATE accounts  
									   USE INDEX (PRIMARY)  -- Note this 
									   SET balance = balance + trans_amt
									WHERE account_id = acc_id 
									LIMIT 1;      -- Note This
								COMMIT;
	END CASE; 
    
    -- Now we will insert the Deposit/Withdrawal details in 'transaction_depo_with' table
    INSERT INTO transaction_depo_with(account_id, type, amount, transaction_date, description)
			VALUES( account_id, trans_type, trans_amt, NOW(), description);
				
 END $$
DELIMITER ;

-- For 'Transfer' Transaction, we need 2 account_ids :
DELIMITER $$
	CREATE PROCEDURE proc_transfer(
		IN from_account_id INT,
		IN to_account_id INT,
		IN trans_type VARCHAR(100),
		IN trans_amt INT,
        IN description VARCHAR(100)
	)
	BEGIN
		DECLARE v_msg TEXT;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
			SELECT CONCAT('Error Occured on Transfer b/w accounts : ', v_msg) AS transfer_error;
            ROLLBACK;
		END;
		
		IF trans_type NOT IN ('Transfer') THEN
			SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Not Transfer Transaction Type!';
	    END IF;
        
       IF from_account_id = to_account_id THEN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
            SELECT CONCAT('Tranfer Transaction Error : ', v_msg) AS No_same_account_ids;
	   END IF;
       
	   IF (from_account_id != 0 AND to_account_id != 0)
	   THEN
		  START TRANSACTION;
				UPDATE accounts
						USE INDEX (PRIMARY)  -- this is becoz "updates" need reference to a key
						SET balance = balance - trans_amt
						WHERE account_id = from_account_id 
						LIMIT 1;            -- only updating 1 row at a time(though it will, even if u dont write it, just for extra enforcement)
				UPDATE accounts
						USE INDEX (PRIMARY)
						SET balance = balance + trans_amt
						WHERE account_id = to_account_id
						LIMIT 1;
			COMMIT;
		ELSE
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
            SELECT CONCAT('Transfer Transaction Error : ', v_msg) AS transfer_error;            
		END IF;
        
        -- Now we will Insert the updated Records to 'transaction_transfer' table :
	INSERT INTO transaction_transfer
	     (from_account_id, to_account_id, type, amount, description, transaction_date)
	VALUES
          (from_account_id, to_account_id, trans_type, trans_amt, description, NOW());
    
	END $$
DELIMITER ;


-- Procedure 4 : Deleting Records from 'accounts' table
DELIMITER $$
	CREATE PROCEDURE proc_delete_account(
		IN cust_id INT
	)
	BEGIN
		DECLARE v_msg TEXT;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
			SELECT CONCAT('Error Occured while deleting Account : ', v_msg) AS cant_del_account;
		END;
		
		SET SQL_SAFE_UPDATES = 0;
        
			DELETE FROM accounts
			WHERE customer_id = cust_id;
		
		SET SQL_SAFE_UPDATES = 1;
	END $$
DELIMITER ;


-- Procedure 5 : Deleting Records from 'customers' table
DELIMITER $$

	CREATE PROCEDURE proc_delete_record(
		IN cust_id INT
	)
	BEGIN
		DECLARE v_msg TEXT;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
			SELECT CONCAT('Error Occured while deleting Record : ', v_msg) AS cant_del_record;
		END;
		
        SET SQL_SAFE_UPDATES = 0;
        
        -- Manually deleting Accounts
			DELETE FROM accounts
			WHERE customer_id = cust_id;
			
			DELETE FROM customers 
			WHERE customer_id = cust_id;
		
		SET SQL_SAFE_UPDATES = 1;
	END $$
DELIMITER ;

-- Procedure 6 : Selecting the Details of an Active Customer using Views 
                                   -- with Dynamic SQL

DELIMITER $$
	CREATE PROCEDURE proc_customer_detail(IN cust_id INT)
	BEGIN
		DECLARE v_msg TEXT;

		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
			SELECT CONCAT('Error Occurred: ', v_msg) AS no_active_customer_detail;
		END;

	-- Select data 
	SET @sql_query = CONCAT('CREATE OR REPLACE VIEW active_customer_view AS ', 
		'SELECT ',
'c.customer_id, a.account_id, a.balance, c.name, c.email, c.phone, c.created_at ',
' FROM customers AS c INNER JOIN accounts AS a USING(customer_id) ',
		'WHERE c.customer_id = ', cust_id);
    
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
-- Now a View named 'active_customer_view' is created on fly by Dynamic SQL. So, 

 SET @sql_query = CONCAT ('SELECT * FROM active_customer_view');
		PREPARE stmt FROM @sql_query;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

	END $$
DELIMITER ;


-- Procedure 7 : To see no. of accounts a customer has :
DELIMITER $$
	CREATE PROCEDURE proc_accounts_per_customer(IN cust_id INT)
	BEGIN
		DECLARE v_msg TEXT;

		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
			SELECT CONCAT('Error Occurred: ', v_msg) AS no_active_customer_detail;
		END;
		
	-- Selecting the TABLES to follow up the Following Codes Working
        SELECT * FROM customers;
        SELECT * FROM accounts;
        SELECT * FROM transaction_depo_with;
        SELECT * FROM transaction_transfer;
        
	-- Select the Data :
 -- ****************** For Deposit and Withdrawals *****************************
 
	SELECT 
			c.name, c.customer_id, a.account_id, c.phone, c.email ,
            a.account_type AS Account_Type,
            SUM( DISTINCT a.balance) AS Net_Balance,
            COUNT( t.transaction_id) AS Total_Deposit_Withdrawal, 
			CASE
				WHEN t.type = 'Deposit' THEN SUM(t.amount) 
				ELSE NULL
			END AS Total_Deposit,
            CASE
				WHEN t.type = 'Withdrawal' THEN SUM(t.amount) 
				ELSE NULL
			END AS Total_Withdrawal
                        
	        FROM customers AS c INNER JOIN accounts AS a
		     ON c.customer_id = a.customer_id
		LEFT JOIN transaction_depo_with AS t
             ON a.account_id = t.account_id
             
		WHERE c.customer_id = cust_id
        GROUP BY
               c.name, a.account_id, t.type, c.phone, c.email ;
               
               
  -- ****************** For Transfers ***************************************
        SELECT 
			c.name, c.customer_id, a.account_id, c.phone, c.email ,
            a.account_type AS Account_Type,
            SUM( DISTINCT a.balance) AS Net_Balance,
            COUNT( t.transaction_id) AS Total_Transfer ,
            CASE
				WHEN t.type = 'Transfer' THEN SUM(t.amount) 
				ELSE NULL
			END AS Total_Transfer
            
	        FROM customers AS c INNER JOIN accounts AS a
		     ON c.customer_id = a.customer_id
		  LEFT JOIN transaction_transfer AS t
			 ON a.account_id = t.from_account_id
             OR a.account_id = t.to_account_id
             
		WHERE c.customer_id = cust_id
        GROUP BY
               c.name, a.account_id, t.type, c.phone, c.email ;
	END $$
DELIMITER ;

-- --------------------------- Wrapping up Procedures --------------------------
-- -----------------------------------------------------------------------------
/* 
	We wil be Wrapping Procedures to catch Argument parsing errors :
    Like Phone No. should be Only 10 Digits, Email must contain '@', 
    datatype mismatch which is outside routine’s own error‐handler machinery.
     
        So we will wrap our procedures inside outer procedures
	
*/

-- 1. To Wrap proc_new_customer()
DELIMITER $$
	CREATE PROCEDURE wrap_proc_new_customer(
		IN cust_name VARCHAR(100),
        IN cust_email VARCHAR(100),
        IN cust_phone VARCHAR(100),
        IN account_type VARCHAR(100),
        IN amount VARCHAR(100)
    )
    BEGIN
		DECLARE v_msg TEXT;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
            SELECT CONCAT('Error on new_customer_insert : ', v_msg) AS new_cust_error;
		END ;
        
        -- All the check conditions for arguments :
        IF cust_email NOT LIKE '%@%' THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Email';
		END IF;
        
        IF account_type NOT IN ('Current', 'Savings') THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Account type';
		END IF;
        
        -- if its Not a 10 digit Number
        IF NOT cust_phone REGEXP '^[0-9]{10}$' THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Phone No.';
		END IF;
        
        SET amount = CAST(amount AS DECIMAL(10, 2));
        
        CALL proc_new_customer(cust_name, cust_email, cust_phone, account_type, amount);
    END $$
DELIMITER ;

-- 2. To Wrap proc_new_account()
DELIMITER $$
	CREATE PROCEDURE wrap_proc_new_account(
		IN cust_id VARCHAR(100),
        IN account_type VARCHAR(100),
        IN amount VARCHAR(100)
    )
    BEGIN
		DECLARE v_msg TEXT;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
            SELECT CONCAT('Error on new_account_insert : ', v_msg) AS new_account_error;
		END ;
        
        SET cust_id = CAST(cust_id AS UNSIGNED);
        
        IF account_type NOT IN ('Current', 'Savings') THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Account type';
		END IF;
        
        SET amount = CAST(amount AS DECIMAL(10, 2));
        
        CALL proc_new_account(cust_id, account_type, amount);
    END $$
DELIMITER ;

-- 3. To Wrap proc_depo_with()
DELIMITER $$
	CREATE PROCEDURE wrap_proc_depo_with(
		IN account_id VARCHAR(100),
		IN trans_type VARCHAR(100),
		IN trans_amt VARCHAR(100),
        IN description VARCHAR(100)
    )
    BEGIN
		DECLARE v_msg TEXT;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
            SELECT CONCAT('Error on Withdrwal/Deposit : ', v_msg) AS depo_with_error;
		END ;
        
        SET account_id = CAST(account_id AS UNSIGNED);
        
        IF trans_type NOT IN ('Withdrawal', 'Deposit') THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Transaction type';
		END IF;
        
        SET trans_amt = CAST(trans_amt AS DECIMAL(10,2));
        
        CALL proc_depo_with( account_id, trans_type, trans_amt, description);
    END $$
DELIMITER ;


-- 4. To Wrap wrap_proc_transfer()
DELIMITER $$
	CREATE PROCEDURE wrap_proc_transfer(
	IN from_account_id VARCHAR(100),
    IN to_account_id VARCHAR(100),
	IN trans_type VARCHAR(100),
    IN trans_amt VARCHAR(100),
    IN description VARCHAR(100)
)
    BEGIN
		DECLARE v_msg TEXT;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
            SELECT CONCAT('Error on Transfer b/w accounts : ', v_msg) AS transfer_error;
		END ;
        
        SET from_account_id = CAST(from_account_id AS UNSIGNED);
        
        SET to_account_id = CAST(to_account_id AS UNSIGNED);
        
        IF trans_type NOT IN ('Transfer') THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Transaction type';
		END IF;
        
        SET trans_amt = CAST(trans_amt AS DECIMAL(10, 2));
        
        CALL proc_transfer( from_account_id, to_account_id, trans_type, trans_amt, description);
    END $$
DELIMITER ;


-- To see All Procedures:
 SHOW PROCEDURE STATUS WHERE Db = DATABASE();

-- ---------------------------- Main Demo Statements ---------------------------
-- -----------------------------------------------------------------------------

-- 1a. To Insert a New Record
CALL wrap_proc_new_customer('MySQL', 'MySQL@gmail.com', '1357924680','Savings', 1000);
  -- SELECT * FROM customers;
  -- SELECT * FROM accounts;

-- 1b. To Insert an existing email : Duplicate Key Error Message
--    CALL wrap_proc_new_customer('PostgreSQL', 'MySQL@gmail.com', '3366882299', 'Current', 2000);

-- To Insert erronous Phone No. 
--    CALL wrap_proc_new_customer('PostgreSQL', 'PostgreSQL@gmail.com', '3366a@82299', 'Current', 2000);

-- 2.a To make a Transaction by Withdrwal/deposit Methods
CALL wrap_proc_depo_with(102, 'Withdrawal', 2000, 'Just a Withdrawal of money');
-- SELECT * FROM accounts;
-- SELECT * FROM transaction_depo_with;

-- 2.b To make a Transaction by Transfer between accounts
CALL wrap_proc_transfer(101, 105, 'Transfer', 4000, 'Just a Transfer of money');
-- SELECT * FROM accounts;
-- SELECT * FROM transaction_transfer;

-- 2.c To hold Errors by Transfer between accounts
CALL wrap_proc_transfer(101, 102, 'Withdrawal', 2000, 'Just a Transfer of money');  
                                         -- Error Catch: Should be 'Transfers'
-- SELECT * FROM accounts;
-- SELECT * FROM transaction_transfer;

-- 3. To create more new account_ids for a given customer_id
CALL wrap_proc_new_account(3, 'Current', 1500);
-- SELECT * FROM accounts;

-- 4.a To see details of a customer
CALL proc_customer_detail(3);

-- 4.b To see the Summary of ALL accounts for a Customer
CALL proc_accounts_per_customer(1);

-- 5.a To Delete an Account
CALL proc_delete_account(4);
-- SELECT * FROM accounts;


-- 5.a To Delete a Record
CALL proc_delete_record(3);

CALL proc_delete_record(5);

-- SELECT * FROM customers;
-- SELECT * FROM accounts;
-- SELECT * FROM account_log_table;
-- SELECT * FROM transaction_depo_with;
-- SELECT * FROM transaction_transfer;
 
-- A customized look to the account_log_table 
/*
SELECT 
	    customer_id,
        COALESCE(account_id, 'Account ids :') AS account_id,
        name,
        email,
        phone,
        deleted_at
FROM account_log_table
 ORDER BY
		customer_id,
		CASE
			WHEN account_id IS NULL THEN 0
            ELSE 1
		END;

*/