#!/bin/bash

set -e

# Функция для вычисления SHA256 хеша пароля
calculate_sha256() {
    echo -n "$1" | sha256sum | awk '{print $1}'
}

# Функция для проверки зависимостей
check_dependencies() {
    local deps=("kubectl" "helm")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "Error: $dep is required but not installed."
            exit 1
        fi
    done
}

# Функция для генерации хешей паролей
generate_password_hashes() {
    echo "Generating password hashes..."
    
    # Временный файл для значений
    local temp_values="temp-values.yaml"
    cp values.yaml "$temp_values"
    
    # Генерируем хеши для каждого пользователя
    for user in admin app_user readonly_user; do
        local password=$(grep -A1 "^\s*$user:" values.yaml | grep "password:" | awk '{print $2}' | tr -d '"')
        if [[ -n "$password" ]]; then
            local sha256_hash=$(calculate_sha256 "$password")
            # Заменяем пустые хеши в values.yaml
            sed -i "s/\($user:\)/\1\n    password_sha256: \"$sha256_hash\"/" "$temp_values"
        fi
    done
    
    echo "$temp_values"
}

# Основная функция развертывания
deploy_clickhouse() {
    echo "Starting ClickHouse deployment..."
    
    # Проверяем зависимости
    check_dependencies
    
    # Генерируем временный файл с хешами
    local values_file=$(generate_password_hashes)
    
    # Создаем namespace
    echo "Creating namespace..."
    kubectl apply -f namespace.yaml
    
    # Применяем конфигурации с использованием helm для шаблонизации
    echo "Applying configurations..."
    for file in configmap.yaml secret.yaml pvc.yaml deployment.yaml service.yaml; do
        if [[ -f "$file" ]]; then
            echo "Processing $file..."
            helm template . -f "$values_file" -s "$file" | kubectl apply -f -
        fi
    done
    
    # Удаляем временный файл
    rm -f "$values_file"
    
    # Ждем готовности пода
    echo "Waiting for ClickHouse to be ready..."
    kubectl wait --namespace clickhouse --for=condition=ready pod -l app=clickhouse --timeout=300s
    
    echo "ClickHouse deployment completed successfully!"
    echo ""
    echo "Access information:"
    echo "  HTTP port: 8123"
    echo "  Native port: 9000"
    echo "  MySQL port: 9004"
    echo "  PostgreSQL port: 9005"
    echo ""
    echo "Connect using:"
    echo "  clickhouse-client --host clickhouse.clickhouse.svc.cluster.local --port 9000 --user admin --password admin123"
}

# Функция удаления
delete_clickhouse() {
    echo "Deleting ClickHouse deployment..."
    kubectl delete namespace clickhouse --ignore-not-found=true
    echo "ClickHouse deployment deleted."
}

# Обработка аргументов командной строки
case "${1:-}" in
    "delete")
        delete_clickhouse
        ;;
    *)
        deploy_clickhouse
        ;;
esac