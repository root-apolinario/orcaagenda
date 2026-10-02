// Optional Edge Function: validates a user-supplied public URL before any metadata workflow.
// Deploy with: supabase functions deploy safe-url-check
// It deliberately does NOT scrape Google Maps, bypass controls, or harvest directories.

const privateHost = /^(localhost|0\.0\.0\.0|127\.|10\.|192\.168\.|169\.254\.|172\.(1[6-9]|2\d|3[01])\.|\[::1\]|\[fc|\[fd)/i;

function isBlockedHostname(hostname: string): boolean {
  return privateHost.test(hostname) || hostname.endsWith('.local') || hostname.endsWith('.internal');
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  try {
    const { url } = await request.json() as { url?: unknown };
    if (typeof url !== 'string' || url.length > 2048) throw new Error('URL inválida.');
    const target = new URL(url);
    if (!['http:', 'https:'].includes(target.protocol) || isBlockedHostname(target.hostname)) throw new Error('Apenas URLs HTTP(S) públicas são permitidas.');
    // Do not fetch here by default. DNS rebinding and redirects require a dedicated hardened proxy.
    // The client can store the source URL for manual review without retrieving remote content.
    return Response.json({ ok: true, normalized_url: target.toString(), message: 'URL aceita para revisão manual.' });
  } catch (error) {
    return Response.json({ ok: false, error: error instanceof Error ? error.message : 'Falha de validação.' }, { status: 400 });
  }
});
