# producer.py
import json
import time
import random
from datetime import datetime
import valkey

# Valkey connection
valkey_client = valkey.Valkey(
    host='localhost',  # If using SSH tunnel
    port=6379,
    decode_responses=True,  # Automatically decode response bytes to str
    ssl=True
)

def generate_mock_event():
    """Generate a mock event"""
    event_types = ['user_signup', 'purchase', 'page_view', 'logout']
    user_ids = list(range(1, 1001))  # User IDs from 1 to 1000
    
    event = {
        'event_id': str(random.randint(1000000, 9999999)),
        'event_type': random.choice(event_types),
        'user_id': random.choice(user_ids),
        'timestamp': datetime.now().isoformat(),
        'data': {
            'ip_address': f'192.168.{random.randint(1, 255)}.{random.randint(1, 255)}',
            'browser': random.choice(['Chrome', 'Firefox', 'Safari']),
            'country': random.choice(['US', 'UK', 'CA', 'AU', 'IN'])
        }
    }
    return event

def main():
    print("Starting event producer...")
    counter = 0
    
    try:
        while True:
            # Generate and publish event
            event = generate_mock_event()
            event_json = json.dumps(event)
            
            # Push to Valkey list
            valkey_client.lpush('event_queue', event_json)
            
            counter += 1
            print(f"Published event {counter}: {event['event_type']} for user {event['user_id']}")
            
            # Random delay between 1-5 seconds
            delay = random.uniform(1, 5)
            time.sleep(delay)
            
    except KeyboardInterrupt:
        print("\nStopping event producer...")
    except valkey.ValkeyError as e:
        print(f"Valkey error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")

if __name__ == "__main__":
    main()
