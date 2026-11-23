#!/usr/bin/env bash
# ПЗ1. Створення БД Pharmacy з нуля: скрипти lab1, потім pz1/01_prepare.sql.
# Запуск: bash pz1/rebuild.sh   (з теки ~/nure/srbd, контейнер має бути піднятий)
# Об'єкти lab2, pz3 і lab3 після цього треба створювати заново.
set -eu
SQL="docker compose exec -T mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P SrbdLab2026! -C -b"

run() { # $1 = назва кроку, далі - команда; вивід показуємо лише при помилці
  local name=$1 out
  shift
  echo "== $name"
  if ! out=$("$@" 2>&1); then
    echo "$out"
    exit 1
  fi
}

run "Pharmacy: DROP + CREATE" $SQL -Q "
  IF DB_ID(N'Pharmacy') IS NOT NULL BEGIN
    ALTER DATABASE Pharmacy SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Pharmacy;
  END
  CREATE DATABASE Pharmacy;"

# у скриптах lab1 немає USE Pharmacy, тому БД задаємо через -d,
# а CREATE DATABASE з першого скрипта (рядки 1-2) пропускаємо
run lab1/01_schema.sql sh -c "tail -n +3 lab1/01_schema.sql | $SQL -d Pharmacy"
for f in lab1/0[2-7]_*.sql pz1/01_prepare.sql; do
  run "$f" $SQL -d Pharmacy -i "/scripts/$f"
done
echo "БД Pharmacy створено"
