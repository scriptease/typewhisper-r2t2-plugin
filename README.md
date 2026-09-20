# TypeWhisper R2T2 Plugin

On-device real-time transcription for [TypeWhisper](https://github.com/TypeWhisper/typewhisper-mac)
with [Confucius4-R2T2](https://github.com/netease-youdao/Confucius4-R2T2), served locally by
[audio.cpp](https://github.com/0xShug0/audio.cpp) on Metal. No cloud, no API key.

- `plugin/` — the TypeWhisper transcription engine plugin (Swift). See `plugin/README.md` for the
  wire protocol, settings, and measured latency.
- `patches/` — one patch that registers the plugin's SwiftPM and Xcode targets in a
  `typewhisper-mac` checkout.
- `server/` — audio.cpp server config and launcher for the R2T2 GGUF.

## Requirements

- macOS 14+, Apple silicon
- TypeWhisper 1.7.0 or newer
- audio.cpp built with Metal, including the live-route `prompt` parameter
  ([PR #618](https://github.com/0xShug0/audio.cpp/pull/618)); without it the plugin still
  transcribes, but dictionary terms are not forwarded as recognition context

## Server

```sh
git clone --recurse-submodules https://github.com/0xShug0/audio.cpp
cd audio.cpp && scripts/build_metal.sh --build-type Release --deployment-build
```

Fetch the GGUF (Q8_0 or F16; audio.cpp rejects lower quantizations) and make sure the file the
server opens ends in `.gguf` — HuggingFace cache symlinks resolve to extension-less blobs that
audio.cpp cannot identify, so hardlink or copy it:

```sh
hf download davidxifeng/Confucius4-R2T2-gguf r2t2-q8_0.gguf
ln "$(readlink -f ~/.cache/huggingface/hub/models--davidxifeng--Confucius4-R2T2-gguf/snapshots/*/r2t2-q8_0.gguf)" \
   models/Confucius4-R2T2-GGUF/r2t2-q8_0.gguf
```

Copy `server/server.json.example` to `server/server.json` and point `path` at that GGUF.
`start.sh` runs the `audiocpp_server` sitting next to it (as shipped in the release archive);
name your own build with `AUDIOCPP_SERVER`:

```sh
AUDIOCPP_SERVER=/path/to/audio.cpp/build/macos-metal-release/bin/audiocpp_server server/start.sh
```

Smoke test:

```sh
tail -c +45 audio.cpp/assets/resources/sample_16k.wav > /tmp/s.pcm
curl -N -X POST -H 'Expect:' -H 'Transfer-Encoding: chunked' -T /tmp/s.pcm \
  'http://127.0.0.1:8488/v1/audio/transcriptions/live?model=r2t2&sample_rate=16000&channels=1&sample_format=s16le'
```

## Plugin

Prebuilt `R2T2Plugin.bundle` and a server archive are attached to each
[release](https://github.com/scriptease/typewhisper-r2t2-plugin/releases). Both are ad-hoc signed,
not notarized, so clear the quarantine flag after unzipping:

```sh
xattr -dr com.apple.quarantine R2T2Plugin.bundle
cp -R R2T2Plugin.bundle ~/Library/Application\ Support/TypeWhisper/Plugins/
```

To build it yourself against a `typewhisper-mac` checkout:

```sh
git clone https://github.com/TypeWhisper/typewhisper-mac
cp -R plugin/ typewhisper-mac/TypeWhisperPluginSDK/Plugins/R2T2Plugin/
cd typewhisper-mac && git apply ../patches/0001-register-r2t2-plugin-targets.patch
xcodebuild -skipPackagePluginValidation -project TypeWhisper.xcodeproj -target R2T2Plugin \
  -configuration Release SYMROOT="$(pwd)/build" \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
cp -R build/Release/R2T2Plugin.bundle ~/Library/Application\ Support/TypeWhisper/Plugins/
```

Restart TypeWhisper, then pick **Confucius4-R2T2** as the transcription engine and confirm the
server URL (`http://127.0.0.1:8488`) and model id (`r2t2`) with **Test Connection**.

## License

GPL-3.0-or-later, matching TypeWhisper, whose plugin SDK this links against.
