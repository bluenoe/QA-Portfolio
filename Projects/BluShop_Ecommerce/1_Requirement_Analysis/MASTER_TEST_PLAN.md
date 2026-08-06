# Master Test Plan: Shopping Cart & Checkout Modules

**Project Name:** BluShop Laravel E-Commerce Platform  
**Target Modules:** Shopping Cart & Checkout / Order Management  
**Author:** QA Lead / QA Manager  
**Version:** 1.0.0  
**Date:** August 2026  
**Document Status:** Final  

---

## 1. Introduction & Objectives

### 1.1 Project Background
BluShop is a Laravel 11 e-commerce web application featuring dynamic product cataloging, session-based cart management, robust checkout workflows with database transactions, and user order tracking.

### 1.2 Testing Objectives
The primary objective of this Master Test Plan is to define the quality assurance framework, test methodologies, and execution guidelines for verifying the **Shopping Cart** and **Checkout/Order Management** modules. 

Key quality goals include:
* **Functional Integrity:** Guarantee accurate cart calculations (subtotal, dynamic shipping fees, thresholds, and total price).
* **Data & Transaction Consistency:** Ensure atomic stock deductions (`decrement('stock')`) and pessimistic database locking (`lockForUpdate()`) to prevent race conditions or overselling under high concurrency.
* **Security & Input Validation:** Prevent price tampering via client-side request modification by verifying price recalculations strictly against database records.
* **Resilience & Fault Handling:** Ensure total transaction rollback (`DB::rollBack()`) upon out-of-stock conditions or database exceptions during checkout placement.

---

## 2. Scope of Testing

### 2.1 In-Scope (Functional & Non-Functional Areas)

| Area / Component | Features & Scenarios in Scope | Technical Sub-components |
| :--- | :--- | :--- |
| **Cart Operations** | - Add product with attributes (Size, Color, Quantity)<br>- Update quantity via AJAX<br>- Remove item / Clear cart<br>- Real-time stock validation against available inventory<br>- Dynamic shipping calculation based on configurable threshold | `CartController` (`index`, `add`, `update`, `remove`, `clear`), Session storage (`cart[{rowId}]`), `Setting::getVal()` |
| **Checkout Flow** | - Authenticated checkout access control<br>- Shipping address input validation & auto-fill (`UserAddress`) <br>- Order summary verification (Subtotal, Shipping, Total) | `CheckoutController` (`index`, `place`, `success`), `PhoneNumberRequest`, Auth middleware |
| **Order Generation & Execution** | - Unique Order Code generation (`ORD-YYYYMMDD-XXXX`)<br>- DB Transaction handling with pessimistic locking (`lockForUpdate()`)<br>- Price verification (forcing DB price over session price)<br>- Stock deduction (`decrement`) and rollback validation | `Order`, `OrderItem`, `OrderPlaced` Event, `DB::transaction()` |
| **Order Management & Cancellation** | - Order status lifecycle (`pending` $\rightarrow$ `confirmed` / `canceled` $\rightarrow$ `shipping` $\rightarrow$ `delivered`)<br>- Order cancellation by customer (allowed only in `pending` status)<br>- Automatic stock restoration upon order cancellation | `OrderController` (`index`, `show`, `cancel`), `OrderCancellationService`, `CancelOrderRequest` |

### 2.2 Out-of-Scope

* **Third-Party Payment Gateways:** Live/Sandbox integration with external gateways (e.g., Stripe, PayPal, VNPay API tokens, webhook handling).
* **Admin Dashboard Analytics:** Reporting charts, bulk export tools, or non-cart admin views.
* **Global Security Penetration:** Network-level DDoS mitigation, SSL certificate validation, or server OS hardening.

---

## 3. Test Strategy & Methodology

The testing approach combines multi-layered validation strategies to guarantee functional accuracy, backend data integrity, and system resilience.

```
       +-------------------------------------------------------+
       |                  MANUAL UI TESTING                    |
       |  Cross-browser verification, responsive layouts, AJAX |
       +---------------------------+---------------------------+
                                   |
                                   v
       +-------------------------------------------------------+
       |                  API POSTMAN TESTING                  |
       | Requests, Validation payloads, HTTP Status (200/422)  |
       +---------------------------+---------------------------+
                                   |
                                   v
       +-------------------------------------------------------+
       |               DATABASE SQL VALIDATION                 |
       |  Pessimistic locks, Stock decrement, Foreign Keys     |
       +-------------------------------------------------------+
```

### 3.1 UI & Functional Testing (Manual)
* **Execution Layer:** Google Chrome (DevTools network & storage analysis).
* **Focus:** Form validation feedback, session updates without page reload, edge-case UI messages (e.g., exceeding stock tooltips, empty cart state).

### 3.2 API & Endpoint Validation (Postman / REST Client)
* **Target Controllers:** `CartController`, `CheckoutController`, `OrderController`.
* **Payload Verification:** Header assertions (`Accept: application/json`, `X-Requested-With: XMLHttpRequest`), response structure checks (JSON payload format, error keys, status codes: 200, 422, 403, 500).

### 3.3 Database Validation (SQL / DB Admin)
* **Direct DB Inspection:** Execute raw MySQL queries to verify field state transitions, foreign key constraints (`orders.user_id`, `order_items.order_id`), column casts (`decimal:2`), and accurate stock decrements/increments.

### 3.4 Concurrency & Integrity Testing
* **Simulated Race Conditions:** Executing concurrent HTTP requests attempting to check out the last remaining stock of a product simultaneously to verify `lockForUpdate()` pessimistic locking behavior in MySQL InnoDB engine.

---

## 4. Test Environment & Tools

### 4.1 Environment Configuration

| Layer | Environment Standard / Specification |
| :--- | :--- |
| **Application Framework** | Laravel 11.x on PHP 8.2+ |
| **Database Management System** | MySQL 8.0+ (InnoDB Engine with Row-Level Locking support) |
| **Web Server / Dev Host** | Local Development Host (`php artisan serve` / Docker / Nginx) |
| **Session Driver** | File / Database Session Driver |
| **Browser Target** | Google Chrome (Latest Version), DevTools enabled |

### 4.2 Test Tooling

* **API Client:** Postman v10+ (for direct endpoint verification and validation payload injection).
* **Database Inspection:** TablePlus / DBeaver / phpMyAdmin / MySQL CLI.
* **Test Runner Framework:** Pest PHP / PHPUnit (for backend automated test suite execution).

---

## 5. Comprehensive Test Case Matrix

### 5.1 Shopping Cart Module (`CartController`)

| Test ID | Module | Scenario / Description | Execution Type | Preconditions | Input / Steps | Expected Outcome |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-CRT-01** | Cart | Add product with valid size & color | UI / API | Product active, stock > 5 | Select size 'M', color 'Black', qty 2 $\rightarrow$ Click "Add to Cart" | Item added. Session key `cart[id_size_color]` created. HTTP status 200/Redirect with success toast. |
| **TC-CRT-02** | Cart | Add quantity exceeding total stock | UI / API | Product stock = 3 | Attempt to add quantity = 5 | Request rejected with HTTP 422 JSON (`success: false`) or error banner: *"Sorry, only 3 units available"*. |
| **TC-CRT-03** | Cart | Cumulative stock check across multiple additions | UI / API | Item in cart qty = 2, DB stock = 3 | Attempt to add 2 more units of same variant | Blocked. Message: *"Product is already at max stock in your bag"*. Total in cart remains 2. |
| **TC-CRT-04** | Cart | Update item quantity in cart | UI / API | Item in cart | Send POST to `/cart/update` with `rowId` & `quantity = 4` | Session updated. Item subtotal, cart subtotal, shipping fee, and grand total recalculated correctly. |
| **TC-CRT-05** | Cart | Calculate Dynamic Shipping Fee (Below Threshold) | UI / SQL | `free_shipping_threshold` = 500,000, `shipping_fee` = 30,000 | Add cart items total = 350,000 VND | Subtotal = 350,000, Shipping = 30,000, Total = 380,000 VND. |
| **TC-CRT-06** | Cart | Calculate Dynamic Shipping Fee (Above Threshold) | UI / SQL | `free_shipping_threshold` = 500,000, `shipping_fee` = 30,000 | Add cart items total = 550,000 VND | Subtotal = 550,000, Shipping = 0 (Free), Total = 550,000 VND. |
| **TC-CRT-07** | Cart | Remove specific item variant | UI / API | Cart contains 2 distinct items | Send POST to `/cart/remove` with `rowId` | Target row deleted from `session('cart')`. Response contains updated totals and `cart_count`. |
| **TC-CRT-08** | Cart | Clear entire cart | UI / API | Cart contains multiple items | Trigger `POST /cart/clear` | Session key `cart` forgotten. Redirection to empty cart UI state. |

---

### 5.2 Checkout & Order Placement (`CheckoutController`)

| Test ID | Module | Scenario / Description | Execution Type | Preconditions | Input / Steps | Expected Outcome |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-CHK-01** | Checkout | Unauthenticated user access redirect | UI / API | Guest user session | Navigate to `/checkout` | Redirected to login page with auth middleware challenge. |
| **TC-CHK-02** | Checkout | Empty cart checkout attempt | UI / API | Logged in user, cart is empty | Access `/checkout` or POST to `/checkout` | Redirected to `/cart` with warning message: *"Cart is empty"*. |
| **TC-CHK-03** | Checkout | Form validation failures | UI / API | Cart has 1 item | Submit checkout with blank `phone` and `address` | Validation errors returned (422 / HTTP redirect back with field errors). |
| **TC-CHK-04** | Checkout | Price Tampering Defense (Security Verification) | API / DB | Product price in DB = 200,000 VND | Modify session cart array setting `price = 10` before submit | System ignores session price, fetches actual price from DB (`lockForUpdate()`), and charges 200,000 VND. |
| **TC-CHK-05** | Checkout | Successful Order Placement & Transaction Commit | UI / SQL | User logged in, Cart valid, Product stock = 10 | Submit valid checkout form | 1. Order created in `orders` table with code `ORD-YYYYMMDD-XXXX`.<br>2. Items inserted in `order_items`.<br>3. Product stock reduced to 9.<br>4. Cart cleared.<br>5. `OrderPlaced` event dispatched. |
| **TC-CHK-06** | Checkout | Stock depletion midway through checkout | DB / API | Product stock = 1 | User A opens checkout. User B purchases last unit before User A submits | User A submit fails. Transaction rolled back (`rollBack()`). No order created. Error: *"Product no longer available"*. |

---

### 5.3 Order Lifecycle & Cancellation (`OrderController`)

| Test ID | Module | Scenario / Description | Execution Type | Preconditions | Input / Steps | Expected Outcome |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-ORD-01** | Orders | View customer order history pagination | UI / SQL | Logged in user with 15 orders | Navigate to `/orders` | Page 1 displays latest 10 orders with eager loaded product images. |
| **TC-ORD-02** | Orders | Access unauthorized order detail | UI / API | User A logged in | Navigate to `/orders/ORD-USER-B-CODE` | Access denied with HTTP 403 Forbidden. |
| **TC-ORD-03** | Orders | Cancel order in `pending` status | UI / API / SQL | Order status = `pending`, Product stock = 5 | Customer submits POST to `/orders/{order_code}/cancel` with reason | Order status updated to `canceled`. `cancellation_reason` and `cancelled_at` saved. Product stock restored to 6 via atomic increment. |
| **TC-ORD-04** | Orders | Attempt cancellation of `shipping` order | UI / API | Order status = `shipping` | Customer attempts cancellation request | Blocked with HTTP 422 JSON: *"Order cannot be canceled in current status"*. Stock unchanged. |

---

## 6. Database Verification & SQL Test Scripts

To ensure underlying database integrity, the following SQL checks must be executed during QA validation.

### 6.1 Verify Order & Order Items Insertion
```sql
-- 1. Check newly created order fields and total precision
SELECT id, order_code, user_id, total_amount, status, payment_status, shipping_address, created_at 
FROM orders 
WHERE order_code = 'ORD-20260806-ABCD';

-- 2. Verify order line items and purchase price snapshot
SELECT oi.id, oi.order_id, oi.product_id, p.name, oi.quantity, oi.price_at_purchase 
FROM order_items oi
JOIN products p ON p.id = oi.product_id
WHERE oi.order_id = (SELECT id FROM orders WHERE order_code = 'ORD-20260806-ABCD');
```

### 6.2 Stock Deduction & Restoration Verification
```sql
-- Check stock level before and after checkout placement/cancellation
SELECT id, name, stock, price FROM products WHERE id IN (10, 12);
```

### 6.3 User Address Sync Check
```sql
-- Ensure user default shipping address is synced properly upon checkout
SELECT * FROM user_addresses WHERE user_id = 1 AND is_default = 1;
```

---

## 7. Defect Management & Risk Matrix

### 7.1 Defect Severity Classification

| Severity Level | Definition | Example Scenario | Target SLA / Resolution Time |
| :--- | :--- | :--- | :--- |
| **P1 - Critical** | System crash, data corruption, financial calculation error, overselling due to missing locks | Total order price calculated incorrectly, stock going negative under concurrency | Must be resolved within 4 hours |
| **P2 - High** | Major feature unusable without immediate workaround | User unable to submit checkout despite valid input | Resolved within 24 hours |
| **P3 - Medium** | Minor feature defect or incorrect error message | Dynamic shipping fee indicator UI glitch showing wrong threshold text | Resolved within 3 business days |
| **P4 - Low** | Cosmetic / Typo / Formatting issue | Alignment mis-spacing on order success page | Scheduled for upcoming sprint |

### 7.2 Risk Assessment & Mitigation

| Identified Technical Risk | Impact | Probability | Mitigation Strategy |
| :--- | :--- | :--- | :--- |
| **Race Conditions during High Concurrency** | High | Medium | Enforce pessimistic row-level locking (`lockForUpdate()`) and atomic DB operations (`decrement()`). Automated concurrency tests using Pest PHP. |
| **Session Tampering (Price Alteration)** | High | Low | Never trust client session prices. Perform DB re-query of prices inside the checkout transaction block. |
| **Un-handled Transaction Abort** | Medium | Medium | Wrap checkout logic inside `DB::beginTransaction()` with explicit `try-catch` and `DB::rollBack()`. |

---

## 8. Resources & Deliverables

### 8.1 QA Team Roles & Responsibilities
* **QA Manager / Lead:** Master Test Plan creation, test strategy oversight, defect triage, final release sign-off.
* **QA Automation / Manual Tester:** Test case execution, Postman API collection maintenance, SQL data verification, bug logging.

### 8.2 QA Deliverables
1. **Master Test Plan Document** (`docs/MASTER_TEST_PLAN.md`)
2. **Postman API Test Collection & Environment File** (`tests/postman/Cart_Checkout_Collection.json`)
3. **Automated Test Suites** (Pest / PHPUnit feature test specs under `tests/Feature/CartTest.php` and `tests/Feature/CheckoutTest.php`)
4. **Defect Log & Summary Report** (Bug tracking matrix with steps to reproduce and proof of fix)

---
*End of Master Test Plan Document.*
