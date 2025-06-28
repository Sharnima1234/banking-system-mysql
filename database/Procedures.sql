

-- ----------------- Creating the PROCEDURES --------------------------------------
-- --------------------------------------------------------------------------------


/*
 This procedure 1 can only run , if an existing customer_id is there.
 For new customers, we will run Procedure 2 first, which has the creation of
 new customer_id, foolowed by a CALL to below Procedure 1. For existing customer_ids,
 we can independently give a CALL to Procedure 1.
*/

-- Procedure 1 : A new record in 'accounts' table
DELIMITER $$
    CREATE PROCEDURE proc_new_account(
		IN cust_id INT,
        IN account_type ENUM('Savings', 'Current'),
        IN amount DECIMAL(10, 2)
        )
      BEGIN
		 DECLARE v_msg TEXT;
		 DECLARE EXIT HANDLER FOR SQLEXCEPTION
         BEGIN
			 GET DIAGNOSTICS CONDITION 1
             v_msg = MESSAGE_TEXT;
             SELECT CONCAT('Error in Insert New Account Record : ', v_msg) AS new_account_error;
         END;

        IF NOT EXISTS (
				SELECT 1
				FROM customers
				WHERE customer_id = cust_id
				) 
		THEN 
		    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer Id Not Found !';
		ELSE
		  -- For Insert New Records in 'accounts' :
			INSERT INTO accounts(customer_id, account_type, balance)
			VALUES(cust_id, account_type, amount);
	    END IF;
        
END $$
DELIMITER ;



/* 
    This Inserts New Records in 'customers' and CALLs proc_new_account(),
    as Every new customer_id should have atleast 1 new account_id
*/

-- Procdure 2 :
DELIMITER $$
    CREATE PROCEDURE proc_new_customer(
		IN cust_name VARCHAR(100),
        IN cust_email VARCHAR(100),
        IN cust_phone CHAR(14),
        IN account_type ENUM('Savings', 'Current'),
        IN amount DECIMAL(10, 2)
    )
    BEGIN    
		DECLARE cust_id INT;
		DECLARE v_msg TEXT ;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
            SELECT CONCAT('Error in Insert New Customer Record : ', v_msg) AS new_customer_error;
        END;
        
        -- Checking if valid, unique mail and phone is given : 
        IF EXISTS(SELECT 1 FROM customers WHERE email = cust_email) 
          THEN 
             SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This Mail ID is already registered! Give another Mail ID.';
        
        ELSEIF EXISTS(SELECT 1 FROM customers WHERE phone = cust_phone)
        THEN 
             SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This Phone Number is already registered! Give another Phone Number.';
        
        END IF; 
        
       -- Inserting New records in 'customers' table
        INSERT INTO customers(name, email, phone, created_at)
          VALUES(cust_name, cust_email, cust_phone, NOW());

       -- We need the LAST_INSERT_ID() to get the recent new_customer_id
        SET cust_id = LAST_INSERT_ID();

        -- A CALL to proc_new_account()
        CALL proc_new_account(cust_id, account_type, amount);

    END $$

DELIMITER ;



-- Procedure 3 : To log every transaction into 'transactions' table 
DELIMITER $$
      CREATE PROCEDURE proc_log_transaction(
                  IN self_account_id INT,
				  IN other_account_id INT ,
				  IN transfer_type VARCHAR(100),  
				  IN deposit_withdrawal VARCHAR(100),  
				  IN transfer_amt DECIMAL(10, 2),
			      IN transaction_description VARCHAR(100)
                        )
       BEGIN 
	       DECLARE v_msg TEXT ;
		   DECLARE EXIT HANDLER FOR SQLEXCEPTION
           BEGIN
			    GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
                SELECT CONCAT('Error in Inserting Transaction Records : ', v_msg) AS log_transaction_error;
           END;

      -- Logging the Transactions into 'transactions' table
	        INSERT INTO transactions ( 
									    self_account_id,
									    Other_account_id,
									    transfer_type,    
	                                    deposit_withdrawal,   
	                                    transfer_amt,
									    transaction_description
									  )
                 VALUES (
                        self_account_id,
						other_account_id,
				        transfer_type,   
                        deposit_withdrawal,   
                        transfer_amt,
						transaction_description
                      );
    END $$
DELIMITER ;



-- Procedure 4 : For Transactions 
DELIMITER $$ 

	CREATE PROCEDURE proc_transaction(
				IN self_account_id INT,
				IN other_account_id INT ,
				IN transfer_type VARCHAR(100),  
                IN deposit_withdrawal VARCHAR(100),  
				IN transfer_amt DECIMAL(10, 2),
				IN transaction_description VARCHAR(100) 
			)
		BEGIN	
		   DECLARE is_self_account_valid BOOLEAN DEFAULT FALSE;
           DECLARE is_other_account_valid BOOLEAN DEFAULT FALSE;

		   DECLARE v_msg TEXT;
		   DECLARE EXIT HANDLER FOR SQLEXCEPTION
		   BEGIN
			    GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
			    SELECT CONCAT('Error Occured on Transaction  : ', v_msg) AS transfer_error;
                ROLLBACK;
           END;
		   
		   
		   
		   
      -- ------------------------ Error Handling Logic ---------------------------  
	  
      -- Checking wether the 'self_account_id' and 'other_account_id' is Valid and Existing, and setting a BOOLEAN value accordingly
			   SELECT EXISTS (
		                       SELECT 1
                               FROM accounts
		                       WHERE account_id = self_account_id
							 )
	           INTO
		             is_self_account_valid;
							
			   SELECT EXISTS (
		                       SELECT 1
		                       FROM accounts
		                       WHERE account_id = other_account_id
							 )
	           INTO
		             is_other_account_valid;
			   
			   
			   
		-- Case 1 : Self account id is Invalid                      
		IF transfer_type = 'Self Transfer'
		      AND ( self_account_id IS NULL
			          OR  
			        is_self_account_valid = FALSE  
			        )
			   THEN
	               SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Self Transfer requires valid self_account_id';
		
		
		
		-- Case 2 : Self Transfer, but only other_account_id is given or both Account ids given        
		ELSEIF transfer_type = 'Self Transfer'
		      AND NOT ( other_account_id IS NULL
			            OR other_account_id = 0 )
			  THEN
	                 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Self Transfer should Only have Valid self_account_id , Other_account_id should be set to 0';
		
		
		
		-- Case 3 : 'Account to Account Transfer', but one or both account ids are not in list
		ELSEIF transfer_type = 'Account to Account Transfer'
		       AND ( self_account_id IS NULL OR is_self_account_valid = FALSE
			         OR 
			         other_account_id IS NULL OR is_other_account_valid = FALSE
			        )
			   THEN
	               SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account to Account Transfer requires Valid Account Ids';
		
		
		
		-- Case 4 : Account to Account Transfer, but both are same account ids
		ELSEIF transfer_type = 'Account to Account Transfer'
		         AND self_account_id = other_account_id 
		THEN
	        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account to Account Transfer requires different account ids';
		
		
		
		-- Case 5 : 'Self Transfer' but deposit_withdrawal not in ('Self Deposit', 'Self Withdrawal')
	    ELSEIF transfer_type = 'Self Transfer'
		       AND deposit_withdrawal NOT IN ('Self Deposit', 'Self Withdrawal') 
		THEN 
	        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Choose correct transaction type under Self Transfer';
		
		
		
		-- Case 6 : 'Account to Account Transfer' but deposit_withdrawal not in ('Transfer In', 'Transfer Out')
	    ELSEIF transfer_type = 'Account to Account Transfer'
		      AND deposit_withdrawal NOT IN ('Transfer In', 'Transfer Out') 
		THEN
	         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Choose correct transaction type under Account to Account Transfer';
		
		
		
		-- Case 7 : If transfer_amt is NULL or <=0
	    ELSEIF transfer_amt IS NULL
		          OR transfer_amt <= 0 
		THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transfer amount must be greater than zero';
		
		
		
		
		
		
		-- ******************************** Transaction Logic here ********************************************************
		
		-- Case 8 : Self Account Transactions
		ELSEIF transfer_type = 'Self Transfer'
		         AND deposit_withdrawal IN ('Self Deposit', 'Self Withdrawal')
		         AND is_self_account_valid = TRUE
		         AND ( other_account_id IS NULL
			           OR other_account_id = 0 ) 
		THEN
		    START TRANSACTION;
		        IF deposit_withdrawal = 'Self Withdrawal'
		        THEN 
		            UPDATE accounts
	                     SET balance = balance - transfer_amt
	                WHERE account_id = self_account_id;
			                              
			                           
		        ELSEIF deposit_withdrawal = 'Self Deposit'
		        THEN 
		            UPDATE accounts
	                     SET balance = balance + transfer_amt
	                WHERE account_id = self_account_id;
	            END IF;
		        
		        
	           -- For "Self Transfers", we will pass Other_account_id as NULL
                CALL proc_log_transaction(self_account_id, NULL, transfer_type, deposit_withdrawal, transfer_amt, transaction_description); 
			        
           COMMIT;
           
           SELECT CONCAT('Transaction successful for ACC_', self_account_id ) AS transfer_result;

           
           
	-- Case 9 : Account to Account transaction
    ELSEIF transfer_type = 'Account to Account Transfer'
	         AND deposit_withdrawal IN ('Transfer In', 'Transfer Out')
	         AND is_self_account_valid = TRUE
	         AND is_other_account_valid = TRUE
	         AND self_account_id != other_account_id
     THEN
		 START TRANSACTION; 
		       IF deposit_withdrawal = 'Transfer Out'
		       THEN 
				    UPDATE accounts
	                    SET balance = balance - transfer_amt
	                WHERE account_id = self_account_id;
			        
			        UPDATE accounts
	                     SET balance = balance + transfer_amt
	                 WHERE account_id = other_account_id;  
			                                  
		        ELSEIF deposit_withdrawal = 'Transfer In' 
		        THEN 
		            UPDATE accounts
	                     SET balance = balance - transfer_amt
	                WHERE account_id = other_account_id;
			              
			        UPDATE accounts
	                     SET balance = balance + transfer_amt
	                WHERE account_id = self_account_id;
	            END IF;
			           
			    
			   CALL proc_log_transaction(self_account_id, other_account_id, transfer_type, deposit_withdrawal, transfer_amt, transaction_description);
			           
		  COMMIT;
		  
		  SELECT CONCAT('Transaction successful between ', 'ACC_', self_account_id, ' and ', 'ACC_', other_account_id) AS transfer_result;

		  
		  
	-- Case 10 : All other cases
	ELSE
	     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unhandled transaction case';
	END IF;
  END $$
DELIMITER ;



-- Procedure 5 : To view active customer's transaction details 
DELIMITER $$ 

CREATE PROCEDURE proc_trans_details_of_cust(IN cust_id INT)
    BEGIN
		DECLARE v_msg TEXT;

		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
			SELECT CONCAT('Error Occurred: ', v_msg) AS no_customer_trans_detail;
        END;
		
	    IF NOT EXISTS (
                     SELECT 1
                     FROM customers
                     WHERE customer_id = cust_id
                     ) 
	  THEN 
	     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer Id Not Found!';
      
	  ELSE
          SELECT
			  c.name AS Name,
			  concat("CUST_", c.customer_id) AS Customer_id,
	          concat("ACC_", t.self_account_id) AS Account_id,
			  a.account_type AS Account_type, 
			  t.transfer_type AS Transfer_type,
			  concat("TRAN_", t.transaction_id) AS Transaction_id,
			  CASE 
				  WHEN t.deposit_withdrawal IN ('Self Deposit', 'Transfer In') THEN 'Credit'
		          WHEN t.deposit_withdrawal IN ('Self Withdrawal', 'Transfer Out') THEN 'Debit'
	          END AS Credit_Debit,
							            
			  CASE  
				   WHEN t.deposit_withdrawal IN ('Self Deposit', 'Transfer In') THEN concat('+ ₹', format(t.transfer_amt, 2) )
		           WHEN t.deposit_withdrawal IN ('Self Withdrawal', 'Transfer Out') THEN concat('- ₹', format(t.transfer_amt, 2) )
	          END AS Transfer_Amount,
							            
			  t.transaction_date AS Transaction_date
			  
         FROM 
			customers AS c INNER JOIN accounts AS a 
			ON c.customer_id = a.customer_id
	        INNER JOIN transactions AS t 
	        ON a.account_id = t.self_account_id
	    WHERE
		    a.customer_id = cust_id;
         
     END IF;
   END $$
DELIMITER ;



-- Procedure 6 : Deleting an account_id related to a customer_id from 'accounts' table
DELIMITER $$
	CREATE PROCEDURE proc_delete_account(
		IN cust_id INT,
		IN acc_id INT
	    )
	BEGIN
		DECLARE v_msg TEXT;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
			SELECT CONCAT('Error Occured while deleting Account : ', v_msg) AS cant_del_account;
        END;
		
        IF NOT EXISTS (
                    SELECT 1
                    FROM customers
                    WHERE customer_id = cust_id
                    )
       THEN SIGNAL SQLSTATE '45000' SET message_text = 'Customer Id Not found !';
        
        ELSEIF
       -- The account id should be related to the customer id
             NOT EXISTS (
                         SELECT 1
                         FROM accounts
                         WHERE account_id = acc_id AND customer_id = cust_id
                        )
        THEN 
        SIGNAL SQLSTATE '45000' SET message_text = 'Account Id Not found for given Customer Id !';
       
        ELSE 
			 SET SQL_SAFE_UPDATES = 0;
        
		          DELETE FROM accounts
                  WHERE account_id = acc_id;
					
	    	 SET SQL_SAFE_UPDATES = 1;
	    	 
	    	 
	-- This is to check if any customer_id occurs in 'customers' table, but no related account_id in 'accounts' table
	-- Left Join gives all customer_ids from customers and exsting/non-existing customer ids from accounts table	
				IF EXISTS(
				       SELECT 1 
				       FROM customers c
			           LEFT JOIN accounts a ON c.customer_id = a.customer_id
			           WHERE c.customer_id = cust_id AND a.customer_id IS NULL 
			        )
			    THEN
			    
			    SET SQL_SAFE_UPDATES = 0;
			        
		             DELETE FROM customers
                     WHERE customer_id = cust_id; 
			      
			    SET SQL_SAFE_UPDATES = 1;
               
			    END IF; -- end if for checking customers with no account_id
       
        END IF;   -- final end if to find valid customer_id and account_id
    END $$
DELIMITER ;



-- Procedure 7 : Deleting Records from 'customers' table and related 'account_ids' too
DELIMITER $$

	CREATE PROCEDURE proc_delete_customer_record(
		IN cust_id INT
	   )
	BEGIN
		DECLARE v_msg TEXT;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
			SELECT CONCAT('Error Occured while deleting Customer Record : ', v_msg) AS cant_del_record;
        END;
		
	   IF NOT EXISTS (
                 SELECT 1
                 FROM customers
                 WHERE customer_id = cust_id
                 ) 
	   THEN SIGNAL SQLSTATE '45000' SET message_text = 'Customer Id Not Found !';

	   ELSE
         -- Wrapping inside transaction, so that if any error , deleted customer_id with related account_ids gets restored
		   START TRANSACTION;
		        SET SQL_SAFE_UPDATES = 0;
                        
	               -- Deleting Account Ids 
					DELETE FROM accounts
                    WHERE customer_id = cust_id;
	               
	              -- Deleting Customer Ids
					DELETE FROM customers
                    WHERE customer_id = cust_id;
				
				SET SQL_SAFE_UPDATES = 1;
		   COMMIT;
      END IF;
   END $$
DELIMITER ;



-- Procedure 8 : Selecting the Details of an Active Customer
DELIMITER $$
	CREATE PROCEDURE proc_active_customer_details(IN cust_id INT)
	BEGIN
		DECLARE v_msg TEXT;

		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
			SELECT CONCAT('Error Occurred: ', v_msg) AS no_active_customer_detail;
        END;
		
        IF NOT EXISTS (
                 SELECT 1
                 FROM customers
                 WHERE customer_id = cust_id
                 ) 
	    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer Id Not Found!';
        
        ELSE
	       SELECT 
	            c.name AS Name,
	            c.email AS Mail_Id,
	            c.phone AS Phone,
				concat("CUST_", c.customer_id) AS Customer_id,
				concat("ACC_", a.account_id) AS Account_id,
				concat('₹', format(a.balance, 2) ) AS Balance,
				a.created_at AS Created_At
           FROM
	          customers AS c INNER JOIN accounts AS a USING(customer_id)
           WHERE c.customer_id = cust_id;
        
       END IF;
   END $$
DELIMITER ;



-- To see All Procedures:
 SHOW PROCEDURE STATUS WHERE Db = DATABASE();