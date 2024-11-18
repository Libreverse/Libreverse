import { Controller } from "@hotwired/stimulus";
import { createStore, useStore } from 'stimulus-store';

const sidebarStore = createStore({
  name: 'sidebarStore',
  type: Boolean,
  initialValue: false
});

export default class extends Controller {
  static stores = [sidebarStore]

  connect() {
    useStore(this);
    this.onSidebarStoreUpdate();
  }

  hover() {
    this.setSidebarStoreValue(true);
  }

  unhover() {
    this.setSidebarStoreValue(false);
  }

  onSidebarStoreUpdate() {
    this.element.classList.toggle('hovered', this.sidebarStoreValue);
  }
}
