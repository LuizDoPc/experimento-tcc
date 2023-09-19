FROM golang:1.19 as builder

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY /api .

RUN CGO_ENABLED=0 GOOS=linux go build -o /goColorHttp

FROM alpine:latest

COPY --from=builder /goColorHttp /goColorHttp

EXPOSE 8080

CMD [ "./goColorHttp" ]