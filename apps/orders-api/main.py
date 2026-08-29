import json
import logging
import os
import random
import time
from contextlib import contextmanager

import psycopg2
import psycopg2.pool
from fastapi import FastAPI, HTTPException, Response, Request
from prometheus_client import Histogram, Counter, generate_latest, CONTENT_TYPE_LATEST
from pydantic import BaseModel



class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            "level": record.levelname.lower(),
            "msg": record.getMessage(),
            "logger": record.name,
        }
        if hasattr(record, "extra_fields"):
            payload.update(record.extra_fields)
        return json.dumps(payload)


logger = logging.getLogger("orders-api")
handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logger.addHandler(handler)
logger.setLevel(logging.INFO)


def log_query(sql: str, duration_ms: float, rows: int = None, error: str = None):
    extra = {"sql": sql, "duration_ms": round(duration_ms, 2)}
    if rows is not None:
        extra["rows"] = rows
    if error:
        extra["error"] = error
        logger.error("query falhou", extra={"extra_fields": extra})
    else:
        logger.info("query executada", extra={"extra_fields": extra})



DB_QUERY_DURATION = Histogram(
    "db_query_duration_seconds",
    "Duracao das queries no banco",
    ["operation", "table"],
)
HTTP_REQUEST_DURATION = Histogram(
    "http_request_duration_seconds",
    "Duracao das requisicoes HTTP",
    ["method", "path", "status"],
)
DB_QUERY_ERRORS = Counter(
    "db_query_errors_total",
    "Total de queries que falharam",
    ["operation", "table"],
)


DB_HOST = os.environ.get("DB_HOST", "postgres")
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ.get("DB_NAME", "ordersdb")
DB_USER = os.environ.get("DB_USER", "orders_api")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "")

pool = psycopg2.pool.SimpleConnectionPool(
    1, 10,
    host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD,
)


@contextmanager
def get_cursor():
    conn = pool.getconn()
    try:
        cur = conn.cursor()
        yield conn, cur
    finally:
        pool.putconn(conn)


def run_query(operation: str, table: str, sql: str, params=None, fetch=False, commit=False):
    start = time.time()
    try:
        with get_cursor() as (conn, cur):
            cur.execute(sql, params)
            result = cur.fetchall() if fetch else None
            if commit:
                conn.commit()
            duration = (time.time() - start) * 1000
            log_query(sql, duration, rows=cur.rowcount)
            DB_QUERY_DURATION.labels(operation=operation, table=table).observe(duration / 1000)
            return result
    except Exception as e:
        duration = (time.time() - start) * 1000
        log_query(sql, duration, error=str(e))
        DB_QUERY_ERRORS.labels(operation=operation, table=table).inc()
        raise



app = FastAPI(title="orders-api")


class OrderIn(BaseModel):
    customer: str
    status: int = 0


@app.on_event("startup")
def startup():
    run_query("create_table", "orders", """
        CREATE TABLE IF NOT EXISTS orders (
            id SERIAL PRIMARY KEY,
            customer TEXT NOT NULL,
            status INT DEFAULT 0,
            created_at TIMESTAMPTZ DEFAULT now()
        )
    """, commit=True)


@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    HTTP_REQUEST_DURATION.labels(
        method=request.method, path=request.url.path, status=response.status_code
    ).observe(duration)
    return response


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/readyz")
def readyz():
    try:
        run_query("healthcheck", "orders", "SELECT 1", fetch=True)
        return {"status": "ready"}
    except Exception:
        raise HTTPException(status_code=503, detail="db unreachable")


@app.post("/orders")
def create_order(order: OrderIn):
    run_query(
        "insert", "orders",
        "INSERT INTO orders (customer, status) VALUES (%s, %s)",
        (order.customer, order.status), commit=True,
    )
    return {"message": "criado"}


@app.get("/orders")
def list_orders(limit: int = 20):
    # de vez em quando simula uma query lenta de proposito - bom pra
    # ter algo interessante pra investigar no Grafana/Loki depois
    if random.random() < 0.1:
        time.sleep(random.uniform(0.3, 1.2))
    rows = run_query(
        "select", "orders",
        "SELECT id, customer, status, created_at FROM orders ORDER BY id DESC LIMIT %s",
        (limit,), fetch=True,
    )
    return [{"id": r[0], "customer": r[1], "status": r[2], "created_at": str(r[3])} for r in rows]


@app.get("/orders/{order_id}")
def get_order(order_id: int):
    rows = run_query(
        "select", "orders",
        "SELECT id, customer, status, created_at FROM orders WHERE id = %s",
        (order_id,), fetch=True,
    )
    if not rows:
        raise HTTPException(status_code=404, detail="pedido nao encontrado")
    r = rows[0]
    return {"id": r[0], "customer": r[1], "status": r[2], "created_at": str(r[3])}


@app.patch("/orders/{order_id}")
def update_order_status(order_id: int, status: int):
    run_query(
        "update", "orders",
        "UPDATE orders SET status = %s WHERE id = %s",
        (status, order_id), commit=True,
    )
    return {"message": "atualizado"}


@app.delete("/orders/{order_id}")
def delete_order(order_id: int):
    run_query(
        "delete", "orders",
        "DELETE FROM orders WHERE id = %s",
        (order_id,), commit=True,
    )
    return {"message": "removido"}