from __future__ import annotations

import base64
import mimetypes
import os
import re
from contextlib import asynccontextmanager
from datetime import datetime
from pathlib import Path
from typing import Any

from fastapi import FastAPI, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse, PlainTextResponse

from models import Ingredient, measure_of
from report import build_report
from store import Store, StoreException, default_data_root

ADMIN_PIN = os.environ.get("ADMIN_PIN", "2468")
KASSA_PIN = os.environ.get("KASSA_PIN", "1357")
PORT = int(os.environ.get("PORT", "8080"))

store = Store(default_data_root())
WEB_ROOT = Path(__file__).resolve().parent.parent / "app" / "build" / "web"


@asynccontextmanager
async def lifespan(_: FastAPI):
    await store.init()
    print(f"TEZ FOOD FastAPI ishlayapti: http://0.0.0.0:{PORT}")
    print(f"Shu kompyuterda: http://localhost:{PORT}")
    print(f"Admin PIN: {ADMIN_PIN}")
    print(f"Kassa PIN: {KASSA_PIN}")
    if not WEB_ROOT.exists():
        print("Web ilova hali yig'ilmagan. app papkasida: flutter build web")
    yield


app = FastAPI(title="TEZ FOOD", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["Origin", "Content-Type", "Authorization"],
)


def _error(status: int, message: str) -> JSONResponse:
    return JSONResponse({"error": message}, status_code=status)


def _json(body: Any, status: int = 200) -> JSONResponse:
    return JSONResponse(body, status_code=status)


def _token(request: Request) -> str | None:
    header = request.headers.get("authorization")
    if not header:
        return None
    if not header.lower().startswith("bearer "):
        return None
    return header[7:].strip()


def _require(request: Request, roles: set[str]) -> JSONResponse | None:
    token = _token(request)
    role = store.tokens.get(token) if token else None
    if role is None or role not in roles:
        return _error(401, "Bu bo'lim uchun PIN kiriting")
    return None


def _name(value: Any, *, label: str, max_len: int = 40) -> str:
    name = str(value or "").strip()
    if not name:
        raise StoreException(f"{label} yozilmagan")
    if len(name) > max_len:
        raise StoreException(f"{label} {max_len} ta belgidan oshmasin")
    return name


def _money(value: Any, *, label: str) -> int:
    if isinstance(value, bool):
        raise StoreException(f"{label} raqam bo'lsin")
    if isinstance(value, int):
        if value < 0:
            raise StoreException(f"{label} manfiy bo'lmasin")
        return value
    if isinstance(value, float):
        if value < 0:
            raise StoreException(f"{label} manfiy bo'lmasin")
        return round(value)
    raise StoreException(f"{label} raqam bo'lsin")


def _coord(value: Any, *, min_v: float, max_v: float, label: str) -> float | None:
    if value is None:
        return None
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        number = float(value)
    else:
        try:
            number = float(str(value))
        except ValueError as exc:
            raise StoreException(f"{label} noto'g'ri") from exc
    if number < min_v or number > max_v:
        raise StoreException(f"{label} noto'g'ri")
    return number


def _ingredients(raw: Any) -> list[Ingredient]:
    if raw is None:
        return []
    if not isinstance(raw, list):
        raise StoreException("Masalliqlar ro'yxati noto'g'ri")
    if len(raw) > 30:
        raise StoreException("Masalliqlar 30 tadan oshmasin")
    items: list[Ingredient] = []
    for entry in raw:
        if not isinstance(entry, dict):
            raise StoreException("Masalliq noto'g'ri")
        name = str(entry.get("name") or "").strip()
        if not name:
            continue
        price = 0 if entry.get("price") is None else _money(entry.get("price"), label="Masalliq narxi")
        qty, unit = measure_of(
            amount=str(entry.get("amount") or "").strip(),
            quantity=entry.get("quantity"),
            unit=entry.get("unit"),
        )
        if qty < 0 or qty > 100000:
            raise StoreException("Miqdor noto'g'ri")
        items.append(Ingredient(name=name, quantity=qty, unit=unit, price=price))
    return items


def _parse_date(raw: str | None) -> datetime | None:
    if raw is None or len(raw) != 10:
        return None
    parts = raw.split("-")
    if len(parts) != 3:
        return None
    try:
        year, month, day = int(parts[0]), int(parts[1]), int(parts[2])
    except ValueError:
        return None
    if month < 1 or month > 12 or day < 1 or day > 31:
        return None
    try:
        return datetime(year, month, day)
    except ValueError:
        return None


def _stamp(date: datetime) -> str:
    return f"{date.year:04d}-{date.month:02d}-{date.day:02d}"


async def _store_image(raw: str, ext: str) -> str:
    cleaned = raw
    if raw.startswith("data:") and "," in raw:
        cleaned = raw.split(",", 1)[1]
    else:
        cleaned = raw.strip()
    try:
        data = base64.b64decode(cleaned, validate=False)
    except Exception as exc:
        raise StoreException("Rasm formati noto'g'ri") from exc
    if len(data) > 2_500_000:
        raise StoreException("Rasm 2.5 MB dan kichik bo'lsin")
    safe = "png" if ext.lower() == "png" else "jpg"
    return await store.save_image(data, safe)


@app.exception_handler(StoreException)
async def store_exception_handler(_: Request, exc: StoreException):
    return _error(400, exc.message)


@app.get("/api/health")
async def health():
    return {"ok": True, "name": "TEZ FOOD"}


@app.post("/api/auth/login")
async def login(request: Request):
    try:
        body = await request.json()
        if not isinstance(body, dict):
            body = {}
    except Exception:
        body = {}
    role = str(body.get("role") or "")
    pin = str(body.get("pin") or "")
    if role == "admin" and pin == ADMIN_PIN:
        token = await store.issue_token("admin")
        return {"token": token, "role": "admin"}
    if role == "kassa" and pin == KASSA_PIN:
        token = await store.issue_token("kassa")
        return {"token": token, "role": "kassa"}
    return _error(401, "PIN noto'g'ri")


@app.post("/api/auth/logout")
async def logout(request: Request):
    token = _token(request)
    if token:
        await store.revoke_token(token)
    return {"ok": True}


@app.get("/api/catalogs")
async def list_catalogs():
    return [c.to_json() for c in store.list_catalogs()]


@app.post("/api/catalogs")
async def create_catalog(request: Request):
    denied = _require(request, {"admin"})
    if denied:
        return denied
    body = await request.json()
    name = _name(body.get("name"), label="Katalog nomi")
    catalog = await store.add_catalog(name)
    return _json(catalog.to_json(), status=201)


@app.put("/api/catalogs/{catalog_id}")
async def rename_catalog(catalog_id: int, request: Request):
    denied = _require(request, {"admin"})
    if denied:
        return denied
    body = await request.json()
    name = _name(body.get("name"), label="Katalog nomi")
    catalog = await store.rename_catalog(catalog_id, name)
    return catalog.to_json()


@app.delete("/api/catalogs/{catalog_id}")
async def delete_catalog(catalog_id: int, request: Request):
    denied = _require(request, {"admin"})
    if denied:
        return denied
    await store.delete_catalog(catalog_id)
    return {"ok": True}


@app.post("/api/catalogs/{catalog_id}/move")
async def move_catalog(catalog_id: int, request: Request):
    denied = _require(request, {"admin"})
    if denied:
        return denied
    body = await request.json()
    direction = str(body.get("direction") or "")
    delta = -1 if direction == "up" else 1 if direction == "down" else 0
    if delta == 0:
        return _error(400, "Yo'nalish noto'g'ri")
    await store.move_catalog(catalog_id, delta)
    return [c.to_json() for c in store.list_catalogs()]


@app.get("/api/products")
async def list_products():
    return [p.to_json() for p in store.list_products()]


@app.post("/api/products")
async def create_product(request: Request):
    return await _save_product(request)


@app.put("/api/products/{product_id}")
async def update_product(product_id: int, request: Request):
    return await _save_product(request, product_id=product_id)


async def _save_product(request: Request, product_id: int | None = None):
    denied = _require(request, {"admin"})
    if denied:
        return denied
    body = await request.json()
    name = _name(body.get("name"), label="Taom nomi", max_len=80)
    catalog_id = _money(body.get("catalogId"), label="Katalog")
    cost = _money(body.get("cost"), label="Xarajat")
    markup = _money(body.get("markup"), label="Ustama")
    if cost > 100_000_000 or markup > 100_000_000:
        return _error(400, "Summa juda katta")
    ingredients = _ingredients(body.get("ingredients"))
    priced = sum(item.price for item in ingredients)
    stored_cost = priced if priced > 0 else cost
    if stored_cost > 100_000_000:
        return _error(400, "Summa juda katta")
    image: str | None = None
    keep_image = True
    if "imageBase64" in body:
        keep_image = False
        raw = body.get("imageBase64")
        if isinstance(raw, str) and raw.strip():
            image = await _store_image(raw, str(body.get("imageExt") or "jpg"))
    product = await store.save_product(
        product_id=product_id,
        catalog_id=catalog_id,
        name=name,
        ingredients=ingredients,
        cost=stored_cost,
        markup=markup,
        image=image,
        keep_image=keep_image and product_id is not None,
    )
    return _json(product.to_json(), status=201 if product_id is None else 200)


@app.delete("/api/products/{product_id}")
async def delete_product(product_id: int, request: Request):
    denied = _require(request, {"admin"})
    if denied:
        return denied
    await store.delete_product(product_id)
    return {"ok": True}


@app.post("/api/orders")
async def place_order(request: Request):
    body = await request.json()
    channel = str(body.get("channel") or "zal")
    if channel not in {"zal", "olib_ketish", "yetkazish"}:
        return _error(400, "Buyurtma turi noto'g'ri")
    phone = str(body.get("phone") or "").strip()
    address = str(body.get("address") or "").strip()
    latitude: float | None = None
    longitude: float | None = None
    if channel == "yetkazish":
        digits = re.sub(r"\D", "", phone)
        if len(digits) < 9:
            return _error(400, "Yetkazish uchun telefon kiriting")
        if len(address) < 5:
            return _error(400, "Yetkazish manzilini kiriting")
        latitude = _coord(body.get("latitude"), min_v=-90, max_v=90, label="Kenglik")
        longitude = _coord(body.get("longitude"), min_v=-180, max_v=180, label="Uzunlik")
        if (latitude is None) != (longitude is None):
            return _error(400, "Joylashuv noto'g'ri")
    raw_lines = body.get("items")
    if not isinstance(raw_lines, list) or not raw_lines:
        return _error(400, "Kamida bitta taom tanlang")
    if len(raw_lines) > 40:
        return _error(400, "Juda ko'p taom")
    lines: list[tuple[int, int]] = []
    for raw in raw_lines:
        if not isinstance(raw, dict):
            return _error(400, "Buyurtma tarkibi noto'g'ri")
        product_id = _money(raw.get("productId"), label="Taom")
        quantity = _money(raw.get("quantity"), label="Soni")
        if quantity < 1 or quantity > 99:
            return _error(400, "Soni 1 dan 99 gacha bo'lsin")
        lines.append((product_id, quantity))
    order = await store.place_order(
        channel=channel,
        phone=phone,
        address=address,
        lines=lines,
        latitude=latitude,
        longitude=longitude,
    )
    return _json(order.to_json(), status=201)


@app.get("/api/orders")
async def list_orders(request: Request, status: str | None = None, day: str | None = None):
    denied = _require(request, {"admin", "kassa"})
    if denied:
        return denied
    orders = store.list_orders(status=status, day=_parse_date(day))
    return [o.to_kassa_json() for o in orders]


@app.patch("/api/orders/{order_id}")
async def set_status(order_id: int, request: Request):
    denied = _require(request, {"admin", "kassa"})
    if denied:
        return denied
    body = await request.json()
    status = str(body.get("status") or "")
    if status not in {"new", "done", "cancelled"}:
        return _error(400, "Holat noto'g'ri")
    order = await store.set_status(order_id, status)
    return order.to_kassa_json()


@app.get("/api/reports")
async def reports(
    request: Request,
    from_: str | None = Query(None, alias="from"),
    to: str | None = None,
):
    denied = _require(request, {"admin"})
    if denied:
        return denied
    start = _parse_date(from_)
    end = _parse_date(to)
    if start is None or end is None:
        return _error(400, "Sana from va to ko'rinishida yyyy-MM-dd bo'lsin")
    if end < start:
        return _error(400, "Tugash sanasi boshlanishidan oldin")
    report = build_report(store.orders, start, end)
    return {"from": _stamp(start), "to": _stamp(end), **report.to_json()}


@app.get("/uploads/{filename}")
async def get_upload(filename: str):
    if not filename or ".." in filename or "/" in filename or "\\" in filename:
        return PlainTextResponse("Ruxsat yo'q", status_code=403)
    path = store.uploads / filename
    if not path.exists() or not path.is_file():
        return PlainTextResponse("Rasm topilmadi", status_code=404)
    media = "image/png" if filename.lower().endswith(".png") else "image/jpeg"
    return FileResponse(path, media_type=media, headers={"Cache-Control": "public, max-age=86400"})


@app.api_route("/{full_path:path}", methods=["GET", "HEAD"])
async def spa_fallback(full_path: str):
    if full_path.startswith("api/") or full_path == "api":
        return _error(404, "Topilmadi")
    if not WEB_ROOT.exists():
        return PlainTextResponse(
            "TEZ FOOD server ishlayapti. Ilovani ko'rish uchun app papkasida flutter build web qiling "
            "yoki ishlab chiqishda flutter run -d chrome ishlating.",
            status_code=404,
        )
    candidate = (WEB_ROOT / full_path).resolve()
    root = WEB_ROOT.resolve()
    try:
        candidate.relative_to(root)
        inside = True
    except ValueError:
        inside = False
    if inside and candidate.is_file():
        media, _ = mimetypes.guess_type(str(candidate))
        return FileResponse(candidate, media_type=media or "application/octet-stream")
    if "." in Path(full_path).name:
        return PlainTextResponse("Topilmadi", status_code=404)
    index = WEB_ROOT / "index.html"
    if not index.exists():
        return PlainTextResponse("index.html topilmadi", status_code=404)
    return FileResponse(index, media_type="text/html; charset=utf-8")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=PORT,
        reload=False,
    )
