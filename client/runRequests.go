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
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

const (
	numReqs      = 	450
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

func getLoadBalancerIP(clientset *kubernetes.Clientset, namespace, serviceName string) (string, error) {
	service, err := clientset.CoreV1().Services(namespace).Get(context.TODO(), serviceName, metav1.GetOptions{})
	if err != nil {
		return "", err
	}

	if len(service.Status.LoadBalancer.Ingress) > 0 {
		return service.Status.LoadBalancer.Ingress[0].IP, nil
	}

	return "", fmt.Errorf("IP do LoadBalancer não encontrado")
}


func main() {
	httpFlag := flag.Bool("javahttp", false, "Testar a aplicação Java HTTP")
	gohttpFlag := flag.Bool("gohttp", false, "Testar a aplicação Go HTTP")
	javagrpcFlag := flag.Bool("javagrpc", false, "Testar a aplicação Java gRPC")
	gogrpcFlag := flag.Bool("gogrpc", false, "Testar a aplicação Go gRPC")

	flag.Parse()

	sizeType := 2

	// Configuração do cliente Kubernetes
	config, err := clientcmd.BuildConfigFromFlags("", "../kubekeep/kubeconfig.yaml")
	if err != nil {
		log.Fatalf("Erro ao criar configuração do cliente Kubernetes: %v", err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Fatalf("Erro ao criar cliente Kubernetes: %v", err)
	}

	// Obter o IP do LoadBalancer para um serviço específico
	ipjavahttp, err := getLoadBalancerIP(clientset, "monitoring", "javahttptest-helm-chart")
	if err != nil {
		log.Fatalf("Erro ao obter o IP do LoadBalancer: %v", err)
	}
	ipjavagrpc, err := getLoadBalancerIP(clientset, "monitoring", "javagrpctest-helm-chart")
	if err != nil {
		log.Fatalf("Erro ao obter o IP do LoadBalancer: %v", err)
	}
	ipgohttp, err := getLoadBalancerIP(clientset, "monitoring", "gohttptest-helm-chart")
	if err != nil {
		log.Fatalf("Erro ao obter o IP do LoadBalancer: %v", err)
	}
	ipgogrpc, err := getLoadBalancerIP(clientset, "monitoring", "gogrpctest-helm-chart")
	if err != nil {
		log.Fatalf("Erro ao obter o IP do LoadBalancer: %v", err)
	}

	httpURL1     := fmt.Sprintf("http://%s/foo", ipjavahttp)
	httpURL2     := fmt.Sprintf("http://%s:8080/foo", ipgohttp)
	grpcAddress1 := fmt.Sprintf("%s:50059", ipjavagrpc)
	grpcAddress2 := fmt.Sprintf("%s:50001", ipgogrpc)

	if *httpFlag {
		fmt.Printf("Enviando %d requisições HTTP POST para %s\n", numReqs, httpURL1)
		httpPayload := getPayload(true, sizeType).(string)
		interval := time.Second
		sendHTTPPOSTRequest(httpURL1, httpPayload, interval)
	} else if *gohttpFlag {
		fmt.Printf("Enviando %d requisições HTTP POST para %s\n", numReqs, httpURL2)
		httpPayload := getPayload(true, sizeType).(string)
		interval := time.Second
		sendHTTPPOSTRequest(httpURL2, httpPayload, interval)
	} else if *javagrpcFlag {
		fmt.Printf("Enviando %d requisições gRPC para %s\n", numReqs, grpcAddress1)
		grpcPayload := getPayload(false, sizeType).([]int32)
		interval := time.Second
		sendGRPCRequest(grpcAddress1, grpcPayload, interval)
	} else if *gogrpcFlag {
		fmt.Printf("Enviando %d requisições gRPC para %s\n", numReqs, grpcAddress2)
		grpcPayload := getPayload(false, sizeType).([]int32)
		interval := time.Second
		sendGRPCRequest(grpcAddress2, grpcPayload, interval)
	} else {
		fmt.Println("Escolha uma aplicação para testar usando os argumentos da linha de comando.")
	}
}

