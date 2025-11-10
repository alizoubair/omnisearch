import React from 'react';

interface OmnisearchIconProps {
  size?: number;
  className?: string;
}

export const OmnisearchIcon: React.FC<OmnisearchIconProps> = ({
  size = 24,
  className = ''
}) => {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={size}
      height={size}
      viewBox="0 0 512 512"
    >
      <defs>
        <linearGradient
          id="omniGradient"
          x1="0%"
          y1="0%"
          x2="100%"
          y2="100%"
        >
          <stop offset="0%" stopColor="#FFFFFF" /> {/* White */}
          <stop offset="50%" stopColor="#F8FAFC" /> {/* Very light gray */}
          <stop offset="100%" stopColor="#FFFFFF" /> {/* White */}
        </linearGradient>
      </defs>

      {/* Infinity loop */}
      <path
        d="M140 256C140 204 188 156 240 156C284 156 308 188 324 212L344 244C356 264 372 292 400 292C424 292 444 276 444 252C444 228 424 212 400 212C384 212 372 220 364 232L340 268C316 304 288 348 240 348C188 348 140 308 140 256Z"
        stroke="url(#omniGradient)"
        strokeWidth="32"
        strokeLinecap="round"
        strokeLinejoin="round"
        fill="none"
      />
    </svg>
  );
};