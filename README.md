# 🏦 Banking Management System ( Excel + MySQL + VBA)

This project is a Banking Management System built using MySQL for the backend and Excel with VBA for the frontend. It simulates how a bank manages its customers, accounts, 
 transactions, and logs using automation, stored procedures, and database triggers.

---

## 📌 Features : 


      - 👤 Create Customers : Add customers and automatically create an associated account

      - 💳 Add Accounts : Link new accounts to existing customers

      - 💸 Execute Transactions : Transfer money using self/other account IDs; handles transaction logs

      - 🧾 View Transaction History : Detailed customer-wise transaction report using stored procedures

      - 🗑️ Delete Account ID : Deletes specific account for a customer and logs it

      - ❌ Delete Customer ID : Deletes customer and related accounts, wrapped in transaction safety

      - 📊 Reporting : View logs and account summaries with ROLLUP reports

      - 🔁 Automation in Excel : All operations are done via macro buttons using VBA and ADO


---


## ⚙️ Technologies Used : 

      - MySQL (Designed and normalized schema)

      - Stored Procedures (for transactions, insert, delete, join logic)

      - Triggers (to log deletions into closed_* log tables)

      - Transactions (for safe delete operations)

      - Excel + VBA (Macro Buttons)

      - ODBC Connector for Excel to MySQL integration


---


## 📁 Project Structure : 

	- banking-system-mysql/
	- ├── database/
	- │   ├── Create Tables.sql       # All CREATE TABLEs (customers, accounts, transactions...)
	- │   ├── Procedures.sql          # Stored procedures like add_customer, delete_account, etc.
	- │   ├── Triggers.sql            # Triggers for closed account and customer logs
	- │   
	- │
	- ├── excel_frontend/
	- │   ├── GitHub - Banking Project using MySQL with VBA Excel.xlsm           # Excel file with macro buttons
	- │   └── VBA_Code_Front-End.bas     # VBA module code (cleaned of credentials)
	- │
	- ├── screenshots/
	- │   ├── Create New Customer ID, Account ID, Transactions.png      
	- │   └── Customers and Accounts Log Table.png        
	- │   └── Transactions Log.png                       
	- │   └── Pivot Table to show Highest Number of Accounts per Customer and Highest Transactions.png        
	- │   └── Active Customer Details.png                
	- │   └── Log of All Deleted Account IDs.png         
	- │   └── Log of All Deleted Customer IDs.png        
	- │
	- ├── README.md                   



---

## 📄 Database Tables : 

	- customers: Stores customer_id, name, email, phone, created_at

	- accounts: Linked to customers, stores balance, account_type, created_at

	- transactions: Stores transfer details using self and other account_id

	- closed_account_log_table: Trigger-based log for deleted accounts

	- closed_customer_acc_log_table: Trigger-based log for deleted customers


---

## 🧠 Stored Procedures Used :

	- proc_new_customer: Adds a customer and one default account

	- proc_new_account: Adds additional accounts to existing customer
         
        - proc_transaction : Executes a transfer with logic based on type

        - proc_log_transaction: Logs the Transactions to the transactions table

	- proc_active_customer_details: Shows active customer profile with join logic

	- proc_trans_details_of_cust: Shows transaction history for customer

	- proc_delete_account: Deletes account (and customer if no accounts remain)

	- proc_delete_customer_record: Deletes customer and all linked accounts using a transaction


---

## 🪝 Triggers : 

        - trigger_check_min_bal : Checks if minimum balance is Rs 100

	- trigger_log_deleted_account: Logs account info into closed_account_log_table after delete

	- trigger_log_deleted_customer: Logs customer info into closed_customer_acc_log_table after delete



---

## 📊 Sample Reports/Visuals : 

	- Pivot tables and charts used to visualize number of transactions vs. total amount per account

	- Log tables show which customer/account was deleted and when


---

## 🧰 Tools Used : 

	- MySQL (used DBeaver as client)

	- ODBC Connector set up (DSN name: MySQL_Excel)

        - Excel with Macro support (.xlsm)

	- Front-End : Basic knowledge of VBA to automate the process 



---

## 🔐 Important Setup Note : 

	- In VBA, I used placeholder connection strings like :
	-	connStr = "DSN=MySQL_Excel;UID=your_username;PWD=your_password;" 
        -    You may replace this with your own credentials


---

## 🚀 Getting Started :

	- Clone or download the repository

	- Set up the database using Create Tables.sql, Procedures.sql, and Triggers.sql

	- Connect Excel to MySQL via ODBC (use DSN: MySQL_Excel)

	- Load the Excel_Front-End.xlsm, Enable Macros

	- Use the buttons in Excel to perform operations


## Author
Sharnima | [LinkedIn](https://www.linkedin.com/in/sharnima-mallik-50464027b)

Please **DO NOT MODIFY** the code in this repository. If you'd like to make changes, fork the repository to your own GitHub account.
