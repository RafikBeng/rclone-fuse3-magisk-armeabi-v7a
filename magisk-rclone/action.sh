#!/system/bin/sh

MODPATH=${MODPATH:-/data/adb/modules/rclone}

echo "Loading Environment Variables"
echo "  * Default (Predefined): $MODPATH/env"
set -a && . "$MODPATH/env" && set +a
echo "  * Custom (Customized): $RCLONE_CONFIG_DIR/env"

# Check and stop any running RClone Web process
function check_stop_web_pid() {
  if [ -f "$RCLONEWEB_PID" ]; then
    PID=$(cat "$RCLONEWEB_PID")
    if ps -p "$PID" > /dev/null 2>&1; then
      echo "RClone Web GUI is already running with PID($PID). Stopping it..."
      pkill -P $PID
      rm -f "$RCLONEWEB_PID"
      echo "RClone Web GUI stopped successfully."
      echo "RClone Web GUI closed successfully."
      return 1
    else
      echo "Found a stale PID file. Removing it..."
      rm -f "$RCLONEWEB_PID"
    fi
  fi
  return 0
}

function start_web() {
  # Build the access URL for the RClone Web GUI
  if [[ "${RCLONE_RC_ADDR}" == :* ]]; then
    LOCAL_IP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
    URL="http://${LOCAL_IP:-localhost}${RCLONE_RC_ADDR}"
  else
    URL=${RCLONE_RC_ADDR}
  fi

  set -e
  echo "RClone Web GUI will start at: ${URL}"
  echo "Open the following URL in your browser to access the web GUI:"
  echo "Open in browser: ${URL} to configure"

  nohup rclone-web > "$RCLONE_LOG_DIR/rclone-web.log" &
  PID=$!
  echo "$PID" > "$RCLONEWEB_PID"
  echo "RClone Web GUI started with PID($PID)."
  echo "Web GUI started at $URL"
}

if check_stop_web_pid; then
  start_web
fi
