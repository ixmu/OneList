FROM alpine:latest

# 1. 安装基础环境
RUN apk add --no-cache ca-certificates wget tzdata gcompat

WORKDIR /app

# 2. 准备备份目录，下载文件
# 关键改动：预设 config.json 为 {} 而不是全空，确保 JSON 解析器不报错
RUN mkdir -p /tmp/defaults && \
    wget --no-check-certificate -O /tmp/defaults/OneList https://raw.githubusercontent.com/MoeClub/OneList/master/Rewrite/amd64/linux/OneList && \
    chmod +x /tmp/defaults/OneList && \
    wget --no-check-certificate -O /tmp/defaults/index.html https://raw.githubusercontent.com/MoeClub/OneList/master/Rewrite/@Theme/HaorWu/index.html && \
    echo '{}' > /tmp/defaults/config.json

# 3. 生成 entrypoint.sh
RUN cat <<-'EOF' > /usr/local/bin/entrypoint.sh
#!/bin/sh
cd /app

# 恢复文件
if [ ! -f "/app/OneList" ]; then
    echo "First run: Initializing /app directory..."
    cp -r /tmp/defaults/* /app/
    chmod +x /app/OneList
fi

CONFIG_FILE="/app/config.json"

# 判断逻辑：如果 config.json 内容是 {}（初始状态），则运行初始化
if [ "$(cat $CONFIG_FILE 2>/dev/null)" = "{}" ]; then
    echo "config.json is default. Running OneList initialization..."
    ./OneList -a "${INIT_VALUE}" -s "${SUB_PATH}"
else
    echo "config.json already configured, skipping initialization."
fi

echo "Starting OneList service..."
exec ./OneList -bind 0.0.0.0 -port 8080
EOF

RUN chmod +x /usr/local/bin/entrypoint.sh

ENV INIT_VALUE="default_token"
ENV SUB_PATH="/"

VOLUME ["/app"]
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
