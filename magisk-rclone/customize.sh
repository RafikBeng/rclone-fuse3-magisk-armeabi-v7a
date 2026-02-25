#!/system/bin/sh

MODPATH=${MODPATH:-0%/*}

set_permissions() {
  set_perm_recursive $MODPATH 0 0 0755 0644
  chmod +x $MODPATH/system/vendor/bin/*
  set_perm_recursive $MODPATH/system/vendor/bin/ 0 0 0755 0755
  chmod +x $MODPATH/sync.service.sh
}

set_permissions

RCLONEPROP="${MODPATH}/module.prop"
MODULE_CONFIG="/data/adb/modules/rclone/conf"

if [ -d "$MODULE_CONFIG" ] ; then
  ui_print "✅ Configuration directory ${MODULE_CONFIG} detected, copied to module directory"
  cp -r "$MODULE_CONFIG" "$MODPATH/"
  sed -i 's/^description=\(.\{1,4\}| \)\?/description=✅| /' "$RCLONEPROP"
else
  ui_print "⚙️ No config file detected. Configure via command line or web."
  ui_print " Web GUI: Tap Action to access the corresponding port"
  ui_print " CLI (root): Run rclone-config to start setup"
  sed -i 's/^description=\(.\{1,4\}| \)\?/description=⚙️| /' "$RCLONEPROP"
fi
