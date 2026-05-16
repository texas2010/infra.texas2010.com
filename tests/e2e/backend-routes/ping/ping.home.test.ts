import { describe, afterAll, beforeAll, expect, test } from 'vitest';
import { startHomeDockerCompose } from '../../../setups/home-docker-compose';

let home: Awaited<ReturnType<typeof startHomeDockerCompose>>;

beforeAll(async () => {
  home = await startHomeDockerCompose();
});

afterAll(async () => {
  await home?.environment.down();
});

describe('Route ping', () => {
  test('GET /ping', async () => {
    const response = await fetch(`${home.baseUrl}/ping`);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data).toStrictEqual({ ping: 'pong' });
  });
});
