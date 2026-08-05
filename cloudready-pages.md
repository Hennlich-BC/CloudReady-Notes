# Объекты и страницы, из которых они запускаются

Порядок определён по правилам из `cloudready.md`: сначала общие библиотеки и активные пользовательские сценарии, затем HTTP/XML-интеграции, фоновые spooler-процессы и отключённый код.

Приоритет учитывает:

1. Количество зависимых объектов.
2. Наличие запуска из пользовательской страницы.
3. Возможность повторно использовать полученный шаблон миграции.
4. Объём и сложность DotNet, XML, HTTP и server file-кода.
5. Активность объекта в текущей конфигурации компиляции.

## W1

| Приоритет | Объект | Метод / trigger | Страница, из которой выполняется запуск | Причина приоритета |
|---:|---|---|---|---|
| 1 | Codeunit 75618 `"Document Export Management_hcz"` | `ExportDocument` | `"Posted Sales Shipment"` — action `"Send Shipment"`; `"Purchase Order"` — action `"Send Order"`; `"Sales Order"` — action `"Send Order Confirmation"` | Общий диспетчер экспорта. Его Cloud Ready-реализация нужна до миграции зависимых экспортных codeunits |
| 2 | Table 60033 `ExcelBuffer_hcz` | Различные методы работы с Excel | Прямых вызовов из страниц не найдено. Таблица используется в reports и обрабатывающих codeunits; их запуск зависит от report, spooler или job | Общая библиотека с большим количеством DotNet/OnPrem-блоков и множеством потребителей |
| 3 | Codeunit 70019 `"NAV WebService Mgmt_hcz"` | `GetItemAvailabilityHttp` | Косвенная цепочка: `"Item Card"` или `"Item List"` — action `"Database"` → `Item.ShowRemoteItemAvailability_hcz` → page `"Item Availability by Dtb_hcz"` → `Item.GetRemoteItemAvailability_hcz` → `NAV WebService Mgmt_hcz.GetItemAvailabilityHttp` | Небольшой активный HTTP-сценарий с пользовательским запуском; подходит для ранней проверки шаблона `HttpClient` |
| 4 | Codeunit 75619 `"GLS Management_hcz"` | `PrintLabel`, `DoRun` | `ParcelCard_aci`, `ParcelList_aci`, `ParcelLinesSubform_aci`, `ParcelLines_aci` — action `"Print Label"`. `DoRun` вызывается из report 75724 `"Export GLS Packages_hcz"` | Активная интеграция уже частично переведена на AL XML-типы; её удобно завершить перед более сложными перевозчиками |
| 5 | Codeunit 75622 `"ExportWaltherPuch.Order._hcz"` | `OnRun` | Зависящая от настроек цепочка из `"Purchase Order"` через `"Document Export Management_hcz"`. Прямых ссылок из страниц на этот codeunit не найдено | Небольшой экспорт: приоритетная замена server file и DotNet XML после готовности общего диспетчера |
| 6 | Codeunit 75634 `ExportSalesOrderEDIConfirm_hcz` | `OnRun`; внутри `GenerateXMLFile` / `ExportOrder` | Зависящая от настроек цепочка из `"Sales Order"` через `"Document Export Management_hcz"` | Пользовательский экспорт заказа; XML и server file следует мигрировать раньше фоновых обработчиков |
| 7 | Codeunit 75676 `ExportPostSalesInvoiceEDI_hcz` | `OnRun`; внутри `GenerateXMLFile` / `ExportInvoice` | Прямых ссылок из страниц не найдено. Запускается динамически через `"Record Export Buffer"` и настройки экспорта для `"Sales Invoice Header"` | Тот же шаблон, что у sales order, но объект больше; выполнять после проверки шаблона на предыдущем codeunit |
| 8 | Report 75528 `"Import Complete BOM XML_hcz"` | Выполнение report, начиная с `OnPreReport` | `"Complete BOM List_hcz"` — action `"Import from Solid Edge"` → `Complete BOM Management_hcz.Import` → `Import Complete BOM XML_hcz.Run` | Явный пользовательский импорт; необходимо заменить DotNet XML и проверить загрузку через stream |
| 9 | Codeunit 75652 `"DPD Management_hcz"` | `PrintLabels`, `SendPackage`, SOAP methods | Активная цепочка: `ParcelCard_aci`, `ParcelList_aci`, `ParcelLinesSubform_aci`, `ParcelLines_aci` — action `"Print Label"` → `ParcelsManagement_hcz.PrintLabel` | Активная SOAP-интеграция. Требуется совместная проверка XML, namespace, HTTP, Fault и request/response logging |
| 10 | Codeunit 75651 `"GEIS Management_hcz"` | `PrintLabel`, `SendPackage` | Активная косвенная цепочка из parcel pages через `ParcelsManagement_hcz.PrintLabel` | Большой объём DotNet, server file и XML-кода; выполнять после стабилизации DPD/GLS-шаблонов |
| 11 | Codeunit 75606 `"TNT Management_hcz"` | `GetLabel`, `SendPackage` | Косвенная цепочка из parcel pages через label report. `SendPackage` вызывается из report 75716 `"Export TNT Packages_hcz"` | Крупная HTTP/XML-интеграция с большим количеством DotNet; высокий риск регрессии, нужны интеграционные тесты |
| 12 | Codeunit 75689 `"Send OUT - HIS_hcz"` | `OnRun` | Ссылок из страниц не найдено. Запускается spooler для записи `OUTBuffer_ach` | Небольшой общий HTTP sender; его шаблон можно повторно использовать для остальных spooler-интеграций |
| 13 | Codeunit 75674 `ImportEDIORDRSPfromspooler_hcz` | `OnRun`; внутри `Process` | Ссылок из страниц не найдено. Запускается spooler для записи `INBuffer_ach` | Относительно компактный входящий XML-процессор; использовать как первый шаблон миграции spooler imports |
| 14 | Codeunit 75654 `"Process GMORS ORDRSP_hcz"` | `OnRun`; внутри `Process` | Ссылок из страниц не найдено. Запускается spooler для записи `INBuffer_ach` | Меньший из однотипных ORDRSP/DESADV-процессоров; удобен для закрепления XML parsing pattern |
| 15 | Codeunit 75661 `"Process GMORS DESADV_hcz"` | `OnRun`; внутри `Process` | Ссылок из страниц не найдено. Запускается spooler для записи `INBuffer_ach` | Продолжение GMORS-шаблона после ORDRSP |
| 16 | Codeunit 75617 `"ProcessHalliteOrderConf._hcz"` | `OnRun`; внутри `Process` | Ссылок из страниц не найдено. Запускается spooler для записи `INBuffer_ach` | Аналогичный XML order confirmation; выполнять после базовых spooler-процессоров |
| 17 | Codeunit 75625 `"Process SKF Order Conf._hcz"` | `OnRun`; внутри `Process` | Ссылок из страниц не найдено. Запускается spooler для записи `INBuffer_ach` | XML с namespace; требует применения проверенного namespace-aware шаблона |
| 18 | Codeunit 75585 `"Process SKF DESADV_hcz"` | `OnRun`; внутри `Process` | Ссылок из страниц не найдено. Запускается spooler для записи `INBuffer_ach` | Второй SKF-процессор; выполнять после `Process SKF Order Conf._hcz` с повторным использованием решений |
| 19 | Codeunit 75695 `ImportIGUSInvDE_hcz` | `OnRun`; внутри `PreprocessInBuffer` / `Process` | Ссылок из страниц не найдено. Запускается spooler для записи `INBuffer_ach` | Помимо XML зависит от извлечения PDF attachment; сложнее обычных входящих XML-процессоров |
| 20 | Codeunit 75624 `"Process EDI_hcz"` | `OnRun`; внутри `Process` | Ссылок из страниц не найдено. Запускается spooler для записи `INBuffer_ach` | Самый большой XML-процессор в списке; переносить после проверки повторяемых шаблонов на меньших объектах |
| 21 | Codeunit 75628 `"Send OUT - WS Spooler_hcz"` | `OnRun`; внутри `SendMsg` | Ссылок из страниц не найдено. Весь объект находится внутри `#if TODO_REMOVE` | Последний приоритет: сначала нужно принять решение об удалении или возврате объекта; сейчас он исключён из компиляции |

## CZ/SK

| Приоритет | Объект | Метод / trigger | Страница, из которой выполняется запуск | Причина приоритета |
|---:|---|---|---|---|
| 1 | Codeunit 75579 `"SKODA-Auto-Inv.XMLexport_hcz"` | `OnRun`; внутри `GenerateXMLFile` | Прямых ссылок из страниц не найдено. Запускается динамически через `"Record Export Buffer"` для `"Sales Invoice Header"` | Основной invoice export; применить шаблон W1 для `Record Export Buffer`, XML и stream-based file handling |
| 2 | Codeunit 75580 `"SKODA-Auto-Cr.m.XMLExport_hcz"` | `OnRun`; внутри `GenerateXMLFile` | Прямых ссылок из страниц не найдено. Запускается динамически через `"Record Export Buffer"` для `"Sales Cr.Memo Header"` | Почти идентичен invoice export; выполнять вторым с повторным использованием готового решения |
| 3 | Report 75735 `"SK Intrastat Export_hcz"` | Выполнение report | `"Intrastat Report"` — action `"Export"`, добавленный через pageextension 63035 `IntrastatReport__hcz` | Отдельный пользовательский XML-export с namespace и файловым выводом; мигрировать после общих экспортных шаблонов |

## Примечания

- Указанный в исходном списке `ExportWaltherPurchaseOrder.Codeunit.al` фактически называется в репозитории `ExportWaltherPuchOrder.Codeunit.al`.
- `Packages_hcz` и `"Packages List_hcz"` содержат прямые вызовы DPD/GEIS только внутри блока `#if TODO_FNC`.
- Объекты, обрабатывающие `INBuffer_ach` или `OUTBuffer_ach`, выбираются и запускаются динамически настройками spooler, а не статически связанной page action.
- Экспортные codeunits, использующие `"Record Export Buffer"`, выбираются динамически настройками экспорта. Тип исходного документа определить можно, но конкретную вызывающую страницу не всегда можно подтвердить по статическим ссылкам.
- Приоритеты W1 и CZ/SK независимы. Для CZ/SK сначала следует завершить соответствующий шаблон экспорта в W1.
