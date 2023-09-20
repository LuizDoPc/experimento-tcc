package main

import (
	"fmt"
	"log"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
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

	customCounter := prometheus.NewCounter(prometheus.CounterOpts{
		Name: "request_counter_total",
		Help: "Counter for requests",
	})

	prometheus.MustRegister(customCounter)

	counter := 0

	r.GET("/metrics", gin.WrapH(promhttp.Handler()))
	r.POST("/foo", func(c *gin.Context) {
		requestDuration := prometheus.NewSummary(prometheus.SummaryOpts{
			Name:    "request_timer",
			Help:    "Duração do request",
			ConstLabels: map[string]string{"c": strconv.Itoa(counter)},
		})

		counter++

		prometheus.MustRegister(requestDuration)

		timer := prometheus.NewTimer(requestDuration)
		defer timer.ObserveDuration()

		var array Array
		if err := c.ShouldBindJSON(&array); err != nil {
			c.JSON(400, gin.H{"error": "Error parsing"})
			return
		}

		index := search(array)

		customCounter.Inc()

		c.JSON(200, index)
	})

	fmt.Println("Server started at http://localhost:8080")
	r.Run(":8080")
}