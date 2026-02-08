package database

import (
	"log"
	"os"
	"path/filepath"

	"github.com/glebarez/sqlite"
	"gorm.io/gorm"
	"ringpos-backend/internal/models"
)

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func Connect() (*gorm.DB, error) {
	// Get database path - default to ./data/ringpos.db
	dbPath := getEnv("DB_PATH", "./data/ringpos.db")
	
	// Create directory if not exists
	dir := filepath.Dir(dbPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, err
	}
	
	log.Printf("📦 Connecting to SQLite database: %s", dbPath)
	
	db, err := gorm.Open(sqlite.Open(dbPath), &gorm.Config{})
	if err != nil {
		return nil, err
	}
	
	log.Println("✅ Database connected!")
	return db, nil
}

func Migrate(db *gorm.DB) error {
	log.Println("🔄 Running database migrations...")
	return db.AutoMigrate(
		&models.Tenant{},
		&models.User{},
		&models.Product{},
		&models.Order{},
		&models.Customer{},
		&models.StockLog{},
		&models.Supplier{},
	)
}
