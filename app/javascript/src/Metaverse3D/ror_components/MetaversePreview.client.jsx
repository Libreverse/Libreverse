import React from 'react';
import styles from './MetaversePreview.module.css';

const MetaversePreview = (props) => {
  return (
    <div className={styles.container}>
      <h2 className={styles.heading}>3D Metaverse Preview (React)</h2>
      <p className={styles.text}>Hello {props.name || 'Explorer'}! This React component is server-rendered via React on Rails.</p>
  <p className={styles['text-small']}>Replace this with your WebGL / Three.js scene integration.</p>
    </div>
  );
};

export default MetaversePreview;
