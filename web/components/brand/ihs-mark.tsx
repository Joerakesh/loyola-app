import type { SVGProps } from "react";

/**
 * The IHS monogram of the Society of Jesus: sun rays, the cross above the H and
 * the three nails. Letters and ring use currentColor; rays use the gold token.
 */
export default function IhsMark({
  size = 40,
  ...props
}: { size?: number } & Omit<SVGProps<SVGSVGElement>, "width" | "height">) {
  return (
    <svg
      viewBox="0 0 100 100"
      width={size}
      height={size}
      role="img"
      aria-label="IHS, the Jesuit monogram"
      {...props}
    >
      <path d="M82.8 46.0 L97.0 50.0 L82.8 54.0Z M82.4 56.4 L94.7 64.5 L79.9 63.9Z M78.8 66.1 L88.0 77.6 L74.2 72.5Z M72.5 74.2 L77.6 88.0 L66.1 78.8Z M63.9 79.9 L64.5 94.7 L56.4 82.4Z M54.0 82.8 L50.0 97.0 L46.0 82.8Z M43.6 82.4 L35.5 94.7 L36.1 79.9Z M33.9 78.8 L22.4 88.0 L27.5 74.2Z M25.8 72.5 L12.0 77.6 L21.2 66.1Z M20.1 63.9 L5.3 64.5 L17.6 56.4Z M17.2 54.0 L3.0 50.0 L17.2 46.0Z M17.6 43.6 L5.3 35.5 L20.1 36.1Z M21.2 33.9 L12.0 22.4 L25.8 27.5Z M27.5 25.8 L22.4 12.0 L33.9 21.2Z M36.1 20.1 L35.5 5.3 L43.6 17.6Z M46.0 17.2 L50.0 3.0 L54.0 17.2Z M56.4 17.6 L64.5 5.3 L63.9 20.1Z M66.1 21.2 L77.6 12.0 L72.5 25.8Z M74.2 27.5 L88.0 22.4 L78.8 33.9Z M79.9 36.1 L94.7 35.5 L82.4 43.6Z" style={{ fill: "var(--gold, #B8892B)" }} />
      <circle cx="50" cy="50" r="30" fill="none" stroke="currentColor" strokeWidth="1.6"/>
  <path d="M50 24v15M44.5 29h11" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round"/>
  <text x="50" y="62" textAnchor="middle" style={{ fontFamily: "var(--font-display), Georgia, serif" }} fontSize={25} fontWeight={700} fill="currentColor">IHS</text>
  <path d="M39.5 68h5L42 76zM47.5 68h5L50 76zM55.5 68h5L58 76z" fill="currentColor"/>
    </svg>
  );
}
