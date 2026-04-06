import { build } from 'esbuild';

const handlers = ['users', 'posts'];

for (const handler of handlers) {
  await build({
    entryPoints: [`src/handlers/${handler}.ts`],
    bundle: true,
    minify: false,
    platform: 'node',
    target: 'node20',
    outfile: `dist/${handler}/index.js`,
    format: 'cjs',
    external: ['@aws-sdk/*'],
  });
}

console.log('Build complete');
