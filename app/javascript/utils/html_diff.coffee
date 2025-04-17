###*
 * Simple HTML diff utility for StimulusReflex debugging
 * Compares before and after HTML and highlights the differences
###

# Helper function (not exported)
_extractAttributes = (html) ->
  attrs = {}
  attrRegex = /(\S+)=["']([^"']*)["']/g
  match = null

  while (match = attrRegex.exec(html)) != null
    attrs[match[1]] = match[2]

  return attrs

# Helper function (not exported)
_findAttributeDifferences = (before, after) ->
  differences = []

  # Extract attributes using regex
  beforeAttrs = _extractAttributes(before)
  afterAttrs = _extractAttributes(after)

  # Find attributes that changed or were added
  Object.keys(afterAttrs).forEach (attr) ->
    if beforeAttrs[attr] != afterAttrs[attr]
      differences.push {
        attribute: attr
        before: beforeAttrs[attr] or null
        after: afterAttrs[attr]
      }

  # Find attributes that were removed
  Object.keys(beforeAttrs).forEach (attr) ->
    unless afterAttrs.hasOwnProperty(attr)
      differences.push {
        attribute: attr
        before: beforeAttrs[attr]
        after: null
      }

  return differences

# Helper function (not exported)
_findContentDifferences = (before, after) ->
  # A basic content diff
  # For a more sophisticated diff, consider using a library
  minLength = Math.min(before.length, after.length)
  firstDiffPos = -1

  for i in [0...minLength]
    if before[i] != after[i]
      firstDiffPos = i
      break

  if firstDiffPos == -1 and before.length != after.length
    # One string is a prefix of the other
    firstDiffPos = minLength

  if firstDiffPos == -1
    return { hasChanges: false }

  # Get context around the difference
  contextStart = Math.max(0, firstDiffPos - 20)
  beforeContext = before.substring(contextStart, firstDiffPos)
  afterContext = after.substring(contextStart, firstDiffPos)

  beforeSuffix = before.substring(firstDiffPos, firstDiffPos + 50)
  afterSuffix = after.substring(firstDiffPos, firstDiffPos + 50)

  return {
    hasChanges: true
    position: firstDiffPos
    beforeContext: "...#{beforeContext}[#{beforeSuffix}]..."
    afterContext: "...#{afterContext}[#{afterSuffix}]..."
  }

# Exported function
export diffHtml = (before, after) ->
  unless before and after
    return {
      hasDiff: false
      message: "Cannot diff: missing before or after HTML"
    }

  # Normalize whitespace to make comparison easier
  normalizedBefore = before.replace(/\s+/g, " ").trim()
  normalizedAfter = after.replace(/\s+/g, " ").trim()

  if normalizedBefore == normalizedAfter
    return { hasDiff: false, message: "No changes detected in HTML" }

  # Find differences in attributes
  attrDiffs = _findAttributeDifferences(before, after)

  # Find content differences (simplified)
  contentDiff = _findContentDifferences(
    normalizedBefore,
    normalizedAfter
  )

  return {
    hasDiff: true
    attributeDiffs: attrDiffs
    contentDiff
    message: "Found #{attrDiffs.length} attribute changes and content differences"
  }