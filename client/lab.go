package main

import (
	"fmt"
	"log"
	"time"

	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func checkPodsLoop(clientset *kubernetes.Clientset, namespace string, checkInterval time.Duration) {
	for {
		running, err := areAllPodsRunning(clientset, namespace)
		if err != nil {
			fmt.Printf("Erro ao verificar os pods: %s\n", err)
			break
		}

		if running {
			fmt.Println("Todos os pods estão rodando!")
			break
		} else {
			fmt.Println("Ainda há pods que não estão no estado 'Running', verificando novamente após o intervalo...")
			time.Sleep(checkInterval)
		}
	}
}


func main() {
	namespace := "monitoring"
	checkInterval := 10 * time.Second

	config, err := clientcmd.BuildConfigFromFlags("", "/home/luiz/Documents/experimento-tcc/kubekeep/kubeconfig.yaml")
	if err != nil {
		log.Fatalf("Erro ao criar configuração do cliente Kubernetes: %v", err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Fatalf("Erro ao criar cliente Kubernetes: %v", err)
	}

	manageKindCluster()

	runHelmfileChartsTwice()	

	checkPodsLoop(clientset, namespace, checkInterval)	
}
