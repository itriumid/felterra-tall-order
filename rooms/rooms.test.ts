import { describe, expect, it } from 'vitest';
import { code, CODE, HOST, LARGEST, type Line, MOST_GUESTS, Room } from './rooms';

/** A player's line that keeps what it's sent, and whether it's been closed. */
function line(id: number, version = '0.0.5') {
	const heard: Record<string, unknown>[] = [];
	let closed = '';
	const it: Line = {
		id,
		version,
		send: (message) => void heard.push(JSON.parse(message)),
		close: (_status, reason) => void (closed = reason)
	};
	return { line: it, heard, closed: () => closed };
}

/** A room holding these lines. */
function room(...lines: Line[]) {
	const held = [...lines];
	return { room: new Room(() => held), held };
}

describe('a room code', () => {
	it('is six of the letters that read as nothing else', () => {
		for (let made = 0; made < 200; made += 1) expect(code()).toMatch(CODE);
	});

	it('takes only the bytes that fall evenly on the letters', () => {
		// 248 and up would favor the first letters: they're passed over.
		const bytes = [255, 250, 248, 0, 1, 2, 3, 4, 5, 6, 7, 8];
		expect(code(() => Uint8Array.from(bytes))).toBe('ABCDEF');
	});
});

describe('a room', () => {
	it('tells the host its code', () => {
		const host = line(HOST);
		room(host.line).room.opened(host.line, 'KTPL42');
		expect(host.heard).toEqual([{ type: 'room', code: 'KTPL42', id: HOST }]);
	});

	it('has no room for a guest without a host', () => {
		expect(room().room.refusal('0.0.5')).toBe('no_room');
	});

	it('takes three guests, and turns the fourth away', () => {
		const lines = [line(HOST), ...Array.from({ length: MOST_GUESTS }, (_, index) => line(index + 2))];
		expect(room(...lines.map((each) => each.line)).room.refusal('0.0.5')).toBe('full');
		expect(room(...lines.slice(0, MOST_GUESTS).map((each) => each.line)).room.refusal('0.0.5')).toBeNull();
	});

	it("turns away a guest on another version, telling them the host's", () => {
		const host = line(HOST, '0.0.6');
		const guest = line(2, '0.0.5');
		const { room: it } = room(host.line);
		expect(it.refusal('0.0.5')).toBe('version');
		expect(it.refusal('')).toBe('version');
		it.refuse(guest.line, 'version');
		expect(guest.heard).toEqual([{ type: 'error', reason: 'version', version: '0.0.6' }]);
		expect(guest.closed()).toBe('version:0.0.6');
	});

	it('tells a guest their number, and the host of them', () => {
		const host = line(HOST);
		const guest = line(2);
		room(host.line, guest.line).room.came(guest.line);
		expect(guest.heard).toEqual([{ type: 'joined', id: 2 }]);
		expect(host.heard).toEqual([{ type: 'peer', id: 2 }]);
	});

	it('tells a guest and the host the servers to reach each other through, before telling them of each other', () => {
		const host = line(HOST);
		const guest = line(2);
		const servers = [
			{ urls: ['stun:stun.cloudflare.com:3478'] },
			{ urls: ['turn:turn.cloudflare.com:3478?transport=udp'], username: 'someone', credential: 'something' }
		];
		room(host.line, guest.line).room.came(guest.line, servers);
		expect(guest.heard).toEqual([
			{ type: 'ice_servers', servers },
			{ type: 'joined', id: 2 }
		]);
		expect(host.heard).toEqual([
			{ type: 'ice_servers', servers },
			{ type: 'peer', id: 2 }
		]);
	});

	it('tells the host the servers again with each guest, and no guest those of another', () => {
		const host = line(HOST);
		const first = line(2);
		const second = line(3);
		const { room: it } = room(host.line, first.line, second.line);
		const servers = (credential: string) => [{ urls: ['turn:turn.cloudflare.com:3478?transport=udp'], username: 'someone', credential }];
		it.came(first.line, servers('one'));
		it.came(second.line, servers('two'));
		expect(host.heard.filter((each) => each.type === 'ice_servers')).toEqual([
			{ type: 'ice_servers', servers: servers('one') },
			{ type: 'ice_servers', servers: servers('two') }
		]);
		expect(first.heard).toEqual([
			{ type: 'ice_servers', servers: servers('one') },
			{ type: 'joined', id: 2 }
		]);
	});

	it('says nothing of servers when there are none to offer', () => {
		const host = line(HOST);
		const guest = line(2);
		room(host.line, guest.line).room.came(guest.line, null);
		expect(guest.heard).toEqual([{ type: 'joined', id: 2 }]);
		expect(host.heard).toEqual([{ type: 'peer', id: 2 }]);
	});

	it('tells the host nothing of servers as the room opens, or a guest turned away', () => {
		const host = line(HOST);
		const guest = line(2, '0.0.4');
		const { room: it } = room(host.line);
		it.opened(host.line, 'KTPL42');
		it.refuse(guest.line, 'version');
		expect([...host.heard, ...guest.heard].some((each) => each.type === 'ice_servers')).toBe(false);
	});

	it('passes no servers from one player to another', () => {
		const host = line(HOST);
		const guest = line(2);
		room(host.line, guest.line).room.heard(guest.line, JSON.stringify({ type: 'ice_servers', servers: [{ urls: ['turn:elsewhere.example'] }] }));
		expect(host.heard).toEqual([]);
	});

	it("passes a guest's offer to the host, marked with who it's from", () => {
		const host = line(HOST);
		const guest = line(3);
		room(host.line, guest.line).room.heard(guest.line, JSON.stringify({ type: 'offer', sdp: 'v=0', to: 2 }));
		// A guest speaks only to the host, whoever they name.
		expect(host.heard).toEqual([{ type: 'offer', sdp: 'v=0', from: 3, to: HOST }]);
	});

	it("passes the host's answer to the guest it names, and no other", () => {
		const host = line(HOST);
		const first = line(2);
		const second = line(3);
		room(host.line, first.line, second.line).room.heard(host.line, JSON.stringify({ type: 'answer', sdp: 'v=0', to: 3 }));
		expect(second.heard).toEqual([{ type: 'answer', sdp: 'v=0', from: HOST, to: 3 }]);
		expect(first.heard).toEqual([]);
	});

	it('passes nothing that is not an offer, an answer or a candidate, or is too large', () => {
		const host = line(HOST);
		const guest = line(2);
		const { room: it } = room(host.line, guest.line);
		it.heard(guest.line, JSON.stringify({ type: 'room', code: 'AAAAAA' }));
		it.heard(guest.line, 'not even JSON');
		it.heard(guest.line, JSON.stringify({ type: 'candidate', sdp: 'x'.repeat(LARGEST) }));
		expect(host.heard).toEqual([]);
	});

	it("tells the host a guest has gone", () => {
		const host = line(HOST);
		const guest = line(2);
		room(host.line, guest.line).room.gone(guest.line);
		expect(host.heard).toEqual([{ type: 'peer_left', id: 2 }]);
	});

	it('lets every guest go when the host goes', () => {
		const host = line(HOST);
		const guests = [line(2), line(3)];
		room(host.line, ...guests.map((each) => each.line)).room.gone(host.line);
		for (const guest of guests) {
			expect(guest.heard).toEqual([{ type: 'error', reason: 'host_gone' }]);
			expect(guest.closed()).toBe('host_gone');
		}
	});
});
