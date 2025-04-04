// Script for handling timer UI

const timerContainer = document.getElementById('timer-container');
const timerValue = document.getElementById('timer-value');
const timerBar = document.getElementById('timer-bar');

let maxTime = 60; // Default value, will be updated from game

// Format seconds to MM:SS
function formatTime(seconds) {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
}

// Update timer UI
function updateTimer(timeLeft) {
    timerValue.textContent = formatTime(timeLeft);
    const percentage = (timeLeft / maxTime) * 100;
    timerBar.style.width = `${percentage}%`;
    
    // Change color based on time remaining
    if (percentage <= 25) {
        timerBar.style.backgroundColor = '#e74c3c'; // Red
    } else if (percentage <= 50) {
        timerBar.style.backgroundColor = '#f39c12'; // Orange
    } else {
        timerBar.style.backgroundColor = '#2ecc71'; // Green
    }
}

// Listen for messages from the NUI callback
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'showTimer') {
        timerContainer.classList.remove('hidden');
        maxTime = data.maxTime || 60;
        updateTimer(data.time);
    } else if (data.action === 'hideTimer') {
        timerContainer.classList.add('hidden');
    } else if (data.action === 'updateTimer') {
        updateTimer(data.time);
    }
}); 