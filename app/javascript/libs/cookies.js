import Cookies from "js-cookie";

/**
 * Cookie utility functions using js-cookie library
 * Provides direct cookie handling for client-side operations
 */
export const CookieUtils = {
  /**
   * Set a cookie with default secure options
   * @param {string} name - Cookie name
   * @param {string} value - Cookie value
   * @param {Object} options - Additional options
   */
  set: (name, value, options = {}) => {
    const defaultOptions = {
      secure: globalThis.location.protocol === 'https:',
      sameSite: 'strict',
      ...options
    };
    Cookies.set(name, value, defaultOptions);
  },

  /**
   * Get a cookie value
   * @param {string} name - Cookie name
   * @returns {string|null} Cookie value or null if not found
   */
  get: (name) => {
    return Cookies.get(name) || undefined;
  },

  /**
   * Remove a cookie
   * @param {string} name - Cookie name
   * @param {Object} options - Additional options
   */
  remove: (name, options = {}) => {
    Cookies.remove(name, options);
  },

  /**
   * Get all cookies as an object
   * @returns {Object} All cookies
   */
  getAll: () => {
    return Cookies.get();
  }
};

export default CookieUtils;