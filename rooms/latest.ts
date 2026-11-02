// The newest version of the game, for its title screen to say when there's an update. It's read
// from where GitHub sends "the latest release" (no key, no rate limit), kept for an hour, and
// answered with the game's page, where every build is.

/** Where GitHub sends whoever asks for the latest release: to its tag's page. */
export const LATEST = 'https://github.com/itriumid/felterra-tall-order/releases/latest';
/** Where players get it. */
export const PAGE = 'https://itrium.id/tall-order';
/** How long an answer is kept, in seconds. */
export const KEPT = 3600;

/** The version a release's address names, as `0.0.5`, or null if it names none. */
export function versionFrom(location: string | null): string | null {
	const tagged = /\/releases\/tag\/v(\d+\.\d+\.\d+)$/.exec(location ?? '');
	return tagged ? tagged[1] : null;
}

/** The answer: the newest version and where to get it, kept for an hour; or, unknown, nothing kept. */
export async function latest(ask: (url: string) => Promise<Response>): Promise<Response> {
	const sent = await ask(LATEST);
	const version = versionFrom(sent.headers.get('location'));
	if (!version) return new Response(null, { status: 503 });
	return Response.json({ version, page: PAGE }, { headers: { 'cache-control': `public, max-age=${KEPT}` } });
}
