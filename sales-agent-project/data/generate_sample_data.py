"""데모용 샘플 판매 데이터를 100건 생성"""
import csv
import random
from datetime import date, timedelta

random.seed(42)

REGIONS = ["APAC", "EMEA", "AMER"]
CATEGORY_PRODUCTS = {
    "Electronics": ["Wireless Mouse", "Keyboard", "Monitor", "Webcam", "USB Hub"],
    "Home": ["Desk Lamp", "Air Purifier", "Humidifier", "Standing Desk", "Office Chair"],
    "Office Supplies": ["Notebook Set", "Sticky Notes", "Pen Pack", "Whiteboard", "Stapler"],
}
UNIT_PRICES = {
    "Wireless Mouse": 25000, "Keyboard": 45000, "Monitor": 320000,
    "Webcam": 68000, "USB Hub": 22000,
    "Desk Lamp": 18000, "Air Purifier": 150000, "Humidifier": 39000,
    "Standing Desk": 480000, "Office Chair": 210000,
    "Notebook Set": 8000, "Sticky Notes": 3500, "Pen Pack": 6000,
    "Whiteboard": 55000, "Stapler": 9000,
}

START_DATE = date(2026, 1, 1)
NUM_ROWS = 100
OUTPUT_PATH="data/sample_sales.csv"

def generate_rows(n: int):
    rows = []
    for i in range(1, n+1):
        order_date = START_DATE + timedelta(days=random.randint(0, 59))
        region = random.choice(REGIONS)
        category = random.choice(list(CATEGORY_PRODUCTS.keys()))
        product = random.choice(CATEGORY_PRODUCTS[category])
        quantity = random.randint(1, 8)
        rows.append(
            [
                1000 + i,
                order_date.isoformat(),
                region,
                category,
                product,
                quantity,
                UNIT_PRICES[product]
            ]
        )
    return rows

def main():
    rows = generate_rows(NUM_ROWS)
    with open(OUTPUT_PATH, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(
            ["order_id", "order_date", "region", "category", "product", "quantity", "unit_price"]
        )
        writer.writerows(rows)
    print(f"{OUTPUT_PATH} 에 {len(rows)}건 생성 완료")
    

if __name__ == "__main__":
    main()