# Сопоставление списка Aricoma с кодом проекта

Источник: `aricoma.md`. Анализ выполнен по проектам `w1` и, для раздела SK, `../czsk`. Перечни файлов ориентировочные: динамические вызовы через настройки экспорта/spooler и объекты зависимых приложений невозможно полностью определить статическим поиском.

## Cloud Ready W1

| Пункт | Что требуется изменить | Вероятно затронутые файлы |
|---|---|---|
| Около 570 задач; HelpDesk по объектам | Это организационные пункты, а не отдельное изменение кода. Для каждого объекта ниже создать отдельную задачу с владельцем, сценарием проверки и критерием Cloud Ready. | `aricoma.md`, при необходимости проектная документация |
| Тип «export» | Сначала мигрировать и проверить один простой экспорт: убрать DotNet XML и серверные пути, перейти на `XmlDocument`, `Temp Blob`, streams и скачивание/передачу содержимого. Затем применить шаблон к остальным экспортам. | `src/Codeunit/DocumentExportManagement.Codeunit.al`, `ExportWaltherPuchOrder.Codeunit.al`, `ExportSalesOrderEDIConfirm.Codeunit.al`, `ExportPostSalesInvoiceEDI.Codeunit.al`, `ExportPurchaseOrderGMORS.Codeunit.al`, `ExportPurchaseOrderDMH.Codeunit.al`, `ExportSalesShipmentEDI.Codeunit.al` |
| Перевозчики | Обновить интеграции под новые API перевозчиков: заменить DotNet HTTP/XML и серверные временные файлы на `HttpClient`, AL XML/JSON и streams; отдельно проверить авторизацию, SOAP Fault, печать и логирование. | `src/Codeunit/GLSManagement.Codeunit.al`, `DPDManagement.Codeunit.al`, `GEISManagement.Codeunit.al`, `TNTManagement.Codeunit.al`, `FedExManagement.Codeunit.al`, `ParcelsManagement.Codeunit.al`, `src/Report/UpdateGLSPostCodeRouteshcz.Report.al` |
| Штрихкоды | Убрать ZXing/.NET (`Bitmap`, `ImageFormat`). Генерацию перенести в SaaS-совместимый сервис/API либо использовать встроенный barcode font/provider; отчёты перевести на получаемый stream/Media. | `src/Codeunit/BarcodeManagement.Codeunit.al`, `src/Dotnet/ZXing.Dotnet.al`, отчёты `src/Report/*BarCode*.al` и их layouts |
| Объединение PDF | Заменить Aspose/.NET и `MemoryStream` на внешний HTTP-сервис/Azure Function или поддерживаемый SaaS-компонент; вход и результат передавать streams/BLOB. | `src/Codeunit/PDFManagement.Codeunit.al`, `src/Dotnet/AsposePDF.Dotnet.al`, `src/Codeunit/DocumentPublishing.Codeunit.al` |
| PDF-этикетки перевозчиков | Убрать сохранение и печать PDF на сервере BC. Передавать PDF в IIS/print service по HTTP, хранить настройки endpoint/printer и обрабатывать ответ сервиса. | `src/Codeunit/GLSManagement.Codeunit.al`, `DPDManagement.Codeunit.al`, `GEISManagement.Codeunit.al`, `TNTManagement.Codeunit.al`, `FedExManagement.Codeunit.al`, `src/Table/ServerPrinterSelection.Table.al` |
| FTP | Прямой FTP-клиент в `w1` не найден. Уточнить с Aptive направления и форматы; реализовать через их API/SFTP gateway или промежуточный сервис, поскольку локальные каталоги и произвольный FTP в SaaS непригодны. | После уточнения — обработчики `INBuffer/OUTBuffer`, вероятно `src/Codeunit/SendOUTHIS.Codeunit.al`, `SendOUTWSSpooler.Codeunit.al` и EDI-processors |
| FinStat HSK | Проверить наличие готового решения у Aricoma. Текущий .NET-клиент заменить на HTTP/JSON API, секреты вынести в защищённую настройку; удалить FinStat DotNet declaration после миграции. | `src/Codeunit/FinStatRequest.Codeunit.al`, `src/Table/FinStatData.Table.al`, `src/Report/FinStat*.al`, `src/Dotnet/FinStat.Dotnet.al` |
| HCZ functions | Разделить общие функции: файловые операции заменить streams/`Temp Blob`, reflection/stack trace убрать либо заменить AL telemetry/error context. | `src/Codeunit/HCZFunctions.Codeunit.al`, `src/Codeunit/CallStack.Codeunit.al` |
| Hint Colour Management | Заменить `System.Drawing.Color` на собственное хранение/разбор RGB/HEX средствами AL; сверить реализацию с MasterTemplate. | `src/Codeunit/HINTColorMgt.Codeunit.al`, `src/Dotnet/System.Dotnet.al` |
| WebService Management | Перенести реализацию из актуального MasterTemplate: DotNet web request заменить `HttpClient`, добавить status/error handling и streams. | `src/Codeunit/NAVWebServiceMgmt.Codeunit.al`; также проверить `EDIWebService.Codeunit.al`, `PWImportWebService.Codeunit.al` |
| PDF Template Management | Внешний `PDFTK`, процессы и серверные пути недоступны в SaaS. Вынести обработку шаблонов в HTTP PDF-service и хранить файлы в BLOB/Media; страницы оставить интерфейсом настройки. | `src/Codeunit/PDFTemplateMgt.Codeunit.al`, `PDFTemplateManualSubscriber.Codeunit.al`, `src/Table/PDFTemplate.Table.al`, `ReportPDFTemplate.Table.al`, `src/Page/PDFTemplates.Page.al`, `ReportPDFTemplates.Page.al` |
| EDI | Перевести DotNet XML и server-file обмен на AL XML + streams/HTTP; проверить входящие spooler-процессы, namespace и вложения. | `src/Codeunit/ProcessEDI.Codeunit.al`, `ImportEDIORDRSPfromspooler.Codeunit.al`, `Export*EDI*.Codeunit.al`, `EDIWebService.Codeunit.al`, `src/XmlPort/EDILECHLERORDRSP.XmlPort.al` |
| Mail Record | Вложения и публикуемые документы больше не сохранять во временные серверные файлы; использовать `Temp Blob`, Document Attachment/Media и stream-based email API. | `src/Codeunit/ProcessMailRecord.Codeunit.al`, `MailRecordSMMgt.Codeunit.al`, `MailRecordPubManagement.Codeunit.al`, `IPMailRecordManagement.Codeunit.al`, страницы/расширения `*MailRecord*` |
| NCH | Заменить файловый import/export на upload/download streams или API; проверить генерацию складского файла и таможенный обмен. | `src/Codeunit/ProcessNCHCustoms.Codeunit.al`, `ProcessNCHOrders.Codeunit.al`, `src/Report/ExportNCHOrders.Report.al`, `NCHItemInventoryhcz.Report.al` |
| SKF | Мигрировать XML import/export заказа, подтверждения и DESADV с DotNet XML/server files на AL XML и streams; проверить namespace на реальных сообщениях. | `src/Codeunit/ExportPurchaseOrderSKF.Codeunit.al`, `ProcessSKFOrderConf.Codeunit.al`, `ProcessSKFDESADV.Codeunit.al` |
| SQL management / отчёты | Прямой ADO.NET-доступ в SaaS невозможен. Вынести запросы в API/Azure Function или перенести расчёты на BC Query/API; заменить connection string настройкой endpoint. | `src/Codeunit/SQLManagement.Codeunit.al`, `CentralDatabaseSQLMgt.Codeunit.al`; потребляющие отчёты определить по каждому SQL-методу |
| Командировки / вложения | Перевести вложения и редактирование с серверных файлов на BLOB/Media/Document Attachment и upload/download streams. | `src/Codeunit/TravelNoticeExtEditMgt.Codeunit.al`, `TravelNoticeAttachmtMgt.Codeunit.al`, `src/Table/TNNoticeData.Table.al`, страницы `src/Page/*TravelNotice*.al` |
| SafeQueFile | Объект/термин с таким именем в исходниках не найден. Нужны номер объекта или пользовательский сценарий; затем проверить локальную очередь/файлы и заменить их облачной очередью/API или таблицей BC. | Не определены до уточнения |
| XML functions | Взять вариант из MasterTemplate: заменить DotNet XML на встроенные `XmlDocument/XmlNode`, работу с путями — на `InStream/OutStream` и `Temp Blob`. | `src/Codeunit/XMLFunctions.Codeunit.al`, после миграции — `src/Dotnet/System.Dotnet.al` |
| DotNet (общий пункт) | После предметных миграций повторно просканировать все объявления/использования DotNet, убрать `target: OnPrem` и зависимость `Productivity Pack OnPrem`, собрать с Cloud target. | `src/Dotnet/*.al`, все файлы с `DotNet`/`Scope('OnPrem')`, `app.json` |
| Page: монтажные заказы | В `DoableAssemblyOrders` найден DotNet; заменить его и проверить все действия страницы в web client. Остальные монтажные/демонтажные страницы требуют функционального smoke-test, но сами по себе не являются Cloud-блокером. | `src/Page/DoableAssemblyOrders.Page.al`, `src/PageExt/Assembly*.PageExt.al`, связанные `src/TableExt/Assembly*.al` и `src/Codeunit/Disassembly*.al` |
| Page: E-ShopData | Заменить server-side upload/delete на streams и BLOB/Media; проверить import/export и HTML content в web client. | `src/Page/EShopDataContent.Page.al`, `EShopDataCard.Page.al`, `EShopDataList.Page.al`, `src/Table/EShopData.Table.al`, `src/Report/ImportEShopData.Report.al`, `ExportEshopData.Report.al` |
| Изображения на сканерах | Убрать чтение изображений из серверных путей и DotNet; хранить/получать изображения как Media/BLOB streams, проверить работу control add-in на мобильном клиенте. | `src/Page/WMSMPictures.Page.al`, `WMSMInventory.Page.al`, `WMSMPickPutawayBasket.Page.al`, `src/Table/WMSMPicture.Table.al`, `src/Enum/WMSMPictureType.Enum.al` |
| Develop Import | Переписать DotNet/локальный файловый импорт на `UploadIntoStream`, AL XML/CSV/Excel Buffer; проверить кодировку и транзакционность. | `src/Report/DEVELOPImport.Report.al`, возможно `src/Codeunit/ItemImport.Codeunit.al` |
| Export Segment | Сам XMLport не содержит найденного DotNet; проверить место запуска и заменить server-file destination на stream/download, если он задаётся вызывающим кодом. | `src/XmlPort/ExportSegmentContact.XmlPort.al`, `src/TableExt/SegmentLinehcz.TableExt.al` |
| Полные спецификации для Engineering | XML-import перевести на AL XML/streams; прямой SQL в management/report заменить API или staging-таблицами BC. | `src/Codeunit/CompleteBOMManagement.Codeunit.al`, `src/Report/ImportCompleteBOMXMLhcz.Report.al`, `ImportCompleteBOMSQL.Report.al`, `src/XmlPort/ImportCompleteBOM*.XmlPort.al`, таблицы/страницы `CompleteBOM*` |
| Excel buffer | Заменить `DocumentFormat.OpenXml` и OnPrem-участки стандартным `Excel Buffer`/stream API. Затем проверить все отчёты-потребители и удалить DotNet declaration, если больше не нужен. | `src/Table/ExcelBuffer.Table.al`, `src/Dotnet/DocumentFormat.Dotnet.al`, отчёты, ссылающиеся на `ExcelBuffer_hcz` |
| HPL складские остатки | В настройке найден connection string, что указывает на прямую внешнюю связь. Заменить её endpoint/API-настройкой и получать остатки через `HttpClient`; уточнить формат и владельца HPL API. | `src/TableExt/InventorySetup.TableExt.al`, `src/PageExt/InventorySetup.PageExt.al`; вызывающий HPL-код найти после уточнения интерфейса |
| Серверные принтеры | Запуск локального процесса/печати из SaaS невозможен. Использовать Universal Print, облачный print service или локальный агент с HTTP/queue API. | `src/Table/ServerPrinterSelection.Table.al`, `src/Page/ServerPrinterSelections.Page.al`, `src/Report/WhseShptCustLblLocPrinterhcz.Report.al` |
| Eračun | Найдено формирование `MojEracunInvoice`; проверить, что XML создаётся и отдаётся stream-based, без server file/DotNet, и выполнить интеграционный тест со словенским сервисом. | `src/XmlPort/SalesInvoiceEUNormaPDVEN.XmlPort.al` и вызывающий export codeunit (определяется настройками экспорта) |

## Cloud Ready SK (`../czsk`)

| Пункт | Что требуется изменить | Вероятно затронутые файлы |
|---|---|---|
| FinStat | Заменить FinStat .NET client/response types на HTTP/JSON и защищённые настройки API; желательно переиспользовать решение W1. | `../czsk/src/codeunits/RegistrationEventMgmnt.Codeunit.al`; общие `w1/src/Codeunit/FinStatRequest.Codeunit.al`, `w1/src/Dotnet/FinStat.Dotnet.al` |
| Škoda Auto: экспорт счетов и кредит-нот | Заменить DotNet XML/server file на AL XML и streams; два почти одинаковых экспорта привести к общему helper и проверить реальные XSD/приём. | `../czsk/src/codeunits/SKODAAutoInvXMLexport.Codeunit.al`, `SKODAAutoCrmXMLExport.Codeunit.al` |
| HSK Intrastat | Убрать файловый/DotNet XML-вывод, формировать XML в stream и отдавать через download/API; проверить namespace и действие Export. | `../czsk/src/report/SKIntrastatExporthcz.Report.al`, `../czsk/src/pageext/w1/IntrastatReport.PageExt.al` |

## Productivity Pack

В `app.json` W1 одновременно указаны зависимости `Productivity Pack` и `Productivity Pack OnPrem`, а target установлен в `OnPrem`. Нужно получить Cloud Ready-версию основного Productivity Pack от Aricoma, удалить/заменить OnPrem-зависимость и только после миграции потребителей переключить приложение на Cloud target. Затрагивается как минимум `app.json`; точный список AL-файлов определяется компиляцией без OnPrem-пакета.

## Задачи, которые можно делегировать собственному REST API

Под «собственным REST API» здесь понимается отдельный управляемый сервис, доступный Business Central SaaS по HTTPS. В BC должны остаться бизнес-правила, подготовка данных и сохранение результата, а сервису следует передавать только технические операции, недоступные или неудобные в AL.

| Задача | Пригодность | Что делегировать REST API |
|---|---|---|
| Объединение PDF | Высокая | Принимать несколько PDF как multipart/base64 или по временным защищённым URL, объединять их и возвращать итоговый PDF. При необходимости сервис также может заполнять шаблоны и извлекать страницы/вложения. |
| PDF Template Management | Высокая | Заменить PDFTK/Aspose: наложение шаблонов, заполнение полей, штампы, конвертацию и другие операции с PDF. Шаблоны можно хранить в BC и передавать сервису на время запроса либо версионировать в сервисе. |
| Штрихкоды | Высокая | Генерировать PNG/SVG/PDF по типу кода и значению. Для обычных штрихкодов сначала стоит проверить стандартный barcode provider/font BC — REST API нужен только для неподдерживаемых форматов или сложных этикеток. |
| PDF-этикетки и серверные принтеры | Высокая | Принимать документ и идентификатор принтера, помещать задание в очередь локального print agent и возвращать ID/статус печати. Сам REST API не сможет печатать в локальной сети без установленного там агента. |
| FTP/SFTP и SafeQueFile | Высокая | Выполнять передачу файлов, polling каталогов/очередей, повторные попытки, дедупликацию и архивирование. BC взаимодействует только с HTTPS API и получает стабильный идентификатор операции. |
| SQL management и HPL складские остатки | Высокая | Изолировать доступ к SQL/HPL: API выполняет разрешённые параметризованные запросы и возвращает типизированный JSON. Нельзя предоставлять BC универсальный endpoint для произвольного SQL. |
| FinStat | Средняя/высокая | Сделать адаптер к FinStat, централизовать API credentials, retry/cache и преобразование ответа в стабильный внутренний контракт. Если FinStat уже предоставляет совместимый REST API, BC может вызывать его напрямую без дополнительного сервиса. |
| Перевозчики | Средняя/высокая | Создать единый gateway для GLS/DPD/GEIS/TNT/FedEx: авторизация, преобразование форматов, SOAP/REST, получение этикетки, retry и журнал технических запросов. Бизнес-выбор перевозчика и данные посылки оставить в BC. |
| EDI, SKF, Škoda Auto и Eračun | Средняя/высокая | Делегировать транспорт, подпись/шифрование, AS2/SFTP, валидацию XSD и преобразование внешних форматов. Формирование и проведение бизнес-документов должно остаться в BC. |
| NCH | Средняя | Вынести файловый/сетевой обмен и при необходимости преобразование формата. Таможенные бизнес-проверки и создание записей оставить в BC. |
| Изображения на сканерах | Средняя | Делегировать resize, rotation, конвертацию, OCR и временное хранение больших файлов. Обычная загрузка и хранение Media/BLOB могут выполняться непосредственно в BC. |
| WebService Management | Низкая/средняя | Собственный API оправдан как gateway при сложной аутентификации, закрытой сети или необходимости стабилизировать контракт старого SOAP-сервиса. Обычный публичный REST/SOAP endpoint лучше вызывать напрямую через AL `HttpClient`. |
| Общие export/XML functions, Excel Buffer, Mail Record, командировки, страницы Assembly/E-ShopData, Develop Import, Export Segment, Complete BOM XML | Низкая | Эти задачи в основном состоят из логики BC и стандартных операций AL со stream/XML/Excel/BLOB. Выносить их целиком в REST API не следует; сервис нужен только для конкретного внешнего транспорта, SQL, тяжёлой конвертации или неподдерживаемого формата. |

### Общие требования к REST API

- HTTPS и аутентификация через OAuth 2.0 client credentials, managed identity или короткоживущие токены; секреты не хранить в AL-коде.
- Идемпотентность для печати, EDI и файлового обмена: BC передаёт уникальный operation ID, повторный запрос не создаёт дубль.
- Асинхронная модель (`202 Accepted` + status endpoint) для печати, больших PDF, FTP/SFTP и долгих SQL-отчётов.
- Ограничения размера, timeout, retry с backoff, correlation ID и журнал без персональных данных/секретов.
- Версионированный контракт (`/api/v1/...`), машинно-читаемые коды ошибок и health endpoint.
- Для каждого API-сценария предусмотреть AL client codeunit, setup table/page, permissions и интеграционные тесты.

## Рекомендуемый стек REST API и Docker Compose

Все зависимые компоненты REST API предлагается запускать локально на сервере заказчика в одном Docker Compose. Business Central On-Prem обращается к API только по HTTPS; внутренние сервисы доступны друг другу через закрытую Docker network и не должны публиковать порты наружу без необходимости.

### Компоненты

| Сервис | Технология | Назначение |
|---|---|---|
| `reverse-proxy` | Nginx или Traefik | TLS termination, маршрутизация, ограничения размера запроса и rate limiting |
| `api` | Python 3.13, FastAPI, Uvicorn, Pydantic | REST/OpenAPI-контракт для Business Central, аутентификация и регистрация операций |
| `worker-documents` | Celery, Typst | Асинхронное создание PDF из Typst-шаблонов, данных JSON, изображений и шрифтов |
| `worker-integrations` | Celery, HTTPX, lxml, Paramiko | Перевозчики, FinStat, EDI/XML, REST/SOAP и SFTP/FTP |
| `scheduler` | Celery Beat | Периодический polling FTP/SFTP, повторные проверки и очистка временных данных |
| `rabbitmq` | RabbitMQ | Надёжная очередь заданий между API и workers |
| `postgres` | PostgreSQL, SQLAlchemy, Alembic | Операции, статусы, конфигурация, идемпотентность и технический аудит |
| `redis` | Redis, опционально | Кэш токенов, rate limiting, короткие блокировки и временные результаты |
| `minio` | MinIO, опционально | S3-совместимое локальное хранилище шаблонов, PDF, этикеток и входных файлов |
| `observability` | OpenTelemetry; опционально Prometheus/Grafana | Метрики, traces, correlation ID и диагностика |

### Работа с PDF

- Typst является основным движком генерации новых PDF, печатных форм и этикеток.
- Typst-шаблон получает данные из JSON; шаблоны, шрифты и assets должны версионироваться.
- Компиляцию Typst выполнять только в отдельном worker-контейнере с ограничениями CPU, памяти, времени и размера входных данных.
- Для объединения, разделения или перестановки страниц уже существующих PDF дополнительно использовать `pikepdf`; Typst не заменяет редактор произвольных PDF.
- Результат сохранять в локальный Docker volume или MinIO и возвращать BC как stream либо через короткоживущую защищённую ссылку.

### Минимальная первая версия

Для пилота достаточно следующих контейнеров:

```text
reverse-proxy
api
worker-documents
rabbitmq
postgres
```

Документы и Typst-шаблоны можно сначала хранить в именованных Docker volumes. `MinIO`, `Redis`, отдельный integration worker и observability добавляются при появлении соответствующей нагрузки или требований.

Рекомендуемые volumes:

```yaml
volumes:
  postgres_data:
  rabbitmq_data:
  document_data:
  typst_templates:
```

- `postgres_data` — база операций и настроек;
- `rabbitmq_data` — персистентная очередь;
- `document_data` — входные и сформированные документы с автоматической очисткой;
- `typst_templates` — шаблоны, шрифты и изображения.

Volumes должны быть привязаны к отдельному каталогу данных, а не к служебным каталогам Business Central. Для production необходимы резервное копирование PostgreSQL и постоянных файлов, healthchecks, фиксированные версии Docker images, политика обновления и ротация логов.

### Сетевая схема

```text
Business Central On-Prem
          │ HTTPS + OAuth2/API credentials
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
          └── integration worker ── перевозчики / FinStat / EDI / SFTP
```

Наружу следует публиковать только HTTPS-порт reverse proxy. PostgreSQL, RabbitMQ, Redis и MinIO должны оставаться во внутренней Docker network; административные интерфейсы открываются только из доверенной сети.

### Исключение для печати

Если Docker Compose работает на Linux, а принтеры обслуживаются Windows Print Spooler, нужен небольшой Windows Print Agent вне Compose. API передаёт ему документ и идемпотентный operation ID по HTTPS/очереди, агент печатает и возвращает статус. Если принтеры доступны напрямую по IPP/CUPS, print service можно разместить в Compose.
