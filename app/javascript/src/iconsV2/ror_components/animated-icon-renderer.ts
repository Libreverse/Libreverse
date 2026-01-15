import React, { memo, useMemo } from "react";
import type { AnimatedIconProps } from "./types";
import { ICON_BY_NAME, type IconType } from "./index";

type RendererProps = AnimatedIconProps & {
  name: string;
  fallbackText?: string;
  [key: string]: unknown;
};

function resolveIcon(name?: string): IconType | undefined {
  if (!name) {
    return undefined;
  }

  const trimmed = `${name}`.trim();
  if (!trimmed) {
    return undefined;
  }

  const lowerCase = trimmed.toLowerCase();
  const normalized = lowerCase.replace(/[_\s]+/g, "-");
  const sanitized = normalized.replace(/[^a-z0-9-]/g, "-");

  const candidates = [
    trimmed,
    lowerCase,
    normalized,
    sanitized,
    sanitized.endsWith("-icon") ? sanitized : `${sanitized}-icon`,
  ];

  for (const key of candidates) {
    const icon = ICON_BY_NAME[key];
    if (icon) {
      return icon;
    }
  }

  return undefined;
}

const AnimatedIconRenderer = memo(function AnimatedIconRenderer(
  props: RendererProps,
) {
  const {
    name,
    fallbackText,
    suppressHydrationWarning = true,
    ...iconProps
  } = props;

  const iconEntry = useMemo(() => resolveIcon(name), [name]);

  if (!iconEntry) {
    const fallbackClassName = ["animated-icon-fallback", iconProps.className]
      .filter(Boolean)
      .join(" ")
      .trim();

    return React.createElement(
      "span",
      {
        className: fallbackClassName,
        role: fallbackText ? "img" : "presentation",
        "aria-label": fallbackText || undefined,
        suppressHydrationWarning,
      },
      fallbackText || "",
    );
  }

  const IconComponent = iconEntry.icon;
  return React.createElement(
    IconComponent,
    {
      suppressHydrationWarning,
      ...(iconProps as AnimatedIconProps & Record<string, unknown>),
    },
  );
});

export default AnimatedIconRenderer;
