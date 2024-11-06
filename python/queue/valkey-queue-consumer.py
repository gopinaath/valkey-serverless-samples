import json
import valkey
from datetime import datetime

# Valkey connection
valkey_client = valkey.Valkey(
    host='localhost',  # Using SSH tunnel
    port=6379,
    decode_responses=True,  # Automatically decode response bytes to str
    ssl=True
)

def process_event(event):
    """Process the received event"""
    try:
        event_data = json.loads(event)
        print("\nProcessing event:")
        print(f"Event ID: {event_data['event_id']}")
        print(f"Type: {event_data['event_type']}")
        print(f"User ID: {event_data['user_id']}")
        print(f"Timestamp: {event_data['timestamp']}")
        print(f"Data: {event_data['data']}")
        
        # Event processing logic goes here
        # For example, storing in database, triggering notifications, etc.
        
        return True
    except json.JSONDecodeError:
        print(f"Error decoding event: {event}")
        return False
    except KeyError as e:
        print(f"Missing required field in event: {e}")
        return False

def main():
    print("Starting event consumer...")
    print("Waiting for events...")
    
    try:
        while True:
            # Block until an event is available (timeout after 1 second)
            event = valkey_client.brpop('event_queue', timeout=1)
            
            if event is not None:
                # event is a tuple of (queue_name, value)
                _, event_data = event
                success = process_event(event_data)
                
                if success:
                    # Implement successful processing and move to a processed queue
                    pass
                else:
                    # Handle failed processing
                    # Maybe move to a dead letter queue
                    valkey_client.lpush('event_queue_failed', event_data)
    
    except KeyboardInterrupt:
        print("\nStopping event consumer...")
    except valkey.ValkeyError as e:
        print(f"Valkey error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")

if __name__ == "__main__":
    main()