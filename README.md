# srbd-pzpi-24-5-nikitchenko-dmytro

ПЗПІ-24-5

Нікітченко Дмитро

Серверні рішення баз даних. MS SQL Server 2022, T-SQL. Тема - аптечна мережа, БД `Pharmacy`.

## Запуск

```bash
docker compose up -d
```

Підключення: `localhost,1433`, користувач `sa`, пароль з `docker-compose.yml`
(локальний контейнер для навчання).

Скрипти в кожній теці виконуються по черзі, наприклад:

```bash
docker compose exec -T mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'SrbdLab2026!' -C -f 65001 \
  -i /scripts/lab1/01_schema.sql
```

## Роботи

- `lab1` - збережені процедури та функції; `reset.sh` перестворює `Pharmacy` у стані ЛР1
- `lab2` - тригери
- `lab3` - веб-застосунок (FastAPI, HTML/JS), див. `lab3/README.md`
- `pz1` - службова інформація
- `pz2` - оптимізація запитів індексами, БД `TestDB`; `bench.sh` - заміри для всіх наборів індексів
- `pz3` - курсори
- `pz4` - резервне копіювання та відновлення на копії `PharmacyCopy`; `06_strategy.sql` - завдання
  SQL Server Agent для `Pharmacy`, `07_cleanup.sql` - прибирання
