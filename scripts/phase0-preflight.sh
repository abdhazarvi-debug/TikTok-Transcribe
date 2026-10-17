#!/usr/bin/env bash
set -u

# Collect environment evidence only. This does not build whisper.cpp or measure Urdu accuracy.
printf '%s\n' '== TikTok Transcript Phase 0 preflight =='
for cmd in git cmake ffmpeg c++ java sdkmanager gradle; do
  if command -v "$cmd" >/dev/null 2>&1; then
    case "$cmd" in
      git) version="$(git --version 2>&1)" ;;
      cmake) version="$(cmake --version 2>&1 | head -n 1)" ;;
      ffmpeg) version="$(ffmpeg -version 2>&1 | head -n 1)" ;;
      c++) version="$(c++ --version 2>&1 | head -n 1)" ;;
      java) version="$(java -version 2>&1 | head -n 1)" ;;
      sdkmanager|gradle) version="available on PATH" ;;
    esac
    printf 'AVAILABLE  %-12s %s\n' "$cmd" "$version"
  else
    printf 'NOT_FOUND  %s\n' "$cmd"
  fi
done

printf '\n%s\n' '== Network reachability probe (optional prerequisite for source/model acquisition) =='
if command -v curl >/dev/null 2>&1 && curl -I -L --max-time 10 -sS https://github.com >/dev/null; then
  printf '%s\n' 'NETWORK_PROBE=PASS (GitHub homepage reachable; model acquisition still must be tested)'
else
  printf '%s\n' 'NETWORK_PROBE=BLOCKED (GitHub not reachable from this environment)'
fi

printf '\n%s\n' 'This preflight is not Phase 0a completion. Pin source, download and hash model files, run benchmark clips, record WER/CER, and make an evidence-based Go/No-Go decision.\n'
