FROM golang:1.24-alpine3.21 AS builder

WORKDIR /app

# 先拷贝依赖文件并下载，利用 Docker 缓存层
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# 编译项目
# CGO_ENABLED=0: 强制静态编译，生成的二进制文件不依赖宿主机的 C 库
# -ldflags="-s -w": 进一步压缩体积，去掉调试信息和符号表
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o main main.go

# Run Stage
FROM alpine:3.21

WORKDIR /app

COPY --from=builder /app/main .
COPY app.env .
COPY db/migration ./db/migration
COPY start.sh .
COPY wait-for.sh .

# 暴露端口
EXPOSE 8080

# 设置容器启动时执行的脚本
CMD [ "/app/main" ]
ENTRYPOINT [ "/app/start.sh" ]