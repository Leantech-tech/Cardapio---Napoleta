# Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copia os arquivos de dependências primeiro (melhora cache do Docker)
COPY pubspec.yaml pubspec.lock ./
COPY assets/ assets/

# Baixa as dependências
RUN flutter config --no-analytics && \
    flutter pub get

# Copia o restante do código
COPY . .

# Build do Flutter web
RUN flutter build web --release --no-tree-shake-icons && \
    rm -f /app/build/web/flutter_service_worker.js

# Runtime stage
FROM nginx:alpine

# Instala envsubst para substituir ${PORT} no nginx.conf
RUN apk add --no-cache gettext

# Copia a configuração do nginx
COPY nginx.conf /app/nginx.conf

# Copia os arquivos buildados do Flutter
COPY --from=builder /app/build/web /app/build/web

# Substitui ${PORT} e inicia o nginx
CMD envsubst '${PORT}' < /app/nginx.conf > /tmp/nginx.conf && nginx -c /tmp/nginx.conf -g "daemon off;"
