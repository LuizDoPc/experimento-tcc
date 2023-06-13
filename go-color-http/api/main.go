package main

import (
	"fmt"
	"log"

	"github.com/gin-gonic/gin"
)

type Array []int

func search(array Array) int {
	for i := range array {
		log.Println(i)	
	}
	
	return -1
}

func main() {
	r := gin.Default()

	r.POST("/foo", func(c *gin.Context) {
		var array Array
		if err := c.ShouldBindJSON(&array); err != nil {
			c.JSON(400, gin.H{"error": "Error parsing"})
			return
		}

		index := search(array)

		c.JSON(200, index)
	})

	fmt.Println("Server started at http://localhost:8080")
	r.Run(":8080")
}