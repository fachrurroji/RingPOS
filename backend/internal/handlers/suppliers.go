package handlers

import (
	"net/http"
	"ringpos-backend/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// GetSuppliers - GET /api/suppliers
func GetSuppliers(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var suppliers []models.Supplier

		query := db.Order("name ASC")

		// Tenant isolation
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil {
				query = query.Where("tenant_id = ?", *tenantID.(*uint))
			}
		}

		// Search
		if search := c.Query("search"); search != "" {
			query = query.Where("name LIKE ? OR contact_person LIKE ?", "%"+search+"%", "%"+search+"%")
		}

		if err := query.Find(&suppliers).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, suppliers)
	}
}

// GetSupplier - GET /api/suppliers/:id
func GetSupplier(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var supplier models.Supplier

		if err := db.First(&supplier, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Supplier not found"})
			return
		}

		// Check tenant
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil {
				if supplier.TenantID != *tenantID.(*uint) {
					c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
					return
				}
			}
		}

		c.JSON(http.StatusOK, supplier)
	}
}

// CreateSupplierRequest - Request body
type CreateSupplierRequest struct {
	Name          string `json:"name" binding:"required"`
	ContactPerson string `json:"contact_person"`
	Phone         string `json:"phone"`
	Email         string `json:"email"`
	Address       string `json:"address"`
	Notes         string `json:"notes"`
}

// CreateSupplier - POST /api/suppliers
func CreateSupplier(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req CreateSupplierRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		var tenantID uint
		role, _ := c.Get("role")
		if role != "superadmin" {
			tid, exists := c.Get("tenant_id")
			if exists && tid != nil {
				tenantID = *tid.(*uint)
			}
		}

		supplier := models.Supplier{
			TenantID:      tenantID,
			Name:          req.Name,
			ContactPerson: req.ContactPerson,
			Phone:         req.Phone,
			Email:         req.Email,
			Address:       req.Address,
			Notes:         req.Notes,
		}

		if err := db.Create(&supplier).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusCreated, supplier)
	}
}

// UpdateSupplier - PUT /api/suppliers/:id
func UpdateSupplier(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var supplier models.Supplier

		if err := db.First(&supplier, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Supplier not found"})
			return
		}

		// Check tenant
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil {
				if supplier.TenantID != *tenantID.(*uint) {
					c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
					return
				}
			}
		}

		var req CreateSupplierRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		supplier.Name = req.Name
		supplier.ContactPerson = req.ContactPerson
		supplier.Phone = req.Phone
		supplier.Email = req.Email
		supplier.Address = req.Address
		supplier.Notes = req.Notes

		if err := db.Save(&supplier).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, supplier)
	}
}

// DeleteSupplier - DELETE /api/suppliers/:id
func DeleteSupplier(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var supplier models.Supplier

		if err := db.First(&supplier, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Supplier not found"})
			return
		}

		// Check tenant
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil {
				if supplier.TenantID != *tenantID.(*uint) {
					c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
					return
				}
			}
		}

		if err := db.Delete(&supplier).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Supplier deleted"})
	}
}
