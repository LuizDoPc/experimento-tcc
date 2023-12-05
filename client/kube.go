package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
)

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

func manageKindCluster() error {
	fmt.Println("Deletando o cluster Kind existente, se houver...")
	deleteCmd := exec.Command("kind", "delete", "cluster")
	if err := deleteCmd.Run(); err != nil {
		return fmt.Errorf("falha ao deletar o cluster Kind: %w", err)
	}

	fmt.Println("Criando um novo cluster Kind...")
	createCmd := exec.Command("kind", "create", "cluster")
	if err := createCmd.Run(); err != nil {
		return fmt.Errorf("falha ao criar o cluster Kind: %w", err)
	}

	kubeconfigPath := filepath.Join(".", "kubeconfig.yaml")
	fmt.Printf("Salvando kubeconfig em: %s\n", kubeconfigPath)

	saveCmd := exec.Command("kind", "get", "kubeconfig")
	outFile, err := os.Create(kubeconfigPath)
	if err != nil {
		return fmt.Errorf("falha ao criar o arquivo kubeconfig: %w", err)
	}
	defer outFile.Close()

	saveCmd.Stdout = outFile
	if err := saveCmd.Run(); err != nil {
		return fmt.Errorf("falha ao salvar o kubeconfig: %w", err)
	}

	fmt.Println("Cluster Kind criado e kubeconfig salvo com sucesso.")
	return nil
}

func runHelmfileChartsTwice() error {
	fmt.Println("Executando 'helmfile charts' pela primeira vez...")
	firstRun := exec.Command("helmfile", "charts")
	if err := firstRun.Run(); err != nil {
		return fmt.Errorf("erro na primeira execução do helmfile charts: %w", err)
	}

	fmt.Println("Executando 'helmfile charts' pela segunda vez...")
	secondRun := exec.Command("helmfile", "charts")
	if err := secondRun.Run(); err != nil {
		return fmt.Errorf("erro na segunda execução do helmfile charts: %w", err)
	}

	fmt.Println("Comandos 'helmfile charts' executados com sucesso.")
	return nil
}

func areAllPodsRunning(clientset *kubernetes.Clientset, namespace string) (bool, error) {
	pods, err := clientset.CoreV1().Pods(namespace).List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		return false, fmt.Errorf("erro ao listar pods: %w", err)
	}

	for _, pod := range pods.Items {
		if pod.Status.Phase != "Running" {
			return false, nil
		}
	}

	return true, nil
}
