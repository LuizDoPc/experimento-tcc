FROM golang:1.19 as builder

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY /api .

COPY /graph ./graph

RUN CGO_ENABLED=0 GOOS=linux go build -o /goColorGrpc

FROM alpine:latest

COPY --from=builder /goColorGrpc /goColorGrpc 

EXPOSE 8081
EXPOSE 50001

CMD [ "./goColorGrpc" ]