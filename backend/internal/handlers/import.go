package handlers

import (
	"encoding/csv"
	"net/http"
	"ringpos-backend/internal/models"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// ImportProductRequest - Single product from CSV
type ImportProductRequest struct {
	Name     string  `json:"name"`
	Price    float64 `json:"price"`
	Stock    int     `json:"stock"`
	Category string  `json:"category"`
	ImageURL string  `json:"image_url"`
}

// ImportProductsRequest - Request body for bulk import
type ImportProductsRequest struct {
	Products []ImportProductRequest `json:"products"`
	CSVData  string                 `json:"csv_data"`
}

// ImportProducts - POST /api/products/import
func ImportProducts(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req ImportProductsRequest
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

		var products []models.Product
		var importedCount int
		var errors []string

		// If CSV data provided, parse it
		if req.CSVData != "" {
			reader := csv.NewReader(strings.NewReader(req.CSVData))
			records, err := reader.ReadAll()
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid CSV format"})
				return
			}

			// Skip header if present
			startIdx := 0
			if len(records) > 0 {
				header := strings.ToLower(records[0][0])
				if header == "name" || header == "product" || header == "nama" {
					startIdx = 1
				}
			}

			for i := startIdx; i < len(records); i++ {
				record := records[i]
				if len(record) < 3 {
					errors = append(errors, "Row "+strconv.Itoa(i+1)+": insufficient columns")
					continue
				}

				// Parse: Name, Price, Stock, Category (optional), ImageURL (optional)
				name := strings.TrimSpace(record[0])
				price, _ := strconv.ParseFloat(strings.TrimSpace(record[1]), 64)
				stock, _ := strconv.Atoi(strings.TrimSpace(record[2]))
				
				category := ""
				if len(record) > 3 {
					category = strings.TrimSpace(record[3])
				}
				
				imageURL := ""
				if len(record) > 4 {
					imageURL = strings.TrimSpace(record[4])
				}

				if name == "" {
					errors = append(errors, "Row "+strconv.Itoa(i+1)+": name is required")
					continue
				}

				products = append(products, models.Product{
					TenantID: tenantID,
					Name:     name,
					Price:    price,
					Stock:    stock,
					Category: category,
					ImageURL: imageURL,
				})
			}
		} else {
			// Use JSON products array
			for _, p := range req.Products {
				products = append(products, models.Product{
					TenantID: tenantID,
					Name:     p.Name,
					Price:    p.Price,
					Stock:    p.Stock,
					Category: p.Category,
					ImageURL: p.ImageURL,
				})
			}
		}

		// Bulk insert products
		for _, product := range products {
			if err := db.Create(&product).Error; err != nil {
				errors = append(errors, "Failed to create: "+product.Name)
			} else {
				importedCount++
			}
		}

		c.JSON(http.StatusOK, gin.H{
			"imported": importedCount,
			"total":    len(products),
			"errors":   errors,
		})
	}
}
