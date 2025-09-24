import React, { useState, useEffect, useCallback } from 'react';
// Import the CSS module as a namespace so we do not rely on a default export.
import * as styles from './MetaversePreview.module.css';

// NOTE: This component now includes obvious client-only interactivity so you can
// confirm hydration is happening. Indicators:
// 1. Hydration status text flips from "(server)" to "Hydrated ✅".
// 2. Click counter increments.
// 3. Color pulse / random color on button click.
// 4. Typing in the input updates greeting live.

const MetaversePreview = (props) => {
  const [hydrated, setHydrated] = useState(false);
  const [count, setCount] = useState(0);
  const [accent, setAccent] = useState('#8e44ad');
  const [name, setName] = useState(props.name || 'Explorer');
  const [serverRenderTime] = useState(() => props.serverRenderTime || Date.now());
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    setHydrated(true);
    const id = requestAnimationFrame(() => setNow(Date.now()));
    console.log('[MetaversePreview] hydrated');
    return () => cancelAnimationFrame(id);
  }, []);

  const handleClick = useCallback(() => {
    setCount(c => c + 1);
    // Generate a random pleasant HSL color.
    const hue = Math.floor(Math.random() * 360);
    setAccent(`hsl(${hue} 70% 55%)`);
  }, []);

  const latencyMs = hydrated ? (now - serverRenderTime) : null;

  return (
    <div
      className={styles.container}
      style={{
        border: `2px solid ${accent}`,
        borderRadius: 12,
        padding: '1.25rem',
        transition: 'border-color .5s ease'
      }}
      data-hydrated={hydrated}
    >
      <h2 className={styles.heading} style={{ display: 'flex', alignItems: 'center', gap: '.5rem' }}>
        3D Metaverse Preview (React)
        <span
          style={{
            fontSize: '0.75em',
            fontWeight: 500,
            padding: '0.15em 0.6em',
            borderRadius: '999px',
            background: hydrated ? 'linear-gradient(90deg,#16a34a,#22c55e)' : '#999',
            color: '#fff',
            letterSpacing: '.5px'
          }}
        >
          {hydrated ? 'Hydrated ✅' : '(server)'}
        </span>
      </h2>
      <p className={styles.text} style={{ marginTop: 0 }}>
        Hello <strong style={{ color: accent }}>{name}</strong>! This React component is
        server-rendered via React on Rails then hydrated client-side.
      </p>
      <p className={styles['text-small']}>
        Replace this with your WebGL / Three.js scene integration. For now we show interactive state.
      </p>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.75rem', alignItems: 'center', marginTop: '0.75rem' }}>
        <button
          type="button"
          onClick={handleClick}
          style={{
            cursor: 'pointer',
            background: accent,
            color: '#fff',
            border: 'none',
            padding: '.6rem 1rem',
            borderRadius: 8,
            fontSize: '0.9rem',
            fontWeight: 600,
            boxShadow: '0 2px 6px rgba(0,0,0,.15)',
            transition: 'transform .15s ease, background .5s ease'
          }}
          onMouseDown={e => e.currentTarget.style.transform = 'scale(.95)'}
          onMouseUp={e => e.currentTarget.style.transform = 'scale(1)'}
        >
          Click Count: {count}
        </button>
        <label style={{ display: 'flex', flexDirection: 'column', fontSize: '.75rem', fontWeight: 600, color: '#555' }}>
          Your Name
          <input
            value={name}
            onChange={e => setName(e.target.value)}
            placeholder="Type to test hydration"
            style={{
              marginTop: 2,
              padding: '.45rem .6rem',
              borderRadius: 6,
              border: '1px solid #ccc',
              fontSize: '.85rem',
              minWidth: 160
            }}
          />
        </label>
        <div style={{ fontSize: '.7rem', lineHeight: 1.2, opacity: .8 }}>
          <div><strong>Accent</strong>: {accent}</div>
          {latencyMs != null && (
            <div title="Time between SSR and first client paint recalculation">
              Hydration Δ: {latencyMs}ms
            </div>
          )}
        </div>
      </div>
      <details style={{ marginTop: '1rem' }}>
        <summary style={{ cursor: 'pointer', fontWeight: 600 }}>Debug Notes</summary>
        <pre style={{ fontSize: '.65rem', background: '#111', color: '#eee', padding: '.75rem', borderRadius: 6, overflowX: 'auto' }}>
{`props: ${JSON.stringify({ ...props, serverRenderTime }, null, 2)}`}
        </pre>
      </details>
    </div>
  );
};

export default MetaversePreview;
