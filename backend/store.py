from __future__ import annotations

import asyncio
import json
from datetime import datetime, timedelta
from pathlib import Path

from models import Catalog, FoodOrder, Ingredient, OrderItem, Product
from report import next_daily_number


class StoreException(Exception):
    def __init__(self, message: str):
        self.message = message
        super().__init__(message)


class Store:
    def __init__(self, root: Path):
        self.root = root
        self.tokens: dict[str, str] = {}
        self.catalogs: list[Catalog] = []
        self.products: list[Product] = []
        self.orders: list[FoodOrder] = []
        self._next_id = 1
        self._lock = asyncio.Lock()

    @property
    def _file(self) -> Path:
        return self.root / "store.json"

    @property
    def uploads(self) -> Path:
        return self.root / "uploads"

    async def init(self) -> None:
        self.root.mkdir(parents=True, exist_ok=True)
        self.uploads.mkdir(parents=True, exist_ok=True)
        if not self._file.exists():
            self._seed()
            await self._persist()
            return
        raw = json.loads(self._file.read_text(encoding="utf-8"))
        self._next_id = int(raw.get("nextId") or 1)
        self.catalogs = [Catalog.from_json(e) for e in (raw.get("catalogs") or [])]
        self.products = [Product.from_json(e) for e in (raw.get("products") or [])]
        self.orders = [FoodOrder.from_json(e) for e in (raw.get("orders") or [])]
        saved = raw.get("tokens") or {}
        self.tokens = {str(k): str(v) for k, v in saved.items()}

    async def _persist(self) -> None:
        payload = {
            "nextId": self._next_id,
            "tokens": self.tokens,
            "catalogs": [c.to_json() for c in self.catalogs],
            "products": [p.to_json() for p in self.products],
            "orders": [o.to_json() for o in self.orders],
        }
        tmp = Path(str(self._file) + ".tmp")
        tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        if self._file.exists():
            self._file.unlink()
        tmp.replace(self._file)

    def _id(self) -> int:
        value = self._next_id
        self._next_id += 1
        return value

    def _seed(self) -> None:
        self.catalogs = [
            Catalog(id=self._id(), name="Lavash", sort_order=0),
            Catalog(id=self._id(), name="Burger", sort_order=1),
            Catalog(id=self._id(), name="Gazaklar", sort_order=2),
            Catalog(id=self._id(), name="Ichimliklar", sort_order=3),
        ]

        def ing(name: str, amount: str = "", price: int = 0) -> Ingredient:
            return Ingredient.from_json({"name": name, "amount": amount, "price": price})

        def food(
            catalog_id: int,
            name: str,
            ingredients: list[Ingredient],
            cost: int,
            markup: int,
        ) -> Product:
            return Product(
                id=self._id(),
                catalog_id=catalog_id,
                name=name,
                image=None,
                ingredients=ingredients,
                cost=cost,
                markup=markup,
            )

        self.products = [
            food(
                self.catalogs[0].id,
                "Tovuqli lavash",
                [
                    ing("Lavash xamiri"),
                    ing("Tovuq go'shti", "120 g"),
                    ing("Pomidor", "30 g"),
                    ing("Bodring", "30 g"),
                    ing("Sous", "20 g"),
                ],
                18000,
                14000,
            ),
            food(
                self.catalogs[0].id,
                "Go'shtli lavash",
                [
                    ing("Lavash xamiri"),
                    ing("Mol go'shti", "130 g"),
                    ing("Piyoz", "20 g"),
                    ing("Pomidor", "30 g"),
                    ing("Sous", "20 g"),
                ],
                22000,
                16000,
            ),
            food(
                self.catalogs[1].id,
                "Chizburger",
                [
                    ing("Burger noni"),
                    ing("Kotlet", "100 g"),
                    ing("Sir", "20 g"),
                    ing("Salat bargi", "10 g"),
                    ing("Sous", "15 g"),
                ],
                20000,
                14000,
            ),
            food(
                self.catalogs[1].id,
                "Tovuqli burger",
                [
                    ing("Burger noni"),
                    ing("Tovuq kotlet", "110 g"),
                    ing("Salat bargi", "10 g"),
                    ing("Sous", "15 g"),
                ],
                17000,
                13000,
            ),
            food(
                self.catalogs[2].id,
                "Hot-dog",
                [
                    ing("Hot-dog noni"),
                    ing("Sosiska"),
                    ing("Ketchup", "15 g"),
                    ing("Xantal", "5 g"),
                ],
                8000,
                7000,
            ),
            food(
                self.catalogs[2].id,
                "Kartoshka fri",
                [
                    ing("Kartoshka", "150 g"),
                    ing("Yog'"),
                    ing("Tuz", "1 g"),
                ],
                6000,
                6000,
            ),
            food(
                self.catalogs[3].id,
                "Cola 0.5",
                [ing("Gazlangan ichimlik")],
                4000,
                4000,
            ),
            food(
                self.catalogs[3].id,
                "Mevali sok",
                [ing("Sok")],
                5000,
                4000,
            ),
        ]

        now = datetime.now()
        self.orders = []

        def line(product: Product, quantity: int) -> OrderItem:
            return OrderItem(
                product_id=product.id,
                name=product.name,
                quantity=quantity,
                unit_price=product.price,
                unit_cost=product.cost,
            )

        def sample(
            days_ago: int,
            status: str,
            channel: str,
            items: list[OrderItem],
            phone: str = "",
            address: str = "",
        ) -> None:
            created = now - timedelta(days=days_ago, hours=1 if days_ago == 0 else 0)
            number = (
                sum(
                    1
                    for o in self.orders
                    if o.created_at.year == created.year
                    and o.created_at.month == created.month
                    and o.created_at.day == created.day
                )
                + 1
            )
            self.orders.append(
                FoodOrder(
                    id=self._id(),
                    number=number,
                    created_at=created,
                    status=status,
                    channel=channel,
                    phone=phone,
                    address=address,
                    items=items,
                )
            )

        sample(0, "done", "zal", [line(self.products[0], 2), line(self.products[6], 1)])
        sample(0, "done", "olib_ketish", [line(self.products[2], 1), line(self.products[5], 1)])
        sample(
            0,
            "new",
            "yetkazish",
            [line(self.products[4], 2), line(self.products[6], 2)],
            phone="90 123 45 67",
            address="Chilonzor 12-kvartal, 8-uy",
        )
        sample(0, "cancelled", "zal", [line(self.products[1], 1)])
        sample(3, "done", "zal", [line(self.products[0], 1), line(self.products[3], 1)])
        sample(20, "done", "zal", [line(self.products[2], 2)])

    def list_catalogs(self) -> list[Catalog]:
        return sorted(self.catalogs, key=lambda c: c.sort_order)

    def list_products(self) -> list[Product]:
        return sorted(self.products, key=lambda p: p.name)

    def catalog_by_id(self, catalog_id: int) -> Catalog | None:
        for catalog in self.catalogs:
            if catalog.id == catalog_id:
                return catalog
        return None

    def product_by_id(self, product_id: int) -> Product | None:
        for product in self.products:
            if product.id == product_id:
                return product
        return None

    async def add_catalog(self, name: str) -> Catalog:
        async with self._lock:
            order = (max((c.sort_order for c in self.catalogs), default=-1) + 1) if self.catalogs else 0
            catalog = Catalog(id=self._id(), name=name, sort_order=order)
            self.catalogs.append(catalog)
            await self._persist()
            return catalog

    async def rename_catalog(self, catalog_id: int, name: str) -> Catalog:
        async with self._lock:
            index = next((i for i, c in enumerate(self.catalogs) if c.id == catalog_id), -1)
            if index < 0:
                raise StoreException("Katalog topilmadi")
            current = self.catalogs[index]
            next_catalog = Catalog(id=current.id, name=name, sort_order=current.sort_order)
            self.catalogs[index] = next_catalog
            await self._persist()
            return next_catalog

    async def delete_catalog(self, catalog_id: int) -> None:
        async with self._lock:
            if self.catalog_by_id(catalog_id) is None:
                raise StoreException("Katalog topilmadi")
            if any(p.catalog_id == catalog_id for p in self.products):
                raise StoreException(
                    "Katalogda taomlar bor. Avval ularni boshqa katalogga o'tkazing yoki o'chiring."
                )
            self.catalogs = [c for c in self.catalogs if c.id != catalog_id]
            await self._persist()

    async def move_catalog(self, catalog_id: int, delta: int) -> None:
        async with self._lock:
            sorted_list = self.list_catalogs()
            index = next((i for i, c in enumerate(sorted_list) if c.id == catalog_id), -1)
            target = index + delta
            if index < 0 or target < 0 or target >= len(sorted_list):
                return
            a = sorted_list[index]
            b = sorted_list[target]
            updated: list[Catalog] = []
            for c in self.catalogs:
                if c.id == a.id:
                    updated.append(Catalog(id=c.id, name=c.name, sort_order=b.sort_order))
                elif c.id == b.id:
                    updated.append(Catalog(id=c.id, name=c.name, sort_order=a.sort_order))
                else:
                    updated.append(c)
            self.catalogs = updated
            await self._persist()

    async def save_product(
        self,
        *,
        product_id: int | None,
        catalog_id: int,
        name: str,
        ingredients: list[Ingredient],
        cost: int,
        markup: int,
        image: str | None,
        keep_image: bool = False,
    ) -> Product:
        async with self._lock:
            if self.catalog_by_id(catalog_id) is None:
                raise StoreException("Katalog topilmadi")
            if product_id is None:
                product = Product(
                    id=self._id(),
                    catalog_id=catalog_id,
                    name=name,
                    image=image,
                    ingredients=ingredients,
                    cost=cost,
                    markup=markup,
                )
                self.products.append(product)
                await self._persist()
                return product

            index = next((i for i, p in enumerate(self.products) if p.id == product_id), -1)
            if index < 0:
                raise StoreException("Taom topilmadi")
            previous = self.products[index]
            next_image = previous.image if keep_image else image
            if not keep_image and previous.image and previous.image != image:
                self._delete_image(previous.image)
            product = Product(
                id=product_id,
                catalog_id=catalog_id,
                name=name,
                image=next_image,
                ingredients=ingredients,
                cost=cost,
                markup=markup,
            )
            self.products[index] = product
            await self._persist()
            return product

    async def delete_product(self, product_id: int) -> None:
        async with self._lock:
            product = self.product_by_id(product_id)
            if product is None:
                raise StoreException("Taom topilmadi")
            if product.image:
                self._delete_image(product.image)
            self.products = [p for p in self.products if p.id != product_id]
            await self._persist()

    def _delete_image(self, name: str) -> None:
        path = self.uploads / name
        if path.exists():
            path.unlink()

    async def save_image(self, data: bytes, ext: str) -> str:
        async with self._lock:
            safe_ext = "png" if ext == "png" else "jpg"
            name = f"{self._id()}.{safe_ext}"
            (self.uploads / name).write_bytes(data)
            return name

    async def place_order(
        self,
        *,
        channel: str,
        phone: str,
        address: str,
        lines: list[tuple[int, int]],
        latitude: float | None = None,
        longitude: float | None = None,
    ) -> FoodOrder:
        async with self._lock:
            items: list[OrderItem] = []
            for product_id, quantity in lines:
                product = self.product_by_id(product_id)
                if product is None:
                    raise StoreException("Tanlangan taom menyuda yo'q")
                items.append(
                    OrderItem(
                        product_id=product.id,
                        name=product.name,
                        quantity=quantity,
                        unit_price=product.price,
                        unit_cost=product.counted_cost,
                    )
                )
            now = datetime.now()
            order = FoodOrder(
                id=self._id(),
                number=next_daily_number(self.orders, now),
                created_at=now,
                status="new",
                channel=channel,
                phone=phone,
                address=address,
                latitude=latitude,
                longitude=longitude,
                items=items,
            )
            self.orders.append(order)
            await self._persist()
            return order

    def list_orders(self, *, status: str | None = None, day: datetime | None = None) -> list[FoodOrder]:
        result: list[FoodOrder] = []
        for order in self.orders:
            if status and order.status != status:
                continue
            if day is not None:
                created = order.created_at.astimezone().replace(tzinfo=None) if order.created_at.tzinfo else order.created_at
                if created.year != day.year or created.month != day.month or created.day != day.day:
                    continue
            result.append(order)
        result.sort(key=lambda o: o.created_at, reverse=True)
        return result

    async def set_status(self, order_id: int, status: str) -> FoodOrder:
        async with self._lock:
            index = next((i for i, o in enumerate(self.orders) if o.id == order_id), -1)
            if index < 0:
                raise StoreException("Buyurtma topilmadi")
            current = self.orders[index]
            next_order = FoodOrder(
                id=current.id,
                number=current.number,
                created_at=current.created_at,
                status=status,
                channel=current.channel,
                phone=current.phone,
                address=current.address,
                latitude=current.latitude,
                longitude=current.longitude,
                items=current.items,
            )
            self.orders[index] = next_order
            await self._persist()
            return next_order

    async def issue_token(self, role: str) -> str:
        async with self._lock:
            token = f"{self._id():x}{int(datetime.now().timestamp() * 1_000_000):x}"
            self.tokens[token] = role
            await self._persist()
            return token

    async def revoke_token(self, token: str) -> None:
        async with self._lock:
            self.tokens.pop(token, None)
            await self._persist()


def default_data_root() -> Path:
    return Path(__file__).resolve().parent / "data"
