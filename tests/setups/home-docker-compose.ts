import path from 'node:path';
import { Wait } from 'testcontainers';
import { startDockerCompose } from './docker-compose';

export const startHomeDockerCompose = async () => {
  const composeFilePath = path.resolve(process.cwd());

  const started = await startDockerCompose({
    composeFilePath,
    composeFile: 'docker-compose.yml',
    projectName: 'home-test',
    envFile: '.env.home.test',
    profiles: ['home'],
    waitStrategies: {
      'caddy-1': Wait.forHttp('/api/ping', 80).forStatusCode(200),
    },
  });

  const caddy = started.environment.getContainer('caddy-1');
  const caddyPort = caddy.getMappedPort(80);

  return {
    ...started,
    baseUrl: `http://localhost:${caddyPort}/api`,
  };
};
