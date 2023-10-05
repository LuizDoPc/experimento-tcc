package main

import (
	"context"
	"flag"
	"fmt"

	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func main() {
	var (
		keepDeployment string
		kubeconfig     string
	)

	// Define as flags de linha de comando
	flag.StringVar(&keepDeployment, "k", "", "Nome do Deployment a ser mantido de pé")
	flag.StringVar(&kubeconfig, "kubeconfig", "/home/luiz/Documents/experimento-tcc/kubekeep/kubeconfig.yaml", "Caminho para o arquivo kubeconfig")
	flag.Parse()

	// Carregue a configuração do Kubernetes do arquivo kubeconfig
	config, err := rest.InClusterConfig()
	if err != nil {
		config, err = clientcmd.BuildConfigFromFlags("", kubeconfig)
		if err != nil {
			panic(err.Error())
		}
	}

	// Crie um cliente Kubernetes
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}

	// Crie um contexto
	ctx := context.TODO()

	if keepDeployment != "" {
		// Se a flag "keep-deployment" estiver definida, mantenha apenas o Deployment especificado
		deployments, err := clientset.AppsV1().Deployments("monitoring").List(ctx, metav1.ListOptions{})
		if err != nil {
			panic(err.Error())
		}

		// Itere sobre os Deployments e ajuste a estratégia para 0 e depois para 1 réplica, exceto para o Deployment especificado
		for _, deployment := range deployments.Items {
			if deployment.Name != keepDeployment+"test-helm-chart" && deployment.Name != "kube-prometheus-stack-operator" {
				fmt.Printf("Ajustando o Deployment %s para 0 réplicas...\n", deployment.Name)

				// Configure a réplica para 0
				deployment.Spec.Replicas = int32Ptr(0)
				_, err = clientset.AppsV1().Deployments("monitoring").Update(ctx, &deployment, metav1.UpdateOptions{})
				if err != nil {
					fmt.Printf("Erro ao ajustar o Deployment %s: %v\n", deployment.Name, err)
				} else {
					fmt.Printf("Deployment %s ajustado para 0 réplicas com sucesso.\n", deployment.Name)
				}
			} else {
				fmt.Printf("Ajustando o Deployment %s para 1 réplicas...\n", deployment.Name)

				// Configure a réplica para 1
				deployment.Spec.Replicas = int32Ptr(1)
				_, err = clientset.AppsV1().Deployments("monitoring").Update(ctx, &deployment, metav1.UpdateOptions{})
				if err != nil {
					fmt.Printf("Erro ao ajustar o Deployment %s: %v\n", deployment.Name, err)
				} else {
					fmt.Printf("Deployment %s ajustado para 1 réplicas com sucesso.\n", deployment.Name)
				}
			}
		}

		// StatefulSets a serem removidos
		statefulSetsToDelete := []string{
			"alertmanager-kube-prometheus-stack-alertmanager",
			"prometheus-kube-prometheus-stack-prometheus",
		}

		// Iterar sobre os StatefulSets e excluí-los
		for _, statefulSetName := range statefulSetsToDelete {
			fmt.Printf("Deletando StatefulSet: %s\n", statefulSetName)
			err := clientset.AppsV1().StatefulSets("monitoring").Delete(ctx, statefulSetName, metav1.DeleteOptions{})
			if err != nil {
				fmt.Printf("Erro ao excluir o StatefulSet %s: %v\n", statefulSetName, err)
			} else {
				fmt.Printf("StatefulSet %s excluído com sucesso.\n", statefulSetName)
			}
		}
		
		// Nome do DaemonSet a ser removido
		daemonSetName := "kube-prometheus-stack-prometheus-node-exporter"

		// Excluir o DaemonSet
		fmt.Printf("Deletando DaemonSet: %s\n", daemonSetName)
		err = clientset.AppsV1().DaemonSets("monitoring").Delete(ctx, daemonSetName, metav1.DeleteOptions{})
		if err != nil {
		    fmt.Printf("Erro ao excluir o DaemonSet %s: %v\n", daemonSetName, err)
		} else {
		    fmt.Printf("DaemonSet %s excluído com sucesso.\n", daemonSetName)
		}
		
		// StatefulSets a serem removidos
		statefulSetsToDelete = []string{
			"alertmanager-kube-prometheus-stack-alertmanager",
			"prometheus-kube-prometheus-stack-prometheus",
		}

		// Iterar sobre os StatefulSets e excluí-los
		for _, statefulSetName := range statefulSetsToDelete {
			fmt.Printf("Deletando StatefulSet: %s\n", statefulSetName)
			err := clientset.AppsV1().StatefulSets("monitoring").Delete(ctx, statefulSetName, metav1.DeleteOptions{})
			if err != nil {
				fmt.Printf("Erro ao excluir o StatefulSet %s: %v\n", statefulSetName, err)
			} else {
				fmt.Printf("StatefulSet %s excluído com sucesso.\n", statefulSetName)
			}
		}
	}
}

func int32Ptr(i int32) *int32 {
	return &i
}

