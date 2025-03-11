import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container"];
  static values = {
    autoHide: { type: Boolean, default: true },
    autoHideDelay: { type: Number, default: 5000 }
  };

  connect() {
    // Show toasts immediately when controller connects
    requestAnimationFrame(() => {
      this.showToasts();
    });

    // Make the create method available globally
    window.createToast = this.createToast.bind(this);
  }

  showToasts() {
    const toasts = this.containerTarget.querySelectorAll(".toast:not(.show)");
    
    toasts.forEach(toast => {
      // Add show class immediately
      toast.classList.add("show");
      
      // Auto-hide toast after delay if autoHide is true
      if (this.autoHideValue) {
        setTimeout(() => {
          this.hideToast(toast);
        }, this.autoHideDelayValue);
      }
    });
  }

  hideToast(toast) {
    toast.classList.remove("show");
    
    // Remove toast from DOM after animation completes
    setTimeout(() => {
      toast.remove();
    }, 500); // Restored to original 500ms to match the CSS transition duration
  }

  close(event) {
    const toast = event.target.closest(".toast");
    this.hideToast(toast);
  }

  // Create a new toast programmatically
  createToast(message, type = 'info', title = null) {
    // Default titles based on type
    if (!title) {
      switch(type) {
        case 'success': title = 'Success'; break;
        case 'error': title = 'Error'; break;
        case 'warning': title = 'Warning'; break;
        default: title = 'Information';
      }
    }

    // Create toast elements
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.setAttribute('role', 'alert');
    toast.setAttribute('aria-live', 'assertive');
    toast.setAttribute('aria-atomic', 'true');

    const header = document.createElement('div');
    header.className = 'toast-header';

    const titleStrong = document.createElement('strong');
    titleStrong.className = 'me-auto';
    titleStrong.textContent = title;

    const closeButton = document.createElement('button');
    closeButton.className = 'toast-close';
    closeButton.setAttribute('type', 'button');
    closeButton.setAttribute('aria-label', 'Close');
    closeButton.setAttribute('data-action', 'toast#close');
    closeButton.innerHTML = '&times;';

    const body = document.createElement('div');
    body.className = 'toast-body';
    body.textContent = message;

    // Assemble toast
    header.appendChild(titleStrong);
    header.appendChild(closeButton);
    toast.appendChild(header);
    toast.appendChild(body);

    // Add to container and show
    this.containerTarget.appendChild(toast);
    
    // Trigger browser reflow to ensure animation works
    void toast.offsetWidth;
    
    // Show the toast
    requestAnimationFrame(() => {
      toast.classList.add('show');
    });

    // Auto hide if enabled
    if (this.autoHideValue) {
      setTimeout(() => {
        this.hideToast(toast);
      }, this.autoHideDelayValue);
    }

    return toast;
  }
} 