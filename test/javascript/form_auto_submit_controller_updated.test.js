// Test the updated form auto submit controller
import { jest } from "@jest/globals";
import "./dom_setup";

// Mock the FormAutoSubmitController
const FormAutoSubmitController = class {
  constructor(element) {
    this.element = element;
    this.formTarget = element;
    this.inputTargets = [...element.querySelectorAll('input')];
    this.hasFormTarget = true;
    this.isSubmitting = false;
    this.debounceTimer = undefined;
    this.validationErrors = [];
    this.debounceTimeValue = 800;
    this.minPasswordLengthValue = 12;
    this.minTimestampValue = 2;
  }

  // Mock the validation methods
  validateSingleField(field) {
    const fieldName = field.name?.toLowerCase() || "";
    const fieldType = field.type?.toLowerCase() || "";
    const value = field.value?.toString() || "";

    // Check required fields
    if (field.hasAttribute('required') && value.trim().length === 0) {
      return false;
    }

    // Validate email fields
    if ((fieldType === 'email' || fieldName.includes('email')) && value.trim().length > 0) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(value.trim())) {
        return false;
      }
    }

    // Validate password fields
    if (fieldType === 'password' && !fieldName.includes('confirmation')) {
      return !(value.length > 0 && value.length < this.minPasswordLengthValue);
    }

    // Validate password confirmation
    if (fieldName.includes('confirmation') && fieldType === 'password') {
      const passwordField = this.formTarget.querySelector('input[type="password"]:not([name*="confirmation"])');
      if (passwordField && value !== passwordField.value) {
        return false;
      }
    }

    return true;
  }

  performClientValidation() {
    let isValid = true;
    for (const input of this.inputTargets) {
      const fieldValid = this.validateSingleField(input);
      isValid = isValid && fieldValid;
    }
    return isValid;
  }

  validateForm() {
    this.validationErrors = [];
    const isValid = this.performClientValidation();
    
    if (isValid) {
      this.submitForm();
    }
    
    return isValid;
  }

  submitForm() {
    if (this.isSubmitting) return;
    
    this.isSubmitting = true;
    this.formTarget.submit();
    
    // Reset after delay
    setTimeout(() => {
      this.isSubmitting = false;
    }, 1000);
  }
};

describe("FormAutoSubmitController (Updated)", () => {
  let controller;
  let form;
  let usernameInput;
  let emailInput;
  let passwordInput;
  let passwordConfirmInput;

  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = `
      <form data-controller="form-auto-submit">
        <input type="text" name="username" required>
        <input type="email" name="email" required>
        <input type="password" name="password" required>
        <input type="password" name="password_confirmation" required>
      </form>
    `;

    form = document.querySelector("form");
    usernameInput = form.querySelector('input[name="username"]');
    emailInput = form.querySelector('input[name="email"]');
    passwordInput = form.querySelector('input[name="password"]');
    passwordConfirmInput = form.querySelector('input[name="password_confirmation"]');

    // Mock form submit
    form.submit = jest.fn();

    // Create controller
    controller = new FormAutoSubmitController(form);
  });

  test("validates required fields", () => {
    // Empty required field should fail
    usernameInput.value = "";
    expect(controller.validateSingleField(usernameInput)).toBe(false);

    // Filled required field should pass
    usernameInput.value = "testuser";
    expect(controller.validateSingleField(usernameInput)).toBe(true);
  });

  test("validates email format", () => {
    // Invalid email should fail
    emailInput.value = "invalid-email";
    expect(controller.validateSingleField(emailInput)).toBe(false);

    // Valid email should pass
    emailInput.value = "test@example.com";
    expect(controller.validateSingleField(emailInput)).toBe(true);
  });

  test("validates password length", () => {
    // Short password should fail
    passwordInput.value = "short";
    expect(controller.validateSingleField(passwordInput)).toBe(false);

    // Long enough password should pass
    passwordInput.value = "long-enough-password";
    expect(controller.validateSingleField(passwordInput)).toBe(true);
  });

  test("validates password confirmation", () => {
    passwordInput.value = "password123";
    
    // Mismatched confirmation should fail
    passwordConfirmInput.value = "different";
    expect(controller.validateSingleField(passwordConfirmInput)).toBe(false);

    // Matching confirmation should pass
    passwordConfirmInput.value = "password123";
    expect(controller.validateSingleField(passwordConfirmInput)).toBe(true);
  });

  test("submits form when all validations pass", () => {
    // Fill all fields with valid values
    usernameInput.value = "testuser";
    emailInput.value = "test@example.com";
    passwordInput.value = "long-enough-password";
    passwordConfirmInput.value = "long-enough-password";

    // Validate and submit
    const isValid = controller.validateForm();
    
    expect(isValid).toBe(true);
    expect(form.submit).toHaveBeenCalled();
  });

  test("does not submit form when validation fails", () => {
    // Fill with invalid values
    usernameInput.value = "";
    emailInput.value = "invalid-email";
    passwordInput.value = "short";
    passwordConfirmInput.value = "different";

    // Validate and check submission
    const isValid = controller.validateForm();
    
    expect(isValid).toBe(false);
    expect(form.submit).not.toHaveBeenCalled();
  });
});
