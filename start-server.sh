#!/usr/bin/env bash
# نظام المطعم الذكي — تشغيل الخادم (Backend + الواجهة)
# الاستخدام: ./start-server.sh        أو:        ./start-server.sh --reset
set -e
cd "$(dirname "$0")"

echo
echo "  نظام المطعم الذكي - تشغيل الخادم (Backend + الواجهة)"
echo "  ================================================="
echo

if ! command -v node >/dev/null 2>&1; then
  echo "  [خطأ] Node.js غير مثبّت. حمّل النسخة 24 أو أحدث من https://nodejs.org"
  exit 1
fi

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_MAJOR" -lt 24 ]; then
  echo "  [تحذير] إصدار Node الحالي ($(node --version)) أقدم من 24. قد لا يتوفر node:sqlite."
  echo
fi

echo "  المنفذ الافتراضي: 8787   |  لإعادة بناء قاعدة البيانات: ./start-server.sh --reset"
echo

node "$(dirname "$0")/server/server.js" "$@"
