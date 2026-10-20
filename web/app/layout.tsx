import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });
const geistMono = Geist_Mono({ variable: "--font-geist-mono", subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Loyola Student Portal",
  description: "Your Loyola academic essentials in one place.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}>
      <head>
        <meta name="google-site-verification" content="7w6pCW1Ppr8mz7ZlkUcdqiJoy2KHCOCdovJYE4-AdwU" />
      </head>
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}