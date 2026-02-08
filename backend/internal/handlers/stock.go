package handlers

import (
	"net/http"
	"ringpos-backend/internal/models"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// GetStockLogs - GET /api/stock/logs
func GetStockLogs(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var logs []models.StockLog

		query := db.Preload("Product").Order("created_at DESC")

		// Tenant isolation
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil {
				query = query.Where("tenant_id = ?", *tenantID.(*uint))
			}
		}

		// Filter by product
		if productID := c.Query("product_id"); productID != "" {
			query = query.Where("product_id = ?", productID)
		}

		// Filter by type
		if logType := c.Query("type"); logType != "" {
			query = query.Where("type = ?", logType)
		}

		// Limit
		limit := 50
		if l := c.Query("limit"); l != "" {
			if parsed, err := strconv.Atoi(l); err == nil {
				limit = parsed
			}
		}
		query = query.Limit(limit)

		if err := query.Find(&logs).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, logs)
	}
}

// GetProductStockHistory - GET /api/stock/logs/:productId
func GetProductStockHistory(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		productID := c.Param("productId")
		var logs []models.StockLog

		query := db.Where("product_id = ?", productID).Order("created_at DESC").Limit(50)

		// Tenant isolation
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil {
				query = query.Where("tenant_id = ?", *tenantID.(*uint))
			}
		}

		if err := query.Find(&logs).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, logs)
	}
}

// StockAdjustmentRequest - Request body for stock adjustment
type StockAdjustmentRequest struct {
	ProductID    uint   `json:"product_id" binding:"required"`
	ChangeAmount int    `json:"change_amount" binding:"required"` // Can be positive or negative
	Reason       string `json:"reason" binding:"required"`        // Damaged, Expired, Correction, Stock Opname
}

// AdjustStock - POST /api/stock/adjust
func AdjustStock(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req StockAdjustmentRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Get tenant_id and user info from context
		var tenantID uint
		role, _ := c.Get("role")
		if role != "superadmin" {
			tid, exists := c.Get("tenant_id")
			if exists && tid != nil {
				tenantID = *tid.(*uint)
			}
		}

		userID, _ := c.Get("user_id")
		username, _ := c.Get("username")

		// Get product
		var product models.Product
		if err := db.First(&product, req.ProductID).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
			return
		}

		// Check tenant isolation
		if role != "superadmin" && product.TenantID != tenantID {
			c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
			return
		}

		// Update product stock
		newStock := product.Stock + req.ChangeAmount
		if newStock < 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Stock cannot be negative"})
			return
		}

		product.Stock = newStock
		if err := db.Save(&product).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		// Create stock log
		log := models.StockLog{
			TenantID:     tenantID,
			ProductID:    req.ProductID,
			ChangeAmount: req.ChangeAmount,
			Type:         "adjustment",
			Reason:       req.Reason,
			UserID:       userID.(uint),
			Username:     username.(string),
		}

		if err := db.Create(&log).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message":   "Stock adjusted successfully",
			"new_stock": newStock,
			"log":       log,
		})
	}
}

// RestockRequest - Request body for restocking from supplier
type RestockRequest struct {
	ProductID  uint   `json:"product_id" binding:"required"`
	Quantity   int    `json:"quantity" binding:"required,gt=0"`
	SupplierID *uint  `json:"supplier_id"`
	Notes      string `json:"notes"`
}

// RestockProduct - POST /api/stock/restock
func RestockProduct(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req RestockRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Get tenant_id and user info
		var tenantID uint
		role, _ := c.Get("role")
		if role != "superadmin" {
			tid, exists := c.Get("tenant_id")
			if exists && tid != nil {
				tenantID = *tid.(*uint)
			}
		}

		userID, _ := c.Get("user_id")
		username, _ := c.Get("username")

		// Get product
		var product models.Product
		if err := db.First(&product, req.ProductID).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
			return
		}

		// Check tenant
		if role != "superadmin" && product.TenantID != tenantID {
			c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
			return
		}

		// Update stock
		product.Stock += req.Quantity
		if err := db.Save(&product).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		// Create stock log
		reason := "Restock"
		if req.Notes != "" {
			reason = "Restock: " + req.Notes
		}

		log := models.StockLog{
			TenantID:     tenantID,
			ProductID:    req.ProductID,
			ChangeAmount: req.Quantity,
			Type:         "restock",
			Reason:       reason,
			ReferenceID:  req.SupplierID,
			UserID:       userID.(uint),
			Username:     username.(string),
		}

		if err := db.Create(&log).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message":   "Product restocked successfully",
			"new_stock": product.Stock,
			"log":       log,
		})
	}
}
