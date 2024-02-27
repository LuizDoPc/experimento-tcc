package main

import (
	"context"
	"fmt"
	pb "go-color-grpc/protobuf"
	"log"
	"math/rand"
	"net"

	"google.golang.org/grpc"
)

type Array []int32

func (s *ArrayServiceServer) Search(ctx context.Context, req *pb.Array) (*pb.Num, error) {
	array := req.GetArray()

	for i := 0; i<3; i++ {
		var r = rand.Intn(len(array))

		fmt.Println(array[r])
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
	// Start the gRPC server
	lis, err := net.Listen("tcp", ":50001")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()
	pb.RegisterArrayServiceServer(s, &ArrayServiceServer{})
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
