document.addEventListener("DOMContentLoaded", function() {
  loadPage('begin.html');  // Load the initial content
});


function loadPage(page) {
  const content = document.getElementById('content');
  fetch(page)
    .then(response => response.text())
    .then(html => {
      content.innerHTML = html; // Insert the HTML
      executeScripts(content); // Call a function to handle scripts
    })
    .catch(err => {
      content.innerHTML = '<p>Error loading the page.</p>';
      console.error('Error loading the page: ', err);
    });
}

function executeScripts(container) {
  const scripts = Array.from(container.querySelectorAll("script"));
  scripts.forEach(oldScript => {
    const newScript = document.createElement("script");
    newScript.text = oldScript.text;
    oldScript.parentNode.replaceChild(newScript, oldScript); // Replace old script with new one
  });
}

var audio_id

// Make loadPage globally available
window.loadPage = loadPage;
window.audio_id = audio_id

