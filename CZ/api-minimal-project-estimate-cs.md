# Odhad minimálního projektu REST API

Dokument doplňuje `CZ\api-infrastructure-cs.md`. Jde o předběžný odhad pro jednoho specialistu a osmihodinový pracovní den, nikoli o obchodní nabídku.

## Rozsah minimálního projektu

MVP zahrnuje:

- interní Linux server, Docker Engine a Docker Compose;
- FastAPI s verzovaným REST/OpenAPI kontraktem;
- PostgreSQL pro operace, stavy a idempotenci;
- RabbitMQ a jeden Celery worker;
- Typst worker pro jeden dohodnutý PDF dokument;
- ukládání do Docker volumes bez povinného MinIO;
- HTTPS a API credentials nebo OAuth 2.0 podle připravenosti infrastruktury;
- jeden AL client codeunit a setup page v Business Central;
- stavy asynchronních operací a stažení vytvořeného PDF;
- základní logy, healthchecks, backup a provozní dokumentaci;
- unit, integration a akceptační testy jednoho end-to-end scénáře.

MVP nezahrnuje všechny přepravce, EDI, FTP/SFTP, FinStat, OCR, univerzální editor šablon, HA cluster, kompletní Grafana monitoring ani migraci všech existujících PDF reportů.

## Odhad pracnosti

| Etapa | Pracovní dny | Výsledek |
|---|---:|---|
| Upřesnění požadavků a architektura | 3–4 | Kontrakt, komponenty, security a acceptance criteria |
| Linux/Docker infrastruktura | 4–6 | Compose, networks, volumes, secrets, TLS a healthchecks |
| Základ API a fronta operací | 6–8 | FastAPI, PostgreSQL, RabbitMQ, Celery, idempotence a stavy |
| Typst/PDF scénář | 5–7 | Jedna production-like šablona, JSON mapping, generování a předání PDF |
| Integrace s Business Central | 5–7 | AL client, setup, permissions, zadání operace a získání výsledku |
| Logy, backup a dokumentace | 3–4 | Correlation ID, evidence chyb, backup/restore a runbook |
| Testování a opravy | 8–11 | Unit, integration, negativní, security a menší zátěžový test |
| Nasazení a akceptace | 6–8 | Instalace, síť/certifikáty, UAT, opravy a předání |
| **Celkem** | **40–55 dnů** | **320–440 hodin** |

Doporučená rezerva je 15 %, tedy plánovaný rozpočet **46–63 pracovních dnů nebo 368–506 hodin**.

## Kalendářní doba pro jednu osobu

| Fáze | Očekávaná doba |
|---|---:|
| Implementace | 5–7 týdnů |
| Testování a stabilizace | 2–3 týdny |
| Nasazení a UAT | 1–2 týdny |
| **Čistá doba** | **8–12 týdnů** |
| **Reálná kalendářní doba včetně schvalování** | **10–14 týdnů** |

Čistá doba předpokládá téměř plnou kapacitu specialisty. Čekání na Linux VM, firewall, DNS, certifikáty, BC credentials nebo rozhodnutí uživatelů o šabloně prodlouží kalendář, ale nemusí zvýšit pracnost.

## Odhad ceny práce

Částky jsou uvedeny v eurech bez DPH, hardware, licencí, následné podpory a poplatků externích služeb.

| Sazba | Základních 320–440 hodin | S rezervou 368–506 hodin |
|---:|---:|---:|
| 50 EUR/h | 16 000–22 000 EUR | 18 400–25 300 EUR |
| 65 EUR/h | 20 800–28 600 EUR | 23 920–32 890 EUR |
| 80 EUR/h | 25 600–35 200 EUR | 29 440–40 480 EUR |

Pro předběžný rozpočet je vhodné počítat přibližně s **25 000–33 000 EUR bez DPH** při kalkulační sazbě přibližně 65 EUR/h a rezervě 15 %. Přesná cena závisí na dohodnuté sazbě, autentizaci, připravenosti Linux serveru a složitosti první Typst šablony.

## Odhad nasazení

Z celkové pracnosti připadá na vlastní nasazení přibližně 6–8 dnů:

- příprava Linux VM, disků, DNS a firewallu — 1–2 dny;
- instalace Compose a první konfigurace — 1 den;
- TLS, secrets a spojení s BC — 1–2 dny;
- instalace a nastavení AL komponent — 1 den;
- backup/restore check, smoke test a UAT — 2 dny.

Pokud VM, DNS, certifikáty a síťová pravidla zajišťuje samostatný infrastrukturní tým, jeho práce není zahrnuta v ceně jednoho vývojáře a musí se odhadnout zvlášť.

## Plán testování

- Unit tests: validace modelů, mapping JSON → Typst, stavy a retry.
- Integration tests: PostgreSQL, RabbitMQ, Typst compilation a file storage.
- BC end-to-end: vytvoření úlohy, polling, stažení PDF a zpracování chyby.
- Negative tests: chybný JSON, chybějící template, timeout, poškozený asset a nedostupný worker.
- Security: authentication, oprávnění, limity velikosti, ochrana cest a odstranění secrets z logů.
- Performance smoke test: několik souběžných PDF a kontrola CPU/RAM/fronty.
- Recovery: restart workeru/API, opakování úlohy bez duplicity a obnova ze zálohy.

## Hlavní rizika odhadu

- Není připraven interní Linux server, DNS, TLS nebo firewall.
- Není určen způsob autentizace Business Central → API.
- První PDF má složitý layout, nestandardní fonty nebo musí přesně kopírovat stávající sestavu.
- Je potřeba slučování či podpis PDF, nejen generování Typst.
- Jeden vývojář současně zajišťuje AL, Python, DevOps a testování; specializovaný security audit vyžaduje další osobu.
- Do MVP se během realizace přidají přepravci, EDI, FTP nebo další šablony.

Každá další doménová integrace po dokončení MVP se odhaduje samostatně. Jednoduchý REST adaptér obvykle zabere 3–6 dnů, složitý přepravce/EDI 8–20 dnů a další Typst šablona 2–7 dnů podle layoutu a pravidel.
