import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  experimental: {
    // Enable view transitions for smooth page changes (Instagram-style)
    viewTransition: true,
  },
};

export default nextConfig;
