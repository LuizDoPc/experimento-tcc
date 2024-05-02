package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
)

func getLoadBalancerIP(namespace, serviceName string) (string, error) {
	// service, err := clientset.CoreV1().Services(namespace).Get(context.TODO(), serviceName, metav1.GetOptions{})
	// if err != nil {
	// 	return "", err
	// }

	// if len(service.Status.LoadBalancer.Ingress) > 0 {
	// 	return service.Status.LoadBalancer.Ingress[0].IP, nil
	// }

	// return "", fmt.Errorf("IP do LoadBalancer não encontrado")

	if serviceName == "javahttptest-helm-chart" {
		return "localhost:8080", nil
	}

	if serviceName == "javagrpctest-helm-chart" {
		return "localhost", nil
	}

	if serviceName == "gohttptest-helm-chart" {
		return "localhost", nil
	}

	if serviceName == "gogrpctest-helm-chart" {
		return "localhost", nil
	}

	return "", nil
}

func copyFile(src, dest string) error {
	in, err := os.Open(src)
	if err != nil{
		return err
	}
	defer in.Close()

	out, err := os.Create(dest)
	if err != nil{
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, in)
	if err != nil{
		return err
	}
	
	return out.Close()
}

func manageKindCluster() error {
//	fmt.Println("Deletando o cluster minikube existente, se houver...")
//	deleteCmd := exec.Command("minikube", "delete")
//	if err := deleteCmd.Run(); err != nil {
//		return fmt.Errorf("falha ao deletar o cluster Kind: %w", err)
//	}
//
//	fmt.Println("Criando um novo cluster minikube...")
//	createCmd := exec.Command("minikube", "start", "--driver=kvm2", "--cpus=8", "--memory=14000")
//	
//	if err := createCmd.Run(); err != nil {
//		fmt.Println(err)
//		return fmt.Errorf("falha ao criar o cluster minikube: %w", err)
//	}

	kubeconfigPath := filepath.Join(".", "kubeconfig.yaml")
	fmt.Printf("Salvando kubeconfig em: %s\n", kubeconfigPath)

	defaultKubeConfigPath := filepath.Join(os.Getenv("HOME"), ".kube", "config")

	err := copyFile(defaultKubeConfigPath , kubeconfigPath)
	if err != nil {
		fmt.Println(err) 
		return fmt.Errorf("falha ao copiar o kubeconfig: %w", err)
	}

	fmt.Println("Cluster Kind criado e kubeconfig salvo com sucesso.")
	return nil
}

func runHelmfileCharts(times int)  error {
	parentDir := filepath.Join("..")

	for i := 0; i < times; i++ {
		fmt.Printf("Executando 'helmfile charts' no diretório pai (%s), iteração %d...\n", parentDir, i+1)
		cmd := exec.Command("helmfile", "charts")
		cmd.Dir = parentDir

		var stderr bytes.Buffer
		cmd.Stderr = &stderr

		cmd.Run()
	}

	fmt.Println("Execução do comando 'helmfile charts' concluída.")
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
