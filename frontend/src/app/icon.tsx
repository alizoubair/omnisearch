import { ImageResponse } from 'next/og'

// Image metadata
export const size = {
    width: 32,
    height: 32,
}
export const contentType = 'image/png'

export default function Icon() {
    return new ImageResponse(
        (
            <div
                style={{
                    background: '#0f172a',
                    width: '100%',
                    height: '100%',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    borderRadius: '20%',
                }}
            >
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="28"
                    height="28"
                    viewBox="0 0 512 512"
                >
                    {/* Infinity loop - same as OmnisearchIcon */}
                    <path
                        d="M140 256C140 204 188 156 240 156C284 156 308 188 324 212L344 244C356 264 372 292 400 292C424 292 444 276 444 252C444 228 424 212 400 212C384 212 372 220 364 232L340 268C316 304 288 348 240 348C188 348 140 308 140 256Z"
                        stroke="white"
                        strokeWidth="32"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        fill="none"
                    />
                </svg>
            </div>
        ),
        {
            ...size,
        }
    )
}
