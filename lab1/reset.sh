#!/usr/bin/env bash
# Перестворює БД Pharmacy у стані ЛР1:
#   схема (01) + дані з розділу 1.4 звіту (02) + процедури й функції (04-07).
# Блоки "-- перевірка" не виконуються, щоб їх можна було запустити наживо.
#   ./lab1/reset.sh          - чистий стан для демонстрації
#   ./lab1/reset.sh --full   - ще й виконати всі перевірки (стан після звіту)
# Перед видаленням робиться бекап у /var/opt/mssql/backup/ всередині контейнера.
set -euo pipefail
cd "$(dirname "$0")/.."

sql() {
    docker compose exec -T mssql /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P 'SrbdLab2026!' -C -f 65001 "$@"
}

stamp=$(date +%Y%m%d_%H%M%S)
docker compose exec -T mssql mkdir -p /var/opt/mssql/backup
sql -b -Q "IF DB_ID('Pharmacy') IS NOT NULL
BEGIN
    BACKUP DATABASE Pharmacy
        TO DISK = '/var/opt/mssql/backup/Pharmacy_${stamp}.bak' WITH INIT;
    ALTER DATABASE Pharmacy SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Pharmacy;
END
CREATE DATABASE Pharmacy;"

# 01_schema.sql без першого батча (CREATE DATABASE уже виконано)
sed '1,/^GO/d' lab1/01_schema.sql | sql -b -d Pharmacy -i /dev/stdin
sql -b -d Pharmacy -i /scripts/lab1/02_data.sql

for f in 04_procedures 05_functions 06_variant_09 07_variant_00; do
    if [[ "${1:-}" == "--full" ]]; then
        sql -d Pharmacy -i "/scripts/lab1/$f.sql"
    else
        sed '/^-- перевірка/,$d' "lab1/$f.sql" | sql -b -d Pharmacy -i /dev/stdin
    fi
done

echo "Pharmacy перестворено (бекап попередньої: Pharmacy_${stamp}.bak)"
