# P2P collaborative document types

```yml
version: 1
messages:
    yjs_update:
        direction: c2s_broadcast
        fields:
            session_id: string
            update_b64: base64
            ts: integer (epoch_ms)
        limits:
            max_size_bytes: 32768 # decoded update bytes (not base64 wire length)
            rate:
                messages_per_second: 10
    yjs_bootstrap_request:
        direction: c2s
        fields:
            session_id: string (implicit via channel)
    yjs_bootstrap:
        direction: s2c
        fields:
            base_b64: base64
            updates: [base64]
            vector: object
            seq_max: integer
    presence_update:
        direction: c2s_broadcast
        fields:
            peer_id: string (server injected)
            fields: object
            ts: integer
        rate_limit_per_minute: 60
    movement_update:
        direction: c2s_broadcast
        fields:
            peer_id: string (server injected)
            entities: array
            seq: integer
            ts: integer
        rate_limit_per_second: 30
    session_finalize:
        direction: c2s
        fields:
            session_id: string
            transient_state: object
            yjs_vector: object
            ts: integer
    session_finalized:
        direction: s2c_broadcast
        fields:
            session_id: string
            finalized_at: integer
    error:
        direction: s2c
        fields:
            code: string
            message: string
```
