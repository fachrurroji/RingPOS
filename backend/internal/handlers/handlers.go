package handlers

import (
	"net/http"
	"os"
	"time"

	"ringpos-backend/internal/middleware"
	"ringpos-backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func getJWTSecret() string {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		return "ringpos-default-secret-change-in-production"
	}
	return secret
}

func Login(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var loginReq struct {
			Username string `json:"username"`
			Password string `json:"password"`
		}

		if err := c.ShouldBindJSON(&loginReq); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}

		var user models.User
		if err := db.Preload("Tenant").Where("username = ?", loginReq.Username).First(&user).Error; err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
			return
		}

		// Verify password (if password is empty, allow for dev mode)
		if user.Password != "" {
			if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(loginReq.Password)); err != nil {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
				return
			}
		}

		// Generate JWT token
		claims := middleware.Claims{
			UserID:   user.ID,
			TenantID: user.TenantID,
			Role:     user.Role,
			RegisteredClaims: jwt.RegisteredClaims{
				ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
				IssuedAt:  jwt.NewNumericDate(time.Now()),
			},
		}

		token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
		tokenString, err := token.SignedString([]byte(getJWTSecret()))
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
			return
		}

		// Prepare response
		response := gin.H{
			"token": tokenString,
			"user": gin.H{
				"id":       user.ID,
				"username": user.Username,
				"role":     user.Role,
			},
		}

		// Add tenant info if not superadmin
		if user.TenantID != nil {
			response["tenant"] = gin.H{
				"id":            user.Tenant.ID,
				"name":          user.Tenant.Name,
				"business_type": user.Tenant.BusinessType,
			}
		}

		c.JSON(http.StatusOK, response)
	}
}

func GetConfig(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Check if user is authenticated (from middleware)
		tenantID := middleware.GetTenantID(c)
		role, _ := c.Get("role")

		// Superadmin gets minimal config
		if role == "superadmin" {
			c.JSON(http.StatusOK, gin.H{
				"mode":     "superadmin",
				"features": []string{"tenant_management", "analytics", "system_settings"},
			})
			return
		}

		// Regular user - get tenant config
		if tenantID == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Tenant not found"})
			return
		}

		var tenant models.Tenant
		if result := db.First(&tenant, *tenantID); result.Error != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Tenant not found"})
			return
		}

		// Return config based on business type
		config := map[string]interface{}{
			"mode":   tenant.BusinessType,
			"theme":  "default",
			"status": tenant.Status,
		}

		if tenant.BusinessType == models.Retail {
			config["features"] = []string{"barcode_scanner", "wholesale_pricing", "inventory"}
		} else if tenant.BusinessType == models.FB {
			config["features"] = []string{"table_map", "kitchen_print", "modifiers"}
		} else {
			config["features"] = []string{"kanban_board", "sms_notification", "calendar"}
		}

		c.JSON(http.StatusOK, config)
	}
}

