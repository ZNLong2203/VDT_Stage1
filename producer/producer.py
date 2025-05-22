import json
import random
import time
from datetime import datetime
from faker import Faker
from kafka import KafkaProducer

fake = Faker()
producer = KafkaProducer(
    bootstrap_servers='kafka:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

channels = ['web', 'mobile', 'store']

def generate_order():
    return {
        "order_id": fake.uuid4(),
        "user_id": random.randint(1000, 9999),
        "total": round(random.uniform(10, 500), 2),
        "created_at": datetime.now().isoformat(),
        "channel": random.choice(channels)
    }

if __name__ == "__main__":
    while True:
        order = generate_order()
        print(f"[SEND] {order}")
        producer.send("retail_orders", order)
        time.sleep(1)
