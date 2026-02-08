package handlers

import (
	"encoding/json"
	"net/http"
	"ringpos-backend/internal/models"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// GetOrders - GET /api/orders
func GetOrders(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var orders []models.Order
		
		query := db.Order("created_at DESC")
		
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
		
		// Filter by status
		if status := c.Query("status"); status != "" {
			query = query.Where("status = ?", status)
		}
		
		// Filter by date range
		if dateFrom := c.Query("date_from"); dateFrom != "" {
			query = query.Where("created_at >= ?", dateFrom)
		}
		if dateTo := c.Query("date_to"); dateTo != "" {
			query = query.Where("created_at <= ?", dateTo)
		}
		
		// Limit (default 50)
		query = query.Limit(50)
		
		if err := query.Find(&orders).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch orders"})
			return
		}
		
		c.JSON(http.StatusOK, orders)
	}
}

// GetOrder - GET /api/orders/:id
func GetOrder(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		
		var order models.Order
		if err := db.First(&order, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
			return
		}
		
		c.JSON(http.StatusOK, order)
	}
}

// CreateOrder - POST /api/orders
func CreateOrder(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var orderReq struct {
			TenantID      uint                     `json:"tenant_id"`
			Items         []map[string]interface{} `json:"items"`
			Subtotal      float64                  `json:"subtotal"`
			Tax           float64                  `json:"tax"`
			Discount      float64                  `json:"discount"`
			Total         float64                  `json:"total"`
			PaymentMethod string                   `json:"payment_method"`
			TableNumber   string                   `json:"table_number,omitempty"`
			CustomerName  string                   `json:"customer_name,omitempty"`
			CustomerPhone string                   `json:"customer_phone,omitempty"`
		}
		
		if err := c.ShouldBindJSON(&orderReq); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		
		// Build order details JSON
		detailsMap := map[string]interface{}{
			"items":          orderReq.Items,
			"subtotal":       orderReq.Subtotal,
			"tax":            orderReq.Tax,
			"discount":       orderReq.Discount,
			"payment_method": orderReq.PaymentMethod,
			"table_number":   orderReq.TableNumber,
			"customer_name":  orderReq.CustomerName,
			"customer_phone": orderReq.CustomerPhone,
			"created_at":     time.Now().Format(time.RFC3339),
		}
		
		detailsJSON, _ := json.Marshal(detailsMap)
		
		order := models.Order{
			TenantID: orderReq.TenantID,
			Status:   "PAID",
			Total:    orderReq.Total,
			Details:  string(detailsJSON),
		}
		
		// Transaction: Create order and update stock
		tx := db.Begin()
		
		if err := tx.Create(&order).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create order"})
			return
		}
		
		// Update stock for each item
		for _, item := range orderReq.Items {
			productID, ok := item["product_id"].(float64)
			quantity, qok := item["quantity"].(float64)
			
			if ok && qok {
				var product models.Product
				if err := tx.First(&product, uint(productID)).Error; err == nil {
					product.Stock -= int(quantity)
					if product.Stock < 0 {
						product.Stock = 0
					}
					tx.Save(&product)
				}
			}
		}
		
		tx.Commit()
		
		c.JSON(http.StatusCreated, gin.H{
			"order_id":     order.ID,
			"order_number": order.ID,
			"status":       order.Status,
			"total":        order.Total,
			"message":      "Order created successfully",
		})
	}
}

// UpdateOrderStatus - PATCH /api/orders/:id/status
func UpdateOrderStatus(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		
		var statusUpdate struct {
			Status string `json:"status"`
		}
		
		if err := c.ShouldBindJSON(&statusUpdate); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		
		var order models.Order
		if err := db.First(&order, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
			return
		}
		
		order.Status = statusUpdate.Status
		db.Save(&order)
		
		c.JSON(http.StatusOK, order)
	}
}

// GetDailySales - GET /api/orders/daily-sales
func GetDailySales(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		tenantID := c.Query("tenant_id")
		date := c.DefaultQuery("date", time.Now().Format("2006-01-02"))
		
		var result struct {
			TotalSales   float64 `json:"total_sales"`
			OrderCount   int64   `json:"order_count"`
			AverageOrder float64 `json:"average_order"`
		}
		
		query := db.Model(&models.Order{}).
			Where("DATE(created_at) = ?", date).
			Where("status = ?", "PAID")
		
		if tenantID != "" {
			query = query.Where("tenant_id = ?", tenantID)
		}
		
		query.Select("COALESCE(SUM(total), 0) as total_sales, COUNT(*) as order_count").
			Scan(&result)
		
		if result.OrderCount > 0 {
			result.AverageOrder = result.TotalSales / float64(result.OrderCount)
		}
		
		c.JSON(http.StatusOK, result)
	}
}

