/**
 * Simple HTML diff utility for StimulusReflex debugging
 * Compares before and after HTML and highlights the differences
 */

export function diffHtml(before, after) {
  if (!before || !after) {
    return { hasDiff: false, message: 'Cannot diff: missing before or after HTML' };
  }

  // Normalize whitespace to make comparison easier
  const normalizedBefore = before.replace(/\s+/g, ' ').trim();
  const normalizedAfter = after.replace(/\s+/g, ' ').trim();

  if (normalizedBefore === normalizedAfter) {
    return { hasDiff: false, message: 'No changes detected in HTML' };
  }

  // Find differences in attributes
  const attrDiffs = findAttributeDifferences(before, after);
  
  // Find content differences (simplified)
  const contentDiff = findContentDifferences(normalizedBefore, normalizedAfter);

  return {
    hasDiff: true,
    attributeDiffs: attrDiffs,
    contentDiff,
    message: `Found ${attrDiffs.length} attribute changes and content differences`
  };
}

function findAttributeDifferences(before, after) {
  const differences = [];
  
  // Extract attributes using regex
  const beforeAttrs = extractAttributes(before);
  const afterAttrs = extractAttributes(after);
  
  // Find attributes that changed or were added
  Object.keys(afterAttrs).forEach(attr => {
    if (beforeAttrs[attr] !== afterAttrs[attr]) {
      differences.push({
        attribute: attr,
        before: beforeAttrs[attr] || null,
        after: afterAttrs[attr]
      });
    }
  });
  
  // Find attributes that were removed
  Object.keys(beforeAttrs).forEach(attr => {
    if (!afterAttrs.hasOwnProperty(attr)) {
      differences.push({
        attribute: attr,
        before: beforeAttrs[attr],
        after: null
      });
    }
  });
  
  return differences;
}

function extractAttributes(html) {
  const attrs = {};
  const attrRegex = /(\S+)=["']([^"']*)["']/g;
  let match;
  
  while ((match = attrRegex.exec(html)) !== null) {
    attrs[match[1]] = match[2];
  }
  
  return attrs;
}

function findContentDifferences(before, after) {
  // A basic content diff
  // For a more sophisticated diff, consider using a library
  const minLength = Math.min(before.length, after.length);
  let firstDiffPos = -1;
  
  for (let i = 0; i < minLength; i++) {
    if (before[i] !== after[i]) {
      firstDiffPos = i;
      break;
    }
  }
  
  if (firstDiffPos === -1 && before.length !== after.length) {
    // One string is a prefix of the other
    firstDiffPos = minLength;
  }
  
  if (firstDiffPos === -1) {
    return { hasChanges: false };
  }
  
  // Get context around the difference
  const contextStart = Math.max(0, firstDiffPos - 20);
  const beforeContext = before.substring(contextStart, firstDiffPos);
  const afterContext = after.substring(contextStart, firstDiffPos);
  
  const beforeSuffix = before.substring(firstDiffPos, firstDiffPos + 50);
  const afterSuffix = after.substring(firstDiffPos, firstDiffPos + 50);
  
  return {
    hasChanges: true,
    position: firstDiffPos,
    beforeContext: `...${beforeContext}[${beforeSuffix}]...`,
    afterContext: `...${afterContext}[${afterSuffix}]...`,
  };
} 