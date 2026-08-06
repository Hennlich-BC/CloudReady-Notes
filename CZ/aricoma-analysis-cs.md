# Porovnání seznamu Aricoma se zdrojovým kódem

Zdroj: `aricoma.md`. Analýza zahrnuje projekty `w1` a pro část SK také `../czsk`. Seznamy souborů jsou orientační, protože exporty a spoolery mohou spouštět objekty dynamicky podle nastavení.

## Cloud Ready W1

| Bod | Požadovaná změna | Pravděpodobně dotčené soubory |
|---|---|---|
| Cca 570 úloh; HelpDesky po objektech | Jde o organizační body. Pro každý objekt níže založit samostatný HelpDesk s vlastníkem, testovacím scénářem a Cloud Ready akceptačními kritérii. | `aricoma.md`, případně projektová dokumentace |
| Typ „export“ | Nejprve migrovat a otestovat jeden jednoduchý export: odstranit DotNet XML a serverové cesty, použít `XmlDocument`, `Temp Blob` a streamy. Ověřený vzor pak aplikovat na ostatní exporty. | `src/Codeunit/DocumentExportManagement.Codeunit.al`, `ExportWaltherPuchOrder.Codeunit.al`, `ExportSalesOrderEDIConfirm.Codeunit.al`, `ExportPostSalesInvoiceEDI.Codeunit.al`, `ExportPurchaseOrderGMORS.Codeunit.al`, `ExportPurchaseOrderDMH.Codeunit.al`, `ExportSalesShipmentEDI.Codeunit.al` |
| Přepravci | Aktualizovat integrace na nová API přepravců; DotNet HTTP/XML a serverové dočasné soubory nahradit `HttpClient`, AL XML/JSON a streamy. Otestovat autentizaci, chyby, tisk a logování. | `src/Codeunit/GLSManagement.Codeunit.al`, `DPDManagement.Codeunit.al`, `GEISManagement.Codeunit.al`, `TNTManagement.Codeunit.al`, `FedExManagement.Codeunit.al`, `ParcelsManagement.Codeunit.al`, `src/Report/UpdateGLSPostCodeRouteshcz.Report.al` |
| Čárové kódy | Odstranit ZXing/.NET (`Bitmap`, `ImageFormat`). Generování přesunout do SaaS-kompatibilní služby/API nebo použít podporovaný barcode font/provider; reportům předávat stream/Media. | `src/Codeunit/BarcodeManagement.Codeunit.al`, `src/Dotnet/ZXing.Dotnet.al`, `src/Report/*BarCode*.al` a jejich layouty |
| Slučování PDF | Aspose/.NET a `MemoryStream` nahradit externí HTTP službou/Azure Function nebo podporovanou SaaS komponentou; vstup i výsledek předávat streamem/BLOBem. | `src/Codeunit/PDFManagement.Codeunit.al`, `src/Dotnet/AsposePDF.Dotnet.al`, `src/Codeunit/DocumentPublishing.Codeunit.al` |
| Tisk PDF štítků přepravců | PDF neukládat ani netisknout na serveru BC. Odesílat je přes HTTP do IIS/print service a doplnit nastavení endpointu/tiskárny a zpracování odpovědi. | `GLSManagement.Codeunit.al`, `DPDManagement.Codeunit.al`, `GEISManagement.Codeunit.al`, `TNTManagement.Codeunit.al`, `FedExManagement.Codeunit.al`, `src/Table/ServerPrinterSelection.Table.al` |
| FTP | Přímý FTP klient nebyl ve `w1` nalezen. S Aptive upřesnit směry a formáty a použít jejich API/SFTP gateway nebo integrační službu; lokální adresáře nejsou pro SaaS vhodné. | Po upřesnění zejména handlery `INBuffer/OUTBuffer`, např. `SendOUTHIS.Codeunit.al`, `SendOUTWSSpooler.Codeunit.al` a EDI procesory |
| FinStat HSK | Prověřit hotové řešení Aricoma. Stávající .NET klient nahradit HTTP/JSON API, tajné údaje uložit bezpečně a po migraci odstranit DotNet deklaraci. | `src/Codeunit/FinStatRequest.Codeunit.al`, `src/Table/FinStatData.Table.al`, `src/Report/FinStat*.al`, `src/Dotnet/FinStat.Dotnet.al` |
| HCZ funkce | Souborové operace převést na streamy/`Temp Blob`; reflection a stack trace odstranit nebo nahradit AL telemetry a kontextem chyby. | `src/Codeunit/HCZFunctions.Codeunit.al`, `src/Codeunit/CallStack.Codeunit.al` |
| Hint Colour Management | `System.Drawing.Color` nahradit vlastním AL zpracováním RGB/HEX a porovnat s implementací v MasterTemplate. | `src/Codeunit/HINTColorMgt.Codeunit.al`, `src/Dotnet/System.Dotnet.al` |
| WebService Management | Převzít aktuální variantu z MasterTemplate: DotNet web request nahradit `HttpClient`, doplnit kontrolu statusu/chyb a streamy. | `src/Codeunit/NAVWebServiceMgmt.Codeunit.al`; prověřit také `EDIWebService.Codeunit.al`, `PWImportWebService.Codeunit.al` |
| PDF Template Management | Externí `PDFTK`, procesy a serverové cesty v SaaS nefungují. Zpracování přesunout do HTTP PDF služby, soubory držet v BLOB/Media. | `src/Codeunit/PDFTemplateMgt.Codeunit.al`, `PDFTemplateManualSubscriber.Codeunit.al`, `src/Table/PDFTemplate.Table.al`, `ReportPDFTemplate.Table.al`, `src/Page/PDFTemplates.Page.al`, `ReportPDFTemplates.Page.al` |
| EDI | DotNet XML a výměnu přes serverové soubory převést na AL XML + streamy/HTTP; ověřit vstupní spoolery, namespaces a přílohy. | `src/Codeunit/ProcessEDI.Codeunit.al`, `ImportEDIORDRSPfromspooler.Codeunit.al`, `Export*EDI*.Codeunit.al`, `EDIWebService.Codeunit.al`, `src/XmlPort/EDILECHLERORDRSP.XmlPort.al` |
| Mail Record | Přílohy a publikované dokumenty nezapisovat do serverových temp souborů; použít `Temp Blob`, Document Attachment/Media a streamové email API. | `src/Codeunit/ProcessMailRecord.Codeunit.al`, `MailRecordSMMgt.Codeunit.al`, `MailRecordPubManagement.Codeunit.al`, `IPMailRecordManagement.Codeunit.al`, objekty `*MailRecord*` |
| NCH | Souborový import/export nahradit upload/download streamy nebo API a ověřit skladové a celní výstupy. | `src/Codeunit/ProcessNCHCustoms.Codeunit.al`, `ProcessNCHOrders.Codeunit.al`, `src/Report/ExportNCHOrders.Report.al`, `NCHItemInventoryhcz.Report.al` |
| SKF | XML export/import objednávek, potvrzení a DESADV převést z DotNet/server files na AL XML a streamy; otestovat namespaces na reálných zprávách. | `src/Codeunit/ExportPurchaseOrderSKF.Codeunit.al`, `ProcessSKFOrderConf.Codeunit.al`, `ProcessSKFDESADV.Codeunit.al` |
| SQL management, reporty | Přímý ADO.NET přístup v SaaS není možný. Dotazy přesunout do API/Azure Function nebo do BC Query/API a connection string nahradit nastavením endpointu. | `src/Codeunit/SQLManagement.Codeunit.al`, `CentralDatabaseSQLMgt.Codeunit.al`; návazné reporty určit podle jednotlivých metod |
| Cestovní zprávy, přílohy | Přílohy a editaci převést ze serverových souborů na BLOB/Media/Document Attachment a upload/download streamy. | `src/Codeunit/TravelNoticeExtEditMgt.Codeunit.al`, `TravelNoticeAttachmtMgt.Codeunit.al`, `src/Table/TNNoticeData.Table.al`, `src/Page/*TravelNotice*.al` |
| SafeQueFile | Objekt ani termín tohoto názvu nebyl nalezen. Je nutné dodat číslo objektu nebo uživatelský scénář; poté lokální frontu/soubory nahradit cloudovou frontou/API nebo tabulkou BC. | Do upřesnění neurčeno |
| XML functions | Převzít variantu z MasterTemplate: DotNet XML nahradit `XmlDocument/XmlNode`, práci s cestami nahradit `InStream/OutStream` a `Temp Blob`. | `src/Codeunit/XMLFunctions.Codeunit.al`, následně `src/Dotnet/System.Dotnet.al` |
| DotNet obecně | Po dílčích migracích znovu vyhledat DotNet a `Scope('OnPrem')`, odstranit `target: OnPrem` a závislost `Productivity Pack OnPrem` a sestavit Cloud variantu. | `src/Dotnet/*.al`, všechny soubory s DotNet/OnPrem, `app.json` |
| Page: Montážní zakázky | V `DoableAssemblyOrders` odstranit DotNet a ověřit všechny akce ve web klientu. Ostatní montážní/demontážní stránky potřebují funkční smoke test. | `src/Page/DoableAssemblyOrders.Page.al`, `src/PageExt/Assembly*.PageExt.al`, `src/TableExt/Assembly*.al`, `src/Codeunit/Disassembly*.al` |
| Page: E-ShopData | Server-side upload/delete převést na streamy a BLOB/Media; otestovat import/export a HTML obsah ve web klientu. | `src/Page/EShopDataContent.Page.al`, `EShopDataCard.Page.al`, `EShopDataList.Page.al`, `src/Table/EShopData.Table.al`, `src/Report/ImportEShopData.Report.al`, `ExportEshopData.Report.al` |
| Obrázky na čtečkách | Odstranit čtení obrázků ze serverových cest a DotNet; ukládat/přenášet je jako Media/BLOB streamy a otestovat mobilní control add-in. | `src/Page/WMSMPictures.Page.al`, `WMSMInventory.Page.al`, `WMSMPickPutawayBasket.Page.al`, `src/Table/WMSMPicture.Table.al`, `src/Enum/WMSMPictureType.Enum.al` |
| Develop Import | DotNet/lokální import přepsat na `UploadIntoStream`, AL XML/CSV/Excel Buffer; ověřit kódování a transakce. | `src/Report/DEVELOPImport.Report.al`, případně `src/Codeunit/ItemImport.Codeunit.al` |
| Export Segment | XMLport sám neobsahuje nalezený DotNet. Prověřit spouštěcí místo a případný server-file destination nahradit streamem/downloadem. | `src/XmlPort/ExportSegmentContact.XmlPort.al`, `src/TableExt/SegmentLinehcz.TableExt.al` |
| Kompletní kusovníky pro Engineering | XML import převést na AL XML/streamy; přímý SQL import v managementu/reportu nahradit API nebo staging tabulkami BC. | `src/Codeunit/CompleteBOMManagement.Codeunit.al`, `src/Report/ImportCompleteBOMXMLhcz.Report.al`, `ImportCompleteBOMSQL.Report.al`, `src/XmlPort/ImportCompleteBOM*.XmlPort.al`, objekty `CompleteBOM*` |
| Excel buffer | `DocumentFormat.OpenXml` a OnPrem části nahradit standardním `Excel Buffer`/stream API; prověřit všechny konzumenty. | `src/Table/ExcelBuffer.Table.al`, `src/Dotnet/DocumentFormat.Dotnet.al`, reporty používající `ExcelBuffer_hcz` |
| HPL skladové zásoby | Connection string v nastavení ukazuje na přímé externí spojení. Nahradit jej endpoint/API nastavením a zásoby číst přes `HttpClient`; upřesnit HPL API. | `src/TableExt/InventorySetup.TableExt.al`, `src/PageExt/InventorySetup.PageExt.al`; volající kód určit po upřesnění rozhraní |
| Serverové tiskárny | SaaS nemůže spouštět lokální proces tisku. Použít Universal Print, cloud print service nebo lokálního agenta s HTTP/queue API. | `src/Table/ServerPrinterSelection.Table.al`, `src/Page/ServerPrinterSelections.Page.al`, `src/Report/WhseShptCustLblLocPrinterhcz.Report.al` |
| Eračun | Nalezeno generování `MojEracunInvoice`. Ověřit streamové vytvoření/předání XML bez server file/DotNet a provést integrační test se slovinskou službou. | `src/XmlPort/SalesInvoiceEUNormaPDVEN.XmlPort.al` a exportní codeunit vybraný nastavením |

## Cloud Ready SK (`../czsk`)

| Bod | Požadovaná změna | Pravděpodobně dotčené soubory |
|---|---|---|
| FinStat | FinStat .NET client/response types nahradit HTTP/JSON a bezpečným nastavením API; znovu použít společné řešení W1. | `../czsk/src/codeunits/RegistrationEventMgmnt.Codeunit.al`; společné `w1/src/Codeunit/FinStatRequest.Codeunit.al`, `w1/src/Dotnet/FinStat.Dotnet.al` |
| Škoda Auto, export faktur a dobropisů | DotNet XML/server file nahradit AL XML a streamy; dva podobné exporty sjednotit společným helperem a ověřit XSD i příjem. | `../czsk/src/codeunits/SKODAAutoInvXMLexport.Codeunit.al`, `SKODAAutoCrmXMLExport.Codeunit.al` |
| HSK Intrastat | Souborový/DotNet XML výstup převést na stream a download/API; ověřit namespace a akci Export. | `../czsk/src/report/SKIntrastatExporthcz.Report.al`, `../czsk/src/pageext/w1/IntrastatReport.PageExt.al` |

## Productivity Pack

`app.json` W1 současně odkazuje na `Productivity Pack` a `Productivity Pack OnPrem` a používá target `OnPrem`. Je potřeba získat Cloud Ready variantu hlavního balíčku od Aricoma, odstranit/nahradit OnPrem závislost a po migraci konzumentů přepnout aplikaci na Cloud target. Minimálně bude změněn `app.json`; přesný seznam AL souborů ukáže kompilace bez OnPrem balíčku.

## Architektura REST API

Návrh organizace API infrastruktury je přesunut do samostatného dokumentu: [`api-infrastructure-cs.md`](api-infrastructure-cs.md).

