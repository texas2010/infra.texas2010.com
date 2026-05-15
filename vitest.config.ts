import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    include: ['tests/**/*.test.ts'],
    setupFiles: ['./tests/setups/vitest-global-setup.ts'],
    testTimeout: 120_000,
    hookTimeout: 120_000,
    isolate: false,
  },
});
