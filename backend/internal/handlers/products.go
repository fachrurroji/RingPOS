package handlers

import (
	"net/http"
	"ringpos-backend/internal/models"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// GetProducts - GET /api/products
func GetProducts(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var products []models.Product
		
		query := db
		
		// Get tenant_id from JWT context (set by TenantMiddleware)
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil {
				query = query.Where("tenant_id = ?", *tenantID.(*uint))
			}
		} else {
			// Superadmin can filter by query param
			if tenantID := c.Query("tenant_id"); tenantID != "" {
				query = query.Where("tenant_id = ?", tenantID)
			}
		}
		
		// Filter by category if provided
		if category := c.Query("category"); category != "" && category != "All Items" {
			query = query.Where("category = ?", category)
		}
		
		// Search by name
		if search := c.Query("search"); search != "" {
			query = query.Where("name LIKE ?", "%"+search+"%")
		}
		
		if err := query.Find(&products).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch products"})
			return
		}
		
		c.JSON(http.StatusOK, products)
	}
}

// GetProduct - GET /api/products/:id
func GetProduct(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		
		var product models.Product
		if err := db.First(&product, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
			return
		}
		
		c.JSON(http.StatusOK, product)
	}
}

// CreateProduct - POST /api/products
func CreateProduct(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var product models.Product
		
		if err := c.ShouldBindJSON(&product); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		
		// Set tenant_id from JWT context
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil {
				product.TenantID = *tenantID.(*uint)
			} else {
				c.JSON(http.StatusForbidden, gin.H{"error": "Tenant ID required"})
				return
			}
		}
		
		if err := db.Create(&product).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create product"})
			return
		}
		
		c.JSON(http.StatusCreated, product)
	}
}

// UpdateProduct - PUT /api/products/:id
func UpdateProduct(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		
		var product models.Product
		if err := db.First(&product, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
			return
		}
		
		// Verify tenant ownership (non-superadmin)
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if !exists || tenantID == nil || product.TenantID != *tenantID.(*uint) {
				c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
				return
			}
		}
		
		var updateData models.Product
		if err := c.ShouldBindJSON(&updateData); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		
		// Prevent changing tenant_id
		updateData.TenantID = product.TenantID
		
		// Update fields
		db.Model(&product).Updates(updateData)
		
		c.JSON(http.StatusOK, product)
	}
}

// DeleteProduct - DELETE /api/products/:id
func DeleteProduct(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		
		var product models.Product
		if err := db.First(&product, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
			return
		}
		
		// Verify tenant ownership (non-superadmin)
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if !exists || tenantID == nil || product.TenantID != *tenantID.(*uint) {
				c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
				return
			}
		}
		
		db.Delete(&product)
		
		c.JSON(http.StatusOK, gin.H{"message": "Product deleted"})
	}
}

// UpdateStock - PATCH /api/products/:id/stock
func UpdateStock(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		
		var stockUpdate struct {
			Quantity int    `json:"quantity"`
			Action   string `json:"action"` // "add" or "subtract"
		}
		
		if err := c.ShouldBindJSON(&stockUpdate); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		
		var product models.Product
		if err := db.First(&product, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
			return
		}
		
		if stockUpdate.Action == "add" {
			product.Stock += stockUpdate.Quantity
		} else if stockUpdate.Action == "subtract" {
			product.Stock -= stockUpdate.Quantity
			if product.Stock < 0 {
				product.Stock = 0
			}
		}
		
		db.Save(&product)
		
		c.JSON(http.StatusOK, product)
	}
}

// BulkUpdateStock - POST /api/products/bulk-stock (for checkout)
func BulkUpdateStock(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var updates []struct {
			ProductID uint `json:"product_id"`
			Quantity  int  `json:"quantity"`
		}
		
		if err := c.ShouldBindJSON(&updates); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		
		// Use transaction
		tx := db.Begin()
		
		for _, update := range updates {
			var product models.Product
			if err := tx.First(&product, update.ProductID).Error; err != nil {
				tx.Rollback()
				c.JSON(http.StatusNotFound, gin.H{"error": "Product " + strconv.Itoa(int(update.ProductID)) + " not found"})
				return
			}
			
			product.Stock -= update.Quantity
			if product.Stock < 0 {
				product.Stock = 0
			}
			
			if err := tx.Save(&product).Error; err != nil {
				tx.Rollback()
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update stock"})
				return
			}
		}
		
		tx.Commit()
		
		c.JSON(http.StatusOK, gin.H{"message": "Stock updated successfully"})
	}
}
