"""ЛР3. REST API для БД Pharmacy.

Запуск:  uvicorn main:app --reload
Сторінка: http://localhost:8000   Swagger: http://localhost:8000/docs
"""
from pathlib import Path

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from db import DbError, query

STATIC = Path(__file__).parent / "static"

app = FastAPI(title="Pharmacy API",
              description="ЛР3: аптечна мережа, MS SQL Server")
app.mount("/static", StaticFiles(directory=STATIC), name="static")


class Sale(BaseModel):
    pharmacy_id: int
    employee_id: int
    medicine_id: int
    quantity: int = 1


@app.exception_handler(DbError)
def db_error_handler(request: Request, exc: DbError):
    # помилки з THROW - це помилки введення, інші - збій сервера
    status = 400 if exc.user_error else 500
    return JSONResponse(status_code=status,
                        content={"detail": exc.message, "code": exc.code})


@app.get("/", include_in_schema=False)
def index():
    return FileResponse(STATIC / "index.html")


@app.get("/api/medicines", tags=["Препарати"])
def get_medicines():
    return query("SELECT medicine_id, name, producer, base_price, "
                 "prescription_only FROM medicines ORDER BY name")


@app.get("/api/medicines/{medicine_id}", tags=["Препарати"])
def get_medicine(medicine_id: int):
    """Препарат, його наявність в аптеках і всі продажі."""
    rows = query("SELECT * FROM medicines WHERE medicine_id = %d",
                 medicine_id)
    if not rows:
        raise HTTPException(404, "Препарат не знайдено")
    stock = query("""
        SELECT p.pharmacy_id, p.name AS pharmacy, s.price, s.quantity
          FROM stock AS s
          JOIN pharmacies AS p ON p.pharmacy_id = s.pharmacy_id
         WHERE s.medicine_id = %d
         ORDER BY p.pharmacy_id""", medicine_id)
    sales = query("""
        SELECT o.order_id, o.order_date, p.name AS pharmacy,
               e.full_name AS employee, oi.quantity, oi.unit_price
          FROM order_items AS oi
          JOIN orders AS o ON o.order_id = oi.order_id
          JOIN pharmacies AS p ON p.pharmacy_id = o.pharmacy_id
          JOIN employees AS e ON e.employee_id = o.employee_id
         WHERE oi.medicine_id = %d
         ORDER BY o.order_id DESC""", medicine_id)
    return {"medicine": rows[0], "stock": stock, "sales": sales}


@app.get("/api/pharmacies", tags=["Аптеки"])
def get_pharmacies():
    return query("SELECT * FROM pharmacies ORDER BY pharmacy_id")


@app.get("/api/pharmacies/{pharmacy_id}/employees", tags=["Аптеки"])
def get_employees(pharmacy_id: int):
    return query("SELECT employee_id, full_name, job_title FROM employees "
                 "WHERE pharmacy_id = %d", pharmacy_id)


@app.get("/api/pharmacies/{pharmacy_id}/assortment", tags=["Функції"])
def get_assortment(pharmacy_id: int):
    """Таблична функція utf_pharmacy_assortment."""
    return query("SELECT * FROM dbo.utf_pharmacy_assortment(%d) "
                 "ORDER BY name", pharmacy_id)


@app.get("/api/functions/cheaper-than", tags=["Функції"])
def get_cheaper_than(price: float):
    """Скалярна функція ufn_count_cheaper_than."""
    rows = query("SELECT dbo.ufn_count_cheaper_than(%s) AS result", price)
    return {"price": price, "count": rows[0]["result"]}


@app.get("/api/functions/employees-by-region", tags=["Функції"])
def get_employees_by_region(region: str):
    """Скалярна функція ufn_employees_by_region."""
    rows = query("SELECT dbo.ufn_employees_by_region(%s) AS result", region)
    return {"region": region, "count": rows[0]["result"]}


@app.post("/api/sales", tags=["Процедури"])
def create_sale(sale: Sale):
    """Процедура usp_sell_medicine: новий чек з одним препаратом."""
    rows = query("EXEC usp_sell_medicine %d, %d, %d, %d",
                 (sale.pharmacy_id, sale.employee_id, sale.medicine_id,
                  sale.quantity), commit=True)
    return {"order_id": rows[0]["order_id"]}
