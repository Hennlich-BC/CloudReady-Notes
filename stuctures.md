## Linux Host Structure
```
Linux Host
│
├── Docker Compose
│   ├── api
│   │   └── FastAPI
│   ├── worker
│   │   ├── Task Dispatcher
│   │   ├── Workflow Executor
│   │   ├── PDF Handler
│   │   ├── Print Handler
│   │   ├── FTP/SFTP Handler
│   │   └── Storage Handler
│   ├── redis
│   ├── postgres
│   └── web
│       └── Web Task Monitor
│
├── Linux Storage
│   ├── documents/
│   ├── uploads/
│   ├── temp/
│   ├── templates/
│   └── config/
│
└── SMB Mounts
    ├── /mnt/windows-exchange
    ├── /mnt/windows-archive
    └── /mnt/windows-shared
```

## General Project Structure
```
task-service/
│
├── app/
│   ├── main.py
│   │
│   ├── api/
│   │   ├── tasks.py
│   │   ├── documents.py
│   │   ├── printers.py
│   │   ├── workflows.py
│   │   └── health.py
│   │
│   ├── core/
│   │   ├── config.py
│   │   ├── security.py
│   │   ├── logging.py
│   │   └── exceptions.py
│   │
│   ├── db/
│   │   ├── models.py
│   │   ├── session.py
│   │   └── migrations/
│   │
│   ├── tasks/
│   │   ├── dispatcher.py
│   │   ├── registry.py
│   │   ├── schemas.py
│   │   └── handlers/
│   │       ├── base.py
│   │       ├── generate_pdf.py
│   │       ├── print.py
│   │       ├── ftp_upload.py
│   │       ├── ftp_download.py
│   │       └── storage_copy.py
│   │
│   ├── services/
│   │   ├── documents/
│   │   │   ├── typst.py
│   │   │   ├── templates.py
│   │   │   └── resolver.py
│   │   ├── printing/
│   │   │   ├── nst_client.py
│   │   │   ├── document_resolver.py
│   │   │   └── printer_config.py
│   │   ├── transfer/
│   │   │   ├── ftp.py
│   │   │   └── sftp.py
│   │   └── storage/
│   │       ├── base.py
│   │       ├── local.py
│   │       └── smb.py
│   │
│   └── workflows/
│       ├── executor.py
│       └── definitions.py
│
├── worker/
│   └── main.py
│
├── web/
│   └── Web Task Monitor
│
├── templates/
│   ├── invoice/
│   ├── label/
│   └── report/
│
├── config/
│   ├── printers.yaml
│   ├── nst.yaml
│   ├── ftp.yaml
│   ├── storage.yaml
│   ├── templates.yaml
│   └── workflows.yaml
│
├── tests/
├── Dockerfile
├── compose.yaml
└── .env
```

![structures](/img/schema03.png)


## Business Central Integration
![structures2](/img/mermaid-diagram.png)