# 使用官方Go镜像作为基础
FROM golang:1.24.1 as builder

# 安装Git和必要的工具
RUN apt-get update && apt-get install -y git

# 设置工作目录
WORKDIR /app

# 复制监控脚本
COPY monitor.sh .

# 设置可执行权限
RUN chmod +x monitor.sh

# 入口点
ENTRYPOINT ["./monitor.sh"]