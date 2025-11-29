# ClickHouse Kubernetes Deployment

Простое автоматическое разворачивание базы данных ClickHouse в Kubernetes.

## Особенности

- **Single-инсталляция**: Один экземпляр ClickHouse для разработки и тестирования
- **Конфигурируемая версия**: Возможность указать желаемую версию ClickHouse
- **Управление пользователями**: Предварительная настройка пользователей с паролями
- **Persistent Storage**: Сохранение данных между перезапусками
- **Готовность и жизнеспособность**: Health checks и пробы
- **Безопасность**: Пароли хранятся в Kubernetes Secrets

## Архитектура

Решение состоит из следующих компонентов:

1. **Namespace**: `clickhouse` для изоляции ресурсов
2. **ConfigMap**: Конфигурационные файлы ClickHouse
3. **Secret**: Хранение паролей пользователей
4. **PersistentVolumeClaim**: Хранилище для данных
5. **Deployment**: Управление Pod'ом ClickHouse
6. **Service**: Сетевой доступ к ClickHouse

## Быстрый старт

### Предварительные требования

- Kubernetes кластер (v1.19+)
- `kubectl` настроенный для доступа к кластеру
- Доступное хранилище (StorageClass)

### Установка

1. Клонируйте или скачайте файлы конфигурации
2. Настройте параметры в `values.yaml`:
   ```yaml
   clickhouse:
     version: "23.3"  # Желаемая версия ClickHouse
   
   users:
     admin:
       password: "admin123"
     app_user:
       password: "app123"
     readonly_user:
       password: "readonly123"
   
   persistence:
     size: "10Gi"
     storageClass: ""  # Укажите свой StorageClass

## Запуск

```bash
    chmod +x deploy.sh
    ./deploy.sh
```

## Проверка установки

```bash
    # Проверить статус пода
    kubectl get pods -n clickhouse

    # Проверить логи
    kubectl logs -n clickhouse deployment/clickhouse

    # Проверить сервис
    kubectl get svc -n clickhouse
```