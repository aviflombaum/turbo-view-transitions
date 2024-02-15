import { Application } from "@hotwired/stimulus";

const application = Application.start();

// Configure Stimulus development experience
application.debug = false;
window.Stimulus = application;

export { application };

addEventListener("turbo:before-frame-render", (event) => {
  if (document.startViewTransition) {
    const originalRender = event.detail.render;
    event.detail.render = (currentElement, newElement) => {
      document.startViewTransition(() => originalRender(currentElement, newElement));
    };
  }
});
