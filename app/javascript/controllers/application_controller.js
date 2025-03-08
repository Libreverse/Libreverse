import { Controller } from "@hotwired/stimulus";
import StimulusReflex from "stimulus_reflex";

// This is the Stimulus ApplicationController.
// All StimulusReflex controllers should inherit from this class.
//
// Example:
//
//   import ApplicationController from './application_controller'
//
//   export default class extends ApplicationController { ... }
//
// Learn more at: https://docs.stimulusreflex.com
//

export default class extends Controller {
  connect() {
    StimulusReflex.register(this);
  }

  // Application-wide lifecycle methods
  //
  // Use these methods to handle lifecycle callbacks for all controllers.
  // Using lifecycle methods is optional, so feel free to delete these if you don't need them.
  //
  // Arguments:
  //
  //   element - the element that triggered the reflex
  //             may be different than the Stimulus controller's this.element
  //
  //   reflex - the name of the reflex e.g. "Example#demo"
  //
  //   error/noop - the error message (for reflexError), otherwise null
  //
  //   id - a UUID4 or developer-provided unique identifier for each Reflex
  //

  // eslint-disable-next-line no-unused-vars
  beforeReflex(element, reflex, noop, id) {
    // document.body.classList.add('wait')
  }

  // eslint-disable-next-line no-unused-vars
  reflexQueued(element, reflex, noop, id) {
    // Reflex will be delivered to server upon reconnection
  }

  // eslint-disable-next-line no-unused-vars
  reflexDelivered(element, reflex, noop, id) {
    // Reflex has been delivered to the server
  }

  // eslint-disable-next-line no-unused-vars
  reflexSuccess(element, reflex, noop, id) {
    // show success message
  }

  // eslint-disable-next-line no-unused-vars
  reflexError(element, reflex, error, id) {
    // show error message
  }

  // eslint-disable-next-line no-unused-vars
  reflexForbidden(element, reflex, noop, id) {
    // Reflex action did not have permission to run
    // window.location = '/'
  }

  // eslint-disable-next-line no-unused-vars
  reflexHalted(element, reflex, noop, id) {
    // handle aborted Reflex action
  }

  // eslint-disable-next-line no-unused-vars
  afterReflex(element, reflex, noop, id) {
    // document.body.classList.remove('wait')
  }

  // eslint-disable-next-line no-unused-vars
  finalizeReflex(element, reflex, noop, id) {
    // all operations have completed, animation etc is now safe
  }
}
