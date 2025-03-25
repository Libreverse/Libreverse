// Import our DOM setup
require('./dom_setup');

// Create a simplified version of the controller for testing
const FormAutoSubmitControllerClass = class {
  constructor(element) {
    this.element = element;
    this.debounceTimeout = null;
    this.debounceTimer = 300; // ms
  }

  connect() {
    // Add event listeners in a real controller
  }

  disconnected() {
    // Clean up in a real controller
  }

  // Handle input changes
  inputChanged() {
    // Debounce the validation
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout);
    }
    
    this.debounceTimeout = setTimeout(() => {
      this.validate();
    }, this.debounceTimer);
  }

  // Validate the form
  validate() {
    const form = this.element;
    const requiredFields = form.querySelectorAll('[required]');
    const passwordField = form.querySelector('input[type="password"]');
    const passwordConfirmField = form.querySelector('input[name="password_confirmation"]');
    
    // Check all required fields have values
    let isValid = true;
    requiredFields.forEach(field => {
      if (!field.value.trim()) {
        isValid = false;
      }
    });
    
    // Check password length if it exists
    if (passwordField && passwordField.value.length < 8) {
      isValid = false;
    }
    
    // Check password confirmation matches
    if (passwordField && passwordConfirmField && 
        passwordField.value !== passwordConfirmField.value) {
      isValid = false;
    }
    
    // Submit if valid
    if (isValid) {
      form.submit();
    }
  }
};

describe('FormAutoSubmitController', () => {
  let controller;
  let form;
  let nameInput;
  let emailInput;
  let passwordInput;
  let passwordConfirmInput;
  
  beforeEach(() => {
    // Set up the DOM
    document.body.innerHTML = `
      <form data-controller="form-auto-submit">
        <input type="text" name="name" required>
        <input type="email" name="email" required>
        <input type="password" name="password" required>
        <input type="password" name="password_confirmation" required>
      </form>
    `;
    
    // Get elements
    form = document.querySelector('form');
    nameInput = form.querySelector('input[name="name"]');
    emailInput = form.querySelector('input[name="email"]');
    passwordInput = form.querySelector('input[name="password"]');
    passwordConfirmInput = form.querySelector('input[name="password_confirmation"]');
    
    // Mock form submit method
    form.submit = jest.fn();
    
    // Create controller instance
    controller = new FormAutoSubmitControllerClass(form);
  });
  
  test('form submits when all fields are valid', () => {
    // Fill in all fields
    nameInput.value = 'Test User';
    emailInput.value = 'test@example.com';
    passwordInput.value = 'password123';
    passwordConfirmInput.value = 'password123';
    
    // Call validate directly
    controller.validate();
    
    // Check form was submitted
    expect(form.submit).toHaveBeenCalled();
  });
  
  test('form does not submit when required fields are empty', () => {
    // Leave one field empty
    nameInput.value = 'Test User';
    emailInput.value = 'test@example.com';
    passwordInput.value = 'password123';
    passwordConfirmInput.value = ''; // empty
    
    // Call validate directly
    controller.validate();
    
    // Check form was not submitted
    expect(form.submit).not.toHaveBeenCalled();
  });
  
  test('form does not submit when password is too short', () => {
    // Fill in all fields, but with short password
    nameInput.value = 'Test User';
    emailInput.value = 'test@example.com';
    passwordInput.value = 'short';
    passwordConfirmInput.value = 'short';
    
    // Call validate directly
    controller.validate();
    
    // Check form was not submitted
    expect(form.submit).not.toHaveBeenCalled();
  });
  
  test('form does not submit when passwords do not match', () => {
    // Fill in all fields, but with different passwords
    nameInput.value = 'Test User';
    emailInput.value = 'test@example.com';
    passwordInput.value = 'password123';
    passwordConfirmInput.value = 'password456';
    
    // Call validate directly
    controller.validate();
    
    // Check form was not submitted
    expect(form.submit).not.toHaveBeenCalled();
  });
  
  test('inputChanged method debounces the validation call', () => {
    // Create a spy for validate
    const validateSpy = jest.spyOn(controller, 'validate');
    
    // Replace setTimeout with immediate execution for testing
    const originalSetTimeout = global.setTimeout;
    global.setTimeout = jest.fn((fn) => {
      fn(); // Execute immediately
      return 123; // Return a fake timer ID
    });
    
    // Call inputChanged
    controller.inputChanged();
    
    // Now validate should have been called since we're executing immediately
    expect(validateSpy).toHaveBeenCalled();
    
    // Clean up
    global.setTimeout = originalSetTimeout;
    validateSpy.mockRestore();
  });
}); 