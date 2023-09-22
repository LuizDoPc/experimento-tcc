package main

import (
	"context"
	"fmt"
	pb "go-color-grpc/protobuf"
	"log"
	"net"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"google.golang.org/grpc"
)

type Array []int32

func (s *ArrayServiceServer) Search(ctx context.Context, req *pb.Array) (*pb.Num, error) {
	requestDuration := prometheus.NewSummary(prometheus.SummaryOpts{
		Name:    "request_timer",
		Help:    "Duração do request",
		ConstLabels: map[string]string{"c": strconv.Itoa(s.counter)},
	})

	s.counter++

	prometheus.MustRegister(requestDuration)

	timer := prometheus.NewTimer(requestDuration)
	defer timer.ObserveDuration()

	array := req.GetArray()
	for i := range array {
		log.Println(i)
	}

	s.customCounter.Inc()

	n := pb.Num{
		Num: -1,
	}
	return &n, nil
}

type ArrayServiceServer struct{
	pb.UnimplementedArrayServiceServer
	customCounter prometheus.Counter
	counter int
}


func main() {
	r := gin.Default()

	customCounter := prometheus.NewCounter(prometheus.CounterOpts{
		Name: "request_counter_total",
		Help: "Contador de requests",
	})

	prometheus.MustRegister(customCounter)

	counter := 0

	// Start the gRPC server
	lis, err := net.Listen("tcp", ":50001")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()
	pb.RegisterArrayServiceServer(s, &ArrayServiceServer{
		customCounter: customCounter,
		counter: counter,
	})
	go func() {
		if err := s.Serve(lis); err != nil {
			log.Fatalf("failed to serve: %v", err)
		}
	}()

	// Start the HTTP server
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))

	fmt.Println("Server started at http://localhost:8080")
	r.Run(":8080")
}
