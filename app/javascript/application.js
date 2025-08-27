// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Load Bootstrap with better error handling
try {
  import("bootstrap").catch(error => {
    console.warn("Bootstrap loading failed:", error);
  });
} catch (error) {
  console.warn("Bootstrap import failed:", error);
}

import "@rails/actiontext"
