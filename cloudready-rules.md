# Правила миграции .NET-зависимого AL-кода в Cloud Ready

Правила составлены по результатам анализа коммитов HD03309, HD03310, HD03311, HD03312, HD03329, HD03331 и HD03335, включая исправления HD03329.

Основная цель изменений — убрать зависимость AL-кода от .NET и серверной файловой системы, используя стандартные AL-типы и codeunit'ы.

## 1. Заменять DotNet XML-типы встроенными типами AL

| Было | Должно стать |
|---|---|
| `DotNet XmlDocument` | `XmlDocument` |
| `DotNet XmlElement` | `XmlNode` или `XmlElement` |
| `DotNet XmlNode` | `XmlNode` |
| `DotNet XmlNodeList` | `XmlNodeList` |

Тип необходимо менять не только у глобальных переменных, но и:

- у локальных переменных;
- в параметрах процедур;
- в возвращаемых значениях;
- во вспомогательных процедурах построения и разбора XML.

## 2. Создавать XML-документ через AL API

Вместо:

```al
XmlDoc := XmlDoc.XmlDocument();
XmlDoc.LoadXml('<Root></Root>');
RootNode := XmlDoc.DocumentElement;
```

использовать:

```al
XmlDoc := XmlDocument.Create();
XmlDomMgt.AddRootElement(XmlDoc, 'Root', RootNode);
```

Для XML с префиксом и namespace:

```al
XmlDomMgt.AddRootElementWithPrefix(
    XmlDoc,
    'Envelope',
    'soapenv',
    SoapNamespace,
    RootNode);
```

Для общих операций следует использовать:

- стандартный codeunit `"XML DOM Management"`;
- проектный codeunit `XMLDOMAddManagement_hcz`, если стандартного API недостаточно.

## 3. Использовать единый тип `XmlNode` при построении дерева

Для перемещения по XML и добавления элементов удобнее объявлять:

```al
CurrElement: XmlNode;
NewElement: XmlNode;
RootElement: XmlNode;
```

При необходимости специфической операции выполнять явное преобразование:

```al
CurrElement.AsXmlElement().InnerText()
RootElement.AsXmlElement().SetAttribute(Name, Value);
```

Перед `AsXmlElement()` желательно убедиться, что узел действительно является элементом:

```al
if not XmlNode.IsXmlElement() then
    Error(...);
```

## 4. Заменять свойства .NET XML их AL-аналогами

| .NET-вызов | AL-аналог |
|---|---|
| `XmlDoc.DocumentElement` | `XmlDoc.GetRoot(RootElement)` |
| `Node.InnerText` | `Node.AsXmlElement().InnerText()` |
| `Node.InnerXml` | `Node.AsXmlElement().InnerXml()` |
| `Node.ParentNode` | `Node.GetParent(...)` или `CurrElementSetParentNode(...)` |
| `Node.SetAttribute(...)` | `Node.AsXmlElement().SetAttribute(...)` |
| `XmlDoc.Save(Stream)` | `XmlDoc.WriteTo(Stream)` |
| `XmlDoc.Load(Stream)` | `XmlDocument.ReadFrom(Stream, XmlDoc)` |
| `SelectSingleNode(...)` | `XmlNode.SelectSingleNode(...)` |
| выбор множества узлов | `XmlNode.SelectNodes(..., XmlNodeList)` и `foreach` |

В проекте переход к родителю унифицирован через:

```al
XMLDOMAddManagement.CurrElementSetParentNode(CurrElement);
```

Это предпочтительнее прямого повторения `GetParent()` в каждом файле.

## 5. XML-декларацию добавлять через встроенный тип

Вместо `CreateXmlDeclaration()` и `InsertBefore()` использовать `XmlDeclaration`:

```al
XmlDoc.Add(XmlDeclaration.Create('1.0', 'UTF-8', ''));
```

Если декларация создаётся через общую вспомогательную процедуру, необходимо отдельно проверить:

- позицию декларации относительно корневого элемента;
- регистр и значение encoding;
- значение `standalone`;
- получившийся XML реальным чтением или тестом.

## 6. Не писать XML непосредственно в путь через `WriteTo(Text)`

У `XmlDocument.WriteTo(Text)` аргумент может восприниматься как текстовый результат, а не имя файла. Поэтому такая замена ненадёжна:

```al
XmlDoc.WriteTo(ServerFilePath);
```

Правильный вариант для временного серверного файла:

```al
TempFile.Create(ServerFilePath, TextEncoding::UTF8);
TempFile.CreateOutStream(OutStr);
XmlDoc.WriteTo(OutStr);
```

Если физический файл не требуется, писать сразу в BLOB:

```al
TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
XmlDoc.WriteTo(OutStr);
```

Это особенно важно для изменений типа HD03309 и HD03310 с `ServerFilePath`.

## 7. По возможности исключать серверную файловую систему

Нужно удалять или перерабатывать прямые вызовы:

- `Exists`;
- `Erase`;
- `File.Open/Create/Close`;
- жёстко заданные пути вроде `C:\Temp`;
- сохранение через `.Save(FileName)`;
- серверные каталоги и `Directory`;
- `[Scope('OnPrem')]`.

Предпочтительные механизмы:

- `Temp Blob`;
- `InStream` и `OutStream`;
- BLOB-поля таблиц;
- `DownloadFromStream`;
- `UploadIntoStream`;
- временный `File` только когда внешний API действительно требует путь.

## 8. Для скачивания файла использовать stream-based подход

Типовой шаблон:

```al
XmlDoc.WriteTo(XmlText);

TempBlob.CreateOutStream(OutStr);
OutStr.WriteText(XmlText);

TempBlob.CreateInStream(InStr);
DownloadFromStream(InStr, '', '', '', FileName);
```

При этом нужно явно контролировать `TextEncoding`, особенно для XML с декларацией `UTF-8`.

## 9. Заменять .NET HTTP/SOAP на стандартные HTTP-типы AL

Использовать:

```al
HttpClient
HttpRequestMessage
HttpResponseMessage
HttpContent
HttpHeaders
```

Общий алгоритм:

1. Записать `XmlDocument` в `OutStream`.
2. Получить `InStream`.
3. Передать его в `HttpContent.WriteFrom`.
4. Удалить автоматически созданный `Content-Type`, если он уже существует.
5. Добавить нужные заголовки.
6. Задать URI, метод и content.
7. Вызвать `HttpClient.Send`.
8. Проверить HTTP-статус.
9. Прочитать ответ.
10. Разобрать его через `XmlDocument.ReadFrom`.

Пример заголовков SOAP:

```al
RequestContent.GetHeaders(ContentHeaders);

if ContentHeaders.Contains('Content-Type') then
    ContentHeaders.Remove('Content-Type');

ContentHeaders.Add('Content-Type', 'text/xml');
ContentHeaders.Add('SOAPAction', SoapAction);
```

## 10. Обрабатывать транспортные ошибки отдельно от SOAP Fault

Проверять необходимо три уровня:

- вернул ли `HttpClient.Send` результат;
- успешен ли `IsSuccessStatusCode()`;
- содержит ли успешный HTTP-ответ SOAP `Fault`.

При HTTP-ошибке следует использовать как минимум:

```al
Response.ReasonPhrase
```

Желательно также включать status code и тело ответа, если оно не содержит чувствительных данных.

## 11. При разборе SOAP учитывать namespace

В HD03329 ответ сначала очищается от namespace через:

```al
XMLDOMManagement.RemoveNamespaces(ResponseText)
```

После этого используются простые XPath:

```al
RootElement.AsXmlNode().SelectSingleNode('/Envelope/Body', CurrElement);
```

Следует выбрать один подход для всей процедуры:

- удалить namespace и использовать простые XPath;
- сохранить namespace и выполнять namespace-aware поиск.

Смешивать эти подходы нельзя.

## 12. Не считать `XmlDocument.AsXmlNode()` корневым элементом

Это стало причиной дополнительного fix-коммита HD03329.

Надёжный вариант:

```al
XmlDoc.GetRoot(RootElement);
CurrElement := RootElement.AsXmlNode();
```

Процедуры проверки ответа лучше принимать как `XmlDocument`, самостоятельно получать root и только затем проверять его имя:

```al
local procedure TestResponse(var XmlDoc: XmlDocument)
var
    RootElement: XmlElement;
begin
    XmlDoc.GetRoot(RootElement);

    if RootElement.Name = 'Fault' then
        ...
end;
```

## 13. Проверять соответствие request/response при логировании

В первоначальном HD03329 были перепутаны документы при сохранении логов. Fix-коммиты исправили это.

Для каждого файла должно быть однозначное соответствие:

- `*_Request.xml` → `RequestContentXmlDoc`;
- `*_ResponseContent.xml` → `ResponseContentXmlDoc`;
- при необходимости извлечённое SOAP body → `ResponseXmlDoc`.

Имя файла и передаваемая переменная должны проверяться вместе.

## 14. После создания дочернего XML-элемента контролировать текущий уровень

Типовой шаблон:

```al
XmlDomMgt.AddElement(CurrElement, 'Parent', '', '', NewElement);
CurrElement := NewElement;

// Добавление дочерних элементов

XmlDomAddMgt.CurrElementSetParentNode(CurrElement);
```

После каждого блока нужно проверять, сколько раз выполняется возврат к родителю. Ошибка на один уровень создаёт валидный, но структурно неправильный XML.

## 15. Форматировать значения независимо от региональных настроек

Для XML и внешних API нельзя полагаться на пользовательский locale.

В проекте используются:

- `Format(Value, 0, 9)`;
- `FormatDa`;
- `FormatTi`;
- `FormatDe`;
- `FormatIn`;
- вспомогательные процедуры `XMLDOMAddManagement_hcz`.

Особенно это относится к:

- датам;
- времени;
- `DateTime`;
- `Decimal`;
- XML-атрибутам сумм и размеров.

## 16. Не удалять `#if TODO_ONPREM` механически

HD03312 показывает три разных варианта обработки OnPrem-блоков:

- реализация уже cloud-compatible — убрать условную компиляцию;
- функциональность зависит от будущей версии BC — заменить на специализированный символ вроде `TODO_PP_CLOUDREADY`;
- безопасного аналога нет — временно изолировать блок для удаления или переработки, например `TODO_REMOVE`.

Перед изменением директив нужно классифицировать код, а не просто удалять `#if/#endif`.

## 17. Заменять системные OnPrem-таблицы cloud-compatible аналогами

Пример из HD03312:

```al
Record "Object"
```

заменён на:

```al
Record AllObjWithCaption
```

Соответственно меняются поля:

```text
Type → "Object Type"
ID   → "Object ID"
```

Такую замену нужно выполнять вместе со всеми фильтрами, сортировкой, `Mark` и обращениями к полям.

## 18. Сохранять функциональное поведение

При миграции нельзя менять без необходимости:

- имена и структуру XML-элементов;
- порядок элементов, если он значим для схемы;
- namespace и префиксы;
- encoding;
- `SOAPAction`;
- формат дат и чисел;
- имена выходных файлов;
- обновление статусов документов и посылок;
- работу spooler/OUTBuffer;
- обработку ошибок внешней системы.

## Обязательная проверка после миграции

Для каждого изменённого файла следует проверить:

1. В файле больше нет активных `DotNet`-переменных.
2. Сигнатуры всех вызываемых процедур согласованы.
3. Нет прямых `.Save()`, `.LoadXml()`, `.DocumentElement`, `.ParentNode` и `.InnerText`.
4. XML можно записать и повторно прочитать.
5. Root является элементом, а не `XmlDocument.AsXmlNode()`.
6. Структура XML совпадает с прежним результатом.
7. Request и response не перепутаны в логах.
8. UTF-8 сохраняется фактически, а не только указан в декларации.
9. HTTP-код обрабатывает неуспешный статус и SOAP Fault.
10. Код компилируется с нужным набором preprocessor symbols.
11. Протестированы успешный ответ, Fault и невалидный или пустой ответ.
12. Для интеграции проверен реальный запрос или сохранённый эталонный XML.

## Итоговый принцип

Миграция должна выполняться не простой заменой типов `DotNet → AL`, а полным переносом жизненного цикла данных: создание XML, навигация, сериализация, HTTP-передача, разбор ответа, логирование и обработка ошибок.
