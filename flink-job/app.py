import json
from kafka import KafkaConsumer, KafkaProducer

consumer = KafkaConsumer(
    'retail_orders',
    bootstrap_servers='kafka:9092',
    value_deserializer=lambda m: json.loads(m.decode('utf-8')),
    group_id='flink-validator'
)

producer = KafkaProducer(
    bootstrap_servers='kafka:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

def is_valid(order):
    required = ['order_id', 'user_id', 'total', 'created_at', 'channel']
    return all(k in order for k in required) and order['total'] >= 0

for msg in consumer:
    order = msg.value
    if is_valid(order):
        producer.send('clean_orders', order)
    else:
        order['error'] = 'invalid_schema_or_negative_total'
        producer.send('error_orders', order)
