from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any


@dataclass
class Ingredient:
    name: str
    amount: str

    def to_json(self) -> dict[str, Any]:
        return {"name": self.name, "amount": self.amount}

    @classmethod
    def from_json(cls, data: dict[str, Any]) -> Ingredient:
        return cls(name=str(data.get("name") or ""), amount=str(data.get("amount") or ""))


@dataclass
class Catalog:
    id: int
    name: str
    sort_order: int

    def to_json(self) -> dict[str, Any]:
        return {"id": self.id, "name": self.name, "sortOrder": self.sort_order}

    @classmethod
    def from_json(cls, data: dict[str, Any]) -> Catalog:
        return cls(
            id=int(data["id"]),
            name=str(data.get("name") or ""),
            sort_order=int(data.get("sortOrder") or 0),
        )


@dataclass
class Product:
    id: int
    catalog_id: int
    name: str
    image: str | None
    ingredients: list[Ingredient]
    cost: int
    markup: int

    @property
    def price(self) -> int:
        return self.cost + self.markup

    def to_json(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "catalogId": self.catalog_id,
            "name": self.name,
            "image": self.image,
            "ingredients": [i.to_json() for i in self.ingredients],
            "cost": self.cost,
            "markup": self.markup,
            "price": self.price,
        }

    @classmethod
    def from_json(cls, data: dict[str, Any]) -> Product:
        raw = data.get("ingredients") or []
        return cls(
            id=int(data["id"]),
            catalog_id=int(data.get("catalogId") or 0),
            name=str(data.get("name") or ""),
            image=data.get("image"),
            ingredients=[Ingredient.from_json(e) for e in raw],
            cost=int(data.get("cost") or 0),
            markup=int(data.get("markup") or 0),
        )


@dataclass
class OrderItem:
    product_id: int
    name: str
    quantity: int
    unit_price: int
    unit_cost: int

    @property
    def revenue(self) -> int:
        return self.unit_price * self.quantity

    @property
    def expense(self) -> int:
        return self.unit_cost * self.quantity

    def to_json(self) -> dict[str, Any]:
        return {
            "productId": self.product_id,
            "name": self.name,
            "quantity": self.quantity,
            "unitPrice": self.unit_price,
            "unitCost": self.unit_cost,
        }

    def to_kassa_json(self) -> dict[str, Any]:
        return {"name": self.name, "quantity": self.quantity}

    @classmethod
    def from_json(cls, data: dict[str, Any]) -> OrderItem:
        return cls(
            product_id=int(data.get("productId") or 0),
            name=str(data.get("name") or ""),
            quantity=int(data.get("quantity") or 0),
            unit_price=int(data.get("unitPrice") or 0),
            unit_cost=int(data.get("unitCost") or 0),
        )


@dataclass
class FoodOrder:
    id: int
    number: int
    created_at: datetime
    status: str
    channel: str
    phone: str
    address: str
    items: list[OrderItem] = field(default_factory=list)

    def to_json(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "number": self.number,
            "createdAt": self.created_at.isoformat(),
            "status": self.status,
            "channel": self.channel,
            "phone": self.phone,
            "address": self.address,
            "items": [i.to_json() for i in self.items],
        }

    def to_kassa_json(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "number": self.number,
            "createdAt": self.created_at.isoformat(),
            "status": self.status,
            "channel": self.channel,
            "phone": self.phone,
            "address": self.address,
            "items": [i.to_kassa_json() for i in self.items],
        }

    @classmethod
    def from_json(cls, data: dict[str, Any]) -> FoodOrder:
        raw = data.get("items") or []
        return cls(
            id=int(data["id"]),
            number=int(data.get("number") or 0),
            created_at=datetime.fromisoformat(str(data["createdAt"])),
            status=str(data.get("status") or "new"),
            channel=str(data.get("channel") or "zal"),
            phone=str(data.get("phone") or ""),
            address=str(data.get("address") or ""),
            items=[OrderItem.from_json(e) for e in raw],
        )
