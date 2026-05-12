import {
  DockerComposeEnvironment,
  type StartedDockerComposeEnvironment,
  type WaitStrategy,
} from 'testcontainers';

type StartDockerComposeOptions = {
  composeFilePath: string;
  composeFile: string | string[];
  projectName: string;
  envFile?: string;
  profiles?: string[];
  waitStrategies?: Record<string, WaitStrategy>;
};

export type StartedDockerCompose = {
  environment: StartedDockerComposeEnvironment;
};

export const startDockerCompose = async ({
  composeFilePath,
  composeFile,
  projectName,
  envFile,
  profiles = [],
  waitStrategies = {},
}: StartDockerComposeOptions): Promise<StartedDockerCompose> => {
  let environment = new DockerComposeEnvironment(
    composeFilePath,
    composeFile
  ).withProjectName(projectName);

  if (envFile) {
    environment = environment.withEnvironmentFile(envFile);
  }

  if (profiles.length > 0) {
    environment = environment.withProfiles(...profiles);
  }

  for (const [containerName, waitStrategy] of Object.entries(waitStrategies)) {
    environment = environment.withWaitStrategy(containerName, waitStrategy);
  }

  const startedEnvironment = await environment.up();

  return {
    environment: startedEnvironment,
  };
};
