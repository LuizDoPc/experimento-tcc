package main

import (
	"context"
	"fmt"
	pb "go-color-grpc/array"
	"log"
	"net"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"
)

type Array []int32

func (s *ArrayServiceServer) Search(ctx context.Context, req *pb.Array) (*pb.Num, error) {
	array := req.GetArray()
	for i := range array {
		log.Println(i)
	}

	n := pb.Num{
		Num: -1,
	}
	return &n, nil
}

type ArrayServiceServer struct{
	pb.UnimplementedArrayServiceServer
}


func main() {
	r := gin.Default()

	// Start the gRPC server
	lis, err := net.Listen("tcp", ":50001")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()
	pb.RegisterArrayServiceServer(s, &ArrayServiceServer{})
	go func() {
		if err := s.Serve(lis); err != nil {
			log.Fatalf("failed to serve: %v", err)
		}
	}()

	// Start the HTTP server
	r.POST("/color-graph", func(c *gin.Context) {
	})

	fmt.Println("Server started at http://localhost:8081")
	r.Run(":8082")
}
