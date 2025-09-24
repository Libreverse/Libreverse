import React from 'react';
// Import the CSS module as a namespace to avoid needing a default export.
import * as styles from './MetaversePreview.module.css';

const MetaversePreview = (props) => {
  return (
    <div className={styles.container}>
      <h2 className={styles.heading}>3D Metaverse Preview (SSR)</h2>
      <p className={styles.text}>Welcome {props.name || 'Explorer'}! (Server Rendered)</p>
  <p className={styles['text-small']}>This content was prerendered on the server.</p>
    </div>
  );
};

export default MetaversePreview;
