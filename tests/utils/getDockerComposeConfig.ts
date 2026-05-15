import { execCommand } from './execCommand';

export const getDockerComposeConfig = (env: NodeJS.ProcessEnv) => {
  const cmdStr = `make docker-config FORMAT=json`;
  const result = execCommand(cmdStr, {
    env: {
      ...process.env,
      ...env,
    },
  });

  if (!result.ok) {
    throw new Error(result.output);
  }

  return JSON.parse(result.output);
};
