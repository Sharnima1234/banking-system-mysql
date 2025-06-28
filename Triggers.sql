
-- ----------------- Creating the TRIGGERS ----------------------------------------
-- --------------------------------------------------------------------------------


-- 1. To Check for Minimum balance in 'accounts' table before any withdrawal is done

DELIMITER $$
	CREATE TRIGGER trigger_check_min_bal
		BEFORE UPDATE
		ON accounts
	 FOR EACH ROW
		BEGIN
			IF NEW.balance < 100 
			THEN
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient Balance! Minimum balance of ₹100 must be maintained.';
            END IF;
       END $$
DELIMITER ;		



-- 2. To log down records for any 'account_id' deleted :

DELIMITER $$
  CREATE TRIGGER trigger_log_deleted_account
		AFTER DELETE
		ON accounts
	-- For 'accounts' table
  FOR EACH ROW
		BEGIN
			INSERT INTO closed_account_log_table(
								customer_id,
								account_id,   
								name,
								email,
								phone,
								deleted_at
						    	)
			SELECT 
				OLD.customer_id,
	            OLD.account_id,
				c.name,
	            c.email,
	            c.phone,
	            NOW()
          FROM
	         customers AS c
          WHERE
         	c.customer_id = OLD.customer_id;
     END $$
DELIMITER ;




-- 3. To log down All the related 'account_ids' for a 'customer_id' being deleted
DELIMITER $$
	CREATE TRIGGER trigger_log_deleted_customer
		AFTER DELETE 
		ON customers
		
	-- For 'customers' table
	FOR EACH ROW
		BEGIN
			INSERT INTO closed_customer_acc_log_table(
								customer_id,
								name,
								email,
								phone,
								deleted_at
							)
             VALUES( 
				OLD.customer_id, 
				OLD.name,
                OLD.email,
                OLD.phone,
                NOW()
			 );
   END $$
DELIMITER ;     



-- To see All Triggers :
 SHOW TRIGGERS ;

