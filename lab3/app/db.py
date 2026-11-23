"""Підключення до MS SQL Server (БД Pharmacy) через pymssql."""
import os

import pymssql

CONFIG = {
    "server": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", "1433")),
    "user": os.getenv("DB_USER", "sa"),
    "password": os.getenv("DB_PASSWORD", "SrbdLab2026!"),
    "database": os.getenv("DB_NAME", "Pharmacy"),
}


class DbError(Exception):
    """Помилка з боку сервера БД."""

    def __init__(self, code, message):
        super().__init__(message)
        self.code = code
        self.message = message
        # 50000 і більше - наші помилки з процедур і тригерів (THROW)
        self.user_error = code >= 50000


def query(sql, params=None, commit=False):
    """Виконати запит і повернути рядки як список словників."""
    try:
        with pymssql.connect(**CONFIG) as conn:
            with conn.cursor(as_dict=True) as cur:
                cur.execute(sql, params)
                rows = cur.fetchall() if cur.description else []
            if commit:
                conn.commit()
            return rows
    except pymssql.DatabaseError as e:
        code, text = e.args[0], e.args[1]
        if isinstance(text, bytes):
            text = text.decode("utf-8", errors="replace")
        # pymssql дописує службовий текст DB-Lib - його відкидаємо
        raise DbError(code, text.split("DB-Lib error")[0].strip())
