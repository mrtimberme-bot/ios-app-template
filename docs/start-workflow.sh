#!/bin/bash
# Start de Workflow Dashboard server en open de browser.
# Gebruik: bash docs/start-workflow.sh
set -e
PORT=7842
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if lsof -i ":${PORT}" -t > /dev/null 2>&1; then
  echo "  ℹ️  Server draait al op poort ${PORT}"
else
  echo "  🚀 Workflow server starten..."
  node "${SCRIPT_DIR}/workflow-server.js" &
  sleep 1
fi

open "http://localhost:${PORT}"
