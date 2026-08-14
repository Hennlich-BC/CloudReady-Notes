# Organizace REST API infrastruktury

## Úlohy vhodné pro delegování do vlastního REST API

„Vlastní REST API“ zde znamená samostatně spravovanou službu dostupnou z Business Central SaaS přes HTTPS. V BC mají zůstat obchodní pravidla, příprava dat a uložení výsledku; službě je vhodné předat pouze technické operace, které AL nepodporuje nebo je provádí neefektivně.

| Úloha | Vhodnost | Co delegovat REST API |
|---|---|---|
| Slučování PDF | Vysoká | Převzít několik PDF jako multipart/base64 nebo přes dočasné zabezpečené URL, sloučit je a vrátit výsledný PDF. Služba může také vyplňovat šablony a extrahovat stránky či přílohy. |
| PDF Template Management | Vysoká | Nahradit PDFTK/Aspose: aplikaci šablon, vyplnění polí, razítka, konverzi a další PDF operace. Šablony lze držet v BC a posílat s požadavkem nebo verzovat ve službě. |
| Čárové kódy | Vysoká | Generovat PNG/SVG/PDF podle typu kódu a hodnoty. Nejdříve ověřit standardní barcode provider/font BC; REST API použít pro nepodporované formáty nebo složité štítky. |
| PDF štítky a serverové tiskárny | Vysoká | Přijmout dokument a identifikátor tiskárny, vložit úlohu do fronty lokálního print agenta a vrátit ID/stav tisku. Bez agenta instalovaného v lokální síti samotné REST API tisknout nemůže. |
| FTP/SFTP a SafeQueFile | Vysoká | Zajistit přenos souborů, polling adresářů/front, opakování, deduplikaci a archivaci. BC komunikuje pouze přes HTTPS API a dostává stabilní identifikátor operace. |
| SQL management a HPL skladové zásoby | Vysoká | Izolovat přístup k SQL/HPL: API provede povolené parametrizované dotazy a vrátí typovaný JSON. BC nesmí dostat univerzální endpoint pro libovolné SQL. |
| FinStat | Střední/vysoká | Vytvořit adaptér pro FinStat, centralizovat credentials, retry/cache a převod odpovědi na stabilní interní kontrakt. Pokud FinStat nabízí vhodné REST API, může jej BC volat přímo. |
| Přepravci | Střední/vysoká | Vytvořit jednotný gateway pro GLS/DPD/GEIS/TNT/FedEx: autentizace, převod formátů, SOAP/REST, získání štítku, retry a technický log. Obchodní volbu přepravce a data zásilky ponechat v BC. |
| EDI, SKF, Škoda Auto a Eračun | Střední/vysoká | Delegovat transport, podpis/šifrování, AS2/SFTP, validaci XSD a transformaci externích formátů. Tvorba a účtování obchodních dokladů musí zůstat v BC. |
| NCH | Střední | Přesunout souborovou/síťovou výměnu a případnou transformaci formátu. Celní obchodní kontroly a tvorbu záznamů ponechat v BC. |
| Obrázky na čtečkách | Střední | Delegovat resize, rotation, konverzi, OCR a dočasné uložení velkých souborů. Běžný upload a uložení Media/BLOB může provádět přímo BC. |
| WebService Management | Nízká/střední | Vlastní API je vhodné jako gateway při složité autentizaci, uzavřené síti nebo stabilizaci kontraktu starého SOAP systému. Běžný veřejný REST/SOAP endpoint má BC volat přímo přes AL `HttpClient`. |
| Obecné export/XML functions, Excel Buffer, Mail Record, cestovní zprávy, stránky Assembly/E-ShopData, Develop Import, Export Segment, Complete BOM XML | Nízká | Jde převážně o BC logiku a standardní práci AL se stream/XML/Excel/BLOB. Celé řešení nepřesouvat do REST API; službu použít jen pro externí transport, SQL, náročnou konverzi nebo nepodporovaný formát. |

### Společné požadavky na REST API

- HTTPS a autentizace pomocí OAuth 2.0 client credentials, managed identity nebo krátkodobých tokenů; tajné údaje neukládat do AL kódu.
- Idempotence pro tisk, EDI a přenosy souborů: BC posílá unikátní operation ID a opakovaný požadavek nevytvoří duplicitu.
- Asynchronní model (`202 Accepted` + status endpoint) pro tisk, velké PDF, FTP/SFTP a dlouhé SQL reporty.
- Limity velikosti, timeout, retry s backoff, correlation ID a log bez osobních údajů a tajných hodnot.
- Verzovaný kontrakt (`/api/v1/...`), strojově čitelné chybové kódy a health endpoint.
- Pro každý API scénář připravit AL client codeunit, setup table/page, permissions a integrační testy.

## Doporučený stack REST API a Docker Compose

Hlavní doporučenou variantou jsou Linux containers. Všechny závislé komponenty REST API běží lokálně na serveru zákazníka v jednom Docker Compose. Windows může zůstat hostitelským operačním systémem, pokud Docker používá Linux backend přes WSL2 nebo Hyper-V.

### Potřeba interního Linux serveru

Pro production se doporučuje samostatný interní Linux server nebo Linux VM. Docker Compose se nemá provozovat přímo na Windows serveru Business Central pomocí Docker Desktop/WSL2, protože to komplikuje správu, aktualizace a oddělení zdrojů. Server zůstává uvnitř infrastruktury zákazníka a nemusí být publikován do internetu.

Na Linux serveru poběží:

- Docker Engine a Docker Compose;
- FastAPI a background workery jako samostatné Docker kontejnery;
- Typst a nástroje pro zpracování PDF;
- RabbitMQ, PostgreSQL a podle potřeby Redis/MinIO;
- reverse proxy, monitoring a technické logy;
- trvalé volumes a jejich zálohování.

Business Central On-Prem na Windows volá interní DNS jméno API přes HTTPS, například `https://bc-api.company.local`. Mezi servery stačí povolit HTTPS port API; administrační porty PostgreSQL, RabbitMQ, MinIO a Dockeru se nemají publikovat. Odchozí internetový přístup Linux serveru se povolí pouze pro potřebná API přepravců, FinStat, EDI a repozitáře aktualizací.

Linux server musí mít statickou IP/DNS, důvěryhodný TLS certifikát, synchronizaci času, řízené aktualizace, monitoring volného místa a backup volumes/databáze. Jeho zdroje mají být odděleny od SQL Serveru a Business Central Service Tier, aby zpracování PDF nebo hromadný přenos souborů neovlivňovaly provoz BC.

Pro první odhad postačí 4 CPU, 8 GB RAM a samostatný disk od 100 GB; konečná velikost závisí na objemu PDF, počtu paralelních workerů a době uchování souborů. Pro production je vhodná Linux VM s podporovanou LTS distribucí, například Ubuntu Server LTS nebo Debian stable.

### Komponenty

FastAPI a všechny přímo související služby jsou provozovány v Docker kontejnerech a spravovány společným souborem Docker Compose. Každá služba (`reverse-proxy`, `api`, workery, scheduler, RabbitMQ, PostgreSQL a volitelně Redis, MinIO a observability) běží ve vlastním kontejneru v privátní Docker network. Na Linux hostu se tyto aplikační služby neinstalují přímo. Navenek se publikuje pouze HTTPS port kontejneru `reverse-proxy`; interní port FastAPI a porty ostatních služeb zůstávají dostupné jen mezi kontejnery. Trvalá data jsou uložena v pojmenovaných Docker volumes, takže nejsou svázána s životním cyklem jednotlivých kontejnerů.

| Služba | Technologie | Účel |
|---|---|---|
| reverse-proxy | Nginx nebo Traefik | TLS, směrování a limity požadavků |
| api | Python 3.13, FastAPI, Uvicorn, Pydantic | REST/OpenAPI kontrakt pro BC, autentizace a operace |
| worker-documents | Celery, Typst, pikepdf | Tvorba a zpracování PDF |
| worker-integrations | Celery, HTTPX, lxml, Paramiko | Přepravci, FinStat, EDI, REST/SOAP a SFTP/FTP |
| scheduler | Celery Beat | Pravidelné úlohy, polling a čištění |
| rabbitmq | RabbitMQ | Spolehlivá fronta úloh |
| postgres | PostgreSQL, SQLAlchemy, Alembic | Operace, stavy, nastavení, idempotence a audit |
| redis | Redis, volitelně | Cache tokenů, rate limiting a krátké zámky |
| minio | MinIO, volitelně | Lokální S3-kompatibilní úložiště dokumentů |
| observability | OpenTelemetry, volitelně Prometheus/Grafana | Metriky, traces a diagnostika |

### Typst a PDF

- Typst je hlavní engine pro generování nových PDF, tiskových sestav a štítků.
- Šablona přijímá JSON; šablony, fonty a assets jsou verzované.
- Typst běží v samostatném worker kontejneru s limity CPU, paměti, času a velikosti vstupu.
- pikepdf slouží ke slučování, dělení a změně pořadí stran existujících PDF.
- Výsledek se uloží do Docker volume nebo MinIO a vrátí do BC jako stream nebo přes krátkodobý zabezpečený odkaz.

### Minimální první verze

~~~text
reverse-proxy
api
worker-documents
rabbitmq
postgres
~~~

Dokumenty a Typst šablony lze nejprve uložit do pojmenovaných volumes. MinIO, Redis, integration worker a observability se doplní podle potřeby.

~~~yaml
volumes:
  postgres_data:
  rabbitmq_data:
  document_data:
  typst_templates:
~~~

Volumes musí směřovat do samostatného datového adresáře mimo Business Central. Production vyžaduje backup, healthchecks, pevné verze images, řízené aktualizace a rotaci logů.

### Síťové schéma

~~~text
Business Central On-Prem
          │ HTTPS
          ▼
     reverse-proxy
          │
          ▼
        FastAPI ───── PostgreSQL
          │
          ▼
       RabbitMQ
          │
          ├── Typst/PDF worker
          └── integration worker ── přepravci / FinStat / EDI / SFTP
~~~

Navenek se publikuje pouze HTTPS port reverse proxy. PostgreSQL, RabbitMQ, Redis a MinIO zůstávají v interní Docker network.

### Tisk

Linux container nemá přímo ovládat Windows Print Spooler. Pro Windows tiskárny se použije Print Agent jako samostatná Windows služba na hostu nebo print serveru. Pokud jsou tiskárny dostupné přes IPP/CUPS, lze print service provozovat v Compose.

## Obtíže implementace pomocí Windows containers

Pokud jsou Linux containers, WSL2 a Linux VM zakázány, musí Compose používat skutečný režim Windows containers. Pro vlastní Python služby je to možné, ale infrastruktura je výrazně složitější:

- oficiální images PostgreSQL, RabbitMQ, Redis, MinIO, Nginx a Typst jsou převážně určeny pro Linux; jsou nutné náhrady, instalace mimo Compose nebo vlastní Windows images;
- Windows Server Core images jsou výrazně větší a verze základního image musí odpovídat Windows hostu;
- existuje méně hotových images, příkladů, healthchecks a diagnostických nástrojů;
- aktualizace OS a základních images je složitější a restart kontejnerů obvykle delší;
- ACL, bind mounts, certifikáty a service accounts vyžadují konfiguraci specifickou pro Windows;
- přímý přístup kontejneru k hostitelskému Print Spooleru zůstává nespolehlivý a nenahrazuje Print Agent;
- Typst se musí instalovat z Windows binary do vlastního image a zvlášť se musí ověřit fonty a rendering;
- Python balíčky s native dependencies musí mít kompatibilní Windows wheels nebo vyžadují build toolchain.

Možný Windows-only kompromis:

- FastAPI, Typst worker a integration worker jako vlastní Windows Server Core containers;
- IIS/ARR jako reverse proxy na Windows hostu;
- SQL Server se samostatnou databází operací mimo Compose;
- tabulka operations v SQL Serveru jako fronta místo RabbitMQ/Celery;
- Windows volumes místo MinIO;
- Windows Print Agent jako samostatná služba.

Tato varianta je použitelná pro jeden server a střední zátěž, ale hůře se přenáší a škáluje. Linux containers proto zůstávají doporučeným řešením, i když fyzický host používá Windows.
