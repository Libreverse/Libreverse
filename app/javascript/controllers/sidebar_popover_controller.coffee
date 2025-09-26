import { Controller } from "@hotwired/stimulus"

# SidebarPopoverController - Adds explanatory popovers to sidebar elements
# Uses a simple custom tooltip implementation for reliability
export default class extends Controller
  @targets = ["item"]
  @values = {
    delay: { type: Number, default: 800 },        # Delay before showing popover
    position: { type: String, default: "right" }, # Tooltip position
    alignment: { type: String, default: "center" } # Tooltip alignment
  }

  initialize: ->
    @hoverTimers = new Map()
    @activePopover = null

  connect: ->
    @setupPopovers()

  disconnect: ->
    @clearAllTimers()
    @hideActivePopover()

  # Set up popovers for all sidebar items
  setupPopovers: ->
    @itemTargets.forEach (item) =>
      @setupItemPopover(item)

  # Configure individual item popover
  setupItemPopover: (item) ->
    # Get popover content from data attribute
    content = item.dataset.popoverContent
    return unless content

    # Add event listeners
    item.addEventListener("mouseenter", @handleMouseEnter.bind(@, item))
    item.addEventListener("mouseleave", @handleMouseLeave.bind(@, item))
    item.addEventListener("focus", @handleFocus.bind(@, item))
    item.addEventListener("blur", @handleBlur.bind(@, item))

  # Handle mouse enter with delay
  handleMouseEnter: (item, event) ->
    @clearTimer(item)
    timer = setTimeout =>
      @showPopover(item)
    , @delayValue
    @hoverTimers.set(item, timer)

  # Handle mouse leave
  handleMouseLeave: (item, event) ->
    @clearTimer(item)
    @hideActivePopover()

  # Handle focus for keyboard navigation
  handleFocus: (item, event) ->
    @showPopover(item)

  # Handle blur for keyboard navigation
  handleBlur: (item, event) ->
    @hideActivePopover()

  # Show popover for item
  showPopover: (item) ->
    return unless item

    content = item.dataset.popoverContent
    return unless content

    # Hide any currently active popover
    @hideActivePopover()

    # Create tooltip element
    tooltip = document.createElement('div')
    tooltip.className = 'sidebar-popover is-active'
    tooltip.textContent = content
    tooltip.setAttribute('role', 'tooltip')
    tooltip.setAttribute('id', 'sidebar-popover-' + Date.now())
    # Position the tooltip
    @positionTooltip(tooltip, item)
    # Add to DOM
    document.body.appendChild(tooltip)
    # Store reference
    @activePopover = tooltip
    # Add highlight to item and accessibility
    item.setAttribute('aria-describedby', tooltip.id)

  # Position tooltip relative to item
  positionTooltip: (tooltip, item) ->
    itemRect = item.getBoundingClientRect()
    scrollTop = window.pageYOffset or document.documentElement.scrollTop
    scrollLeft = window.pageXOffset or document.documentElement.scrollLeft

    # Position to the right of the item
    tooltip.style.position = 'absolute'
    tooltip.style.left = (itemRect.right + scrollLeft + 12) + 'px'
    tooltip.style.top = (itemRect.top + scrollTop + (itemRect.height / 2)) + 'px'
    tooltip.style.transform = 'translateY(-50%)'
    tooltip.style.zIndex = '1050'

  # Hide currently active popover
  hideActivePopover: ->
    if @activePopover
      @activePopover.remove()
      @activePopover = null

      # Remove aria-describedby from all items
      @itemTargets.forEach (item) =>
        item.removeAttribute('aria-describedby')

  # Clear timer for specific item
  clearTimer: (item) ->
    timer = @hoverTimers.get(item)
    if timer
      clearTimeout(timer)
      @hoverTimers.delete(item)

  # Clear all timers
  clearAllTimers: ->
    @hoverTimers.forEach (timer) =>
      clearTimeout(timer)
    @hoverTimers.clear()

  # Action to force show popover (for testing/accessibility)
  showPopoverAction: (event) ->
    item = event.currentTarget
    @showPopover(item)

  # Action to force hide popover
  hidePopoverAction: (event) ->
    @hideActivePopover()

  # Refresh popovers (useful when sidebar items change)
  refresh: ->
    @disconnect()
    @connect()
