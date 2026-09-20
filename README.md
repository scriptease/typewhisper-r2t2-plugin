# r2t2-server

Local Confucius4-R2T2 speech recognition server on `127.0.0.1:8488`, built from
`~/github/audio.cpp` (Metal) and loading the Q8_0 GGUF hardlinked from the HuggingFace cache
into `~/github/audio.cpp/models/Confucius4-R2T2-GGUF/`.

Managed by devboard (`devboard project start r2t2`). Consumed by the TypeWhisper plugin
`typewhisper-mac/TypeWhisperPluginSDK/Plugins/R2T2Plugin`.

Smoke test:

    tail -c +45 ~/github/audio.cpp/assets/resources/sample_16k.wav > /tmp/s.pcm
    curl -N -X POST -H 'Expect:' -H 'Transfer-Encoding: chunked' -T /tmp/s.pcm \
      'http://127.0.0.1:8488/v1/audio/transcriptions/live?model=r2t2&sample_rate=16000&channels=1&sample_format=s16le'
