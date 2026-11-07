/** BIG-BUS Travel Cloudflare Worker entrypoint.
 * Safe skeleton: no booking writes until real authentication and seat validation are implemented.
 * D1 database binding name for future use: DB.
 */
export interface Env { DB: D1Database }
export default {
 async fetch(request: Request, _env: Env): Promise<Response> {
  const url = new URL(request.url);
  if (request.method === 'GET' && url.pathname === '/api/health') {
   return Response.json({ ok: true, service: 'BIG-BUS Travel API', stage: 'migration' }, {
    headers: { 'Cache-Control': 'no-store' }
   });
  }
  if (url.pathname.startsWith('/api/')) {
   return Response.json({ error: 'API ще готується; живі бронювання не приймаються.' }, { status: 503 });
  }
  return Response.json({ error: 'Not found' }, { status: 404 });
 }
};
