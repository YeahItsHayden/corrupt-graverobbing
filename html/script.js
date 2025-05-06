let canvas, ctx, config, progress = 0, cursorPos = 0, isMovingRight = true;
let isMinigameActive = false;

window.addEventListener('message', (event) => {
    const data = event.data;
    if (data.action === 'startMinigame') {
        config = data.config;
        startMinigame();
    }
});

window.onload = function () {
    document.getElementById("minigame").classList.add("hidden");
};

function startMinigame() {
    isMinigameActive = true;
    progress = 0;
    cursorPos = 0;
    isMovingRight = true;
    document.body.classList.add("minigame-active");
    canvas = document.getElementById('diggingCanvas');
    ctx = canvas.getContext('2d');
    document.getElementById('minigame').classList.remove('hidden');
    document.getElementById('progress').textContent = `Progress: ${progress}/${config.stages}`;

    animate();
    document.addEventListener('keydown', handleInput);
}

function animate() {
    if (!isMinigameActive) return;

    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw safe zones
    config.safeZones.forEach(zone => {
        const startX = (zone.start / 100) * canvas.width;
        const width = ((zone.finish - zone.start) / 100) * canvas.width;
        ctx.fillStyle = 'rgba(0, 255, 0, 0.5)';
        ctx.fillRect(startX, 0, width, canvas.height);
    });

    // Draw danger zones
    config.dangerZones.forEach(zone => {
        const startX = (zone.start / 100) * canvas.width;
        const width = ((zone.finish - zone.start) / 100) * canvas.width;
        ctx.fillStyle = 'rgba(255, 0, 0, 0.5)';
        ctx.fillRect(startX, 0, width, canvas.height);
    });

    // Draw cursor
    const cursorX = (cursorPos / 100) * canvas.width;
    ctx.fillStyle = '#fff';
    ctx.fillRect(cursorX - 5, 0, 10, canvas.height);

    // Update cursor position
    const speed = 100 / (config.speed / 16.67); // Convert speed to % per frame (60 FPS)
    cursorPos += isMovingRight ? speed : -speed;
    if (cursorPos >= 100) {
        cursorPos = 100;
        isMovingRight = false;
    } else if (cursorPos <= 0) {
        cursorPos = 0;
        isMovingRight = true;
    }

    requestAnimationFrame(animate);
}

function handleInput(event) {
    if (!isMinigameActive) return;

    if (event.code === 'Escape') {
        // Cancel the minigame with failure
        isMinigameActive = false;
        endMinigame(false);
        return;
    }

    if (event.code !== 'Space') return;

    // Spacebar logic
    const cursorPercent = cursorPos;
    let isSafe = false;

    for (const zone of config.safeZones) {
        if (cursorPercent >= zone.start && cursorPercent <= zone.finish) {
            isSafe = true;
            break;
        }
    }

    if (isSafe) {
        progress++;
        new Audio('assets/shovel_click.wav').play();
        document.getElementById('progress').textContent = `Progress: ${progress}/${config.stages}`;
        if (progress >= config.stages) {
            isMinigameActive = false;
            endMinigame(true);
        }
    } else {
        new Audio('assets/obstacle_hit.wav').play();
        isMinigameActive = false;
        endMinigame(false);
    }
}


function endMinigame(success) {
    document.getElementById('minigame').classList.add('hidden');
    document.removeEventListener('keydown', handleInput);
    document.body.classList.remove("minigame-active");

    fetch(`https://${GetParentResourceName()}/minigameResult`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ success })
    });
}