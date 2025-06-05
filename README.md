# 🏦 Banking Management System using MySQL

This project is a fully functional **Banking Database System** built using **MySQL**. It simulates real-world banking operations like account creation, deposits, withdrawals, transfers, deletions, logging, and more — all through a structured, normalized database with **procedures**, **triggers**, and **error handling**.

---

## 📌 Features

- ✅ Normalized Database Design
- ✅ Multiple account types per customer
- ✅ Supports deposits, withdrawals, and transfers
- ✅ Detailed transaction tracking
- ✅ Automatic logging of deleted accounts
- ✅ Custom procedures for dynamic querying and account management
- ✅ Trigger-based validation and backup
- ✅ Wrapped procedures for runtime input validation

---

## 🗃️ Database Schema

### 📁 `customers`
- `customer_id` (PK)
- `name`, `email`, `phone`
- Validations: phone format, email format, uniqueness

### 💳 `accounts`
- `account_id` (PK), `customer_id` (FK)
- `account_type`, `balance`, `status`
- Validations: minimum balance, account status

### 💰 `transaction_depo_with`
- Deposit & withdrawal records
- Tracks amount, time, description

### 🔁 `transaction_transfer`
- Logs fund transfers between two accounts

### 🧾 `account_log_table`
- Stores deleted account/customer info for auditing

---

## ⚙️ Functionalities via Stored Procedures

### 1. `proc_new_customer`  
➡️ Adds a customer and their first account

### 2. `proc_new_account`  
➡️ Adds a new account to an existing customer

### 3. `proc_depo_with`  
➡️ Handles deposits and withdrawals with validation

### 4. `proc_transfer`  
➡️ Handles fund transfers between accounts

### 5. `proc_delete_account`  
➡️ Deletes all accounts of a given customer

### 6. `proc_delete_record`  
➡️ Deletes a customer only after deleting their accounts

### 7. `proc_customer_detail`  
➡️ Creates a dynamic view for a customer's active accounts

### 8. `proc_accounts_per_customer`  
➡️ Returns summaries of a customer's balances and transactions

---

## ⚠️ Triggers

### `trigger_check_neg_bal`  
- Prevents accounts from going below ₹200 balance

### `trigger_log_deleted_account`  
- Logs deleted account data into `account_log_table`

### `trigger_log_deleted_customer`  
- Logs deleted customer data for audit

---

## 🧪 Data Validation via Wrapper Procedures

Wrapper procedures such as `wrap_proc_new_customer`, `wrap_proc_transfer`, etc., include:
- Phone number regex checks
- Email format validation
- Account type checks
- Type-safe conversions for inputs

These prevent malformed data or misuse during procedure calls.

---

## 🚀 How to Run This Project

1. Open MySQL Workbench or CLI
2. Paste contents of `BANKING_DB_Final_Interview_Ready.sql`
3. Execute the script to create tables, procedures, and sample data
4. Try demo calls at the end of the script like:

```sql
CALL wrap_proc_new_customer('Alice', 'alice@email.com', '9876543211', 'Savings', 1000);
CALL wrap_proc_depo_with(102, 'Deposit', 2000, 'Bonus credited');
CALL proc_customer_detail(1);


## Author
Sharnima | [LinkedIn](https://www.linkedin.com/in/sharnima-mallik-50464027b)

Please **DO NOT MODIFY** the code in this repository. If you'd like to make changes, fork the repository to your own GitHub account.
