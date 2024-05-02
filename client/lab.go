package main

import (
	"fmt"
	// "log"
	// "time"
	// "k8s.io/client-go/kubernetes"
	// "k8s.io/client-go/tools/clientcmd"
)

func runExperiment(experimentId int, size string) {
	fmt.Println("Iniciando experimento ", experimentId, " com tamanho ", size, "...")
	// manageKindCluster()

	// time.Sleep(20 * time.Second)

	// runHelmfileCharts(2)	

	// time.Sleep(20 * time.Second)

	namespace := "monitoring"
	// checkInterval := 10 * time.Second

	// config, err := clientcmd.BuildConfigFromFlags("", "./kubeconfig.yaml")
	// if err != nil {
	// 	log.Fatalf("Erro ao criar configuração do cliente Kubernetes: %v", err)
	// }

	// clientset, err := kubernetes.NewForConfig(config)
	// if err != nil {
	// 	log.Fatalf("Erro ao criar cliente Kubernetes: %v", err)
	// }

	// checkPodsLoop(clientset, namespace, checkInterval)	

	// time.Sleep(20 * time.Second)

	// runHelmfileCharts(2)	

	// time.Sleep(20 * time.Second)

	metrics := runRequests(namespace, size)

	fmt.Println("Finalizando as requests! Iniciando persistência...")

	persistMetrics(experimentId, size, metrics)

	fmt.Println("Finalizando experimento com sucesso! \n\n")
}

func main() {
//	for i := 1; i < 10; i++ {
//		runExperiment(6, "small")
		runExperiment(1, "big")
//	}
}
