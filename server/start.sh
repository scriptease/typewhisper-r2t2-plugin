#!/bin/sh
# Confucius4-R2T2 streaming ASR via audio.cpp (Metal). Used by the TypeWhisper R2T2 plugin.
# Live endpoint: POST http://127.0.0.1:8488/v1/audio/transcriptions/live?model=r2t2
# Set AUDIOCPP_SERVER to use an audiocpp_server built elsewhere.
cd "$(dirname "$0")"
exec "${AUDIOCPP_SERVER:-./audiocpp_server}" --config server.json
