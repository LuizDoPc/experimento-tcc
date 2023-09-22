package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"time"

	pb "client/protobuf"

	context "context"

	"google.golang.org/grpc"
)

const (
    numReqs = 350
    httpURL1 = "http://localhost:8080/foo" 
    httpURL2 = "http://localhost:8081/foo"
    grpcAddress1 = "localhost:50051"   
    grpcAddress2 = "localhost:50052"
)


func getPayload(isHttp bool) interface {} {
    numberOfNumbers := 125000
	goArray := make([]int32, numberOfNumbers)

	rand.Seed(time.Now().UnixNano())

	for i := 0; i < numberOfNumbers; i++ {
		randomNumber := rand.Int31n(1000) 
		goArray[i] = randomNumber
	}

    if isHttp {
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
    } else {
        return goArray
    }

}

func sendHTTPPOSTRequest(url, payload string) {
    for i := 0; i < numReqs; i++ {
        _, err := http.Post(url, "application/json", bytes.NewBuffer([]byte(payload)))
        if err != nil {
            log.Fatalf("Erro na requisição HTTP POST: %v", err)
        }
        fmt.Printf("Requisição HTTP POST para %s número %d\n", url, i+1)
    }
}

func sendGRPCRequest(address string, payload []int32) {
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
    }
}

func main() {
    fmt.Printf("Enviando %d requisições HTTP POST para %s e %s\n", numReqs, httpURL1, httpURL2)
    httpPayload := getPayload(true).(string)
    go sendHTTPPOSTRequest(httpURL1, httpPayload)
    go sendHTTPPOSTRequest(httpURL2, httpPayload)

    fmt.Printf("Enviando %d requisições gRPC para %s e %s\n", numReqs, grpcAddress1, grpcAddress2)
    grpcPayload := getPayload(false).([]int32)
    go sendGRPCRequest(grpcAddress1, grpcPayload)
    go sendGRPCRequest(grpcAddress2, grpcPayload)

    var input string
    fmt.Println("Pressione Enter para encerrar o programa...")
    fmt.Scanln(&input)
}
