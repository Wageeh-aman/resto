@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo.
echo   نظام المطعم الذكي - تشغيل الخادم (Backend + الواجهة)
echo   =================================================
echo.

where node >nul 2>nul
if errorlevel 1 (
  echo   [خطأ] Node.js غير مثبّت. حمّل النسخة 24 أو أحدث من https://nodejs.org
  echo.
  pause
  exit /b 1
)

echo   المنفذ الافتراضي: 8787   ^|  لإعادة بناء قاعدة البيانات: start-server.cmd --reset
echo.

node "%~dp0server\server.js" %*

echo.
echo   توقف الخادم.
pause
