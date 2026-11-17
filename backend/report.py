from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Any

from models import FoodOrder


@dataclass
class ProductSales:
    product_id: int
    name: str
    quantity: int
    revenue: int
    expense: int

    @property
    def profit(self) -> int:
        return self.revenue - self.expense

    @property
    def profit_percent(self) -> float:
        if self.revenue == 0:
            return 0.0
        return round(self.profit * 1000 / self.revenue) / 10

    def to_json(self) -> dict[str, Any]:
        return {
            "productId": self.product_id,
            "name": self.name,
            "quantity": self.quantity,
            "revenue": self.revenue,
            "expense": self.expense,
            "profit": self.profit,
            "profitPercent": self.profit_percent,
        }


@dataclass
class SalesReport:
    sales_count: int
    open_count: int
    cancelled_count: int
    revenue: int
    expense: int
    products: list[ProductSales]

    @property
    def profit(self) -> int:
        return self.revenue - self.expense

    @property
    def profit_percent(self) -> float:
        if self.revenue == 0:
            return 0.0
        return round(self.profit * 1000 / self.revenue) / 10

    def to_json(self) -> dict[str, Any]:
        return {
            "salesCount": self.sales_count,
            "openCount": self.open_count,
            "cancelledCount": self.cancelled_count,
            "revenue": self.revenue,
            "expense": self.expense,
            "profit": self.profit,
            "profitPercent": self.profit_percent,
            "products": [p.to_json() for p in self.products],
        }


def _same_day(a: datetime, b: datetime) -> bool:
    return a.year == b.year and a.month == b.month and a.day == b.day


def in_range(created: datetime, start: datetime, end: datetime) -> bool:
    local = created.astimezone().replace(tzinfo=None) if created.tzinfo else created
    day_start = datetime(start.year, start.month, start.day)
    day_end = datetime(end.year, end.month, end.day, 23, 59, 59, 999000)
    return day_start <= local <= day_end


def build_report(orders: list[FoodOrder], start: datetime, end: datetime) -> SalesReport:
    ranged = [o for o in orders if in_range(o.created_at, start, end)]
    cancelled = sum(1 for o in ranged if o.status == "cancelled")
    open_count = sum(1 for o in ranged if o.status == "new")
    counted = [o for o in ranged if o.status != "cancelled"]

    by_product: dict[int, ProductSales] = {}
    revenue = 0
    expense = 0

    for order in counted:
        for item in order.items:
            revenue += item.revenue
            expense += item.expense
            current = by_product.get(item.product_id)
            if current is None:
                by_product[item.product_id] = ProductSales(
                    product_id=item.product_id,
                    name=item.name,
                    quantity=item.quantity,
                    revenue=item.revenue,
                    expense=item.expense,
                )
            else:
                by_product[item.product_id] = ProductSales(
                    product_id=item.product_id,
                    name=item.name,
                    quantity=current.quantity + item.quantity,
                    revenue=current.revenue + item.revenue,
                    expense=current.expense + item.expense,
                )

    products = sorted(
        by_product.values(),
        key=lambda p: (-p.quantity, p.name),
    )

    return SalesReport(
        sales_count=len(counted),
        open_count=open_count,
        cancelled_count=cancelled,
        revenue=revenue,
        expense=expense,
        products=products,
    )


def next_daily_number(orders: list[FoodOrder], now: datetime) -> int:
    today = [
        o
        for o in orders
        if _same_day(
            o.created_at.astimezone().replace(tzinfo=None) if o.created_at.tzinfo else o.created_at,
            now.astimezone().replace(tzinfo=None) if now.tzinfo else now,
        )
    ]
    max_number = 0
    for order in today:
        if order.number > max_number:
            max_number = order.number
    return max_number + 1
