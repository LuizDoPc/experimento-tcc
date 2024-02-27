package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
)

func createTableIfNotExists(db *sql.DB) error {
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS experiments (
			id INT NOT NULL AUTO_INCREMENT,
			c VARCHAR(255) NOT NULL,
			value FLOAT NOT NULL,
			experiment_id INT NOT NULL,
			app_name VARCHAR(255) NOT NULL,
			request_size VARCHAR(255) NOT NULL,
			PRIMARY KEY (id)
		);
	`)
	if err != nil {
		return err
	}

	fmt.Println("Tabela verificada com sucesso.")
	return nil
}

func persistMetrics(idDaExecucao int, requestSize string, metrics []MetricValue) error {
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
	
	createTableIfNotExists(db)

    stmt, err := db.Prepare("INSERT INTO experiments(c, value, experiment_id, app_name, request_size) VALUES(?, ?, ?, ?, ?)")
    if err != nil {
        return err
    }
    defer stmt.Close()

    insertMetrics := func(metrics []MetricValue) error {
        for _, metric := range metrics {
            _, err := stmt.Exec(metric.CValue, metric.Value, idDaExecucao, metric.AppName, requestSize)
            if err != nil {
                return err
            }
        }
        return nil
    }

	fmt.Println("Inserindo métricas no banco de dados...")

    if err := insertMetrics(metrics); err != nil {
        return err
    }

    return nil
}