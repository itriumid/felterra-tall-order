// A room: a host, and up to three guests finding their way to it. The service only introduces
// them: it passes each one's offer, answer and network candidates to the other, and once they've
// reached each other over WebRTC, the game goes between them directly, never through here.
//
// Each player is a line into the room, numbered: the host is 1, and each guest who comes gets
// the next number, never one used before in that room, so a guest back after a dropped connection
// is never mistaken for who they were.

/** A code's letters: none that read as another (no I, L or O, no 0 or 1). */
export const LETTERS = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
export const CODE = /^[ABCDEFGHJKMNPQRSTUVWXYZ2-9]{6}$/;
export const HOST = 1;
export const MOST_GUESTS = 3;
/** The largest message passed on, in characters: an offer is a few kilobytes. */
export const LARGEST = 16 * 1024;
/** What may be passed from one player to another. */
const PASSED = new Set(['offer', 'answer', 'candidate']);

/** A player's line into the room. */
export interface Line {
	readonly id: number;
	send(message: string): void;
	close(code: number, reason: string): void;
}

/** A fresh code, from the letters above. */
export function code(random: (count: number) => Uint8Array = (count) => crypto.getRandomValues(new Uint8Array(count))): string {
	// Only bytes that fall evenly on the letters, so each letter is as likely as the next.
	const fair = 256 - (256 % LETTERS.length);
	let made = '';
	while (made.length < 6) {
		for (const byte of random(12)) {
			if (byte < fair && made.length < 6) made += LETTERS[byte % LETTERS.length];
		}
	}
	return made;
}

function say(line: Line, message: object) {
	line.send(JSON.stringify(message));
}

export class Room {
	/** Everyone in the room right now, however they're kept. */
	constructor(private readonly lines: () => Line[]) {}

	host(): Line | undefined {
		return this.lines().find((line) => line.id === HOST);
	}

	guests(): Line[] {
		return this.lines().filter((line) => line.id !== HOST);
	}

	/** Why a guest can't come in, or null if they can. */
	refusal(): 'no_room' | 'full' | null {
		if (!this.host()) return 'no_room';
		if (this.guests().length >= MOST_GUESTS) return 'full';
		return null;
	}

	/** The host in: told their room's code. */
	opened(host: Line, room: string) {
		say(host, { type: 'room', code: room, id: HOST });
	}

	/** A guest in: told their number, and the host told of them. */
	came(guest: Line) {
		say(guest, { type: 'joined', id: guest.id });
		const host = this.host();
		if (host) say(host, { type: 'peer', id: guest.id });
	}

	/** A guest turned away, told why. */
	refuse(guest: Line, reason: string) {
		say(guest, { type: 'error', reason });
		guest.close(1000, reason);
	}

	/** Something said by one player for another: passed on, marked with who it's from. */
	heard(from: Line, text: string) {
		if (text.length > LARGEST) return;
		let message: Record<string, unknown>;
		try {
			message = JSON.parse(text);
		} catch {
			return;
		}
		if (typeof message !== 'object' || message === null || !PASSED.has(message.type as string)) return;
		// A guest speaks only to the host; the host to any guest.
		const to = from.id === HOST ? Number(message.to) : HOST;
		const target = this.lines().find((line) => line.id === to && line.id !== from.id);
		if (!target) return;
		say(target, { ...message, from: from.id, to });
	}

	/** Someone gone. The host gone, the room's over: every guest is told, and let go. */
	gone(line: Line) {
		const staying = this.lines().filter((each) => each.id !== line.id);
		if (line.id === HOST) {
			for (const guest of staying) this.refuse(guest, 'host_gone');
			return;
		}
		const host = staying.find((each) => each.id === HOST);
		if (host) say(host, { type: 'peer_left', id: line.id });
	}
}
