import { describe, expect, it } from 'vitest';
import { type Asking, iceServers, iceServersFrom, KEY_API_TOKEN, KEY_ID, keyFrom, SERVICE, TIME_TO_LIVE } from './turn';

const KEY = { id: 'a-key', token: 'a-token' };
/** What Cloudflare answers with, as its documentation has it. */
const ANSWER = {
	iceServers: [
		{ urls: ['stun:stun.cloudflare.com:3478'] },
		{
			urls: [
				'turn:turn.cloudflare.com:3478?transport=udp',
				'turn:turn.cloudflare.com:443?transport=udp',
				'turn:turn.cloudflare.com:3478?transport=tcp',
				'turn:turn.cloudflare.com:80?transport=tcp',
				'turns:turn.cloudflare.com:5349?transport=tcp',
				'turns:turn.cloudflare.com:443?transport=tcp'
			],
			username: 'someone',
			credential: 'something'
		}
	]
};

describe('a TURN key', () => {
	it("is read from the Worker's two secrets", () => {
		expect(keyFrom({ [KEY_ID]: 'a-key', [KEY_API_TOKEN]: 'a-token' })).toEqual(KEY);
	});

	it('is none with either secret missing, empty, or not a secret at all', () => {
		expect(keyFrom({})).toBeNull();
		expect(keyFrom({ [KEY_ID]: 'a-key' })).toBeNull();
		expect(keyFrom({ [KEY_API_TOKEN]: 'a-token' })).toBeNull();
		expect(keyFrom({ [KEY_ID]: '', [KEY_API_TOKEN]: 'a-token' })).toBeNull();
		expect(keyFrom({ [KEY_ID]: 'a-key', [KEY_API_TOKEN]: 7 })).toBeNull();
	});
});

describe('servers to reach another player through', () => {
	it("are asked of Cloudflare with the key, for a credential that lasts the time to live", async () => {
		const asked: { url: string; asking: Asking }[] = [];
		const servers = await iceServers(KEY, async (url, asking) => {
			asked.push({ url, asking });
			return Response.json(ANSWER, { status: 201 });
		});
		expect(servers).toEqual(ANSWER.iceServers);
		expect(asked).toHaveLength(1);
		expect(asked[0].url).toBe(`${SERVICE}/a-key/credentials/generate-ice-servers`);
		expect(asked[0].asking.method).toBe('POST');
		expect(asked[0].asking.headers).toEqual({ authorization: 'Bearer a-token', 'content-type': 'application/json' });
		expect(JSON.parse(asked[0].asking.body)).toEqual({ ttl: TIME_TO_LIVE });
		expect(asked[0].asking.signal).toBeInstanceOf(AbortSignal);
	});

	it('are none, and Cloudflare never asked, without a key', async () => {
		let asked = 0;
		const servers = await iceServers(keyFrom({ [KEY_ID]: 'a-key' }), async () => {
			asked += 1;
			return Response.json(ANSWER, { status: 201 });
		});
		expect(servers).toBeNull();
		expect(asked).toBe(0);
	});

	it('are none when Cloudflare refuses', async () => {
		expect(await iceServers(KEY, async () => new Response('no such key', { status: 401 }))).toBeNull();
		expect(await iceServers(KEY, async () => Response.json(ANSWER, { status: 500 }))).toBeNull();
	});

	it("are none when Cloudflare can't be reached, or doesn't answer in time", async () => {
		expect(
			await iceServers(KEY, async () => {
				throw new TypeError('fetch failed');
			})
		).toBeNull();
		expect(
			await iceServers(KEY, async () => {
				throw new DOMException('The operation timed out.', 'TimeoutError');
			})
		).toBeNull();
	});

	it('are none when the answer is not one', async () => {
		expect(await iceServers(KEY, async () => new Response('<html>busy</html>', { status: 201 }))).toBeNull();
		expect(await iceServers(KEY, async () => Response.json({ errors: ['busy'] }, { status: 201 }))).toBeNull();
		expect(iceServersFrom(null)).toBeNull();
		expect(iceServersFrom({ iceServers: 'turn:turn.cloudflare.com:3478' })).toBeNull();
		expect(iceServersFrom({ iceServers: [] })).toBeNull();
		expect(iceServersFrom({ iceServers: ['turn:turn.cloudflare.com:3478'] })).toBeNull();
		expect(iceServersFrom({ iceServers: [{ urls: [7, 'https://elsewhere.example'] }] })).toBeNull();
	});

	it('keep only what WebRTC can be handed', () => {
		expect(
			iceServersFrom({
				iceServers: [
					// One address by itself, as WebRTC allows.
					{ urls: 'stun:stun.cloudflare.com:3478', more: 'unread' },
					// A relay without its credential.
					{ urls: ['turn:turn.cloudflare.com:3478?transport=udp'], username: 'someone' },
					{ urls: ['turn:turn.cloudflare.com:3478?transport=udp', 'x'.repeat(600), 9], username: 'someone', credential: 'something' }
				]
			})
		).toEqual([
			{ urls: ['stun:stun.cloudflare.com:3478'] },
			{ urls: ['turn:turn.cloudflare.com:3478?transport=udp'], username: 'someone', credential: 'something' }
		]);
	});
});
