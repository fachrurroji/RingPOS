package handlers

import (
	"net/http"
	"ringpos-backend/internal/models"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// UserResponse - User without password
type UserResponse struct {
	ID       uint   `json:"id"`
	Username string `json:"username"`
	TenantID *uint  `json:"tenant_id"`
	Role     string `json:"role"`
}

func toUserResponse(user models.User) UserResponse {
	return UserResponse{
		ID:       user.ID,
		Username: user.Username,
		TenantID: user.TenantID,
		Role:     user.Role,
	}
}

// GetUsers - GET /api/users
func GetUsers(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var users []models.User
		
		query := db.Order("created_at DESC")
		
		// Tenant isolation for non-superadmins
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil {
				query = query.Where("tenant_id = ?", *tenantID.(*uint))
			}
		} else {
			// Superadmin can filter by tenant
			if tenantID := c.Query("tenant_id"); tenantID != "" {
				query = query.Where("tenant_id = ?", tenantID)
			}
		}

		if err := query.Find(&users).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		
		// Convert to response (without password)
		var response []UserResponse
		for _, user := range users {
			response = append(response, toUserResponse(user))
		}

		c.JSON(http.StatusOK, response)
	}
}

// GetUser - GET /api/users/:id
func GetUser(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var user models.User

		if err := db.First(&user, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			return
		}

		// Check tenant isolation
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil && user.TenantID != nil {
				if *user.TenantID != *tenantID.(*uint) {
					c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
					return
				}
			}
		}

		c.JSON(http.StatusOK, toUserResponse(user))
	}
}

// CreateUserRequest - Request body for creating user
type CreateUserRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
	Role     string `json:"role" binding:"required"`
	TenantID *uint  `json:"tenant_id"`
}

// CreateUser - POST /api/users
func CreateUser(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req CreateUserRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Check if username exists
		var existing models.User
		if err := db.Where("username = ?", req.Username).First(&existing).Error; err == nil {
			c.JSON(http.StatusConflict, gin.H{"error": "Username already exists"})
			return
		}

		// Hash password
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error hashing password"})
			return
		}

		// For non-superadmins, force their own tenant_id
		role, _ := c.Get("role")
		var tenantID *uint
		if role != "superadmin" {
			tid, exists := c.Get("tenant_id")
			if exists && tid != nil {
				tenantID = tid.(*uint)
			}
		} else {
			tenantID = req.TenantID
		}

		// Non-superadmin cannot create superadmin users
		if role != "superadmin" && req.Role == "superadmin" {
			c.JSON(http.StatusForbidden, gin.H{"error": "Cannot create superadmin user"})
			return
		}

		user := models.User{
			Username: req.Username,
			Password: string(hashedPassword),
			Role:     req.Role,
			TenantID: tenantID,
		}

		if err := db.Create(&user).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusCreated, toUserResponse(user))
	}
}

// UpdateUserRequest - Request body for updating user
type UpdateUserRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Role     string `json:"role"`
}

// UpdateUser - PUT /api/users/:id
func UpdateUser(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var user models.User

		if err := db.First(&user, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			return
		}

		// Check tenant isolation
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil && user.TenantID != nil {
				if *user.TenantID != *tenantID.(*uint) {
					c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
					return
				}
			}
		}

		var req UpdateUserRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Update fields
		if req.Username != "" {
			// Check if new username exists
			var existing models.User
			if err := db.Where("username = ? AND id != ?", req.Username, id).First(&existing).Error; err == nil {
				c.JSON(http.StatusConflict, gin.H{"error": "Username already exists"})
				return
			}
			user.Username = req.Username
		}

		if req.Password != "" {
			hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Error hashing password"})
				return
			}
			user.Password = string(hashedPassword)
		}

		if req.Role != "" {
			// Non-superadmin cannot change to superadmin
			if role != "superadmin" && req.Role == "superadmin" {
				c.JSON(http.StatusForbidden, gin.H{"error": "Cannot set superadmin role"})
				return
			}
			user.Role = req.Role
		}

		if err := db.Save(&user).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, toUserResponse(user))
	}
}

// DeleteUser - DELETE /api/users/:id
func DeleteUser(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var user models.User

		if err := db.First(&user, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			return
		}

		// Check tenant isolation
		role, _ := c.Get("role")
		if role != "superadmin" {
			tenantID, exists := c.Get("tenant_id")
			if exists && tenantID != nil && user.TenantID != nil {
				if *user.TenantID != *tenantID.(*uint) {
					c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
					return
				}
			}
		}

		// Cannot delete superadmin
		if user.Role == "superadmin" {
			c.JSON(http.StatusForbidden, gin.H{"error": "Cannot delete superadmin user"})
			return
		}

		// Cannot delete self
		currentUserID, _ := c.Get("user_id")
		if currentUserID != nil && currentUserID.(uint) == user.ID {
			c.JSON(http.StatusForbidden, gin.H{"error": "Cannot delete yourself"})
			return
		}

		if err := db.Delete(&user).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "User deleted"})
	}
}
