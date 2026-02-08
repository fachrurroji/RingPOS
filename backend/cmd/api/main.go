package main

import (
	"log"
	"ringpos-backend/internal/database"
	"ringpos-backend/internal/handlers"
	"ringpos-backend/internal/middleware"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using default env variables")
	}

	// Connect to Database
	db, err := database.Connect()
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// Auto Migrate
	if err := database.Migrate(db); err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	// Seed default data
	database.Seed(db)

	// Setup Router
	r := gin.Default()

	// CORS - Allow Flutter web app
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:*", "http://127.0.0.1:*", "*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		AllowCredentials: true,
	}))

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// Get JWT secret for middleware
	jwtSecret := middleware.GetJWTSecretForRouter()

	// API Routes
	api := r.Group("/api")
	{
		// Public routes (no auth required)
		api.POST("/login", handlers.Login(db))

		// Protected routes (require JWT auth)
		protected := api.Group("")
		protected.Use(middleware.AuthMiddleware(jwtSecret))
		protected.Use(middleware.TenantMiddleware())
		{
			// Config
			protected.GET("/config", handlers.GetConfig(db))

			// Products
			protected.GET("/products", handlers.GetProducts(db))
			protected.GET("/products/:id", handlers.GetProduct(db))
			protected.POST("/products", handlers.CreateProduct(db))
			protected.PUT("/products/:id", handlers.UpdateProduct(db))
			protected.DELETE("/products/:id", handlers.DeleteProduct(db))
			protected.PATCH("/products/:id/stock", handlers.UpdateStock(db))
			protected.POST("/products/bulk-stock", handlers.BulkUpdateStock(db))

			// Orders
			protected.GET("/orders", handlers.GetOrders(db))
			protected.GET("/orders/daily-sales", handlers.GetDailySales(db))
			protected.GET("/orders/:id", handlers.GetOrder(db))
			protected.POST("/orders", handlers.CreateOrder(db))
			protected.PATCH("/orders/:id/status", handlers.UpdateOrderStatus(db))

			// Users
			protected.GET("/users", handlers.GetUsers(db))
			protected.GET("/users/:id", handlers.GetUser(db))
			protected.POST("/users", handlers.CreateUser(db))
			protected.PUT("/users/:id", handlers.UpdateUser(db))
			protected.DELETE("/users/:id", handlers.DeleteUser(db))

			// Customers
			protected.GET("/customers", handlers.GetCustomers(db))
			protected.GET("/customers/:id", handlers.GetCustomer(db))
			protected.POST("/customers", handlers.CreateCustomer(db))
			protected.PUT("/customers/:id", handlers.UpdateCustomer(db))
			protected.DELETE("/customers/:id", handlers.DeleteCustomer(db))

			// Import
			protected.POST("/products/import", handlers.ImportProducts(db))

			// Stock Management
			protected.GET("/stock/logs", handlers.GetStockLogs(db))
			protected.GET("/stock/logs/:productId", handlers.GetProductStockHistory(db))
			protected.POST("/stock/adjust", handlers.AdjustStock(db))
			protected.POST("/stock/restock", handlers.RestockProduct(db))

			// Suppliers
			protected.GET("/suppliers", handlers.GetSuppliers(db))
			protected.GET("/suppliers/:id", handlers.GetSupplier(db))
			protected.POST("/suppliers", handlers.CreateSupplier(db))
			protected.PUT("/suppliers/:id", handlers.UpdateSupplier(db))
			protected.DELETE("/suppliers/:id", handlers.DeleteSupplier(db))
		}

		// Superadmin routes (require superadmin role)
		superadmin := api.Group("/superadmin")
		superadmin.Use(middleware.AuthMiddleware(jwtSecret))
		superadmin.Use(middleware.SuperadminOnly())
		{
			superadmin.GET("/stats", handlers.GetSuperadminStats(db))
			superadmin.GET("/tenants", handlers.ListTenants(db))
			superadmin.POST("/tenants", handlers.CreateTenant(db))
			superadmin.PUT("/tenants/:id", handlers.UpdateTenant(db))
			superadmin.DELETE("/tenants/:id", handlers.DeleteTenant(db))
			superadmin.POST("/tenants/:id/impersonate", handlers.ImpersonateTenant(db))
		}
	}

	// Start Server
	port := ":8080"
	log.Printf("🚀 RingPOS Backend running on http://localhost%s", port)
	log.Printf("📚 API Endpoints:")
	log.Printf("   POST   /api/login (Public)")
	log.Printf("   GET    /api/config (Protected)")
	log.Printf("   GET    /api/products (Protected)")
	log.Printf("   POST   /api/orders (Protected)")
	log.Printf("   GET    /api/superadmin/tenants (Superadmin)")
	
	if err := r.Run(port); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}

