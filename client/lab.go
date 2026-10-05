package main

import (
	"fmt"
	// "log"
	// "time"
	// "k8s.io/client-go/kubernetes"
	// "k8s.io/client-go/tools/clientcmd"
)

func runExperiment(experimentId int, payloadSize int) {
	fmt.Printf("Iniciando experimento %d com payload de %d números...\n", experimentId, payloadSize)

	namespace := "monitoring"

	metrics := runRequests(namespace, payloadSize)

	fmt.Println("Finalizando as requests! Iniciando persistência...")

	payloadSizeStr := fmt.Sprintf("%d", payloadSize)
	persistMetrics(experimentId, payloadSizeStr, metrics)

	fmt.Println("Finalizando experimento com sucesso! \n\n")
}

func runExperimentBatch(experimentIdStart int, payloadSizes []int, runsPerSize int) {
	currentExperimentId := experimentIdStart
	
	for _, payloadSize := range payloadSizes {
		for run := 1; run <= runsPerSize; run++ {
			runExperiment(currentExperimentId, payloadSize)
			currentExperimentId++
		}
	}
	
	fmt.Printf("Concluído: %d experimentos executados\n", currentExperimentId-experimentIdStart)
}

func main() {
	payloadSizesPhase1 := []int{200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 150000, 204800}
	// payloadSizesPhase1 := []int{200, 500}
	
	runExperimentBatch(1, payloadSizesPhase1, 5)
}
