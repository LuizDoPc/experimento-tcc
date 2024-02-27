package main

import (
	"fmt"
	"math/rand"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

type Array []int

func main() {
	r := gin.Default()

	r.GET("/metrics", gin.WrapH(promhttp.Handler()))
	r.POST("/foo", func(c *gin.Context) {
		var array Array
		if err := c.ShouldBindJSON(&array); err != nil {
			c.JSON(400, gin.H{"error": "Error parsing"})
			return
		}

		for i := 0; i<3; i++ {
			var r = rand.Intn(len(array))

			fmt.Println(array[r])
		}

		c.JSON(200, -1)
	})

	fmt.Println("Server started at http://localhost:8080")
	r.Run(":8080")
}