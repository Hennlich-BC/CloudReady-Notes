# API — aktuální stav (BC Gateway)

Datum: 05.11.2026
Zdroje: `api-infrastructure-cs.md` (cílová architektura a seznam scénářů) a `README_bc_get_away.md` (implementované MVP M1–M9).

> Podle obsahu popisuje `api-infrastructure-cs.md` cílový stav („co delegovat“, „doporučený stack“), zatímco README popisuje to, co je již sestaveno a funguje. Proto je níže `api-infrastructure` brán jako 100 % rozsahu a README jako skutečný stav plnění.

## Souhrnná statistika

| Oblast | Počet bodů | Hotovo |
|---|---|---|
| Obchodní scénáře pro delegování do REST API | 12 | **≈ 9 %** |
| Společné požadavky na REST API | 6 | **65 %** |
| Komponenty stacku Docker Compose | 10 | **40 %** |
| Infrastruktura a provoz | 7 | **75 %** |
| Minimální první verze (5 služeb) | 5 | **60 %** (3 z 5) |
| **Celkem (průměr čtyř hlavních oblastí)** | | **≈ 47 %** |

Stručně: platforma (fronta, databáze, outbox, API, retry/DLQ, monitoring, backup) je postavena dobře a pokrývá většinu infrastrukturních požadavků. Z obchodních scénářů reálně funguje pouze FTP/SFTP; PDF, tisk, přepravci, FinStat a SQL/HPL zatím nejsou zahájeny.

## 1. Obchodní scénáře (≈ 9 %)

| Scénář | Hotovo | Co je / co chybí |
|---|---|---|
| FTP/SFTP a SafeQueFile | 80 % | Je: FTP/FTPS/SFTP upload, list, download (podle názvu nebo masky), move, retry s backoff, idempotence, DLQ, ruční retry, profily v `ftp.yaml`. Chybí: pravidelný polling adresářů/front podle plánu, automatická archivace, samostatná podpora SafeQueFile. |
| EDI, SKF, Škoda Auto, Eračun | 15 % | Je: přenos EDI souborů přes FTP profily `FTP-GMORS-DESADV` / `FTP-GMORS-ORDRSP`. Chybí: AS2, podpis/šifrování, validace XSD, transformace formátů. |
| PDF štítky a serverové tiskárny | 10 % | Je: plán M10 (SMB/CUPS backendy, společný print job) a diagnostický skript `test-vprint-connection.py`. Chybí: implementace tisku a Print Agent. |
| Slučování PDF | 0 % | — |
| PDF Template Management | 0 % | — |
| Čárové kódy | 0 % | — |
| SQL management a HPL skladové zásoby | 0 % | — |
| FinStat | 0 % | — |
| Přepravci (GLS/DPD/GEIS/TNT/FedEx) | 0 % | — |
| NCH | 0 % | Bude možné znovu využít FTP přenos. |
| Obrázky na čtečkách | 0 % | — |
| WebService Management (gateway) | 0 % | — |

## 2. Společné požadavky na REST API (65 %)

| Požadavek | Hotovo | Komentář |
|---|---|---|
| Idempotence | 100 % | Unikátní index `(type, idempotency_key)`, handlery jsou idempotentní podle `task_id`. |
| Asynchronní model + status endpoint | 100 % | Úlohy přes frontu, `GET /api/v1/tasks/{id}`, seznam s cursor pagination, WebSocket notifikace. |
| Verzovaný kontrakt, chybové kódy, health | 100 % | `/api/v1/...`, jednotný formát chyb (`AUTH_REQUIRED`, `TASK_NOT_FOUND` …), `/health` a `/health/ready`, OpenAPI `/docs`. |
| Limity, timeout, retry s backoff, correlation ID, logy | 60 % | Je: retry 15 s → 1 → 5 → 15 min, DLQ, `request_id` v chybách, timeouty outboxu, metriky v logu. Nepopsáno: limity velikosti požadavku, průběžné correlation ID, pravidla logování bez osobních údajů. |
| HTTPS a OAuth 2.0 / krátkodobé tokeny | 30 % | Je: `X-API-Key`, tajné údaje pouze v `.env`. Chybí: HTTPS (API naslouchá přes HTTP na `127.0.0.1:8000`), OAuth 2.0 / managed identity. |
| AL client codeunit, setup table/page, permissions, integrační testy v BC | 0 % | — |

## 3. Komponenty stacku (40 %)

| Služba | Cíl | Hotovo | Komentář |
|---|---|---|---|
| api | FastAPI, Uvicorn, Pydantic | 100 % | M5, navíc Swagger UI. |
| rabbitmq | Spolehlivá fronta | 100 % | Durable topologie, `tasks.direct`, DLX, priority, TTL 7 dní. |
| postgres | SQLAlchemy, Alembic | 100 % | Modely v `bc_gateway_core`, migrace přes `migrator`. |
| redis (volitelně) | Cache tokenů, rate limiting, zámky | 50 % | Nasazen, ale používá se pro Pub/Sub WebSocketu, ne pro cache/rate limiting. |
| worker-integrations | HTTPX, lxml, Paramiko | 30 % | Je FTP/FTPS/SFTP worker (vlastní consumer, ne Celery). Chybí přepravci, FinStat, EDI, REST/SOAP. |
| observability (volitelně) | OpenTelemetry, Prometheus/Grafana | 20 % | Jsou metriky-čítače v logu relay a workeru, `make health`. Chybí OTel/Prometheus. |
| reverse-proxy (Nginx) | Nginx, TLS | 0 % | API je publikováno přímo na loopback. |
| worker-documents | Typst, pikepdf | 0 % | Nezahájeno. Pokryje rovnou tři scénáře s vysokou vhodností: slučování PDF, šablony, čárové kódy/štítky. |
| scheduler | Celery Beat | 0 % | Pravidelný polling FTP a čištění chybí. |
| minio (volitelně) | S3 úložiště | 0 % | Soubory se ukládají do `/app/data/documents`. |

## 4. Infrastruktura a provoz (75 %)

| Požadavek | Hotovo | Komentář |
|---|---|---|
| Samostatný Linux server, Docker Engine + Compose | 100 % | Stack běží na samostatném SSH serveru. |
| Backup databáze | 100 % | `make backup-postgres` s kontrolou `pg_restore --list` a retencí (M9). |
| Healthchecks | 100 % | `make health`: PostgreSQL, Redis, RabbitMQ, readiness API, DLQ, exit kódy pro monitoring. |
| Rotace logů | 100 % | Logging driver `local` s limity, konfigurace logrotate. |
| Pojmenované volumes | 75 % | Jsou pro PostgreSQL, RabbitMQ, Redis a dokumenty. Chybí `typst_templates` (Typst zatím není nasazen). |
| Navenek pouze HTTPS port | 50 % | AMQP a Redis nejsou publikovány, PostgreSQL a API jen na loopback. Webové rozhraní RabbitMQ je ale publikováno (podle README je nutné ho před produkcí odstranit) a HTTPS port zatím neexistuje. |
| Důvěryhodný TLS certifikát | 0 % | Závisí na reverse-proxy (Nginx). |

## Souhrnná tabulka

| Oblast | Prvek | Hotovo |
|---|---|---|
| Vstup | reverse-proxy (Nginx) | 0 % |
| Vstup | HTTPS / OAuth 2.0 | 30 % |
| Jádro | FastAPI | 100 % |
| Jádro | PostgreSQL (tasks, outbox) | 100 % |
| Jádro | RabbitMQ (q.ftp, DLX, q.dead_letter) | 100 % |
| Jádro | Redis (Pub/Sub stavů) | 50 % |
| Zpracování | worker-integrations | 30 % |
| Zpracování | worker-documents (Typst / pikepdf) | 0 % |
| Zpracování | tisk (M10) | 10 % |
| Zpracování | scheduler | 0 % |
| Integrace | FTP / FTPS / SFTP | 80 % |
| Integrace | EDI (SKF, Škoda Auto, Eračun) | 15 % |
| Integrace | přepravci / FinStat / NCH / SQL-HPL | 0 % |
| Úložiště | volumes | 75 % |
| Úložiště | MinIO | 0 % |
| Provoz | observability | 20 % |
| Provoz | backup | 100 % |
| Provoz | healthchecks | 100 % |
| Provoz | rotace logů | 100 % |
| Provoz | TLS certifikát | 0 % |
| **Celkem** | scénáře ≈ 9 % · požadavky 65 % · komponenty 40 % · infrastruktura 75 % | **≈ 47 %** |
