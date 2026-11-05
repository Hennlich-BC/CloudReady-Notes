# API — текущее состояние (BC Gateway)

Дата: 05.11.2026
Источники: `api-infrastructure-cs.md` (целевая архитектура и список сценариев) и `README_bc_get_away.md` (реализованный MVP M1–M9).

> По содержанию `api-infrastructure-cs.md` описывает целевое состояние («что делегировать», «рекомендуемый стек»), а README — то, что уже собрано и работает. Поэтому ниже `api-infrastructure` принят за 100 % объёма, а README — за факт выполнения.

## Сводная статистика

| Раздел | Пунктов | Готовность |
|---|---|---|
| Бизнес-сценарии для делегирования в REST API | 12 | **≈ 9 %** |
| Общие требования к REST API | 6 | **65 %** |
| Компоненты стека Docker Compose | 10 | **40 %** |
| Инфраструктура и эксплуатация | 7 | **75 %** |
| Минимальная первая версия (5 сервисов) | 5 | **60 %** (3 из 5) |
| **Итого (среднее по четырём основным разделам)** | | **≈ 47 %** |

Коротко: платформа (очередь, БД, outbox, API, retry/DLQ, мониторинг, backup) построена хорошо и закрывает большую часть инфраструктурных требований. Из бизнес-сценариев реально работает только FTP/SFTP; PDF, печать, перевозчики, FinStat, SQL/HPL ещё не начаты.

## 1. Бизнес-сценарии (≈ 9 %)

| Сценарий | Готовность | Что есть / чего нет |
|---|---|---|
| FTP/SFTP и SafeQueFile | 80 % | Есть: FTP/FTPS/SFTP upload, list, download (по имени или маске), move, retry с backoff, идемпотентность, DLQ, ручной retry, профили в `ftp.yaml`. Нет: периодического polling каталогов/очередей по расписанию, автоматической архивации, отдельной поддержки SafeQueFile. |
| EDI, SKF, Škoda Auto, Eračun | 15 % | Есть: транспорт EDI-файлов через FTP-профили `FTP-GMORS-DESADV` / `FTP-GMORS-ORDRSP`. Нет: AS2, подписи/шифрования, валидации XSD, трансформации форматов. |
| PDF-этикетки и серверные принтеры | 10 % | Есть: план M10 (SMB/CUPS backend-ы, общий print job) и диагностический скрипт `test-vprint-connection.py`. Нет: реализации печати и Print Agent. |
| Объединение PDF | 0 % | — |
| PDF Template Management | 0 % | — |
| Штрихкоды | 0 % | — |
| SQL management и складские остатки HPL | 0 % | — |
| FinStat | 0 % | — |
| Перевозчики (GLS/DPD/GEIS/TNT/FedEx) | 0 % | — |
| NCH | 0 % | Можно будет переиспользовать FTP-транспорт. |
| Изображения на терминалах сбора данных | 0 % | — |
| WebService Management (gateway) | 0 % | — |

## 2. Общие требования к REST API (65 %)

| Требование | Готовность | Комментарий |
|---|---|---|
| Идемпотентность | 100 % | Уникальный индекс `(type, idempotency_key)`, обработчики идемпотентны по `task_id`. |
| Асинхронная модель + status endpoint | 100 % | Задачи через очередь, `GET /api/v1/tasks/{id}`, список с cursor pagination, WebSocket-уведомления. |
| Версионированный контракт, коды ошибок, health | 100 % | `/api/v1/...`, единый формат ошибок (`AUTH_REQUIRED`, `TASK_NOT_FOUND` …), `/health` и `/health/ready`, OpenAPI `/docs`. |
| Лимиты, timeout, retry с backoff, correlation ID, логи | 60 % | Есть: retry 15 с → 1 → 5 → 15 мин, DLQ, `request_id` в ошибках, таймауты outbox, метрики в логах. Не описаны: лимиты размера запроса, сквозной correlation ID, политика логов без персональных данных. |
| HTTPS и OAuth 2.0 / короткоживущие токены | 30 % | Есть: `X-API-Key`, секреты только в `.env`. Нет: HTTPS (API слушает HTTP на `127.0.0.1:8000`), OAuth 2.0 / managed identity. |
| AL client codeunit, setup table/page, permissions, интеграционные тесты в BC | 0 % | — |

## 3. Компоненты стека (40 %)

| Сервис | Цель | Готовность | Комментарий |
|---|---|---|---|
| api | FastAPI, Uvicorn, Pydantic | 100 % | M5, плюс Swagger UI. |
| rabbitmq | Надёжная очередь | 100 % | Durable-топология, `tasks.direct`, DLX, приоритеты, TTL 7 суток. |
| postgres | SQLAlchemy, Alembic | 100 % | Модели в `bc_gateway_core`, миграции через `migrator`. |
| redis (опционально) | Кэш токенов, rate limiting, блокировки | 50 % | Развёрнут, но используется для Pub/Sub WebSocket, а не для кэша/rate limiting. |
| worker-integrations | HTTPX, lxml, Paramiko | 30 % | Есть FTP/FTPS/SFTP worker (собственный consumer, не Celery). Нет перевозчиков, FinStat, EDI, REST/SOAP. |
| observability (опционально) | OpenTelemetry, Prometheus/Grafana | 20 % | Есть метрики-счётчики в логах relay и worker, `make health`. Нет OTel/Prometheus. |
| reverse-proxy (Nginx) | Nginx, TLS | 0 % | API опубликован напрямую на loopback. |
| worker-documents | Typst, pikepdf | 0 % | Не начат. Даёт сразу три сценария с высокой пригодностью: объединение PDF, шаблоны, штрихкоды/этикетки. |
| scheduler | Celery Beat | 0 % | Регулярный polling FTP и очистка отсутствуют. |
| minio (опционально) | S3-хранилище | 0 % | Файлы хранятся в `/app/data/documents`. |

## 4. Инфраструктура и эксплуатация (75 %)

| Требование | Готовность | Комментарий |
|---|---|---|
| Отдельный Linux-сервер, Docker Engine + Compose | 100 % | Стек работает на отдельном SSH-сервере. |
| Backup БД | 100 % | `make backup-postgres` с проверкой `pg_restore --list` и retention (M9). |
| Healthchecks | 100 % | `make health`: PostgreSQL, Redis, RabbitMQ, readiness API, DLQ, exit codes для мониторинга. |
| Ротация логов | 100 % | Logging driver `local` с лимитами, конфигурация logrotate. |
| Именованные volumes | 75 % | Есть для PostgreSQL, RabbitMQ, Redis, документов. Нет `typst_templates` (Typst ещё не внедрён). |
| Наружу только HTTPS-порт | 50 % | AMQP и Redis не публикуются, PostgreSQL и API — только loopback. Но веб-интерфейс RabbitMQ проброшен (по README его нужно убрать перед продакшеном), а HTTPS-порта пока нет. |
| Доверенный TLS-сертификат | 0 % | Зависит от reverse-proxy (Nginx). |

## Итоговая таблица

| Область | Элемент | Готовность |
|---|---|---|
| Вход | reverse-proxy (Nginx) | 0 % |
| Вход | HTTPS / OAuth 2.0 | 30 % |
| Ядро | FastAPI | 100 % |
| Ядро | PostgreSQL (tasks, outbox) | 100 % |
| Ядро | RabbitMQ (q.ftp, DLX, q.dead_letter) | 100 % |
| Ядро | Redis (Pub/Sub статусов) | 50 % |
| Обработчики | worker-integrations | 30 % |
| Обработчики | worker-documents (Typst / pikepdf) | 0 % |
| Обработчики | печать (M10) | 10 % |
| Обработчики | scheduler | 0 % |
| Интеграции | FTP / FTPS / SFTP | 80 % |
| Интеграции | EDI (SKF, Škoda Auto, Eračun) | 15 % |
| Интеграции | перевозчики / FinStat / NCH / SQL-HPL | 0 % |
| Хранилище | volumes | 75 % |
| Хранилище | MinIO | 0 % |
| Эксплуатация | observability | 20 % |
| Эксплуатация | backup | 100 % |
| Эксплуатация | healthchecks | 100 % |
| Эксплуатация | ротация логов | 100 % |
| Эксплуатация | TLS-сертификат | 0 % |
| **Итого** | сценарии ≈ 9 % · требования 65 % · компоненты 40 % · инфраструктура 75 % | **≈ 47 %** |
