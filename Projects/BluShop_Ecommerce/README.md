# 🛒 BluShop E-Commerce — QA Technical Project Specification

## 📌 Project Overview
**BluShop** is a modern B2C E-commerce web application built on the Laravel framework. The application handles end-to-end shopping workflows including product catalog browsing, session-based cart management, dynamic discount application, and order checkout processing.

This directory contains the complete **Quality Assurance & Testing Artifacts** developed for BluShop, focusing on critical business logic, security validation, and database integrity.

---

## 🛠️ System Architecture & Tech Stack
* **Application Framework:** Laravel 11.x (PHP 8.2+)
* **Database Engine:** MySQL 8.0
* **Frontend Architecture:** Blade Templates, JavaScript, CSS3
* **Session & State Management:** Laravel Session Driver & Database Transactions
* **QA & Testing Tools:** Postman, MySQL Workbench / CLI, Chrome DevTools

---

## 🎯 Test Scope & Objectives

The testing strategy for BluShop focuses on **High-Risk Business Logic & Transactional Flows**:

### 1. Shopping Cart Logic
* Validation of quantity increments/decrements and item removal.
* Boundary Value Analysis (BVA) on item limits, stock availability, and multi-item totals.
* Protection against parameter injection (e.g., negative integers, zero values, non-numeric strings, array payloads).

### 2. Order & Checkout Processing
* Order total calculation accuracy including taxes, shipping fees, and discount codes.
* Stock deduction synchronization upon successful order placement.
* Verification of stale price exploitation and session price manipulation protection.

### 3. API & Backend Endpoint Validation
* Direct HTTP request interception and payload manipulation using Postman.
* HTTP Status Code verification (`200 OK`, `422 Unprocessable Entity`, `400 Bad Request`, `403 Forbidden`).
* JSON response schema validation and backend exception handling.

### 4. Database Integrity & ACID Compliance
* State verification of `products`, `orders`, `order_items`, and `users` tables.
* Database transaction rollback verification upon failed payments or checkout errors.
* Direct SQL query verification for inventory deduction accuracy.

---

## 📂 STLC Test Artifacts & Deliverables

Testing deliverables are organized into the 5 core phases of the **Software Testing Life Cycle (STLC)**:

| STLC Phase | Folder / Location | Key Deliverables & Artifacts |
| :--- | :--- | :--- |
| **1. Requirement Analysis** | [`1_Requirement_Analysis/`](./1_Requirement_Analysis/) | [`BluShop_Test_Plan.pdf`](./1_Requirement_Analysis/BluShop_Test_Plan.pdf) & [`MASTER_TEST_PLAN.md`](./1_Requirement_Analysis/MASTER_TEST_PLAN.md)<br>Master Test Plan defining test scope, strategy, environments, and entry/exit criteria. |
| **2. Test Design** | [`2_Test_Design/`](./2_Test_Design/) | [`Test_Case_Matrix.xlsx`](./2_Test_Design/Test_Case_Matrix.xlsx)<br>Comprehensive functional, regression, boundary, and security test cases. |
| **3. Test Execution** | [`3_Test_Execution/`](./3_Test_Execution/) | [`Bug_Report.pdf`](./3_Test_Execution/Bug_Report.pdf)<br>Detailed Defect Tracking Log with reproducible steps, Root Cause Analysis (RCA), and remediation guides. |
| **4. API Testing** | [`4_API_Testing/`](./4_API_Testing/) | [`Postman_Collection.json`](./4_API_Testing/Postman_Collection.json)<br>Postman Collection with REST API requests, positive/negative test assertions, and security payloads. |
| **5. Database Testing** | [`5_Database_Testing/`](./5_Database_Testing/) | [`Validation_Queries.sql`](./5_Database_Testing/Validation_Queries.sql)<br>SQL scripts for database state validation, ACID transaction audits, and inventory checks. |

---

## 🔍 Technical QA Execution Highlights

### 🛡️ Grey-Box API Payload Testing
Using Postman to test backend endpoint resilience against input tampering:
```json
// Negative Quantity Payload Test (POST /api/cart/add)
{
    "product_id": 101,
    "quantity": -5,
    "size": "L"
}
```
* **Expected Result:** Backend returns `422 Unprocessable Entity` with validation message `"The quantity must be at least 1."`
* **Verified Defense:** Ensures backend does not blindly accept raw request values into session state.

### 💾 SQL Database State Verification
Executing verification queries post-checkout to guarantee transactional consistency:
```sql
-- Stock Synchronization Audit Query
SELECT p.id, p.name, p.stock AS current_stock, oi.quantity AS ordered_qty
FROM products p
JOIN order_items oi ON p.id = oi.product_id
WHERE oi.order_id = 1001;
```
* **Verified Behavior:** Confirms product stock decreases by exact `ordered_qty` and database transactions maintain ACID guarantees.
