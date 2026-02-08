# RingPOS - Product Requirements Document

## 1. Product Overview

**Product Name:** RingPOS
**Version:** 1.0
**Type:** Multi-tenant Cloud-Based Point of Sale System

RingPOS is a unified POS platform supporting three distinct business modes: Retail, Food & Beverage (F&B), and Service-based businesses. The system features a multi-tenant architecture with Superadmin and Admin roles, ensuring complete data isolation between tenants.

---

## 2. User Roles

| Role | Description | Access Level |
|------|-------------|--------------|
| Superadmin | System administrator managing all tenants | Full system access, tenant CRUD, impersonation |
| Owner | Business owner/admin of a single tenant | Full tenant access, settings, reports |
| Staff | Cashier/employee | POS operations only |

---

## 3. Core Features

### 3.1 Authentication
- **Login Flow**: Username/password authentication
- **JWT Token**: Secure token-based authentication
- **Role-based Access**: Different UI/features based on role
- **Session Management**: Persistent login state

### 3.2 Multi-Tenant Dashboard
- **Mode Selection**: Retail, F&B, or Service mode
- **Dynamic Sidebar**: Menu adapts based on business configuration
- **Quick Stats**: Real-time sales, orders, products overview

### 3.3 Product Management
- **CRUD Operations**: Add, edit, delete products
- **Categories**: Organize products by category
- **Stock Tracking**: Monitor inventory levels
- **Search & Filter**: Find products quickly
- **Tenant Isolation**: Each tenant sees only their products

### 3.4 POS Cashier Flow
- **Product Grid**: Visual product selection
- **Cart Management**: Add/remove items, adjust quantities
- **Payment Processing**: Cash, Card, E-Wallet support
- **Order Creation**: Submit order to backend
- **Receipt Generation**: Print or share receipts

### 3.5 Order History
- **Order List**: View all past orders
- **Status Filters**: All, Paid, Pending, Cancelled
- **Order Details**: Expandable view with items
- **Sales Stats**: Total orders, total sales

---

## 4. Technical Specifications

### Frontend
- **Framework**: Flutter Web
- **State Management**: Riverpod
- **HTTP Client**: Dio
- **Authentication**: JWT stored in memory

### Backend
- **Language**: Go
- **Framework**: Gin
- **Database**: SQLite (dev) / PostgreSQL (prod)
- **ORM**: GORM

### API Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/login | User authentication |
| GET | /api/products | List products (tenant-scoped) |
| POST | /api/products | Create product |
| PUT | /api/products/:id | Update product |
| DELETE | /api/products/:id | Delete product |
| GET | /api/orders | List orders (tenant-scoped) |
| POST | /api/orders | Create order |
| GET | /api/config | Business configuration |

---

## 5. Test Scenarios

### 5.1 Login Flow
1. Open login page
2. Enter valid credentials (admin/admin123)
3. Verify redirect to dashboard
4. Verify user info displayed correctly

### 5.2 Product Management
1. Navigate to Products tab
2. Click "Add Product" button
3. Fill in product details
4. Save and verify product appears in list
5. Edit product and verify changes
6. Delete product and verify removal

### 5.3 POS Transaction
1. Navigate to POS screen
2. Click products to add to cart
3. Verify cart total updates
4. Click "Pay" button
5. Select payment method
6. Complete payment
7. Verify order created in Order History

### 5.4 Order History
1. Navigate to Orders tab
2. Verify orders list displays
3. Filter by status (Paid)
4. Expand order to see details
5. Verify order items match

---

## 6. Success Criteria

- Login successfully authenticates user
- Products CRUD operations work correctly
- POS creates orders with correct totals
- Order history displays accurate data
- Tenant data isolation is enforced
