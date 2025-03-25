// Import JSDOM
const { JSDOM } = require('jsdom');

// Create a new JSDOM instance
const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>', {
  url: 'http://localhost/',
  pretendToBeVisual: true
});

// Set up global variables
global.window = dom.window;
global.document = dom.window.document;
global.navigator = dom.window.navigator;
global.Node = dom.window.Node;
global.getComputedStyle = dom.window.getComputedStyle;

// Add other DOM globals that might be needed
global.HTMLElement = dom.window.HTMLElement;
global.CustomEvent = dom.window.CustomEvent;
global.Event = dom.window.Event;
global.MouseEvent = dom.window.MouseEvent;

// Make available for import
module.exports = dom; 