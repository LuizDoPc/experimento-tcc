package main

import (
	"bufio"
	"fmt"
	"log"
	"net/http"
	"regexp"
	"strconv"

	"k8s.io/client-go/kubernetes"
)

type MetricValue struct {
	CValue   string
	Value    float64
}

func collectMetricsFromUrl(endpointURL, appLang string) ([]MetricValue, error) {
	metricJava := "request_timer_seconds_sum"
	metricGo := "request_timer_sum" 
	
	resp, err := http.Get(endpointURL)
	if err != nil {
		return nil, fmt.Errorf("erro ao fazer a requisição para o Prometheus: %w", err)
	}
	defer resp.Body.Close()

	var metricName string
	var re *regexp.Regexp
	if appLang == "java" {
		metricName = metricJava
		re = regexp.MustCompile(fmt.Sprintf(`%s\{c="([0-9]+\.?[0-9]*)",?\}\s+([0-9]+\.?[0-9]*)`, regexp.QuoteMeta(metricName)))
	} else {
		metricName = metricGo
		re = regexp.MustCompile(fmt.Sprintf(`%s\{c="(\d+)"\}\s+(\d+\.?\d*)`, regexp.QuoteMeta(metricName)))
	}

	scanner := bufio.NewScanner(resp.Body)
	var metrics []MetricValue
	for scanner.Scan() {
		matches := re.FindStringSubmatch(scanner.Text())
		if matches != nil {
			metricValue, _ := strconv.ParseFloat(matches[2], 64)
			metrics = append(metrics, MetricValue{
				CValue:   matches[1],
				Value:    metricValue,
			})
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("erro ao ler a resposta do Prometheus: %w", err)
	}

	return metrics, nil
}

func collectMetrics(clientset *kubernetes.Clientset, namespace string) ([]MetricValue, []MetricValue, []MetricValue, []MetricValue, error) {
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

	httpURL1     := fmt.Sprintf("http://%s/actuator/prometheus", ipjavahttp)
	httpURL2     := fmt.Sprintf("http://%s:8080/metrics", ipgohttp)
	grpcAddress1 := fmt.Sprintf("http://%s:8080/actuator/prometheus", ipjavagrpc)
	grpcAddress2 := fmt.Sprintf("http://%s:8080/metrics", ipgogrpc)


	metricsJavaHTTP, err := collectMetricsFromUrl(httpURL1, "java")
    if err != nil {
        return nil, nil, nil, nil, fmt.Errorf("erro ao coletar métricas do Java HTTP Prometheus: %w", err)
    }
    metricsGoHTTP, err := collectMetricsFromUrl(httpURL2, "go")
    if err != nil {
        return nil, nil, nil, nil, fmt.Errorf("erro ao coletar métricas do Go HTTP Prometheus: %w", err)
    }
    metricsJavaGRPC, err := collectMetricsFromUrl(grpcAddress1, "java")
    if err != nil {
        return nil, nil, nil, nil, fmt.Errorf("erro ao coletar métricas do Java GRPC Prometheus: %w", err)
    }
    metricsGoGRPC, err := collectMetricsFromUrl(grpcAddress2, "go")
    if err != nil {
        return nil, nil, nil, nil, fmt.Errorf("erro ao coletar métricas do Go GRPC Prometheus: %w", err)
    }

    return metricsJavaHTTP, metricsGoHTTP, metricsJavaGRPC, metricsGoGRPC, nil
}