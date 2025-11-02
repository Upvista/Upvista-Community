/**
 * Root Layout
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Application root with theme provider
 */

import type { Metadata, Viewport } from "next";
import "./globals.css";
import { ThemeProvider } from "@/lib/contexts/ThemeContext";

export const metadata: Metadata = {
  title: "Upvista Community - Professional Social Networking",
  description: "Connect, collaborate, and grow with professionals worldwide. Built by Hamza Hafeez.",
  icons: {
    icon: "/assets/u.png",
  },
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="antialiased">
        <ThemeProvider>
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
