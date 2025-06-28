Attribute VB_Name = "Module1"

' === Constants for ADODB types ===
Const adVarChar = 200
Const adChar = 129
Const adDouble = 5
Const adParamInput = 1

' === Email Validation ===
Function IsValidEmail(email As String) As Boolean
    Dim re As Object
    Set re = CreateObject("VBScript.RegExp")
    With re
        .Pattern = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
        .IgnoreCase = True
        .Global = False
    End With
    IsValidEmail = re.Test(email)
End Function

' === Phone Validation ===
Function IsValidPhone(phone As Variant) As Boolean
    Dim re As Object
    On Error GoTo InvalidInput
    phone = Trim(CStr(phone))
    If Left(phone, 1) = "'" Then phone = Mid(phone, 2)
    Do While InStr(phone, "  ") > 0
        phone = Replace(phone, "  ", " ")
    Loop

    Set re = CreateObject("VBScript.RegExp")
    With re
        .Pattern = "^\+91\s?[0-9]{10}$"
        .IgnoreCase = False
        .Global = False
    End With

    IsValidPhone = re.Test(phone)
    Exit Function
InvalidInput:
    IsValidPhone = False
End Function

' === Clean Cell Format to Text ===
Sub CleanCustomerFields(selectedRange As Range)
    Dim cell As Range
    For Each cell In selectedRange
        If Not IsEmpty(cell.Value) Then
            If cell.Hyperlinks.Count > 0 Then cell.Hyperlinks.Delete
            cell.NumberFormat = "@"
            cell.Value = CStr(cell.Value)
        End If
    Next cell
End Sub

' === MAIN PROCEDURE to Create a Customer ID and automatically an Account ID ===

Sub SubmitCustomerAndFirstAccount()
    On Error GoTo ErrHandler

    Dim conn As Object, cmd As Object, rs As Object  ' ?? Added rs
    Dim connStr As String
    Dim custName As String, custEmail As String, custPhone As String
    Dim acctType As String, openingBalance As Variant
    Dim ws As Worksheet: Set ws = ActiveSheet

    ' Step 1: Clean Fields
    Call CleanCustomerFields(ws.Range("E4:F4"))

    ' Step 2: Read Inputs
    custName = Trim(ws.Range("D4").Value)
    custEmail = Trim(ws.Range("E4").Value)
    custPhone = Trim(ws.Range("F4").Value)
    acctType = Trim(ws.Range("G4").Value)
    openingBalance = ws.Range("H4").Value

    ' Step 3: Validation
    If custName = "" Or custEmail = "" Or custPhone = "" Or acctType = "" Then
        MsgBox "All fields are required.", vbExclamation
        Exit Sub
    End If

    If Not IsValidEmail(custEmail) Then
        MsgBox "Invalid email format.", vbExclamation
        Exit Sub
    End If

    If Not IsValidPhone(custPhone) Then
        MsgBox "Invalid phone number. Format: +91 9876543210", vbExclamation
        Exit Sub
    End If

    If Not IsNumeric(openingBalance) Or openingBalance < 100 Then
        MsgBox "Balance must be a number of at least 100.", vbExclamation
        Exit Sub
    End If

    ' Step 4: Connect and Call Procedure
    Set conn = CreateObject("ADODB.Connection")
    Set cmd = CreateObject("ADODB.Command")
    connStr = "DSN=MySQL_Excel;UID=your_username;PWD=your_password;"
    conn.Open connStr

    With cmd
        .ActiveConnection = conn
        .CommandText = "CALL proc_new_customer(?, ?, ?, ?, ?)"
        .CommandType = 1
        .Parameters.Append .CreateParameter("cust_name", adVarChar, adParamInput, 100, custName)
        .Parameters.Append .CreateParameter("cust_email", adVarChar, adParamInput, 100, custEmail)
        .Parameters.Append .CreateParameter("cust_phone", adChar, adParamInput, 14, custPhone)
        .Parameters.Append .CreateParameter("account_type", adVarChar, adParamInput, 20, acctType)
        .Parameters.Append .CreateParameter("amount", adDouble, adParamInput, , CDbl(openingBalance))

        ' ?? IMPORTANT: Capture SELECT message as recordset
        Set rs = .Execute
    End With

      ' ? Check result from SELECT inside MySQL procedure
      If Not rs Is Nothing Then
         If Not rs.EOF Then
             Dim dbMsg As String
             dbMsg = rs.Fields(0).Value

             If InStr(dbMsg, "Error in Insert New Customer Record") > 0 Then
                 MsgBox dbMsg, vbExclamation
                 GoTo Cleanup
             ElseIf InStr(dbMsg, "Error in Insert New Account Record") > 0 Then
                 MsgBox dbMsg, vbExclamation
                 GoTo Cleanup
             End If
         End If
     End If

     MsgBox "Customer and Account created successfully!", vbInformation

Cleanup:
    On Error Resume Next
    If Not conn Is Nothing Then conn.Close
    Set rs = Nothing: Set cmd = Nothing: Set conn = Nothing
    Exit Sub

ErrHandler:
    MsgBox "VBA Error: " & Err.Description, vbCritical
    Resume Cleanup

End Sub



' AddAccountToExistingCustomer (Existing Customer + Add Extra Account)

Sub AddAccountToExistingCustomer()
    On Error GoTo ErrHandler

    Dim conn As Object, cmd As Object
    Dim connStr As String
    Dim customerId As Variant, acctType As String, openingBalance As Variant
    Dim ws As Worksheet: Set ws = ActiveSheet

    ' Read inputs from D16, E16, F16
    customerId = Trim(ws.Range("D16").Value)
    acctType = Trim(ws.Range("E16").Value)
    openingBalance = ws.Range("F16").Value

    ' Validate inputs
    If Not IsNumeric(customerId) Or customerId <= 0 Then
        MsgBox "Please enter a valid Customer ID.", vbExclamation: Exit Sub
    End If

    If acctType = "" Then
        MsgBox "Please select an Account Type.", vbExclamation: Exit Sub
    End If

    If Not IsNumeric(openingBalance) Or openingBalance < 100 Then
        MsgBox "Opening balance must be at least 100.", vbExclamation: Exit Sub
    End If

    ' Setup DB connection
    Set conn = CreateObject("ADODB.Connection")
    Set cmd = CreateObject("ADODB.Command")
    connStr = "DSN=MySQL_Excel;UID=your_username;PWD=your_password;"
    conn.Open connStr

    With cmd
        .ActiveConnection = conn
        .CommandText = "CALL proc_new_account(?, ?, ?)"
        .CommandType = 1
        .Parameters.Append .CreateParameter("cust_id", 3, 1, , CLng(customerId))  ' adInteger
        .Parameters.Append .CreateParameter("account_type", 200, 1, 20, acctType)    ' adVarChar
        .Parameters.Append .CreateParameter("amount", 5, 1, , CDbl(openingBalance))  ' adDouble
        .Execute
    End With

    MsgBox " Additional account added successfully!", vbInformation

Cleanup:
    On Error Resume Next
    If Not conn Is Nothing Then conn.Close
    Set cmd = Nothing: Set conn = Nothing
    Exit Sub

ErrHandler:
    MsgBox " Error: " & Err.Description, vbCritical
    Resume Cleanup
End Sub



' To start a Transaction

Sub ExecuteTransaction()
    On Error GoTo ErrHandler

    Dim conn As Object, cmd As Object, rs As Object
    Dim connStr As String
    Dim selfAcc As Variant, otherAcc As Variant
    Dim transferType As String, transMode As String
    Dim amount As Variant, remarks As String
    Dim resultMsg As String
    Dim ws As Worksheet: Set ws = ActiveSheet

    ' Step 1: Read Excel inputs (D34 to I34)
    With ws
        selfAcc = Trim(.Range("D34").Value)
        otherAcc = Trim(.Range("E34").Value)
        transferType = Trim(.Range("F34").Value)
        transMode = Trim(.Range("G34").Value)
        amount = .Range("H34").Value
        remarks = Trim(.Range("I34").Value)
    End With

    ' Step 2: Basic validations
    If Not IsNumeric(selfAcc) Or selfAcc <= 0 Then
        MsgBox "Invalid or missing Self Account ID.", vbExclamation: Exit Sub
    End If

    If transferType = "" Or transMode = "" Then
        MsgBox "Please select both Transfer Type and Transaction Mode.", vbExclamation: Exit Sub
    End If

    If Not IsNumeric(amount) Or amount <= 0 Then
        MsgBox "Transfer amount must be greater than 0.", vbExclamation: Exit Sub
    End If

    ' Step 3: Setup DB connection
    Set conn = CreateObject("ADODB.Connection")
    Set cmd = CreateObject("ADODB.Command")
    connStr = "DSN=MySQL_Excel;UID=your_username;PWD=your_password;"
    conn.Open connStr

    ' Step 4: Pass parameters
    With cmd
        .ActiveConnection = conn
        .CommandText = "CALL proc_transaction(?, ?, ?, ?, ?, ?)"
        .CommandType = 1

        .Parameters.Append .CreateParameter("self_acc", 3, 1, , CLng(selfAcc)) ' adInteger
        If otherAcc = "" Or otherAcc = 0 Then
            .Parameters.Append .CreateParameter("other_acc", 3, 1, , Null)
        Else
            .Parameters.Append .CreateParameter("other_acc", 3, 1, , CLng(otherAcc))
        End If
        .Parameters.Append .CreateParameter("transfer_type", 200, 1, 100, transferType) ' adVarChar
        .Parameters.Append .CreateParameter("mode", 200, 1, 100, transMode) ' adVarChar
        .Parameters.Append .CreateParameter("amt", 5, 1, , CDbl(amount)) ' adDouble
        .Parameters.Append .CreateParameter("remarks", 200, 1, 255, remarks) ' adVarChar

        Set rs = .Execute
    End With

    ' Step 5: Show result in message box
    If Not rs Is Nothing Then
        If rs.State = 1 And Not rs.EOF Then
            resultMsg = rs.Fields(0).Value
            MsgBox resultMsg, vbInformation
        Else
            MsgBox " Transaction executed successfully.", vbInformation
        End If
    Else
        MsgBox " Transaction executed successfully.", vbInformation
    End If

Cleanup:
    On Error Resume Next
    If Not conn Is Nothing Then conn.Close
    Set rs = Nothing: Set cmd = Nothing: Set conn = Nothing
    Exit Sub

ErrHandler:
    MsgBox " VBA Runtime Error: " & Err.Description, vbCritical
    Resume Cleanup
End Sub



' Loading the Customers Table and Accounts Table


Sub LoadCustomerAndAccountTables()
    On Error GoTo ErrHandler

    Dim conn As Object, cmd As Object, rs As Object
    Dim connStr As String
    Dim ws As Worksheet
    Dim i As Long, rowOffset As Long, lastRowCustomers As Long
    Dim startRowAccounts As Long

    ' Use active sheet
    Set ws = ActiveSheet
    ws.Activate

    ' Setup DB connection
    Set conn = CreateObject("ADODB.Connection")
    Set cmd = CreateObject("ADODB.Command")
    connStr = "DSN=MySQL_Excel;UID=your_username;PWD=your_password;"
    conn.Open connStr

    ' === 1. Load Customers Table ===
    With cmd
        .ActiveConnection = conn
        .CommandText = "SELECT concat('CUST_', customer_id) AS Customer_ID, name AS Name, email AS Email, phone AS Phone_Number, created_at AS Created_At FROM customers;"
        .CommandType = 1
        Set rs = .Execute
    End With

    ' Title
    ws.Range("B2").Value = "Customers Table"
    ws.Range("B2").Font.Bold = True

    ' Clear old customers data only (B5 downward)
    ws.Range("B4", ws.Cells(ws.Rows.Count, "B").End(xlUp).Offset(0, rs.Fields.Count - 1)).ClearContents

    ' Headers
    For i = 0 To rs.Fields.Count - 1
        ws.Cells(3, i + 2).Value = rs.Fields(i).Name
        ws.Cells(3, i + 2).Font.Bold = True
    Next i

    ' Data
    ws.Range("B4").CopyFromRecordset rs
    lastRowCustomers = ws.Cells(ws.Rows.Count, "B").End(xlUp).row
    rs.Close

' ? Format date column (Created_At in column F)
    ws.Range("F4:F" & lastRowCustomers).NumberFormat = "dd mm yyyy"



    ' === 2. Load Accounts Table ===
    With cmd
        .CommandText = "SELECT concat('CUST_', customer_id) AS Customer_ID, concat('ACC_', account_id) AS Account_ID, account_type AS Account_Type, round(balance, 2)  AS Balance, created_at AS Account_Created_at FROM accounts ORDER BY customer_id ASC, account_id ASC;"
        Set rs = .Execute
    End With

    ' Start 8 rows below last customer row
    startRowAccounts = lastRowCustomers + 8
    ws.Cells(startRowAccounts - 2, 2).Value = "Accounts Table"
    ws.Cells(startRowAccounts - 2, 2).Font.Bold = True

    ' Clear old accounts data
    ws.Range("B" & startRowAccounts, ws.Cells(ws.Rows.Count, "B")).ClearContents

    ' Headers
    For i = 0 To rs.Fields.Count - 1
        ws.Cells(startRowAccounts, i + 2).Value = rs.Fields(i).Name
        ws.Cells(startRowAccounts, i + 2).Font.Bold = True
    Next i

    ' Data
    ws.Range("B" & (startRowAccounts + 1)).CopyFromRecordset rs

' ? Format Balance as ? and Date as dd-mm-yyyy
    lastRowAccounts = ws.Cells(ws.Rows.Count, "B").End(xlUp).row

    ' Balance = Column E, Date = Column F
    If lastRowAccounts >= startRowAccounts + 1 Then
        ws.Range("E" & (startRowAccounts + 1) & ":E" & lastRowAccounts).NumberFormat = "?#,##0.00"
        ws.Range("F" & (startRowAccounts + 1) & ":F" & lastRowAccounts).NumberFormat = "dd mm yyyy"
    End If

    ' Autofit
    ws.Columns("B:L").AutoFit


    MsgBox "Customer and Account tables loaded successfully!", vbInformation

Cleanup:
    On Error Resume Next
    If Not rs Is Nothing Then rs.Close
    If Not conn Is Nothing Then conn.Close
    Set rs = Nothing: Set cmd = Nothing: Set conn = Nothing
    Exit Sub

ErrHandler:
    MsgBox "Error: " & Err.Description, vbCritical
    Resume Cleanup
End Sub



' To load All Transactions

Sub LoadAllTransactionsFormatted()
    On Error GoTo ErrHandler

    Dim conn As Object, rs As Object, cmd As Object
    Dim connStr As String
    Dim targetSheet As Worksheet
    Dim row As Long
    Dim i As Integer
    Dim dataRange As Range

    ' Use the currently active sheet to load the data
    Set targetSheet = ActiveSheet

    ' Clear only the old data (preserve formatting)
    Set dataRange = targetSheet.Range("D9:L1000") ' Clear data below headers only
    dataRange.ClearContents

    ' Optional: Add a heading (preserve formatting)
    targetSheet.Range("E7").Value = "Transactions from Banking DataBase"

    ' Create connection and command objects
    Set conn = CreateObject("ADODB.Connection")
    Set cmd = CreateObject("ADODB.Command")
    Set rs = CreateObject("ADODB.Recordset")

    ' MySQL ODBC connection string
    connStr = "DSN=MySQL_Excel;UID=your_username;PWD=your_password;"
    conn.Open connStr

    ' Set the SQL command to fetch formatted transactions
    With cmd
        .ActiveConnection = conn
        .CommandType = 1 ' adCmdText
        .CommandText = _
            "SELECT " & _
            "  CONCAT('TRAN_', transaction_id) AS Transaction_Id, " & _
            "  CONCAT('ACC_', self_account_id) AS Self_Account_Id, " & _
            "  COALESCE(CONCAT('ACC_', Other_account_id), 'Not Applicable') AS Other_Account_Id, " & _
            "  transfer_type AS Transfer_Type, " & _
            "  deposit_withdrawal AS Credit_Debit, " & _
            "  transfer_amt AS Transfer_Amount, " & _
            "  transaction_date AS Transaction_Date, " & _
            "  transaction_description AS Reason " & _
            "FROM transactions " & _
            "ORDER BY transaction_date DESC;"
    End With

    ' Execute SQL query
    Set rs = cmd.Execute

    ' Write column headers starting from row 8, column D (i.e. column 4)
    For i = 1 To rs.Fields.Count
        targetSheet.Cells(8, i + 3).Value = rs.Fields(i - 1).Name
    Next i

    ' Write data starting from row 9, column D
    row = 9
    Do While Not rs.EOF
        For i = 1 To rs.Fields.Count
            targetSheet.Cells(row, i + 3).Value = rs.Fields(i - 1).Value
        Next i
        row = row + 1
        rs.MoveNext
    Loop

    ' Apply currency format to Transfer_Amount (column I)

    Dim lastRow As Long
    lastRow = targetSheet.Cells(targetSheet.Rows.Count, "I").End(xlUp).row
    If lastRow >= 9 Then
        targetSheet.Range("I9:I" & lastRow).NumberFormat = "?#,##0.00"
    End If

    MsgBox "All Transactions loaded successfully into '" & targetSheet.Name & "'.", vbInformation


Cleanup:
    On Error Resume Next
    rs.Close
    conn.Close
    Set rs = Nothing
    Set cmd = Nothing
    Set conn = Nothing
    Exit Sub

ErrHandler:
    MsgBox "Error loading transactions: " & Err.Description, vbCritical
    Resume Cleanup
End Sub



' Active Customers Profile and Transactions

Sub ShowCustomerProfileAndTransactions()
    On Error GoTo ErrHandler

    Dim conn As Object, cmd As Object, rs As Object
    Dim connStr As String
    Dim custId As Variant
    Dim ws As Worksheet
    Dim i As Integer, rowOffset As Long
    Dim headerColOffset As Integer
    Dim lastRow1 As Long
    Dim errorFlag As Boolean

    Set ws = ActiveSheet
    custId = ws.Range("A6").Value
    headerColOffset = 2 ' Column B

    If custId = "" Or Not IsNumeric(custId) Then
        MsgBox "Please enter a valid numeric Customer ID in cell A6!", vbExclamation
        Exit Sub
    End If

    ' Clean up old content but retain formatting (from B4 down)
    ws.Range("B4:K1000").ClearContents

    ' Setup DB connection
    Set conn = CreateObject("ADODB.Connection")
    Set cmd = CreateObject("ADODB.Command")
    connStr = "DSN=MySQL_Excel;UID=your_username;PWD=your_password;"
    conn.Open connStr

    ' === 1. Customer Profile ===
    With cmd
        .ActiveConnection = conn
        .CommandText = "CALL proc_active_customer_details(?)"
        .CommandType = 1
        .Parameters.Append .CreateParameter(, 3, 1, , custId)
        Set rs = .Execute
    End With

    ws.Cells(2, headerColOffset).Value = "Customer Profile"
    With ws.Cells(2, headerColOffset)
        .Font.Bold = True
        .Font.Size = 14
        .Font.Color = RGB(0, 102, 204)
    End With

    If Not rs.EOF Then
        If rs.Fields(0).Name = "no_active_customer_detail" Then
            MsgBox "Customer ID not found in customer details!", vbExclamation
        Else
            ' Header
            For i = 0 To rs.Fields.Count - 1
                With ws.Cells(4, i + headerColOffset)
                    .Value = rs.Fields(i).Name
                    .Interior.Color = RGB(221, 235, 247) ' Light blue
                    .Font.Bold = True
                End With
            Next i

            ' Data
            ws.Range(ws.Cells(5, headerColOffset), ws.Cells(5, headerColOffset)).CopyFromRecordset rs
        End If
    Else
        MsgBox "No data found in active customer details!", vbExclamation
    End If
    lastRow1 = ws.Cells(ws.Rows.Count, headerColOffset).End(xlUp).row
    rs.Close
    cmd.Parameters.Delete 0

    ' === 2. Transaction History ===
    rowOffset = lastRow1 + 5

    With cmd
        .CommandText = "CALL proc_trans_details_of_cust(?)"
        .Parameters.Append .CreateParameter(, 3, 1, , custId)
        Set rs = .Execute
    End With

    ws.Cells(rowOffset, headerColOffset).Value = "Transaction History"
    With ws.Cells(rowOffset, headerColOffset)
        .Font.Bold = True
        .Font.Size = 12
        .Font.Color = RGB(0, 102, 204)
    End With

    If Not rs.EOF Then
        If rs.Fields(0).Name = "no_customer_trans_detail" Then
            MsgBox "No transactions found for this customer!", vbInformation
        Else
            ' Header
            For i = 0 To rs.Fields.Count - 1
                With ws.Cells(rowOffset + 1, i + headerColOffset)
                    .Value = rs.Fields(i).Name
                    .Interior.Color = RGB(221, 235, 247) ' Light blue
                    .Font.Bold = True
                End With
            Next i

            ' Data
            ws.Range(ws.Cells(rowOffset + 2, headerColOffset), ws.Cells(rowOffset + 2, headerColOffset)).CopyFromRecordset rs
        End If
    Else
        MsgBox "No data returned from transaction procedure!", vbExclamation
    End If

    ' Autofit
    ws.Columns("B:K").AutoFit

Cleanup:
    On Error Resume Next
    If Not rs Is Nothing Then rs.Close
    If Not conn Is Nothing Then conn.Close
    Set rs = Nothing: Set cmd = Nothing: Set conn = Nothing
    Exit Sub

ErrHandler:
    MsgBox "Unexpected Error: " & Err.Description, vbCritical
    Resume Cleanup
End Sub




' To load All Transactions for Pivot

Sub LoadTransactionSummaryToTableforPivot()
    On Error GoTo ErrHandler

    Dim conn As Object, cmd As Object, rs As Object
    Dim ws As Worksheet
    Dim connStr As String
    Dim tblRange As Range
    Dim lastRow As Long, lastCol As Long
    Dim tbl As ListObject
    Dim i As Long
    Dim startCell As Range

    ' Target worksheet
    Set ws = ActiveSheet
    Set startCell = ws.Range("D8")  ' Headers in D8, data starts from D9
    ws.Range("D8:G1000").ClearContents ' Clear old output

    ' Open DB connection
    Set conn = CreateObject("ADODB.Connection")
    Set cmd = CreateObject("ADODB.Command")
    connStr = "DSN=MySQL_Excel;UID=your_username;PWD=your_password;"
    conn.Open connStr

    ' SQL Query with CTE
    cmd.ActiveConnection = conn
    cmd.CommandType = 1
    cmd.CommandText = _
        "WITH acc_id_count AS (" & _
        "   SELECT " & _
        "     CONCAT('CUST_', a.customer_id) AS Customer_Id, " & _
        "     CONCAT('ACC_', a.account_id) AS Account_Id, " & _
        "     COUNT(*) AS Num_of_Transactions, " & _
        "     SUM(t.transfer_amt) AS Total_Transfer_Amount " & _
        "   FROM accounts a " & _
        "   INNER JOIN transactions t " & _
        "     ON a.account_id = t.self_account_id OR a.account_id = t.other_account_id " & _
        "   GROUP BY a.account_id " & _
        ") " & _
        "SELECT * FROM acc_id_count ORDER BY Num_of_Transactions DESC;"

    Set rs = cmd.Execute

    ' Set headers in D8
    For i = 0 To rs.Fields.Count - 1
        startCell.Offset(0, i).Value = rs.Fields(i).Name
        startCell.Offset(0, i).Font.Bold = True
    Next i

    ' Set data starting from D9
    startCell.Offset(1, 0).CopyFromRecordset rs

    ' Calculate range for table
    lastRow = ws.Cells(ws.Rows.Count, startCell.Column).End(xlUp).row
    lastCol = startCell.Column + rs.Fields.Count - 1
    Set tblRange = ws.Range(startCell, ws.Cells(lastRow, lastCol))

    ' Remove existing table if present
    On Error Resume Next
    ws.ListObjects("TransactionSummaryTbl").Delete
    On Error GoTo ErrHandler

    ' Create Excel table
    Set tbl = ws.ListObjects.Add(xlSrcRange, tblRange, , xlYes)
    tbl.Name = "TransactionSummaryTbl"
    tbl.TableStyle = "TableStyleMedium9"

    ' Apply currency format to "Total_Transfer_Amount" column
    Dim totalAmtCol As Range
    Set totalAmtCol = tbl.ListColumns("Total_Transfer_Amount").DataBodyRange
    totalAmtCol.NumberFormat = "?#,##0.00"

    ' Autofit
    tbl.Range.Columns.AutoFit

    MsgBox " Transaction summary loaded and formatted as a table!", vbInformation

Cleanup:
    On Error Resume Next
    rs.Close: conn.Close
    Set rs = Nothing: Set cmd = Nothing: Set conn = Nothing
    Exit Sub

ErrHandler:
    MsgBox " Error: " & Err.Description, vbCritical
    Resume Cleanup
End Sub



' Logging All Deleted Account Ids

Sub DeleteAccountAndLog()
    On Error GoTo ErrHandler

    Dim conn As Object, cmd As Object, rs As Object
    Dim ws As Worksheet
    Dim connStr As String
    Dim custId As Variant, accId As Variant
    Dim currentRow As Long

    Set ws = ActiveSheet
    custId = ws.Range("A5").Value
    accId = ws.Range("B5").Value
    currentRow = 12

    If custId = "" Or Not IsNumeric(custId) Then
        MsgBox "Enter valid Customer ID in A5", vbExclamation: Exit Sub
    End If
    If accId = "" Or Not IsNumeric(accId) Then
        MsgBox "Enter valid Account ID in B5", vbExclamation: Exit Sub
    End If

    Set conn = CreateObject("ADODB.Connection")
    Set cmd = CreateObject("ADODB.Command")
    connStr = "DSN=MySQL_Excel;UID=your_username;PWD=your_password;"
    conn.Open connStr
    cmd.ActiveConnection = conn

    ' Clear space before logs
    ws.Range("B" & currentRow & ":K1000").ClearContents

    ' === Call delete account procedure ===
    cmd.CommandType = 4
    cmd.CommandText = "proc_delete_account"
    cmd.Parameters.Append cmd.CreateParameter("cust_id", 3, 1, , custId)
    cmd.Parameters.Append cmd.CreateParameter("acc_id", 3, 1, , accId)
    Set rs = cmd.Execute
    currentRow = DisplayResult(rs, ws, currentRow, "Deleted Account Info")
    cmd.Parameters.Delete 0
    cmd.Parameters.Delete 0
    rs.Close

    ' === Log closed account summary ===
    cmd.CommandType = 1
    cmd.CommandText = _
        "SELECT " & _
        "CASE WHEN GROUPING(customer_id) = 1 AND GROUPING(account_id) = 1 " & _
        "THEN CONCAT('Total Customers: ', COUNT(DISTINCT customer_id), ' | Total Accounts: ') " & _
        "WHEN GROUPING(customer_id) = 0 AND GROUPING(account_id) = 1 " & _
        "THEN CONCAT('CUST_', customer_id, ' had ') " & _
        "ELSE CONCAT('CUST_', customer_id) END AS Customer_Id, " & _
        "CASE WHEN GROUPING(account_id) = 1 THEN CONCAT(COUNT(account_id), ' Accounts') " & _
        "ELSE CONCAT('ACC_', account_id) END AS Account_Id " & _
        "FROM closed_account_log_table GROUP BY customer_id, account_id WITH ROLLUP;"
    Set rs = cmd.Execute
    currentRow = DisplayResult(rs, ws, currentRow + 2, "Closed Account Log Summary")
    rs.Close

    ws.Columns("B:K").AutoFit
    MsgBox "Account deleted and log updated successfully!", vbInformation

Cleanup:
    On Error Resume Next
    If Not rs Is Nothing Then rs.Close
    If Not conn Is Nothing Then conn.Close
    Set rs = Nothing: Set cmd = Nothing: Set conn = Nothing
    Exit Sub

ErrHandler:
    MsgBox "Error: " & Err.Description, vbCritical
    Resume Cleanup
End Sub



' Logging All Deleted Account and Customer Ids

Sub DeleteCustomerAndLog()
    On Error GoTo ErrHandler

    Dim conn As Object, cmd As Object, rs As Object
    Dim ws As Worksheet
    Dim connStr As String
    Dim custId As Variant
    Dim currentRow As Long

    Set ws = ActiveSheet
    custId = ws.Range("B5").Value
    currentRow = 12

    If custId = "" Or Not IsNumeric(custId) Then
        MsgBox "Enter valid Customer ID in B5", vbExclamation: Exit Sub
    End If

    Set conn = CreateObject("ADODB.Connection")
    Set cmd = CreateObject("ADODB.Command")
    connStr = "DSN=MySQL_Excel;UID=your_username;PWD=your_password;"
    conn.Open connStr
    cmd.ActiveConnection = conn

    ws.Range("B" & currentRow & ":L1000").ClearContents

    ' === Call delete customer record procedure ===
    cmd.CommandType = 4
    cmd.CommandText = "proc_delete_customer_record"
    cmd.Parameters.Append cmd.CreateParameter("cust_id", 3, 1, , custId)
    Set rs = cmd.Execute
    currentRow = DisplayResult(rs, ws, currentRow, "Deleted Customer Info")
    cmd.Parameters.Delete 0
    rs.Close

    ' === Log closed customer table ===
    cmd.CommandType = 1
    cmd.CommandText = _
        "SELECT CONCAT('CUST_', customer_id) AS Customer_Id, name, email, phone, deleted_at " & _
        "FROM closed_customer_acc_log_table;"
    Set rs = cmd.Execute
    currentRow = DisplayResult(rs, ws, currentRow + 2, "Closed Customer Log Table")
    rs.Close

    ws.Columns("B:L").AutoFit
    MsgBox "Customer deleted and log updated successfully!", vbInformation

Cleanup:
    On Error Resume Next
    If Not rs Is Nothing Then rs.Close
    If Not conn Is Nothing Then conn.Close
    Set rs = Nothing: Set cmd = Nothing: Set conn = Nothing
    Exit Sub

ErrHandler:
    MsgBox "Error: " & Err.Description, vbCritical
    Resume Cleanup
End Sub






'===========================
' Sub to Display Recordset
'===========================
Function DisplayResult(rs As Object, ws As Worksheet, startRow As Long, title As String) As Long
    Dim i As Long, row As Long
    row = startRow + 1

    ' Title
    With ws.Range("B" & startRow)
        .Value = title
        .Font.Bold = True
        .Font.Size = 12
        .Font.Color = RGB(0, 102, 204)
    End With

    ' If no data
    If rs.EOF Then
        ws.Range("B" & row).Value = "No data returned."
        DisplayResult = row + 2
        Exit Function
    End If

    ' Headers
    For i = 0 To rs.Fields.Count - 1
        With ws.Cells(row, i + 2)
            .Value = rs.Fields(i).Name
            .Font.Bold = True
            .Interior.Color = RGB(221, 235, 247)
        End With
    Next i

    ' Data
    row = row + 1
    Do While Not rs.EOF
        For i = 0 To rs.Fields.Count - 1
            ws.Cells(row, i + 2).Value = rs.Fields(i).Value
        Next i
        row = row + 1
        rs.MoveNext
    Loop

    DisplayResult = row
End Function



