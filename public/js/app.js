/* ===========================================
   MAPAS BONITOS - Frontend JavaScript
   =========================================== */

const API_BASE = '/api';

// State
let themes = [];
let selectedTheme = 'noir';
let currentJobId = null;
let pollInterval = null;

// DOM Elements
const form = document.getElementById('createMapForm');
const locationInput = document.getElementById('location');
const distanceSlider = document.getElementById('distance');
const distanceValue = document.getElementById('distanceValue');
const themesGrid = document.getElementById('themesGrid');
const themesShowcase = document.getElementById('themesShowcase');
const submitBtn = document.getElementById('submitBtn');
const rateLimitNote = document.getElementById('rateLimit');

// Modal Elements
const modal = document.getElementById('statusModal');
const statusQueued = document.getElementById('statusQueued');
const statusRunning = document.getElementById('statusRunning');
const statusDone = document.getElementById('statusDone');
const statusError = document.getElementById('statusError');
const infoLocation = document.getElementById('infoLocation');
const infoTheme = document.getElementById('infoTheme');
const resultPreview = document.getElementById('resultPreview');
const errorMessage = document.getElementById('errorMessage');
const downloadBtn = document.getElementById('downloadBtn');
const closeModalBtn = document.getElementById('closeModalBtn');
const newMapBtn = document.getElementById('newMapBtn');

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadThemes();
    setupEventListeners();
});

// Load themes from API
async function loadThemes() {
    try {
        const response = await fetch(`${API_BASE}/themes.php`);
        const data = await response.json();
        
        if (data.success && data.data) {
            themes = data.data;
            renderThemesGrid();
            renderThemesShowcase();
        } else {
            themesGrid.innerHTML = '<div class="themes-loading">Error al cargar temas</div>';
        }
    } catch (error) {
        console.error('Error loading themes:', error);
        themesGrid.innerHTML = '<div class="themes-loading">Error al cargar temas</div>';
    }
}

// Render theme selection grid
function renderThemesGrid() {
    themesGrid.innerHTML = themes.map(theme => `
        <div class="theme-card ${theme.id === selectedTheme ? 'selected' : ''}" 
             data-theme="${theme.id}"
             title="${theme.name}: ${theme.description || ''}">
            <div class="theme-card-bg" style="background: ${theme.preview.bg}"></div>
            <div class="theme-card-roads">
                <div class="theme-card-road" style="background: ${theme.preview.road}; opacity: 1"></div>
                <div class="theme-card-road" style="background: ${theme.preview.road}; opacity: 0.7"></div>
                <div class="theme-card-road" style="background: ${theme.preview.road}; opacity: 0.4"></div>
            </div>
            <div class="theme-card-name">${theme.name}</div>
        </div>
    `).join('');
    
    // Add click handlers
    themesGrid.querySelectorAll('.theme-card').forEach(card => {
        card.addEventListener('click', () => selectTheme(card.dataset.theme));
    });
}

// Render themes showcase section
function renderThemesShowcase() {
    if (!themesShowcase) return;
    
    themesShowcase.innerHTML = themes.map(theme => `
        <div class="theme-showcase-card">
            <div class="theme-showcase-preview" style="background: ${theme.preview.bg}">
                <div class="theme-showcase-roads">
                    <div class="theme-showcase-road" style="background: ${theme.preview.road}"></div>
                    <div class="theme-showcase-road" style="background: ${theme.preview.road}; opacity: 0.7"></div>
                    <div class="theme-showcase-road" style="background: ${theme.preview.road}; opacity: 0.4"></div>
                </div>
            </div>
            <div class="theme-showcase-info">
                <div class="theme-showcase-name">${theme.name}</div>
                <div class="theme-showcase-desc">${theme.description || ''}</div>
            </div>
        </div>
    `).join('');
}

// Select theme
function selectTheme(themeId) {
    selectedTheme = themeId;
    themesGrid.querySelectorAll('.theme-card').forEach(card => {
        card.classList.toggle('selected', card.dataset.theme === themeId);
    });
}

// Setup event listeners
function setupEventListeners() {
    // Distance slider
    distanceSlider.addEventListener('input', () => {
        const km = (distanceSlider.value / 1000).toFixed(0);
        distanceValue.textContent = `${km} km`;
    });
    
    // Form submission
    form.addEventListener('submit', handleSubmit);
    
    // Modal buttons
    closeModalBtn.addEventListener('click', closeModal);
    newMapBtn.addEventListener('click', () => {
        closeModal();
        form.reset();
        distanceSlider.value = 10000;
        distanceValue.textContent = '10 km';
    });
    
    downloadBtn.addEventListener('click', () => {
        if (currentJobId) {
            window.location.href = `${API_BASE}/download.php?id=${currentJobId}`;
        }
    });
    
    // Close modal on backdrop click
    modal.querySelector('.modal-backdrop').addEventListener('click', closeModal);
}

// Handle form submission
async function handleSubmit(e) {
    e.preventDefault();
    
    const location = locationInput.value.trim();
    if (!location) {
        alert('Por favor, introduce una ubicación');
        return;
    }
    
    // Prepare data
    const data = {
        location: location,
        theme: selectedTheme,
        distance: parseInt(distanceSlider.value)
    };
    
    // Optional fields
    const title = document.getElementById('title').value.trim();
    const subtitle = document.getElementById('subtitle').value.trim();
    if (title) data.title = title;
    if (subtitle) data.subtitle = subtitle;
    
    // Update UI
    setSubmitLoading(true);
    
    try {
        const response = await fetch(`${API_BASE}/jobs.php`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        
        const result = await response.json();
        
        if (result.success && result.data) {
            currentJobId = result.data.id;
            
            // Update rate limit display
            if (result.data.remaining_requests !== undefined) {
                rateLimitNote.textContent = `${result.data.remaining_requests} mapas restantes esta hora`;
            }
            
            // Show modal and start polling
            showModal(data.location, selectedTheme);
            startPolling();
        } else {
            alert(result.error || 'Error al crear el trabajo');
        }
    } catch (error) {
        console.error('Error:', error);
        alert('Error de conexión. Por favor, inténtalo de nuevo.');
    } finally {
        setSubmitLoading(false);
    }
}

// Set submit button loading state
function setSubmitLoading(loading) {
    submitBtn.disabled = loading;
    submitBtn.querySelector('.btn-text').hidden = loading;
    submitBtn.querySelector('.btn-loading').hidden = !loading;
}

// Show status modal
function showModal(location, theme) {
    // Reset states
    statusQueued.hidden = false;
    statusRunning.hidden = true;
    statusDone.hidden = true;
    statusError.hidden = true;
    resultPreview.hidden = true;
    errorMessage.hidden = true;
    downloadBtn.hidden = true;
    newMapBtn.hidden = true;
    closeModalBtn.hidden = false;
    
    // Set info
    infoLocation.textContent = location;
    const themeObj = themes.find(t => t.id === theme);
    infoTheme.textContent = themeObj ? themeObj.name : theme;
    
    // Show modal
    modal.hidden = false;
    document.body.style.overflow = 'hidden';
}

// Close modal
function closeModal() {
    stopPolling();
    modal.hidden = true;
    document.body.style.overflow = '';
}

// Start polling for job status
function startPolling() {
    pollInterval = setInterval(async () => {
        try {
            const response = await fetch(`${API_BASE}/jobs.php?id=${currentJobId}`);
            const result = await response.json();
            
            if (result.success && result.data) {
                updateModalStatus(result.data);
            }
        } catch (error) {
            console.error('Polling error:', error);
        }
    }, 2000);
}

// Stop polling
function stopPolling() {
    if (pollInterval) {
        clearInterval(pollInterval);
        pollInterval = null;
    }
}

// Update modal based on job status
function updateModalStatus(job) {
    switch (job.status) {
        case 'queued':
            statusQueued.hidden = false;
            statusRunning.hidden = true;
            break;
            
        case 'running':
            statusQueued.hidden = true;
            statusRunning.hidden = false;
            break;
            
        case 'done':
            stopPolling();
            statusQueued.hidden = true;
            statusRunning.hidden = true;
            statusDone.hidden = false;
            resultPreview.hidden = false;
            downloadBtn.hidden = false;
            closeModalBtn.hidden = true;
            newMapBtn.hidden = false;
            break;
            
        case 'error':
            stopPolling();
            statusQueued.hidden = true;
            statusRunning.hidden = true;
            statusError.hidden = false;
            errorMessage.hidden = false;
            errorMessage.textContent = job.error_message || 'Error desconocido';
            closeModalBtn.hidden = true;
            newMapBtn.hidden = false;
            break;
    }
}

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    });
});
