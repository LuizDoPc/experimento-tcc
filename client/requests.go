package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"strconv"
	"time"

	pb "lab-client/protobuf"

	"google.golang.org/grpc"
	"k8s.io/client-go/kubernetes"
)

const (
	numReqs     = 350
	numReqsJava = 1350
	// numReqs     = 3
	// numReqsJava = 4
)

func getPayload(isHTTP bool, sizeType int) interface{} {
	numberOfNumbers := 204800
	switch sizeType {
		case 1:
			numberOfNumbers = 200
		case 2:
			numberOfNumbers = 204800
		default:
			numberOfNumbers = 204800
	}

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

type MetricValue struct {
	CValue   string
	Value    float64
	AppName  string
}

var metrics = []MetricValue{}

func sendHTTPPOSTRequest(url, payload string, interval time.Duration, amount int, appName string) {
	for i := 0; i < amount; i++ {

		start := time.Now()
		_, err := http.Post(url, "application/json", bytes.NewBuffer([]byte(payload)))
		elapsed := time.Since(start)

		if appName != "javahttp" || i >= 1000 {
			fmt.Printf("Registrando metrica de requisicao")
			metrics = append(metrics, MetricValue{
				CValue: strconv.Itoa(i),
				Value: elapsed.Seconds(),
				AppName: appName,
			})
		}

		if err != nil {
			log.Fatalf("Erro na requisição HTTP POST: %v", err)
		}
		fmt.Printf("Requisição HTTP POST para %s número %d\n", url, i+1)
		time.Sleep(interval)
	}
}

func sendGRPCRequest(address string, payload []int32, interval time.Duration, amount int, appName string) {
	conn, err := grpc.Dial(address, grpc.WithInsecure())
	if err != nil {
		log.Fatalf("Erro ao conectar-se ao servidor gRPC: %v", err)
	}
	defer conn.Close()

	client := pb.NewArrayServiceClient(conn)

	for i := 0; i < amount; i++ {

		start := time.Now()
		_, err := client.Search(context.Background(), &pb.Array{Array: payload})
		elapsed := time.Since(start)

		if appName != "javagrpc" || i >= 1000 {
			fmt.Printf("Registrando metrica de requisicao")
			metrics = append(metrics, MetricValue{
				CValue: strconv.Itoa(i),
				Value: elapsed.Seconds(),
				AppName: appName,
			})
		 }

		if err != nil {
			log.Fatalf("Erro na requisição gRPC para %s: %v", address, err)
		}
		fmt.Printf("Requisição gRPC para %s número %d\n", address, i+1)
		time.Sleep(interval)
	}
}

func sendJavaHttpRequests (url string, sizeType int, amount int) {
	fmt.Printf("JAVA-HTTP - Enviando %d requisições HTTP POST para %s\n", amount, url)
	httpPayload := getPayload(true, sizeType).(string)
	interval := time.Second
	sendHTTPPOSTRequest(url, httpPayload, interval, amount, "javahttp")
}

func sendGoHttpRequests (url string, sizeType int, amount int) {
	fmt.Printf("GO-HTTP - Enviando %d requisições HTTP POST para %s\n", amount, url)
	httpPayload := getPayload(true, sizeType).(string)
	interval := time.Second
	sendHTTPPOSTRequest(url, httpPayload, interval, amount, "gohttp")
}

func sendJavaGrpcRequests (address string, sizeType int, amount int) {
	fmt.Printf("JAVA-GRPC - Enviando %d requisições gRPC para %s\n", amount, address)
	grpcPayload := getPayload(false, sizeType).([]int32)
	interval := time.Second
	sendGRPCRequest(address, grpcPayload, interval, amount, "javagrpc")
}

func sendGoGrpcRequests (address string, sizeType int, amount int) {
	fmt.Printf("GO-GRPC - Enviando %d requisições gRPC para %s\n", amount, address)
	grpcPayload := getPayload(false, sizeType).([]int32)
	interval := time.Second
	sendGRPCRequest(address, grpcPayload, interval, amount, "gogrpc")
}

func runRequests(clientset *kubernetes.Clientset, namespace string, size string) []MetricValue {
	sizeType := 1

	if size == "big" {
		sizeType = 2
	}

	ipjavahttp, err := getLoadBalancerIP(clientset, namespace, "javahttptest-helm-chart")
	if err != nil {
		log.Fatalf("Erro ao obter o IP do LoadBalancer: %v", err)
	}
	ipjavagrpc, err := getLoadBalancerIP(clientset, namespace, "javagrpctest-helm-chart")
	if err != nil {
		log.Fatalf("Erro ao obter o IP do LoadBalancer: %v", err)
	}
	ipgohttp, err := getLoadBalancerIP(clientset, namespace, "gohttptest-helm-chart")
	if err != nil {
		log.Fatalf("Erro ao obter o IP do LoadBalancer: %v", err)
	}
	ipgogrpc, err := getLoadBalancerIP(clientset, namespace, "gogrpctest-helm-chart")
	if err != nil {
		log.Fatalf("Erro ao obter o IP do LoadBalancer: %v", err)
	}

	httpURL1     := fmt.Sprintf("http://%s/foo", ipjavahttp)
	httpURL2     := fmt.Sprintf("http://%s:8080/foo", ipgohttp)
	grpcAddress1 := fmt.Sprintf("%s:50059", ipjavagrpc)
	grpcAddress2 := fmt.Sprintf("%s:50001", ipgogrpc)

	fmt.Println("Testando todas as aplicações")
	sendJavaHttpRequests(httpURL1, sizeType, numReqsJava)
	sendGoHttpRequests(httpURL2, sizeType, numReqs)
	sendJavaGrpcRequests(grpcAddress1, sizeType, numReqsJava)
	sendGoGrpcRequests(grpcAddress2, sizeType, numReqs)

	tempMetrics := metrics

	metrics = []MetricValue{}

	return tempMetrics
}
