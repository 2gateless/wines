import { defineConfig } from 'vite';

export default defineConfig({
  base: '/wines/',
  build: {
    outDir: 'dist',
    target: 'es2022',
  },
});
