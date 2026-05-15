import { describe, expect, test } from 'vitest';
import { getDockerComposeConfig } from '../utils/getDockerComposeConfig';
import { execCommand } from '../utils/execCommand';

const repoName = 'com-texas2010-infra-';

describe('Docker Compose Config', () => {
  describe('Output Modes', () => {
    test('docker config JSON mode should return valid JSON', () => {
      const result = execCommand(
        'make docker-config INFRA_LOCATION=home DEPLOY_ENV=dev FORMAT=json'
      );

      expect(result.ok).toBe(true);

      const config = JSON.parse(result.output);

      expect(config.name).toBe('com-texas2010-infra-home-dev');
      expect(config.services).toHaveProperty('api');
      expect(config.services).toHaveProperty('caddy');
    });

    test('docker config normal mode should include human output', () => {
      const result = execCommand(
        'make docker-config INFRA_LOCATION=home DEPLOY_ENV=dev'
      );

      expect(result.ok).toBe(true);

      expect(result.output).toContain('Infrastructure Location:');
      expect(result.output).toContain('Deploy Environment:');
      expect(result.output).toContain('Platform:');
      expect(result.output).toContain('Env File Name:');
      expect(result.output).toContain('services:');
    });

    test('docker config should fail with invalid format', () => {
      const result = execCommand(
        'make docker-config INFRA_LOCATION=home DEPLOY_ENV=dev FORMAT=xml'
      );

      expect(result.ok).toBe(false);
      expect(result.output).toContain('Invalid FORMAT: xml');
    });
  });
  describe('Infra Location: Home', () => {
    describe('Deploy Env: Prod', () => {
      const fullProjectName = repoName + 'home-prod';
      const expectedServices = ['api', 'caddy', 'watchtower'];

      const envObj = {
        INFRA_LOCATION: 'home',

        DOCKER_ENV: 'production',
        DOCKER_RESTART: 'unless-stopped',

        NODE_ENV: 'production',

        HTTPS_PORT: '443',
        HTTP_PORT: '80',

        DOMAIN: 'home.texas2010.com',

        CADDYFILE_PATH: './Caddyfile',
        CLOUDFLARE_API_TOKEN: 'fake-api-token-c3f8f2f9f7f24f1ab2f9c6e0d3b7a1e4',

        DEPLOY_ENV: 'prod',
      };

      const config = getDockerComposeConfig(envObj);

      test('should have same name', () => {
        expect(config.name).toBe(fullProjectName);
      });

      test('should have expected services only', () => {
        const serviceNames = Object.keys(config.services).sort();
        expect(serviceNames).toEqual([...expectedServices].sort());
      });

      describe('caddy service', () => {
        test('should have environment', () => {
          expect(config.services.caddy.environment).toStrictEqual({
            CLOUDFLARE_API_TOKEN: envObj.CLOUDFLARE_API_TOKEN,
            DOMAIN: envObj.DOMAIN,
          });
        });

        test('ports should be correct', () => {
          expect(config.services.caddy.ports).toMatchObject([
            { target: 443, published: '443' },
            { target: 80, published: '80' },
          ]);
        });

        test('should have dockerfile', () => {
          expect(config.services.caddy.build.dockerfile).toBe(
            'Dockerfile.caddy'
          );
        });

        test('should mount Caddyfile in correct place', () => {
          const volumes = config.services.caddy.volumes;

          const caddyfileVolume = volumes.find(
            (volume: any) =>
              volume.type === 'bind' && volume.target === '/etc/caddy/Caddyfile'
          );

          expect(caddyfileVolume).toMatchObject({
            type: 'bind',
            target: '/etc/caddy/Caddyfile',
            read_only: true,
          });
        });
      });

      describe('api service', () => {
        test('should have environment', () => {
          expect(config.services.api.environment).toStrictEqual({
            DOMAIN: envObj.DOMAIN,
            INFRA_LOCATION: envObj.INFRA_LOCATION,
            WATCHTOWER_NOTIFICATIONS_LEVEL: 'info',
          });
        });

        test('port should be correct', () => {
          expect(config.services.api.expose).toStrictEqual(['3000']);
        });

        test('image should be correct', () => {
          expect(config.services.api.image).toBe(
            'ghcr.io/texas2010/api.home.texas2010.com:latest'
          );
        });
      });

      describe('watchtower service', () => {
        test('should exist', () => {
          expect(config.services).toHaveProperty('watchtower');
        });

        test('should be production in the profile', () => {
          expect(config.services.watchtower.profiles).toContain('production');
        });

        test('image should be correct', () => {
          expect(config.services.watchtower.image).toBe(
            'containrrr/watchtower'
          );
        });
      });
    });

    describe('Deploy Env: Dev', () => {
      const fullProjectName = repoName + 'home-dev';
      const expectedServices = ['api', 'caddy'];

      const envObj = {
        INFRA_LOCATION: 'home',

        DOCKER_ENV: 'development',
        DOCKER_RESTART: 'no',

        NODE_ENV: 'production',

        HTTPS_PORT: '8443',
        HTTP_PORT: '8888',

        DOMAIN: 'home.dev.texas2010.com',

        CADDYFILE_PATH: './Caddyfile',
        CLOUDFLARE_API_TOKEN: 'fake-api-token-8f2d4c7a91e64b0ab5e3d2f7c8a14e6b',

        DEPLOY_ENV: 'dev',
      };

      const config = getDockerComposeConfig(envObj);

      test('should have same name', () => {
        expect(config.name).toBe(fullProjectName);
      });

      test('should have expected services only', () => {
        const serviceNames = Object.keys(config.services).sort();
        expect(serviceNames).toEqual([...expectedServices].sort());
      });

      describe('caddy service', () => {
        test('should have environment', () => {
          expect(config.services.caddy.environment).toStrictEqual({
            CLOUDFLARE_API_TOKEN: envObj.CLOUDFLARE_API_TOKEN,
            DOMAIN: envObj.DOMAIN,
          });
        });

        test('ports should be correct', () => {
          expect(config.services.caddy.ports).toMatchObject([
            { target: 443, published: '8443' },
            { target: 80, published: '8888' },
          ]);
        });
      });

      describe('api service', () => {
        test('should have environment', () => {
          expect(config.services.api.environment).toStrictEqual({
            DOMAIN: envObj.DOMAIN,
            INFRA_LOCATION: envObj.INFRA_LOCATION,
            WATCHTOWER_NOTIFICATIONS_LEVEL: 'info',
          });
        });
      });
    });

    describe('Deploy Env: Test', () => {
      const fullProjectName = repoName + 'home-test';
      const expectedServices = ['api', 'caddy'];

      const envObj = {
        INFRA_LOCATION: 'home',

        DOCKER_ENV: 'test',
        DOCKER_RESTART: 'no',

        NODE_ENV: 'production',

        HTTPS_PORT: '9443',
        HTTP_PORT: '9080',

        DOMAIN: 'localhost',

        CADDYFILE_PATH: './Caddyfile.test',

        DEPLOY_ENV: 'test',
      };

      const config = getDockerComposeConfig(envObj);

      test('should have same name', () => {
        expect(config.name).toBe(fullProjectName);
      });

      test('should have expected services only', () => {
        const serviceNames = Object.keys(config.services).sort();
        expect(serviceNames).toEqual([...expectedServices].sort());
      });

      describe('caddy service', () => {
        test('should have environment', () => {
          expect(config.services.caddy.environment).toStrictEqual({
            DOMAIN: envObj.DOMAIN,
            CLOUDFLARE_API_TOKEN: '',
          });
        });

        test('ports should be correct', () => {
          expect(config.services.caddy.ports).toMatchObject([
            { target: 443, published: '9443' },
            { target: 80, published: '9080' },
          ]);
        });
      });

      describe('api service', () => {
        test('should have environment', () => {
          expect(config.services.api.environment).toStrictEqual({
            DOMAIN: envObj.DOMAIN,
            INFRA_LOCATION: envObj.INFRA_LOCATION,
            WATCHTOWER_NOTIFICATIONS_LEVEL: 'info',
          });
        });
      });
    });
  });
});
