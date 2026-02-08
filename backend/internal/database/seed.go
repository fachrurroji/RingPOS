package database

import (
	"encoding/json"
	"log"
	"ringpos-backend/internal/models"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// hashPassword hashes a password using bcrypt
func hashPassword(password string) string {
	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("Warning: Failed to hash password: %v", err)
		return password // fallback to plain text in dev
	}
	return string(hashed)
}

// Seed creates default data if not exists
func Seed(db *gorm.DB) {
	// Check if already seeded
	var count int64
	db.Model(&models.Tenant{}).Count(&count)
	if count > 0 {
		log.Println("📦 Database already seeded, skipping...")
		return
	}

	log.Println("🌱 Seeding database...")

	// Create Superadmin user (no tenant)
	superadmin := models.User{
		Username: "superadmin",
		Password: hashPassword("super123"),
		TenantID: nil, // No tenant for superadmin
		Role:     "superadmin",
	}
	db.Create(&superadmin)

	// Create default Retail tenant
	retailTenant := models.Tenant{
		Name:             "RingPOS Demo Store",
		BusinessType:     models.Retail,
		Address:          "123 Main Street",
		Status:           "active",
		SubscriptionPlan: "pro",
		ModulesEnabled:   `["barcode_scanner","wholesale_pricing","inventory"]`,
	}
	db.Create(&retailTenant)

	// Create admin user for retail tenant
	retailAdmin := models.User{
		Username: "admin",
		Password: hashPassword("admin123"),
		TenantID: &retailTenant.ID,
		Role:     "owner",
	}
	db.Create(&retailAdmin)

	// Create F&B tenant  
	fnbTenant := models.Tenant{
		Name:             "Kopi Kenangan Demo",
		BusinessType:     models.FB,
		Address:          "456 Food Court",
		Status:           "active",
		SubscriptionPlan: "basic",
		ModulesEnabled:   `["table_map","kitchen_print","modifiers"]`,
	}
	db.Create(&fnbTenant)

	fnbAdmin := models.User{
		Username: "fnbadmin",
		Password: hashPassword("fnb123"),
		TenantID: &fnbTenant.ID,
		Role:     "owner",
	}
	db.Create(&fnbAdmin)

	// Create sample products for retail tenant
	products := []models.Product{
		{TenantID: retailTenant.ID, Name: "Fresh Whole Milk 1L", Price: 2.50, Stock: 50, Category: "Dairy", ImageURL: "milk"},
		{TenantID: retailTenant.ID, Name: "Whole Wheat Bread", Price: 3.20, Stock: 30, Category: "Bakery", ImageURL: "bread"},
		{TenantID: retailTenant.ID, Name: "Coca Cola 500ml", Price: 1.50, Stock: 100, Category: "Beverages", ImageURL: "cola"},
		{TenantID: retailTenant.ID, Name: "Snickers Bar", Price: 0.99, Stock: 80, Category: "Snacks", ImageURL: "snickers"},
		{TenantID: retailTenant.ID, Name: "Dove Soap Bar", Price: 1.20, Stock: 60, Category: "Household", ImageURL: "soap"},
		{TenantID: retailTenant.ID, Name: "Red Apples (kg)", Price: 3.50, Stock: 40, Category: "Produce", ImageURL: "apples"},
		{TenantID: retailTenant.ID, Name: "Lays Classic", Price: 1.80, Stock: 70, Category: "Snacks", ImageURL: "lays"},
		{TenantID: retailTenant.ID, Name: "Head & Shoulders", Price: 5.50, Stock: 25, Category: "Household", ImageURL: "shampoo"},
		{TenantID: retailTenant.ID, Name: "Tomato Soup Can", Price: 1.10, Stock: 45, Category: "Pantry", ImageURL: "soup"},
		{TenantID: retailTenant.ID, Name: "Mineral Water 1L", Price: 0.80, Stock: 120, Category: "Beverages", ImageURL: "water"},
		{TenantID: retailTenant.ID, Name: "Rice 25kg", Price: 45.00, Stock: 20, Category: "Quick Keys", ImageURL: "rice",
			Metadata: toJSON(map[string]interface{}{"wholesale_rules": []map[string]interface{}{{"min_qty": 5, "price": 43.00}, {"min_qty": 10, "price": 40.00}}})},
		{TenantID: retailTenant.ID, Name: "LPG Cylinder", Price: 22.50, Stock: 15, Category: "Quick Keys", ImageURL: "lpg"},
		{TenantID: retailTenant.ID, Name: "Egg Tray (30)", Price: 8.99, Stock: 25, Category: "Quick Keys", ImageURL: "eggs"},
	}

	// Create sample products for F&B tenant
	fnbProducts := []models.Product{
		{TenantID: fnbTenant.ID, Name: "Americano", Price: 18000, Stock: 999, Category: "Coffee", ImageURL: "coffee"},
		{TenantID: fnbTenant.ID, Name: "Latte", Price: 25000, Stock: 999, Category: "Coffee", ImageURL: "latte"},
		{TenantID: fnbTenant.ID, Name: "Croissant", Price: 15000, Stock: 50, Category: "Pastry", ImageURL: "croissant"},
		{TenantID: fnbTenant.ID, Name: "Cheesecake", Price: 35000, Stock: 20, Category: "Dessert", ImageURL: "cake"},
	}

	for _, p := range products {
		db.Create(&p)
	}
	for _, p := range fnbProducts {
		db.Create(&p)
	}

	log.Println("✅ Database seeded with demo data!")
	log.Printf("   - Superadmin: superadmin (password: super123)")
	log.Printf("   - Retail Tenant: %s", retailTenant.Name)
	log.Printf("     Admin: admin (password: admin123)")
	log.Printf("   - F&B Tenant: %s", fnbTenant.Name)
	log.Printf("     Admin: fnbadmin (password: fnb123)")
	log.Printf("   - %d Products total", len(products)+len(fnbProducts))
}

func toJSON(v interface{}) string {
	b, _ := json.Marshal(v)
	return string(b)
}

