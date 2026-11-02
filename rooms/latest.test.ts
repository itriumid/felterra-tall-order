import { describe, expect, it } from 'vitest';
import { LATEST, latest, PAGE, versionFrom } from './latest';

describe('the newest version', () => {
	it("is read from where GitHub sends the latest release", () => {
		expect(versionFrom('https://github.com/itriumid/felterra-tall-order/releases/tag/v0.0.5')).toBe('0.0.5');
		expect(versionFrom('https://github.com/itriumid/felterra-tall-order/releases/tag/v12.3.40')).toBe('12.3.40');
	});

	it('is none when GitHub sends nowhere a version is named', () => {
		expect(versionFrom(null)).toBeNull();
		expect(versionFrom('https://github.com/itriumid/felterra-tall-order/releases')).toBeNull();
		expect(versionFrom('https://github.com/itriumid/felterra-tall-order/releases/tag/nightly')).toBeNull();
	});

	it('is answered with the page to get it from, and kept for an hour', async () => {
		const asked: string[] = [];
		const response = await latest(async (url) => {
			asked.push(url);
			return new Response(null, { status: 302, headers: { location: `${LATEST.replace('latest', 'tag')}/v0.0.6` } });
		});
		expect(asked).toEqual([LATEST]);
		expect(await response.json()).toEqual({ version: '0.0.6', page: PAGE });
		expect(response.headers.get('cache-control')).toBe('public, max-age=3600');
	});

	it("isn't answered, or kept, when GitHub doesn't say", async () => {
		const response = await latest(async () => new Response('busy', { status: 500 }));
		expect(response.status).toBe(503);
		expect(response.headers.get('cache-control')).toBeNull();
	});
});
