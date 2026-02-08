package middleware

import (
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
	UserID   uint   `json:"user_id"`
	TenantID *uint  `json:"tenant_id"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

// AuthMiddleware validates JWT token and extracts claims
func AuthMiddleware(jwtSecret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		// Extract token from "Bearer <token>"
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization header format"})
			c.Abort()
			return
		}

		tokenString := parts[1]

		// Parse and validate token
		token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
			return []byte(jwtSecret), nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		claims, ok := token.Claims.(*Claims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token claims"})
			c.Abort()
			return
		}

		// Set claims in context for handlers to use
		c.Set("user_id", claims.UserID)
		c.Set("tenant_id", claims.TenantID)
		c.Set("role", claims.Role)

		c.Next()
	}
}

// TenantMiddleware enforces tenant-scoped data access
func TenantMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, exists := c.Get("role")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Role not found in context"})
			c.Abort()
			return
		}

		// Superadmin can access all data
		if role == "superadmin" {
			c.Next()
			return
		}

		// Regular users must have tenant_id
		tenantID, exists := c.Get("tenant_id")
		if !exists || tenantID == nil {
			c.JSON(http.StatusForbidden, gin.H{"error": "Tenant access required"})
			c.Abort()
			return
		}

		c.Next()
	}
}

// SuperadminOnly restricts access to superadmin users
func SuperadminOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, exists := c.Get("role")
		if !exists || role != "superadmin" {
			c.JSON(http.StatusForbidden, gin.H{"error": "Superadmin access required"})
			c.Abort()
			return
		}
		c.Next()
	}
}

// GetTenantID helper to extract tenant_id from context
func GetTenantID(c *gin.Context) *uint {
	tenantID, exists := c.Get("tenant_id")
	if !exists || tenantID == nil {
		return nil
	}
	id := tenantID.(*uint)
	return id
}

// GetUserID helper to extract user_id from context  
func GetUserID(c *gin.Context) uint {
	userID, _ := c.Get("user_id")
	return userID.(uint)
}

// GenerateToken creates a JWT token from claims
func GenerateToken(claims Claims) (string, error) {
	claims.RegisteredClaims = jwt.RegisteredClaims{
		ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
		IssuedAt:  jwt.NewNumericDate(time.Now()),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(getJWTSecret()))
}

// GetJWTSecretForRouter returns the JWT secret for use in router configuration
func GetJWTSecretForRouter() string {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		return "ringpos-default-secret-change-in-production"
	}
	return secret
}

func getJWTSecret() string {
	return GetJWTSecretForRouter()
}
