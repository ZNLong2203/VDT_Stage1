import json
import time
import random
from datetime import datetime
from kafka import KafkaProducer

time.sleep(5)

producer = KafkaProducer(
    bootstrap_servers='kafka:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

actions = ["view", "add_to_cart", "purchase"]
products = [f"P{str(i).zfill(4)}" for i in range(1, 101)]
locations = ["Hanoi", "HCM", "Da Nang", "Can Tho", "Hai Phong"]

while True:
    event = {
        "user_id": f"user_{random.randint(1, 1000)}",
        "product_id": random.choice(products),
        "action": random.choice(actions),
        "location": random.choice(locations),
        "event_time": int(time.time() * 1000)
    }
    producer.send("user_events", event)
    print("Sent:", event)
    time.sleep(1)
