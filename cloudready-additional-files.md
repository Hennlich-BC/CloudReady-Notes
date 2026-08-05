# Дополнительные файлы для Cloud Ready-миграции

Проверены остальные AL-файлы проектов:

- W1: найдено 67 потенциальных кандидатов.
- CZ/SK: найдено 2 дополнительных кандидата.
- PL: аналогичных проблем не найдено.
- `.install`: AL-объектов для такой миграции нет.

После исключения ложных совпадений с уже корректным `HttpClient` отобраны следующие файлы.

## Приоритет 1 — общие библиотеки

| Файл | Основные изменения |
|---|---|
| `XMLFunctions.Codeunit.al` | Удаление server file, переход на `XmlDocument`, `InStream`/`OutStream` |
| `HCZFunctions.Codeunit.al` | DotNet reflection/stack trace, server temp files |
| `PDFManagement.Codeunit.al` | DotNet PDF extraction/merge, `MemoryStream` |
| `PDFTemplateMgt.Codeunit.al` | Внешние процессы, PDFTK, server files |
| `DocumentPublishing.Codeunit.al` | Массовое использование временных серверных PDF-файлов |
| `ServerPrinterSelection.Table.al` | Запуск внешних процессов через DotNet |
| `BarcodeManagement.Codeunit.al` | DotNet ZXing, Bitmap и ImageFormat |
| `CompleteBOMManagement.Codeunit.al` | OnPrem SQL-зависимости, связанные с BOM import |
| `HINTColorMgt.Codeunit.al` | DotNet `Color` |
| `Typo3DataProcess.Codeunit.al` | DotNet Image/Bitmap и сохранение изображений |

## Приоритет 2 — активные экспорты и интеграции

| Проект | Файл | Основные изменения |
|---|---|---|
| W1 | `UpdateGLSPostCodeRouteshcz.Report.al` | `HttpWebRequest` → `HttpClient`, DotNet JSON → `JsonObject`/`JsonArray` |
| W1 | `FedExManagement.Codeunit.al` | Server file logging и временные PDF-файлы |
| W1 | `FinStatRequest.Codeunit.al` | DotNet FinStat client → HTTP/JSON API |
| CZ/SK | `RegistrationEventMgmnt.Codeunit.al` | DotNet FinStat client и response types |
| W1 | `ExportPurchaseOrderGMORS.Codeunit.al` | Оставшиеся DotNet XML и server file-блоки |
| W1 | `ExportPurchaseOrderDMH.Codeunit.al` | Оставшиеся DotNet XML и server file-блоки |
| W1 | `ExportSalesShipmentEDI.Codeunit.al` | Удаление `TODO_ONPREM`, запись XML непосредственно в stream |
| W1 | `ExportHallitePuchOrder.Codeunit.al` | Server temp XML/PDF и BLOB import |
| W1 | `ExportIGUSPuchOrder.Codeunit.al` | Server temp CSV и BLOB import |
| CZ/SK | `PaymentAdviceManagement.Codeunit.al` | Server temp PDF/XLSX и BLOB import |
| W1 | `SMActionSendandPubCI.Codeunit.al` | `Report.SaveAs*` в server file, публикация и вложения |

## Приоритет 3 — публикация, импорт и файловые операции

| Файл | Основные изменения |
|---|---|
| `PDFTemplate.Table.al` | Server file API |
| `TNNoticeData.Table.al` | Несколько OnPrem-only блоков |
| `EShopDataContent.Page.al` | Server file upload/delete |
| `ImpContactsToSegmExcel.Report.al` | OnPrem Excel-обработка |
| `ImportTeaserItemcategory.Report.al` | Excel/DotNet-зависимый импорт |
| `ProcessMailRecord.Codeunit.al` | Server files и вложения |
| `TravelNoticeExtEditMgt.Codeunit.al` | Server file operations |
| `TravelNoticeAttachmtMgt.Codeunit.al` | OnPrem attachments |
| `SMActionPublishCI.Codeunit.al` | Server file publication |
| `PublishIncomingDocumsUNI.Codeunit.al` | Server file publication |
| `PublishIncomingDocuments.Codeunit.al` | Server file publication |
| `ProcessPublishPurchOrder.Codeunit.al` | Server file publication |
| `PublishFiletoSPandPWR.Codeunit.al` | OnPrem SharePoint/file operations |
| `PublishPostedWhseRcpts.Codeunit.al` | Server file publication |
| `ProcessNCHCustoms.Codeunit.al` | Server file import/export |
| `IGUSOrderExport.Report.al` | Server file export |
| `SendDelayedPurchaseshcz.Report.al` | OnPrem report/file generation |
| `WMSMPictures.Page.al` | Server-side picture files |

## Приоритет 4 — требуется архитектурное решение

Эти файлы нельзя безопасно исправить простой заменой DotNet-типа:

| Файл | Причина |
|---|---|
| `SQLManagement.Codeunit.al` | Прямой ADO.NET/SQL-доступ; для SaaS нужен API, Azure Function или другой внешний сервис |
| `CentralDatabaseSQLMgt.Codeunit.al` | Зависит от прямого SQL-доступа |
| `CallStack.Codeunit.al` | DotNet reflection и `StackTrace` |
| `CentralDataDelaySynchAgent.Codeunit.al` | DotNet timer и event trigger |
| `AttributeSearchCondition.Table.al` | DotNet-связанная логика требует отдельной проверки |
| `ServerPrinterSelection.Table.al` | Облачный сервер не может запускать локальные процессы печати |
| `PDFTemplateMgt.Codeunit.al` | PDFTK и внешние executable недоступны в SaaS |

## DotNet declaration-файлы

После миграции потребителей нужно проверить возможность удаления следующих файлов:

- `System.Dotnet.al`
- `Microsoft.Dotnet.al`
- `ZXing.Dotnet.al`
- `AsposePDF.Dotnet.al`
- `FinStat.Dotnet.al`
- `DocumentFormat.Dotnet.al`

## Критерии исключения

В список не включены файлы, где поиск нашёл только уже встроенные AL-типы `HttpClient`, `HttpRequestMessage`, `DownloadFromStream` или `UploadIntoStream`: само их наличие не означает необходимость Cloud Ready-исправления.
