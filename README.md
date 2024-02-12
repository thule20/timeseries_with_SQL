TASK: SQL PRACTICE WITH DATE functions & WINDOW FUNCTIONs 

- Case study: TIME SERIES ANALYSIS applying to Paytm database
- Credit to: @Mazhocdata https://madzynguyen.com/khoa-hoc-practical-sql-for-data-analytics/ for Database provider & How to apply SQL in real problems

  
**Database explaination**

- Paytm is an Indian multinational financial technology company. It specializes in digital payment systems, e-commerce and financial services.
- Paytm wallet is a secure and RBI (Reserve Bank of India)-approved digital/mobile wallet that provides a myriad of financial features to fulfill every consumer’s payment needs.
- Paytm wallet can be topped up through UPI (Unified Payments Interface), internet banking, or credit/debit cards. Users can also transfer money from a Paytm wallet to the recipient's bank account or their own Paytm wallet.

I have practiced on a small database of payment transactions from 2019 to 2020 of Paytm Wallet. The database includes 6 tables: 
+ fact_transaction: Store information of all types of transactions: Payments, Top-up, Transfers, Withdrawals, with the list of columns: transaction_id, customer_id, scenario_id, payment_channel_id, promotion_id, platform_id, status_id, original_price, discount_value, charged_amount, transaction_time
+ dim_scenario: Detailed description of transaction types, with columns: scenario_id, transaction_type, sub_category, category
+ dim_payment_channel: Detailed description of payment methods, including columns: payment_channel_id, payment_method
+ dim_platform: Detailed description of payment devices, with columns: playform_id, payment_platform
+	dim_status: Detailed description of the results of the transaction: status_id, status_description

**Final visualisation dashboard**

The SQL results are visualised here: https://community.fabric.microsoft.com/t5/Data-Stories-Gallery/Paytm-Practice-Time-Series-Analysis-with-SQL-amp-Power-BI/td-p/3693063


