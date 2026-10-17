# ============================================================================
#  نظام المطعم الذكي — صورة النشر
#  بلا أي مكتبات خارجية: لا npm install، فقط Node 24 + الملفات.
# ============================================================================
FROM node:24-alpine

ENV NODE_ENV=production \
    PORT=8787 \
    HOST=0.0.0.0 \
    DATA_DIR=/app/server/data

WORKDIR /app

# نسخ الكود (الملفات المطلوبة فقط — انظر .dockerignore)
COPY package.json ./
COPY smart-restaurant.html ./
COPY server/ ./server/

# مجلد البيانات (يُربط في الإنتاج كـ volume للاحتفاظ بقاعدة البيانات والصور)
VOLUME ["/app/server/data"]

EXPOSE 8787

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||8787)+'/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "server/server.js"]
