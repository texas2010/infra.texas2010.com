import { execSync } from 'node:child_process';

type ExecCommandOptions = {
  cwd?: string;
  env?: NodeJS.ProcessEnv;
};

export const execCommand = (cmd: string, opts: ExecCommandOptions = {}) => {
  try {
    if (process.env.ENABLE_TEST_LOGS) {
      console.log(`Executing... $ ${cmd}`);
    }

    const output = execSync(cmd, {
      cwd: opts.cwd,
      env: opts.env,
      stdio: 'pipe',
      encoding: 'utf-8',
    });

    return {
      ok: true,
      output,
    };
  } catch (err) {
    if (process.env.ENABLE_TEST_LOGS) {
      console.error(`Execution failed: ${cmd}`);
    }

    const error = err as {
      stdout?: Buffer;
      stderr?: Buffer;
      message?: string;
    };

    const stdout = error.stdout?.toString() ?? '';
    const stderr = error.stderr?.toString() ?? '';
    const output = stdout + stderr || error.message || '';

    if (process.env.ENABLE_TEST_LOGS) {
      console.error('Error:', output);
    }

    return {
      ok: false,
      output,
      error: err,
    };
  }
};
