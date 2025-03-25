# JavaScript Testing

This directory contains Jest tests for the JavaScript files in the application.

## Test Structure

The JavaScript tests in this project are organized as follows:

- `basic.test.js`: Basic tests to verify Jest configuration
- `dom_test.test.js`: Tests for DOM manipulation
- `dom_setup.js`: Common DOM setup used by all tests
- `simple_controller.test.js`: Simple Stimulus controller test
- `drawer_controller.test.js`: Tests for the drawer controller
- `form_auto_submit_controller.test.js`: Tests for the form auto-submit controller
- `toast_controller.test.js`: Tests for the toast controller
- `dismissible_controller.test.js`: Tests for the dismissible controller
- `utils/xmlrpc.test.js`: Tests for the XML-RPC utility

Each controller test uses a simplified approach to testing, creating a lightweight version of the controller that can be easily tested outside of the Stimulus framework.

## Running Tests

Run all the tests:

```bash
bun test
```

Run specific tests:

```bash
bun test test/javascript/basic.test.js
```

## Current Limitations

- Tests use simplified versions of the controllers rather than testing the actual controllers in a Stimulus context
- Complex mocking for dependencies like XMLHttpRequest may be needed for some utilities
- Some tests may not perfectly match the behavior of the real controllers in all edge cases

## Future Improvements

- Implement a proper Stimulus testing framework to test controllers in their native context
- Add more integration tests for interactions between controllers
- Add tests for remaining controllers
- Improve mocking to better reflect real-world scenarios
- Add test coverage reporting 