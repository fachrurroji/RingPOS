package handlers

import (
	"net/http"
	"ringpos-backend/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// GetCustomers - GET /api/customers
func GetCustomers(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var customers []models.Customer
		
		query := db.Order("created_at DESC")
		
		// Tenant isolation
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil {
				query = query.Where("tenant_id = ?", *tenantID.(*uint))
			}
		} else {
			if tenantID := c.Query("tenant_id"); tenantID != "" {
				query = query.Where("tenant_id = ?", tenantID)
			}
		}
		
		// Search
		if search := c.Query("search"); search != "" {
			query = query.Where("name LIKE ? OR phone LIKE ? OR email LIKE ?", 
				"%"+search+"%", "%"+search+"%", "%"+search+"%")
		}

		if err := query.Find(&customers).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, customers)
	}
}

// GetCustomer - GET /api/customers/:id
func GetCustomer(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var customer models.Customer

		if err := db.First(&customer, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Customer not found"})
			return
		}

		// Check tenant isolation
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil {
				if customer.TenantID != *tenantID.(*uint) {
					c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
					return
				}
			}
		}

		c.JSON(http.StatusOK, customer)
	}
}

// CreateCustomerRequest - Request body for creating customer
type CreateCustomerRequest struct {
	Name    string `json:"name" binding:"required"`
	Phone   string `json:"phone"`
	Email   string `json:"email"`
	Address string `json:"address"`
	Notes   string `json:"notes"`
}

// CreateCustomer - POST /api/customers
func CreateCustomer(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req CreateCustomerRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Get tenant_id from context
		var tenantID uint
		role, _ := c.Get("role")
		if role != "superadmin" {
			tid, exists := c.Get("tenant_id")
			if exists && tid != nil {
				tenantID = *tid.(*uint)
			}
		}

		customer := models.Customer{
			TenantID: tenantID,
			Name:     req.Name,
			Phone:    req.Phone,
			Email:    req.Email,
			Address:  req.Address,
			Notes:    req.Notes,
		}

		if err := db.Create(&customer).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusCreated, customer)
	}
}

// UpdateCustomer - PUT /api/customers/:id
func UpdateCustomer(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var customer models.Customer

		if err := db.First(&customer, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Customer not found"})
			return
		}

		// Check tenant isolation
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil {
				if customer.TenantID != *tenantID.(*uint) {
					c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
					return
				}
			}
		}

		var req CreateCustomerRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		customer.Name = req.Name
		customer.Phone = req.Phone
		customer.Email = req.Email
		customer.Address = req.Address
		customer.Notes = req.Notes

		if err := db.Save(&customer).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, customer)
	}
}

// DeleteCustomer - DELETE /api/customers/:id
func DeleteCustomer(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var customer models.Customer

		if err := db.First(&customer, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Customer not found"})
			return
		}

		// Check tenant isolation
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil {
				if customer.TenantID != *tenantID.(*uint) {
					c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
					return
				}
			}
		}

		if err := db.Delete(&customer).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Customer deleted"})
	}
}
