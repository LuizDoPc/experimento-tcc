package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"time"

	pb "client/protobuf"

	"context"

	"google.golang.org/grpc"
)

const (
	numReqs      = 10
	httpURL1     = "http://172.18.255.203/foo"
	httpURL2     = "http://172.18.255.202:8080/foo"
	grpcAddress1 = "172.18.255.204:50059"
	grpcAddress2 = "172.18.255.201:50001"
)

func getPayload(isHTTP bool) interface{} {
	numberOfNumbers := 125000
	goArray := make([]int32, numberOfNumbers)

	rand.Seed(time.Now().UnixNano())

	for i := 0; i < numberOfNumbers; i++ {
		randomNumber := rand.Int31n(1000)
		goArray[i] = randomNumber
	}

	if isHTTP {
		var interfaceSlice []interface{}
		for _, num := range goArray {
			interfaceSlice = append(interfaceSlice, num)
		}

		jsonString, err := json.Marshal(interfaceSlice)
		if err != nil {
			fmt.Println("Erro ao converter para JSON:", err)
			return nil
		}

		return fmt.Sprintf("%s", string(jsonString))
	}

	return goArray
}

func sendHTTPPOSTRequest(url, payload string, interval time.Duration) {
	for i := 0; i < numReqs; i++ {
		_, err := http.Post(url, "application/json", bytes.NewBuffer([]byte(payload)))
		if err != nil {
			log.Fatalf("Erro na requisição HTTP POST: %v", err)
		}
		fmt.Printf("Requisição HTTP POST para %s número %d\n", url, i+1)
		time.Sleep(interval)
	}
}

func sendGRPCRequest(address string, payload []int32, interval time.Duration) {
	conn, err := grpc.Dial(address, grpc.WithInsecure())
	if err != nil {
		log.Fatalf("Erro ao conectar-se ao servidor gRPC: %v", err)
	}
	defer conn.Close()

	client := pb.NewArrayServiceClient(conn)

	for i := 0; i < numReqs; i++ {
		_, err := client.Search(context.Background(), &pb.Array{Array: payload})
		if err != nil {
			log.Fatalf("Erro na requisição gRPC para %s: %v", address, err)
		}
		fmt.Printf("Requisição gRPC para %s número %d\n", address, i+1)
		time.Sleep(interval)
	}
}

func main() {
	httpFlag := flag.Bool("javahttp", false, "Testar a aplicação Java HTTP")
	gohttpFlag := flag.Bool("gohttp", false, "Testar a aplicação Go HTTP")
	javagrpcFlag := flag.Bool("javagrpc", false, "Testar a aplicação Java gRPC")
	gogrpcFlag := flag.Bool("gogrpc", false, "Testar a aplicação Go gRPC")

	flag.Parse()

	if *httpFlag {
		fmt.Printf("Enviando %d requisições HTTP POST para %s\n", numReqs, httpURL1)
		httpPayload := getPayload(true).(string)
		interval := time.Second
		sendHTTPPOSTRequest(httpURL1, httpPayload, interval)
	} else if *gohttpFlag {
		fmt.Printf("Enviando %d requisições HTTP POST para %s\n", numReqs, httpURL2)
		httpPayload := getPayload(true).(string)
		interval := time.Second
		sendHTTPPOSTRequest(httpURL2, httpPayload, interval)
	} else if *javagrpcFlag {
		fmt.Printf("Enviando %d requisições gRPC para %s\n", numReqs, grpcAddress1)
		grpcPayload := getPayload(false).([]int32)
		interval := time.Second
		sendGRPCRequest(grpcAddress1, grpcPayload, interval)
	} else if *gogrpcFlag {
		fmt.Printf("Enviando %d requisições gRPC para %s\n", numReqs, grpcAddress2)
		grpcPayload := getPayload(false).([]int32)
		interval := time.Second
		sendGRPCRequest(grpcAddress2, grpcPayload, interval)
	} else {
		fmt.Println("Escolha uma aplicação para testar usando os argumentos da linha de comando.")
	}
}

