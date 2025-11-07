/**
 * Root Layout
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Application root with theme provider and PWA support
 */

import type { Metadata, Viewport } from "next";
import "./globals.css";
import { ThemeProvider } from "@/lib/contexts/ThemeContext";
import PWAWrapper from "@/components/pwa/PWAWrapper";

export const metadata: Metadata = {
  title: "Upvista Community - Professional Social Networking",
  description: "Post your wins, connect with legends, collab on projects, and get paid. Build a different world.",
  applicationName: "Upvista Community",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "Upvista",
  },
  formatDetection: {
    telephone: false,
  },
  manifest: "/manifest.json",
  icons: {
    icon: [
      { url: "/PWA-icons/android/android-launchericon-192-192.png", sizes: "192x192", type: "image/png" },
      { url: "/PWA-icons/android/android-launchericon-512-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: [
      { url: "/PWA-icons/ios/180.png", sizes: "180x180", type: "image/png" },
    ],
  },
  openGraph: {
    type: "website",
    siteName: "Upvista Community",
    title: "Upvista Community - Your Whole World in One App",
    description: "Post your wins, connect with legends, collab on projects, and get paid. Build a different world.",
    images: [
      {
        url: "/PWA-icons/ios/1024.png",
        width: 1024,
        height: 1024,
        alt: "Upvista Community",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Upvista Community - Professional Social Networking",
    description: "Post your wins, connect with legends, collab on projects, and get paid. Build a different world.",
    images: ["/PWA-icons/ios/1024.png"],
  },
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#9333ea' },
    { media: '(prefers-color-scheme: dark)', color: '#7e22ce' },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        {/* PWA Meta Tags */}
        <link rel="manifest" href="/manifest.json" />
        <meta name="application-name" content="Upvista" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
        <meta name="apple-mobile-web-app-title" content="Upvista" />
        <meta name="mobile-web-app-capable" content="yes" />
        <meta name="theme-color" content="#9333ea" />
        
        {/* iOS Splash Screens */}
        <link rel="apple-touch-startup-image" href="/PWA-icons/ios/1024.png" />
        
        {/* Apple Touch Icons */}
        <link rel="apple-touch-icon" href="/PWA-icons/ios/180.png" />
        <link rel="apple-touch-icon" sizes="152x152" href="/PWA-icons/ios/152.png" />
        <link rel="apple-touch-icon" sizes="167x167" href="/PWA-icons/ios/167.png" />
        <link rel="apple-touch-icon" sizes="180x180" href="/PWA-icons/ios/180.png" />
      </head>
      <body className="antialiased">
        <ThemeProvider>
          <PWAWrapper>
            {children}
          </PWAWrapper>
        </ThemeProvider>
      </body>
    </html>
  );
}
