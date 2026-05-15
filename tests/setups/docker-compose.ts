import {
  DockerComposeEnvironment,
  type StartedDockerComposeEnvironment,
  type WaitStrategy,
} from 'testcontainers';

type EnvObj = Record<string, string>;

type StartDockerComposeOptions = {
  composeFilePath: string;
  composeFile: string | string[];
  projectName: string;
  envObj?: EnvObj;
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
  envObj,
  profiles = [],
  waitStrategies = {},
}: StartDockerComposeOptions): Promise<StartedDockerCompose> => {
  let environment = new DockerComposeEnvironment(
    composeFilePath,
    composeFile
  ).withProjectName(projectName);

  if (envObj) {
    environment = environment.withEnvironment(envObj);
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
