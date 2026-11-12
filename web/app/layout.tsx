import type { Metadata, Viewport } from "next";
import { Hanken_Grotesk, Newsreader } from "next/font/google";
import "./globals.css";

// Newsreader carries the college's voice (titles, figures, the motto); Hanken
// Grotesk keeps tables, forms and navigation plain and legible at small sizes.
const display = Newsreader({
  variable: "--font-display",
  subsets: ["latin"],
  style: ["normal", "italic"],
  display: "swap",
});
const body = Hanken_Grotesk({
  variable: "--font-body",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "Loyola Student Portal",
  description: "Your Loyola academic essentials in one place.",
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#651222" },
    { media: "(prefers-color-scheme: dark)", color: "#141013" },
  ],
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${display.variable} ${body.variable} h-full antialiased`}>
      <head>
        <meta name="google-site-verification" content="7w6pCW1Ppr8mz7ZlkUcdqiJoy2KHCOCdovJYE4-AdwU" />
      </head>
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
