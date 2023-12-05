package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
)

func persistMetrics(idDaExecucao int, metricsJavaHTTP, metricsGoHTTP, metricsJavaGRPC, metricsGoGRPC []MetricValue) error {
	dbHost := "localhost:3306"
    dbUser := "admin"
    dbPassword := "123"
    dbName := "metrics"

    dsn := fmt.Sprintf("%s:%s@tcp(%s)/%s", dbUser, dbPassword, dbHost, dbName)

	db, err := sql.Open("mysql", dsn)
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()
	

    stmt, err := db.Prepare("INSERT INTO experiments(c, value, experiment_id, app_name) VALUES(?, ?, ?, ?)")
    if err != nil {
        return err
    }
    defer stmt.Close()

    insertMetrics := func(metrics []MetricValue, appName string) error {
        for _, metric := range metrics {
            _, err := stmt.Exec(metric.CValue, metric.Value, idDaExecucao, appName)
            if err != nil {
                return err
            }
        }
        return nil
    }

    if err := insertMetrics(metricsJavaHTTP, "javahttp"); err != nil {
        return err
    }
    if err := insertMetrics(metricsGoHTTP, "gohttp"); err != nil {
        return err
    }
    if err := insertMetrics(metricsJavaGRPC, "javagrpc"); err != nil {
        return err
    }
    if err := insertMetrics(metricsGoGRPC, "gogrpc"); err != nil {
        return err
    }

    return nil
}