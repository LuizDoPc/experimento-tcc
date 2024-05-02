package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"time"

	pb "lab-client/protobuf"

	"google.golang.org/grpc"
)

const (
	numReqs     = 248
	numReqsJava = 1248
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

type ManagedCommand struct {
	Cmd *exec.Cmd
}

func (mc *ManagedCommand) Start(command string, args ...string) error {
	mc.Cmd = exec.Command("nice", append([]string{"-n", "-20", command}, args...)...)

	if err := mc.Cmd.Start(); err != nil {
		fmt.Println(err)
		return fmt.Errorf("falha ao iniciar o comando: %w", err)
	}
	return nil
}

func (mc *ManagedCommand) Stop() error {
	if mc.Cmd != nil && mc.Cmd.Process != nil {
		if err := mc.Cmd.Process.Signal(os.Interrupt); err != nil {
			return fmt.Errorf("falha ao enviar sinal de interrupção: %w", err)
		}

		if err := mc.Cmd.Wait(); err != nil {
			return fmt.Errorf("falha ao esperar o processo terminar: %w", err)
		}
	}
	return nil
}

func createJavaApp(jarPath string) (ManagedCommand, error) {
	fmt.Println("Criando aplicação Java")

	jarCommand := ManagedCommand{}

	if err := jarCommand.Start("java", "-jar", jarPath); err != nil {
		fmt.Println("Erro ao iniciar o arquivo JAR:", err)
		return jarCommand, err
	}

	return jarCommand, nil
}

func createGoApp(binPath string) (ManagedCommand, error) {
	fmt.Println("Criando aplicação Go")

	goCommand := ManagedCommand{}

	if err := goCommand.Start(binPath); err != nil {
		fmt.Println("Erro ao iniciar o binário Go:", err)
		return goCommand, err
	}

	return goCommand, nil
}

func runRequests(namespace string, size string) []MetricValue {
	sizeType := 1

	if size == "big" {
		sizeType = 2
	}

	ipjavahttp, err := getLoadBalancerIP(namespace, "javahttptest-helm-chart")
	if err != nil {
		log.Fatalf("Erro ao obter o IP do LoadBalancer: %v", err)
	}
	ipjavagrpc, err := getLoadBalancerIP(namespace, "javagrpctest-helm-chart")
	if err != nil {
		log.Fatalf("Erro ao obter o IP do LoadBalancer: %v", err)
	}
	ipgohttp, err := getLoadBalancerIP(namespace, "gohttptest-helm-chart")
	if err != nil {
		log.Fatalf("Erro ao obter o IP do LoadBalancer: %v", err)
	}
	ipgogrpc, err := getLoadBalancerIP(namespace, "gogrpctest-helm-chart")
	if err != nil {
		log.Fatalf("Erro ao obter o IP do LoadBalancer: %v", err)
	}

	httpURL1     := fmt.Sprintf("http://%s/foo", ipjavahttp)
	httpURL2     := fmt.Sprintf("http://%s:8080/foo", ipgohttp)
	grpcAddress1 := fmt.Sprintf("%s:50059", ipjavagrpc)
	grpcAddress2 := fmt.Sprintf("%s:50001", ipgogrpc)

	fmt.Println("Testando todas as aplicações")

	javaGrpcPath := "../java-grpc/target/java-grpc-0.0.1-SNAPSHOT.jar"
	javagrpc, err := createJavaApp(javaGrpcPath)
	if err != nil {
		fmt.Println(err)
		log.Fatalf("Erro ao criar aplicação Java: %v", err)
	}
	sendJavaGrpcRequests(grpcAddress1, sizeType, numReqsJava)
	javagrpc.Stop()
	
	goGrpcPath := "../go-grpc/api/api"
	gogrpc, err := createGoApp(goGrpcPath)
	if err != nil {
		log.Fatalf("Erro ao criar aplicação Go: %v", err)
	}
	sendGoGrpcRequests(grpcAddress2, sizeType, numReqs)
	gogrpc.Stop()

	javaHttpPath := "../java-http/target/java-http-0.0.1-SNAPSHOT.jar"
	javahttp, err := createJavaApp(javaHttpPath)
	if err != nil {
		log.Fatalf("Erro ao criar aplicação Java: %v", err)
	}
	sendJavaHttpRequests(httpURL1, sizeType, numReqsJava)
	javahttp.Stop()

	goHttpPath := "../go-http/api/api"
	gohttp, err := createGoApp(goHttpPath)
	if err != nil {
		log.Fatalf("Erro ao criar aplicação Go: %v", err)
	}
	sendGoHttpRequests(httpURL2, sizeType, numReqs)
	gohttp.Stop()

	tempMetrics := metrics

	metrics = []MetricValue{}

	return tempMetrics
}
