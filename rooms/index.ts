// Felterra: Tall Order's rooms, on Cloudflare: where a host gets a code and guests use it to find
// them. Each room is its own Durable Object, its players' WebSockets held by it and let sleep
// between messages, so an open room nobody's talking in costs nothing. The rules are in
// `rooms.ts`; this is only how they meet Cloudflare.
//
//   wss://api.tall-order.felterra.games.itrium.id/host?version=<v>          a new room, its code
//   wss://api.tall-order.felterra.games.itrium.id/join/<code>?version=<v>   into that room
//   https://api.tall-order.felterra.games.itrium.id/latest                  the newest version
//
// The version is the game's, as `0.0.5`: a guest on another version than the host's is turned
// away. One that doesn't say comes in as version "", which matches no host.

import { DurableObject } from 'cloudflare:workers';
import { latest } from './latest';
import { code, CODE, HOST, type Line, Room } from './rooms';

/** Codes tried before giving up on making a room: with 887 million of them, one is plenty. */
const TRIES = 5;
/** What a version looks like, kept short: anything else is taken as none. */
const VERSION = /^[0-9a-z.-]{1,20}$/;

export class RoomObject extends DurableObject<Env> {
	private lines(leaving?: WebSocket): Line[] {
		return this.ctx
			.getWebSockets()
			.filter((socket) => socket !== leaving)
			.map((socket) => this.line(socket));
	}

	private line(socket: WebSocket): Line {
		const kept = socket.deserializeAttachment() as { id: number; version: string };
		return {
			id: kept.id,
			version: kept.version,
			send: (message) => socket.send(message),
			close: (status, reason) => socket.close(status, reason)
		};
	}

	async fetch(request: Request): Promise<Response> {
		if (request.headers.get('upgrade') !== 'websocket') return new Response(null, { status: 426 });
		const room = new Room(() => this.lines());
		const hosting = request.headers.get('x-room-role') === 'host';
		if (hosting && room.host()) return new Response(null, { status: 409 });
		const pair = new WebSocketPair();
		const [client, server] = [pair[0], pair[1]];
		// Numbers are never used twice in a room: a guest back after a dropped connection is new.
		const next = (await this.ctx.storage.get<number>('next')) ?? HOST + 1;
		const id = hosting ? HOST : next;
		if (!hosting) await this.ctx.storage.put('next', next + 1);
		const asked = new URL(request.url).searchParams.get('version') ?? '';
		const version = VERSION.test(asked) ? asked : '';
		server.serializeAttachment({ id, version });
		this.ctx.acceptWebSocket(server);
		const line = this.line(server);
		if (hosting) {
			room.opened(line, request.headers.get('x-room-code') ?? '');
		} else {
			// Asked before this one was counted in.
			const refusal = new Room(() => this.lines().filter((each) => each.id !== id)).refusal(version);
			if (refusal) room.refuse(line, refusal);
			else room.came(line);
		}
		return new Response(null, { status: 101, webSocket: client });
	}

	async webSocketMessage(socket: WebSocket, message: string | ArrayBuffer) {
		if (typeof message !== 'string') return;
		new Room(() => this.lines()).heard(this.line(socket), message);
	}

	async webSocketClose(socket: WebSocket) {
		new Room(() => this.lines(socket)).gone(this.line(socket));
		// The last one out: nothing of the room is kept.
		if (this.lines(socket).length === 0) await this.ctx.storage.deleteAll();
	}
}

export default {
	async fetch(request, env, context) {
		const path = new URL(request.url).pathname;
		if (path === '/latest' && request.method === 'GET') {
			// Kept in Cloudflare's cache for the hour the answer says, so GitHub is asked rarely.
			const cache = caches.default;
			const kept = await cache.match(request);
			if (kept) return kept;
			const answer = await latest((url) => fetch(url, { redirect: 'manual' }));
			if (answer.ok) context.waitUntil(cache.put(request, answer.clone()));
			return answer;
		}
		if (path === '/host') {
			for (let tried = 0; tried < TRIES; tried += 1) {
				const room = code();
				const headers = new Headers(request.headers);
				headers.set('x-room-role', 'host');
				headers.set('x-room-code', room);
				const response = await env.ROOM.get(env.ROOM.idFromName(room)).fetch(new Request(request, { headers }));
				if (response.status !== 409) return response;
			}
			return new Response(null, { status: 503 });
		}
		const joining = /^\/join\/([^/]+)$/.exec(path);
		if (joining && CODE.test(joining[1])) {
			const headers = new Headers(request.headers);
			headers.set('x-room-role', 'guest');
			return env.ROOM.get(env.ROOM.idFromName(joining[1])).fetch(new Request(request, { headers }));
		}
		return new Response(null, { status: 404 });
	}
} satisfies ExportedHandler<Env>;
