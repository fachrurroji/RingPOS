package models

import (
	"time"

	"gorm.io/gorm"
)

type TenantType string

const (
	Retail  TenantType = "RETAIL"
	FB      TenantType = "FB"
	Service TenantType = "SERVICE"
)

type Tenant struct {
	gorm.Model
	Name             string     `json:"name"`
	BusinessType     TenantType `json:"business_type"` // RETAIL, FB, SERVICE
	Address          string     `json:"address"`
	Config           string     `json:"config"`           // JSON string for custom config
	ModulesEnabled   string     `json:"modules_enabled"`  // JSON array of enabled modules
	Status           string     `json:"status"`           // active, suspended, trial
	SubscriptionPlan string     `json:"subscription_plan"` // basic, pro, enterprise
	ExpiresAt        *time.Time `json:"expires_at"`
}

type User struct {
	gorm.Model
	Username string `json:"username" gorm:"uniqueIndex"`
	Password string `json:"-"` // Store hashed password
	TenantID *uint  `json:"tenant_id"` // Nullable for superadmin
	Tenant   Tenant `json:"tenant"`
	Role     string `json:"role"` // superadmin, owner, cashier, kitchen
}

type Product struct {
	gorm.Model
	TenantID uint    `json:"tenant_id"`
	Name     string  `json:"name"`
	Price    float64 `json:"price"`
	Stock    int     `json:"stock"`
	Category string  `json:"category"`
	ImageURL string  `json:"image_url"`
	Metadata string  `json:"metadata"` // JSON string for flexible fields
}

type Order struct {
	gorm.Model
	TenantID uint    `json:"tenant_id"`
	Status   string  `json:"status"` // PENDING, PAID, SERVED, COMPLETED
	Total    float64 `json:"total"`
	Details  string  `json:"details"` // JSON string for order items
}

type Customer struct {
	gorm.Model
	TenantID uint   `json:"tenant_id"`
	Name     string `json:"name"`
	Phone    string `json:"phone"`
	Email    string `json:"email"`
	Address  string `json:"address"`
	Notes    string `json:"notes"`
}

// StockLog tracks all inventory changes
type StockLog struct {
	gorm.Model
	TenantID     uint   `json:"tenant_id"`
	ProductID    uint   `json:"product_id"`
	Product      Product `json:"product" gorm:"foreignKey:ProductID"`
	ChangeAmount int    `json:"change_amount"` // Positive for IN, Negative for OUT
	Type         string `json:"type"`          // sale, restock, adjustment, return
	Reason       string `json:"reason"`        // e.g., "Sold", "Damaged", "Expired", "Stock Opname"
	ReferenceID  *uint  `json:"reference_id"`  // Order ID or other reference
	UserID       uint   `json:"user_id"`
	Username     string `json:"username"`      // Denormalized for easy display
}

// Supplier for managing suppliers
type Supplier struct {
	gorm.Model
	TenantID      uint   `json:"tenant_id"`
	Name          string `json:"name"`
	ContactPerson string `json:"contact_person"`
	Phone         string `json:"phone"`
	Email         string `json:"email"`
	Address       string `json:"address"`
	Notes         string `json:"notes"`
}
