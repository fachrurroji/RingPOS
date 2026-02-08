# RingPOS - Alur Aplikasi

## 🔐 Alur Login

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Login Page │ -> │ POST /login │ -> │  JWT Token  │ -> │  Dashboard  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

**Role-based redirect:**
- `superadmin` → Superadmin Dashboard
- `owner/admin` → Admin Dashboard (mode-specific)
- `staff` → POS Screen (mode-specific)

---

## 🛒 Mode: RETAIL

### Alur Transaksi Kasir

```
┌──────────┐    ┌──────────┐    ┌────────────┐    ┌───────────┐    ┌──────────┐
│ POS Screen│ -> │ Add Item │ -> │   Cart     │ -> │  Payment  │ -> │  Receipt │
└──────────┘    └──────────┘    └────────────┘    └───────────┘    └──────────┘
      │
      ├── Scan Barcode
      ├── Click Product Grid
      └── Quick Keys
```

**Detail Steps:**
1. Kasir buka POS Screen
2. Scan barcode ATAU klik produk dari grid
3. Item masuk ke cart (bisa adjust qty)
4. Klik "Pay" → pilih metode pembayaran
5. Cash: input nominal, hitung kembalian
6. Card/E-Wallet: proses
7. Print/share receipt

### Alur Stock Management

```
Dashboard → Products → Add/Edit/Delete Product → Stock Update
                 ↓
         Low Stock Alert (< 10 items)
```

---

## 🍕 Mode: F&B (Food & Beverage)

### Alur Order Restoran

```
┌──────────┐    ┌──────────┐    ┌────────────┐    ┌───────────┐    ┌──────────┐
│ Table Map│ -> │Select Tbl│ -> │ Add Menu   │ -> │  Kitchen  │ -> │  Payment │
└──────────┘    └──────────┘    └────────────┘    └───────────┘    └──────────┘
                                      │
                                      └── + Modifiers (extra topping, etc)
```

**Detail Steps:**
1. Waitress buka Table Map
2. Pilih meja yang tersedia (status: Available)
3. Tambah menu ke order
4. Pilih modifier (jika ada): extra cheese, less sugar, etc.
5. Submit order → Kitchen Display menerima
6. Kitchen update status: Preparing → Ready → Served
7. Customer minta bill → Payment → Print receipt
8. Meja kembali ke status Available

### Status Meja

| Status | Color | Meaning |
|--------|-------|---------|
| Available | 🟢 Green | Meja kosong |
| Occupied | 🟡 Yellow | Ada order aktif |
| Reserved | 🔵 Blue | Sudah dibooking |
| Cleaning | 🟠 Orange | Sedang dibersihkan |

---

## 💇 Mode: SERVICE

### Alur Booking & Layanan

```
┌──────────┐    ┌──────────┐    ┌────────────┐    ┌───────────┐    ┌──────────┐
│ Calendar │ -> │ Book Slot│ -> │Assign Staff│ -> │  Service  │ -> │  Payment │
└──────────┘    └──────────┘    └────────────┘    └───────────┘    └──────────┘
```

**Detail Steps:**
1. Customer booking via calendar (pilih tanggal & waktu)
2. Pilih jenis layanan (Haircut, Massage, etc)
3. System assign staff available
4. Customer datang → Check-in
5. Staff mulai layanan
6. Layanan selesai → Payment
7. Optional: Add-on services selama proses

### Walk-in Customer

```
┌──────────┐    ┌──────────┐    ┌────────────┐    ┌───────────┐
│Walk-in   │ -> │ Queue    │ -> │  Service   │ -> │  Payment  │
└──────────┘    └──────────┘    └────────────┘    └───────────┘
```

---

## 👑 Superadmin Flow

### Multi-Tenant Management

```
┌──────────────┐    ┌────────────────────────────────────────┐
│ Superadmin   │ -> │ - Create/Edit/Delete Tenants           │
│ Dashboard    │    │ - View All Stats (cross-tenant)        │
│              │    │ - Impersonate Tenant Admin             │
│              │    │ - Manage Subscriptions                 │
└──────────────┘    └────────────────────────────────────────┘
```

**Impersonation Flow:**
1. Superadmin klik "Impersonate" pada tenant
2. Session switch ke context tenant tersebut
3. Lihat data & operasi sebagai admin tenant
4. Klik "Exit Impersonation" untuk kembali

---

## 📊 Reporting Flow

```
Dashboard → Reports → Select Date Range → View Analytics
                           │
                           ├── Sales by Day
                           ├── Sales by Category  
                           ├── Top Products
                           └── Payment Methods
```

---

## 🔄 Data Isolation

```
                    ┌─────────────────┐
                    │   Superadmin    │  (sees all tenants)
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
    ┌────┴────┐         ┌────┴────┐         ┌────┴────┐
    │Tenant A │         │Tenant B │         │Tenant C │
    │ (Retail)│         │  (F&B)  │         │(Service)│
    └────┬────┘         └────┬────┘         └────┬────┘
         │                   │                   │
    ┌────┴────┐         ┌────┴────┐         ┌────┴────┐
    │Products │         │Products │         │Services │
    │Orders   │         │Orders   │         │Bookings │
    │Users    │         │Tables   │         │Staff    │
    └─────────┘         └─────────┘         └─────────┘
```

**Tenant Isolation Rules:**
- Setiap API request di-filter by `tenant_id` dari JWT token
- Admin hanya bisa akses data tenant sendiri
- Staff hanya bisa operasi POS

---

## API Endpoint Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/login` | Authentication |
| GET | `/api/products` | List products |
| POST | `/api/products` | Create product |
| GET | `/api/orders` | List orders |
| POST | `/api/orders` | Create order |
| GET | `/api/orders/daily-sales` | Today's sales |
| GET | `/api/config` | Business config |
