# Аптечна мережа - ЛР3

Лабораторна робота №3 з дисципліни «Серверні рішення баз даних».
REST-застосунок для бази даних `Pharmacy` (MS SQL Server 2022).

## Технології

- MS SQL Server 2022 у Docker, T-SQL (процедури, функції, тригери)
- Python 3.12, FastAPI, Uvicorn
- pymssql - підключення до SQL Server
- Swagger UI (вбудований у FastAPI)
- HTML, CSS, JavaScript (fetch)

## Запуск

1. Підняти SQL Server і виконати скрипти попередніх робіт (`lab1`, `lab2`, `pz3`),
   потім `01_sell_throw.sql` з цієї теки.
2. Запустити застосунок:

```bash
cd app
pip install -r requirements.txt
uvicorn main:app --reload
```

3. Сторінка - http://localhost:8000, Swagger - http://localhost:8000/docs

Параметри підключення можна змінити змінними середовища
`DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`.

## API

| Метод | Адреса | Що робить |
| --- | --- | --- |
| GET | `/api/medicines` | список препаратів |
| GET | `/api/medicines/{id}` | препарат, наявність в аптеках і продажі |
| GET | `/api/pharmacies` | список аптек |
| GET | `/api/pharmacies/{id}/employees` | працівники аптеки |
| GET | `/api/pharmacies/{id}/assortment` | таблична функція `utf_pharmacy_assortment` |
| GET | `/api/functions/cheaper-than?price=` | скалярна функція `ufn_count_cheaper_than` |
| GET | `/api/functions/employees-by-region?region=` | скалярна функція `ufn_employees_by_region` |
| POST | `/api/sales` | процедура `usp_sell_medicine` |

Помилки, які процедури й тригери генерують через `THROW` (коди від 50000),
повертаються з кодом 400 і текстом помилки, сторінка показує їх червоним.
