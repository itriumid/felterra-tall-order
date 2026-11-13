// A relay for players who can't reach each other directly: Cloudflare's TURN service, which
// carries the game between two machines whose networks let nothing else through. The room hands
// each pair of players the servers to try and a credential for the relay, made for them and
// short-lived, so the relay can't be used by anyone who was never in a room.
//
// The credential is made with a TURN key, kept in two of the Worker's secrets. Without them, or
// with Cloudflare not answering, there is no relay and nothing else changes: players find each
// other through STUN alone, as the game does by itself.
// https://developers.cloudflare.com/realtime/turn/generate-credentials/

/** The secrets a TURN key is kept in: its identifier, and the token that makes credentials with it. */
export const KEY_ID = 'TURN_KEY_ID';
export const KEY_API_TOKEN = 'TURN_KEY_API_TOKEN';
/** Where Cloudflare makes credentials: one address per key. */
export const SERVICE = 'https://rtc.live.cloudflare.com/v1/turn/keys';
/**
 * How long a credential lasts, in seconds: four hours. It has to outlast the playing, not only the
 * connecting: Cloudflare asks for longer than the relay will be used, and a relay whose credential
 * has run out can't be counted on to carry on. Four hours is a long evening's run. A guest still
 * playing after that, dropped, finds the host again through the room within the minute the game
 * gives them, and both are handed a fresh credential then.
 */
export const TIME_TO_LIVE = 4 * 60 * 60;
/** How long Cloudflare is waited for, in milliseconds, before the players go on without a relay. */
export const WAIT = 2000;
/** The most servers handed on, addresses on each, and characters in anything said of them. */
const MOST_SERVERS = 4;
const MOST_ADDRESSES = 8;
const LONGEST = 512;

/** A TURN key: its identifier and its token. */
export interface Key {
	readonly id: string;
	readonly token: string;
}

/** Servers to find a way through, as WebRTC takes them; a relay comes with a credential. */
export interface IceServer {
	urls: string[];
	username?: string;
	credential?: string;
}

/** What Cloudflare is asked with. */
export interface Asking {
	method: 'POST';
	headers: Record<string, string>;
	body: string;
	signal: AbortSignal;
}

/** The TURN key in the Worker's secrets, or null unless both halves are there. */
export function keyFrom(secrets: object): Key | null {
	const id: unknown = Reflect.get(secrets, KEY_ID);
	const token: unknown = Reflect.get(secrets, KEY_API_TOKEN);
	if (typeof id !== 'string' || typeof token !== 'string' || id === '' || token === '') return null;
	return { id, token };
}

function short(value: unknown): value is string {
	return typeof value === 'string' && value.length > 0 && value.length <= LONGEST;
}

/** The servers in Cloudflare's answer, or null if it isn't one: nothing unread is handed on. */
export function iceServersFrom(answer: unknown): IceServer[] | null {
	if (typeof answer !== 'object' || answer === null) return null;
	const listed: unknown = Reflect.get(answer, 'iceServers');
	if (!Array.isArray(listed)) return null;
	const servers: IceServer[] = [];
	for (const each of listed.slice(0, MOST_SERVERS) as unknown[]) {
		if (typeof each !== 'object' || each === null) return null;
		const given: unknown = Reflect.get(each, 'urls');
		// WebRTC allows one address by itself as well as a list of them.
		const addresses: unknown[] = Array.isArray(given) ? given : [given];
		const urls = addresses.filter(short).filter((url) => /^(stun|turns?):/.test(url)).slice(0, MOST_ADDRESSES);
		if (urls.length === 0) continue;
		const username: unknown = Reflect.get(each, 'username');
		const credential: unknown = Reflect.get(each, 'credential');
		if (short(username) && short(credential)) servers.push({ urls, username, credential });
		// A relay without its credential is no use to anyone: only what needs none is kept.
		else if (urls.every((url) => url.startsWith('stun:'))) servers.push({ urls });
	}
	return servers.length > 0 ? servers : null;
}

/**
 * Servers for two players to reach each other through, with a credential for the relay; or null,
 * with no key, or Cloudflare refusing, not answering in time, or answering something else. Null
 * is never a failure to whoever asked: they play on without a relay.
 */
export async function iceServers(key: Key | null, ask: (url: string, asking: Asking) => Promise<Response>): Promise<IceServer[] | null> {
	if (!key) return null;
	try {
		const sent = await ask(`${SERVICE}/${encodeURIComponent(key.id)}/credentials/generate-ice-servers`, {
			method: 'POST',
			headers: { authorization: `Bearer ${key.token}`, 'content-type': 'application/json' },
			body: JSON.stringify({ ttl: TIME_TO_LIVE }),
			signal: AbortSignal.timeout(WAIT)
		});
		if (!sent.ok) return null;
		return iceServersFrom(await sent.json());
	} catch {
		return null;
	}
}
