export interface AnimatedIconProps {
  /** Icon size in pixels or CSS string */
  size?: number | string;
  /** Icon color (defaults to currentColor) */
  color?: string;
  /** SVG stroke width */
  strokeWidth?: number;
  /** Additional CSS classes */
  className?: string;
  /** Hide non-critical hydration mismatches (useful when HTML is post-processed) */
  suppressHydrationWarning?: boolean;
}

export interface AnimatedIconHandle {
  startAnimation: () => void;
  stopAnimation: () => void;
}
