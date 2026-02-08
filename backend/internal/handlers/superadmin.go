package handlers

import (
	"net/http"

	"ringpos-backend/internal/middleware"
	"ringpos-backend/internal/models"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// ========== Tenant Management ==========

// ListTenants returns all tenants (superadmin only)
func ListTenants(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var tenants []models.Tenant
		if err := db.Find(&tenants).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch tenants"})
			return
		}
		c.JSON(http.StatusOK, tenants)
	}
}

// CreateTenant creates a new tenant with admin user
func CreateTenant(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			Name           string `json:"name" binding:"required"`
			BusinessType   string `json:"business_type" binding:"required"`
			Address        string `json:"address"`
			AdminUsername  string `json:"admin_username" binding:"required"`
			AdminPassword  string `json:"admin_password" binding:"required"`
			ModulesEnabled string `json:"modules_enabled"`
			Plan           string `json:"subscription_plan"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Validate business type
		businessType := models.TenantType(req.BusinessType)
		if businessType != models.Retail && businessType != models.FB && businessType != models.Service {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid business_type. Must be RETAIL, FB, or SERVICE"})
			return
		}

		// Start transaction
		tx := db.Begin()

		// Create tenant
		tenant := models.Tenant{
			Name:             req.Name,
			BusinessType:     businessType,
			Address:          req.Address,
			Status:           "active",
			SubscriptionPlan: req.Plan,
			ModulesEnabled:   req.ModulesEnabled,
		}

		if err := tx.Create(&tenant).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create tenant"})
			return
		}

		// Hash password
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.AdminPassword), bcrypt.DefaultCost)
		if err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
			return
		}

		// Create admin user for tenant
		user := models.User{
			Username: req.AdminUsername,
			Password: string(hashedPassword),
			TenantID: &tenant.ID,
			Role:     "owner",
		}

		if err := tx.Create(&user).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create admin user"})
			return
		}

		tx.Commit()

		c.JSON(http.StatusCreated, gin.H{
			"tenant": tenant,
			"user": gin.H{
				"id":       user.ID,
				"username": user.Username,
				"role":     user.Role,
			},
		})
	}
}

// UpdateTenant updates tenant settings
func UpdateTenant(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")

		var tenant models.Tenant
		if err := db.First(&tenant, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Tenant not found"})
			return
		}

		var req struct {
			Name             *string `json:"name"`
			BusinessType     *string `json:"business_type"`
			Address          *string `json:"address"`
			Status           *string `json:"status"`
			ModulesEnabled   *string `json:"modules_enabled"`
			SubscriptionPlan *string `json:"subscription_plan"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Update fields if provided
		if req.Name != nil {
			tenant.Name = *req.Name
		}
		if req.BusinessType != nil {
			tenant.BusinessType = models.TenantType(*req.BusinessType)
		}
		if req.Address != nil {
			tenant.Address = *req.Address
		}
		if req.Status != nil {
			tenant.Status = *req.Status
		}
		if req.ModulesEnabled != nil {
			tenant.ModulesEnabled = *req.ModulesEnabled
		}
		if req.SubscriptionPlan != nil {
			tenant.SubscriptionPlan = *req.SubscriptionPlan
		}

		if err := db.Save(&tenant).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update tenant"})
			return
		}

		c.JSON(http.StatusOK, tenant)
	}
}

// DeleteTenant soft-deletes a tenant (sets status to suspended)
func DeleteTenant(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")

		var tenant models.Tenant
		if err := db.First(&tenant, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Tenant not found"})
			return
		}

		tenant.Status = "suspended"
		if err := db.Save(&tenant).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to suspend tenant"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Tenant suspended successfully"})
	}
}

// ImpersonateTenant generates a token to login as tenant admin
func ImpersonateTenant(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		tenantID := c.Param("id")

		// Find tenant admin (owner role)
		var user models.User
		if err := db.Preload("Tenant").Where("tenant_id = ? AND role = ?", tenantID, "owner").First(&user).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Tenant admin not found"})
			return
		}

		// Generate token for this user
		token, err := generateTokenForUser(user)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"token":  token,
			"tenant": user.Tenant,
			"user": gin.H{
				"id":       user.ID,
				"username": user.Username,
				"role":     user.Role,
			},
		})
	}
}

// ========== Dashboard Stats ==========

// GetSuperadminStats returns platform-wide statistics
func GetSuperadminStats(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var tenantCount int64
		var userCount int64
		var orderCount int64

		db.Model(&models.Tenant{}).Where("status = ?", "active").Count(&tenantCount)
		db.Model(&models.User{}).Count(&userCount)
		db.Model(&models.Order{}).Count(&orderCount)

		c.JSON(http.StatusOK, gin.H{
			"total_tenants": tenantCount,
			"total_users":   userCount,
			"total_orders":  orderCount,
		})
	}
}

// Helper function to generate token
func generateTokenForUser(user models.User) (string, error) {
	claims := middleware.Claims{
		UserID:   user.ID,
		TenantID: user.TenantID,
		Role:     user.Role,
	}

	return middleware.GenerateToken(claims)
}
