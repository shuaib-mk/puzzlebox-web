// Puzzlebox Website Interactivity & Theme Switcher

document.addEventListener('DOMContentLoaded', () => {
  initThemeToggle();
  initTocObserver();
  initGameSearch();
  initSuggestionForm();
});

// Theme Toggle System
function initThemeToggle() {
  const toggleBtn = document.getElementById('theme-toggle-btn');
  const sunIcon = toggleBtn?.querySelector('.sun-icon');
  const moonIcon = toggleBtn?.querySelector('.moon-icon');
  const themeText = document.getElementById('theme-text');

  // Check saved theme or system preference
  const savedTheme = localStorage.getItem('puzzlebox-theme');
  const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  
  let currentTheme = savedTheme || (systemPrefersDark ? 'dark' : 'light');
  applyTheme(currentTheme);

  if (toggleBtn) {
    toggleBtn.addEventListener('click', () => {
      currentTheme = currentTheme === 'dark' ? 'light' : 'dark';
      applyTheme(currentTheme);
      localStorage.setItem('puzzlebox-theme', currentTheme);
    });
  }

  function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    if (themeText) {
      if (theme === 'dark') {
        if (sunIcon) sunIcon.style.display = 'inline-block';
        if (moonIcon) moonIcon.style.display = 'none';
        themeText.textContent = 'Light Mode';
      } else {
        if (sunIcon) sunIcon.style.display = 'none';
        if (moonIcon) moonIcon.style.display = 'inline-block';
        themeText.textContent = 'Dark Mode';
      }
    }
  }
}

// Table of Contents Active Link Highlight Observer
function initTocObserver() {
  const sections = document.querySelectorAll('.policy-section');
  const navLinks = document.querySelectorAll('.toc-links a');

  if (!sections.length || !navLinks.length) return;

  const observerOptions = {
    root: null,
    rootMargin: '-20% 0px -60% 0px',
    threshold: 0
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const id = entry.target.getAttribute('id');
        navLinks.forEach(link => {
          if (link.getAttribute('href') === `#${id}`) {
            link.classList.add('active');
          } else {
            link.classList.remove('active');
          }
        });
      }
    });
  }, observerOptions);

  sections.forEach(section => observer.observe(section));
}

// Interactive Game Search & Filtering
function initGameSearch() {
  const searchInput = document.getElementById('game-search-input');
  const gameCards = document.querySelectorAll('.game-card');

  if (!searchInput || !gameCards.length) return;

  searchInput.addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase().trim();
    gameCards.forEach(card => {
      const title = card.querySelector('.game-title')?.textContent.toLowerCase() || '';
      const desc = card.querySelector('.game-desc')?.textContent.toLowerCase() || '';
      const tag = card.querySelector('.game-tag')?.textContent.toLowerCase() || '';

      if (title.includes(query) || desc.includes(query) || tag.includes(query)) {
        card.style.display = 'flex';
      } else {
        card.style.display = 'none';
      }
    });
  });
}

// Suggestion Form AJAX Handler
function initSuggestionForm() {
  const form = document.getElementById('suggestion-form');
  const statusMsg = document.getElementById('form-status-message');
  const submitBtn = document.getElementById('btn-submit-suggestion');

  if (!form || !statusMsg || !submitBtn) return;

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    submitBtn.disabled = true;
    submitBtn.querySelector('span').textContent = 'Sending Suggestion...';

    statusMsg.style.display = 'none';
    statusMsg.className = 'form-status';

    const formData = new FormData(form);

    try {
      const response = await fetch('https://formsubmit.co/ajax/q04tiofficial@gmail.com', {
        method: 'POST',
        headers: {
          'Accept': 'application/json'
        },
        body: formData
      });

      if (response.ok) {
        statusMsg.textContent = "Thanks! Your game suggestion has been sent directly to q04tiofficial@gmail.com. I'll review it!";
        statusMsg.classList.add('success');
        statusMsg.style.display = 'block';
        form.reset();
      } else {
        throw new Error('Server responded with an error');
      }
    } catch (err) {
      statusMsg.textContent = "Something went wrong sending your suggestion. You can also email q04tiofficial@gmail.com directly.";
      statusMsg.classList.add('error');
      statusMsg.style.display = 'block';
    } finally {
      submitBtn.disabled = false;
      submitBtn.querySelector('span').textContent = 'Send Suggestion to q04tiofficial@gmail.com';
    }
  });
}

