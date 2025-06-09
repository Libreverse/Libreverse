#!/usr/bin/env ruby
# frozen_string_literal: true

# Rails runner script to add example experiences
# Usage: rails runner scripts/add_example_experiences.rb

puts "🎯 Adding example experiences to Libreverse..."

# First, let's find or create an admin account to own these experiences
admin_account = Account.find_by(admin: true)

if admin_account.nil?
  puts "⚠️  No admin account found. Creating one..."
  
  # Create an admin account (bypassing validations for username)
  admin_account = Account.new(
    username: "admin_demo",
    status: 2, # verified
    admin: true,
    guest: false
  )
  
  # Save without validations to avoid moderation issues with demo data
  admin_account.save!(validate: false)
  puts "✅ Created admin account: #{admin_account.username} (ID: #{admin_account.id})"
else
  puts "✅ Using existing admin account: #{admin_account.username} (ID: #{admin_account.id})"
end

# Sample HTML content for experiences
sample_html_files = [
  {
    filename: "virtual_gallery.html",
    content: <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Virtual Art Gallery</title>
          <style>
              body { margin: 0; font-family: Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
              .gallery { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; padding: 20px; }
              .artwork { background: white; border-radius: 10px; padding: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); transition: transform 0.3s ease; }
              .artwork:hover { transform: translateY(-5px); }
              .artwork-image { width: 100%; height: 200px; background: #f0f0f0; border-radius: 5px; margin-bottom: 10px; display: flex; align-items: center; justify-content: center; }
              h1 { text-align: center; color: white; margin: 20px 0; }
          </style>
      </head>
      <body>
          <h1>🎨 Virtual Art Gallery</h1>
          <div class="gallery">
              <div class="artwork">
                  <div class="artwork-image">🖼️ Digital Landscape</div>
                  <h3>Mountain Serenity</h3>
                  <p>A peaceful digital landscape showcasing mountain ranges at sunset.</p>
              </div>
              <div class="artwork">
                  <div class="artwork-image">🌆 City Lights</div>
                  <h3>Urban Dreams</h3>
                  <p>An abstract representation of city life through vibrant colors.</p>
              </div>
              <div class="artwork">
                  <div class="artwork-image">🌊 Ocean Waves</div>
                  <h3>Eternal Tide</h3>
                  <p>Capturing the eternal motion of ocean waves in digital art.</p>
              </div>
          </div>
      </body>
      </html>
    HTML
  },
  {
    filename: "interactive_story.html",
    content: <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Interactive Adventure</title>
          <style>
              body { margin: 0; padding: 20px; font-family: 'Georgia', serif; background: #1a1a1a; color: #f0f0f0; line-height: 1.6; }
              .story-container { max-width: 800px; margin: 0 auto; background: #2a2a2a; padding: 30px; border-radius: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
              .choices { margin: 20px 0; }
              .choice-btn { display: block; width: 100%; padding: 15px; margin: 10px 0; background: #4a4a4a; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; transition: background 0.3s; }
              .choice-btn:hover { background: #5a5a5a; }
              h1 { color: #ffd700; text-align: center; margin-bottom: 30px; }
              .story-text { font-size: 18px; margin-bottom: 20px; }
          </style>
      </head>
      <body>
          <div class="story-container">
              <h1>🗡️ The Mystic Forest</h1>
              <div class="story-text" id="story">
                  You stand at the edge of a mysterious forest. Ancient trees tower above you, their branches creating intricate patterns against the starlit sky. A gentle breeze carries whispers of forgotten legends.
              </div>
              <div class="choices">
                  <button class="choice-btn" onclick="updateStory('path')">Take the winding path deeper into the forest</button>
                  <button class="choice-btn" onclick="updateStory('clearing')">Head towards a moonlit clearing</button>
                  <button class="choice-btn" onclick="updateStory('stream')">Follow the sound of a babbling stream</button>
              </div>
          </div>
          
          <script>
              function updateStory(choice) {
                  const storyElement = document.getElementById('story');
                  switch(choice) {
                      case 'path':
                          storyElement.innerHTML = "The path winds deeper into the forest. Glowing mushrooms light your way as you discover an ancient stone circle covered in mystical runes. Magic fills the air around you.";
                          break;
                      case 'clearing':
                          storyElement.innerHTML = "In the moonlit clearing, you find a crystal-clear pond reflecting the stars above. A wise old owl perches nearby, watching you with knowing eyes.";
                          break;
                      case 'stream':
                          storyElement.innerHTML = "Following the stream, you discover it flows from an enchanted spring. The water sparkles with an otherworldly light, and you feel a sense of peace wash over you.";
                          break;
                  }
              }
          </script>
      </body>
      </html>
    HTML
  },
  {
    filename: "space_exploration.html",
    content: <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Space Exploration Dashboard</title>
          <style>
              body { margin: 0; padding: 0; background: radial-gradient(ellipse at center, #0c1445 0%, #000000 70%); color: white; font-family: 'Courier New', monospace; height: 100vh; overflow: hidden; }
              .dashboard { display: grid; grid-template-columns: 1fr 1fr; grid-template-rows: 1fr 1fr; height: 100vh; gap: 20px; padding: 20px; box-sizing: border-box; }
              .panel { background: rgba(0, 50, 100, 0.3); border: 2px solid #00ffff; border-radius: 10px; padding: 20px; position: relative; }
              .panel h2 { color: #00ffff; margin-top: 0; text-align: center; }
              .stars { position: fixed; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: -1; }
              .star { position: absolute; background: white; border-radius: 50%; animation: twinkle 2s infinite; }
              @keyframes twinkle { 0%, 100% { opacity: 0.3; } 50% { opacity: 1; } }
              .planet { width: 60px; height: 60px; border-radius: 50%; margin: 10px auto; }
              .earth { background: linear-gradient(45deg, #4a90e2, #50c878); }
              .mars { background: linear-gradient(45deg, #cd5c5c, #a0522d); }
              .jupiter { background: linear-gradient(45deg, #daa520, #ff8c00); }
              .data-stream { font-family: monospace; color: #00ff00; font-size: 12px; }
          </style>
      </head>
      <body>
          <div class="stars" id="stars"></div>
          <div class="dashboard">
              <div class="panel">
                  <h2>🌍 Earth Status</h2>
                  <div class="planet earth"></div>
                  <div class="data-stream">
                      Orbital Velocity: 29.78 km/s<br>
                      Distance from Sun: 149.6M km<br>
                      Atmosphere: 78% N₂, 21% O₂<br>
                      Status: Habitable ✅
                  </div>
              </div>
              <div class="panel">
                  <h2>🔴 Mars Mission</h2>
                  <div class="planet mars"></div>
                  <div class="data-stream">
                      Mission Status: En Route<br>
                      Travel Time: 7 months<br>
                      Crew: 6 astronauts<br>
                      Objective: Sample Collection 🚀
                  </div>
              </div>
              <div class="panel">
                  <h2>🪐 Jupiter Observatory</h2>
                  <div class="planet jupiter"></div>
                  <div class="data-stream">
                      Moons Detected: 79<br>
                      Great Red Spot: Active<br>
                      Magnetic Field: Intense<br>
                      Research: Ongoing 🔭
                  </div>
              </div>
              <div class="panel">
                  <h2>📡 Deep Space Communications</h2>
                  <div class="data-stream" id="communications">
                      [INCOMING SIGNAL]<br>
                      Source: Voyager 1<br>
                      Status: Operational<br>
                      Message: "Still exploring..."
                  </div>
              </div>
          </div>
          
          <script>
              // Create twinkling stars
              function createStars() {
                  const starsContainer = document.getElementById('stars');
                  for (let i = 0; i < 50; i++) {
                      const star = document.createElement('div');
                      star.className = 'star';
                      star.style.left = Math.random() * 100 + '%';
                      star.style.top = Math.random() * 100 + '%';
                      star.style.width = Math.random() * 3 + 1 + 'px';
                      star.style.height = star.style.width;
                      star.style.animationDelay = Math.random() * 2 + 's';
                      starsContainer.appendChild(star);
                  }
              }
              
              createStars();
          </script>
      </body>
      </html>
    HTML
  },
  {
    filename: "music_visualizer.html",
    content: <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Audio Visualizer</title>
          <style>
              body { margin: 0; padding: 0; background: #000; color: white; font-family: Arial, sans-serif; height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; }
              .visualizer { width: 800px; height: 400px; background: radial-gradient(circle, #1a1a2e 0%, #16213e 50%, #0f3460 100%); border-radius: 20px; padding: 20px; display: flex; align-items: end; justify-content: space-around; overflow: hidden; }
              .bar { width: 8px; background: linear-gradient(to top, #ff6b6b, #4ecdc4, #45b7d1); border-radius: 4px 4px 0 0; transition: height 0.1s ease; animation: pulse 2s infinite; }
              @keyframes pulse { 0%, 100% { opacity: 0.7; } 50% { opacity: 1; } }
              .controls { margin-top: 20px; text-align: center; }
              .btn { background: #4ecdc4; color: white; border: none; padding: 10px 20px; border-radius: 25px; cursor: pointer; margin: 0 10px; font-size: 16px; transition: background 0.3s; }
              .btn:hover { background: #45b7d1; }
              h1 { margin-bottom: 20px; background: linear-gradient(45deg, #ff6b6b, #4ecdc4); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
          </style>
      </head>
      <body>
          <h1>🎵 Audio Visualizer Experience</h1>
          <div class="visualizer" id="visualizer"></div>
          <div class="controls">
              <button class="btn" onclick="startVisualization()">Start Visualization</button>
              <button class="btn" onclick="changeMode()">Change Mode</button>
              <button class="btn" onclick="randomize()">Randomize</button>
          </div>
          
          <script>
              let isPlaying = false;
              let animationId;
              let mode = 0;
              
              function createBars() {
                  const visualizer = document.getElementById('visualizer');
                  visualizer.innerHTML = '';
                  for (let i = 0; i < 80; i++) {
                      const bar = document.createElement('div');
                      bar.className = 'bar';
                      bar.style.height = '10px';
                      bar.style.animationDelay = (i * 0.1) + 's';
                      visualizer.appendChild(bar);
                  }
              }
              
              function animateBars() {
                  const bars = document.querySelectorAll('.bar');
                  bars.forEach((bar, index) => {
                      let height;
                      switch(mode) {
                          case 0:
                              height = Math.sin(Date.now() * 0.005 + index * 0.1) * 150 + 160;
                              break;
                          case 1:
                              height = Math.random() * 300 + 50;
                              break;
                          case 2:
                              height = Math.abs(Math.sin(Date.now() * 0.003 + index * 0.2)) * 250 + 100;
                              break;
                      }
                      bar.style.height = height + 'px';
                  });
                  
                  if (isPlaying) {
                      animationId = requestAnimationFrame(animateBars);
                  }
              }
              
              function startVisualization() {
                  isPlaying = !isPlaying;
                  if (isPlaying) {
                      animateBars();
                      event.target.textContent = 'Stop Visualization';
                  } else {
                      cancelAnimationFrame(animationId);
                      event.target.textContent = 'Start Visualization';
                  }
              }
              
              function changeMode() {
                  mode = (mode + 1) % 3;
                  const modes = ['Wave', 'Random', 'Pulse'];
                  event.target.textContent = 'Mode: ' + modes[mode];
              }
              
              function randomize() {
                  const bars = document.querySelectorAll('.bar');
                  bars.forEach(bar => {
                      bar.style.height = Math.random() * 300 + 50 + 'px';
                      bar.style.background = `hsl(${Math.random() * 360}, 70%, 60%)`;
                  });
              }
              
              createBars();
          </script>
      </body>
      </html>
    HTML
  },
  {
    filename: "digital_garden.html",
    content: <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Digital Garden</title>
          <style>
              body { margin: 0; padding: 0; background: linear-gradient(to bottom, #87CEEB 0%, #98FB98 50%, #228B22 100%); font-family: Arial, sans-serif; height: 100vh; overflow: hidden; }
              .garden { position: relative; width: 100%; height: 100%; }
              .flower { position: absolute; cursor: pointer; transition: transform 0.3s ease; }
              .flower:hover { transform: scale(1.2); }
              .sun { position: absolute; top: 50px; right: 50px; width: 80px; height: 80px; background: radial-gradient(circle, #FFD700, #FFA500); border-radius: 50%; animation: shine 3s ease-in-out infinite; }
              @keyframes shine { 0%, 100% { box-shadow: 0 0 20px #FFD700; } 50% { box-shadow: 0 0 40px #FFD700; } }
              .cloud { position: absolute; background: white; border-radius: 50px; opacity: 0.8; animation: float 10s linear infinite; }
              .cloud::before, .cloud::after { content: ''; position: absolute; background: white; border-radius: 50px; }
              .controls { position: absolute; bottom: 20px; left: 50%; transform: translateX(-50%); text-align: center; }
              .garden-btn { background: rgba(34, 139, 34, 0.8); color: white; border: none; padding: 10px 20px; border-radius: 20px; margin: 0 5px; cursor: pointer; }
              .garden-btn:hover { background: rgba(34, 139, 34, 1); }
              .counter { position: absolute; top: 20px; left: 20px; background: rgba(255, 255, 255, 0.8); padding: 10px; border-radius: 10px; }
          </style>
      </head>
      <body>
          <div class="garden" id="garden">
              <div class="sun"></div>
              <div class="counter">
                  <div>🌸 Flowers: <span id="flower-count">0</span></div>
                  <div>☁️ Clouds: <span id="cloud-count">3</span></div>
              </div>
              <div class="controls">
                  <button class="garden-btn" onclick="plantFlower()">🌱 Plant Flower</button>
                  <button class="garden-btn" onclick="addCloud()">☁️ Add Cloud</button>
                  <button class="garden-btn" onclick="clearGarden()">🧹 Clear Garden</button>
                  <button class="garden-btn" onclick="makeItRain()">🌧️ Rain</button>
              </div>
          </div>
          
          <script>
              let flowerCount = 0;
              let cloudCount = 3;
              
              const flowers = ['🌸', '🌺', '🌻', '🌷', '🌹', '💐', '🌼'];
              
              function plantFlower() {
                  const garden = document.getElementById('garden');
                  const flower = document.createElement('div');
                  flower.className = 'flower';
                  flower.innerHTML = flowers[Math.floor(Math.random() * flowers.length)];
                  flower.style.fontSize = (Math.random() * 30 + 20) + 'px';
                  flower.style.left = Math.random() * (window.innerWidth - 50) + 'px';
                  flower.style.top = Math.random() * (window.innerHeight - 200) + 100 + 'px';
                  flower.onclick = function() { this.remove(); updateFlowerCount(-1); };
                  garden.appendChild(flower);
                  updateFlowerCount(1);
                  
                  // Grow animation
                  flower.style.transform = 'scale(0)';
                  setTimeout(() => { flower.style.transform = 'scale(1)'; }, 10);
              }
              
              function addCloud() {
                  const garden = document.getElementById('garden');
                  const cloud = document.createElement('div');
                  cloud.className = 'cloud';
                  cloud.style.width = (Math.random() * 60 + 40) + 'px';
                  cloud.style.height = (Math.random() * 30 + 20) + 'px';
                  cloud.style.top = Math.random() * 200 + 50 + 'px';
                  cloud.style.left = '-100px';
                  cloud.style.animationDuration = (Math.random() * 10 + 15) + 's';
                  garden.appendChild(cloud);
                  
                  setTimeout(() => cloud.remove(), 25000);
                  updateCloudCount(1);
              }
              
              function clearGarden() {
                  const flowers = document.querySelectorAll('.flower');
                  flowers.forEach(flower => flower.remove());
                  flowerCount = 0;
                  document.getElementById('flower-count').textContent = flowerCount;
              }
              
              function makeItRain() {
                  const garden = document.getElementById('garden');
                  for (let i = 0; i < 20; i++) {
                      setTimeout(() => {
                          const raindrop = document.createElement('div');
                          raindrop.innerHTML = '💧';
                          raindrop.style.position = 'absolute';
                          raindrop.style.left = Math.random() * window.innerWidth + 'px';
                          raindrop.style.top = '-20px';
                          raindrop.style.fontSize = '20px';
                          raindrop.style.animation = 'fall 2s linear';
                          raindrop.style.pointerEvents = 'none';
                          garden.appendChild(raindrop);
                          
                          setTimeout(() => raindrop.remove(), 2000);
                      }, i * 100);
                  }
              }
              
              function updateFlowerCount(delta) {
                  flowerCount += delta;
                  document.getElementById('flower-count').textContent = flowerCount;
              }
              
              function updateCloudCount(delta) {
                  cloudCount += delta;
                  document.getElementById('cloud-count').textContent = cloudCount;
              }
              
              // Initialize with some clouds
              for (let i = 0; i < 3; i++) {
                  setTimeout(addCloud, i * 2000);
              }
              
              // Add CSS for falling animation
              const style = document.createElement('style');
              style.textContent = `
                  @keyframes fall {
                      to { transform: translateY(${window.innerHeight + 50}px); }
                  }
                  @keyframes float {
                      from { transform: translateX(-100px); }
                      to { transform: translateX(${window.innerWidth + 100}px); }
                  }
              `;
              document.head.appendChild(style);
          </script>
      </body>
      </html>
    HTML
  }
]

# Experience data
experiences_data = [
  {
    title: "Virtual Art Gallery Experience",
    description: "Step into a beautiful virtual art gallery featuring digital artworks and interactive displays. Explore different artistic styles and immerse yourself in a curated collection of digital masterpieces.",
    author: "Gallery Curator",
    html_file_data: sample_html_files[0]
  },
  {
    title: "Interactive Fantasy Adventure",
    description: "Embark on a choose-your-own-adventure story set in a mysterious enchanted forest. Make decisions that shape your journey and discover the secrets hidden within the mystical woodland.",
    author: "Story Weaver",
    html_file_data: sample_html_files[1]
  },
  {
    title: "Space Mission Control Dashboard",
    description: "Experience life as a space mission controller with this interactive dashboard. Monitor multiple planets, track space missions, and stay connected with deep space communications.",
    author: "Astronaut Alpha",
    html_file_data: sample_html_files[2]
  },
  {
    title: "Dynamic Audio Visualizer",
    description: "A mesmerizing audio visualization experience with multiple modes and interactive controls. Watch as sound comes to life through beautiful animated graphics and responsive visual effects.",
    author: "Sound Engineer",
    html_file_data: sample_html_files[3]
  },
  {
    title: "Interactive Digital Garden",
    description: "Create and tend your own digital garden! Plant flowers, add clouds, make it rain, and watch your virtual garden grow. A peaceful and interactive nature experience.",
    author: "Digital Gardener",
    html_file_data: sample_html_files[4]
  },
  {
    title: "Retro Arcade Experience",
    description: "A nostalgic journey back to the golden age of arcade games. Features classic game aesthetics, pixel art styling, and interactive elements that capture the spirit of retro gaming.",
    author: "Pixel Artist",
    html_file_data: {
      filename: "retro_arcade.html",
      content: <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Retro Arcade</title>
            <style>
                @import url('https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap');
                body { margin: 0; padding: 0; background: #000; color: #00ff00; font-family: 'Press Start 2P', monospace; height: 100vh; overflow: hidden; }
                .arcade-machine { width: 100%; height: 100%; background: linear-gradient(45deg, #1a1a1a, #333); display: flex; flex-direction: column; align-items: center; justify-content: center; }
                .screen { width: 80%; height: 70%; background: #000; border: 10px solid #444; border-radius: 20px; position: relative; overflow: hidden; }
                .game-area { width: 100%; height: 100%; position: relative; }
                .player { position: absolute; bottom: 50px; left: 50%; transform: translateX(-50%); color: #00ff00; font-size: 24px; }
                .enemy { position: absolute; color: #ff0000; font-size: 20px; }
                .score { position: absolute; top: 20px; left: 20px; color: #ffff00; }
                .controls { margin-top: 20px; text-align: center; }
                .control-btn { background: #444; color: #00ff00; border: none; padding: 15px 20px; margin: 0 5px; font-family: inherit; font-size: 12px; border-radius: 5px; cursor: pointer; }
                .control-btn:hover { background: #666; }
                .title { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); text-align: center; animation: blink 1s infinite; }
                @keyframes blink { 0%, 50% { opacity: 1; } 51%, 100% { opacity: 0; } }
            </style>
        </head>
        <body>
            <div class="arcade-machine">
                <div class="screen">
                    <div class="game-area" id="gameArea">
                        <div class="title" id="title">
                            🕹️ RETRO ARCADE 🕹️<br><br>
                            PRESS START
                        </div>
                        <div class="score" id="score" style="display: none;">SCORE: 0</div>
                        <div class="player" id="player" style="display: none;">🚀</div>
                    </div>
                </div>
                <div class="controls">
                    <button class="control-btn" onclick="startGame()">START</button>
                    <button class="control-btn" onclick="moveLeft()">◀ LEFT</button>
                    <button class="control-btn" onclick="moveRight()">RIGHT ▶</button>
                    <button class="control-btn" onclick="shoot()">🔥 FIRE</button>
                </div>
            </div>
            
            <script>
                let gameStarted = false;
                let score = 0;
                let playerPos = 50;
                let enemies = [];
                let bullets = [];
                
                function startGame() {
                    gameStarted = true;
                    document.getElementById('title').style.display = 'none';
                    document.getElementById('score').style.display = 'block';
                    document.getElementById('player').style.display = 'block';
                    spawnEnemies();
                }
                
                function moveLeft() {
                    if (!gameStarted) return;
                    playerPos = Math.max(5, playerPos - 10);
                    document.getElementById('player').style.left = playerPos + '%';
                }
                
                function moveRight() {
                    if (!gameStarted) return;
                    playerPos = Math.min(95, playerPos + 10);
                    document.getElementById('player').style.left = playerPos + '%';
                }
                
                function shoot() {
                    if (!gameStarted) return;
                    const bullet = document.createElement('div');
                    bullet.innerHTML = '•';
                    bullet.style.position = 'absolute';
                    bullet.style.color = '#ffff00';
                    bullet.style.fontSize = '20px';
                    bullet.style.left = playerPos + '%';
                    bullet.style.bottom = '90px';
                    document.getElementById('gameArea').appendChild(bullet);
                    
                    bullets.push({ element: bullet, x: playerPos, y: 90 });
                    moveBullets();
                }
                
                function spawnEnemies() {
                    if (!gameStarted) return;
                    
                    const enemy = document.createElement('div');
                    enemy.className = 'enemy';
                    enemy.innerHTML = '👾';
                    enemy.style.left = Math.random() * 90 + '%';
                    enemy.style.top = '0px';
                    document.getElementById('gameArea').appendChild(enemy);
                    
                    enemies.push({ element: enemy, x: Math.random() * 90, y: 0 });
                    
                    setTimeout(spawnEnemies, 2000);
                }
                
                function moveBullets() {
                    bullets.forEach((bullet, index) => {
                        bullet.y += 10;
                        bullet.element.style.bottom = bullet.y + 'px';
                        
                        if (bullet.y > window.innerHeight) {
                            bullet.element.remove();
                            bullets.splice(index, 1);
                        }
                    });
                    
                    if (bullets.length > 0) {
                        setTimeout(moveBullets, 100);
                    }
                }
                
                function updateScore() {
                    score += 10;
                    document.getElementById('score').textContent = 'SCORE: ' + score;
                }
                
                // Keyboard controls
                document.addEventListener('keydown', function(e) {
                    switch(e.key) {
                        case 'ArrowLeft':
                            moveLeft();
                            break;
                        case 'ArrowRight':
                            moveRight();
                            break;
                        case ' ':
                            e.preventDefault();
                            shoot();
                            break;
                        case 'Enter':
                            if (!gameStarted) startGame();
                            break;
                    }
                });
            </script>
        </body>
        </html>
      HTML
    }
  },
  {
    title: "Meditation and Mindfulness Space",
    description: "A tranquil digital environment designed for meditation and relaxation. Features ambient sounds, breathing exercises, and calming visual elements to help you find inner peace.",
    author: "Zen Master",
    html_file_data: {
      filename: "meditation_space.html",
      content: <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Meditation Space</title>
            <style>
                body { margin: 0; padding: 0; background: radial-gradient(circle, #2c3e50 0%, #1a252f 70%); color: white; font-family: 'Georgia', serif; height: 100vh; overflow: hidden; display: flex; align-items: center; justify-content: center; }
                .meditation-container { text-align: center; max-width: 800px; padding: 40px; }
                .breathing-circle { width: 200px; height: 200px; border: 3px solid rgba(255, 255, 255, 0.3); border-radius: 50%; margin: 40px auto; position: relative; transition: transform 4s ease-in-out; }
                .breathing-circle.inhale { transform: scale(1.5); }
                .inner-circle { width: 100%; height: 100%; background: radial-gradient(circle, rgba(100, 149, 237, 0.3), transparent); border-radius: 50%; display: flex; align-items: center; justify-content: center; }
                .breathing-text { font-size: 18px; opacity: 0.8; margin: 20px 0; }
                .meditation-controls { margin-top: 40px; }
                .med-btn { background: rgba(255, 255, 255, 0.1); color: white; border: 2px solid rgba(255, 255, 255, 0.3); padding: 12px 24px; margin: 0 10px; border-radius: 30px; cursor: pointer; font-size: 16px; transition: all 0.3s; }
                .med-btn:hover { background: rgba(255, 255, 255, 0.2); }
                .quote { font-style: italic; font-size: 20px; margin: 30px 0; opacity: 0.9; line-height: 1.6; }
                .floating-particles { position: fixed; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: -1; }
                .particle { position: absolute; background: rgba(255, 255, 255, 0.1); border-radius: 50%; animation: float 20s linear infinite; }
                @keyframes float { 0% { transform: translateY(100vh) rotate(0deg); opacity: 0; } 10% { opacity: 1; } 90% { opacity: 1; } 100% { transform: translateY(-100px) rotate(360deg); opacity: 0; } }
            </style>
        </head>
        <body>
            <div class="floating-particles" id="particles"></div>
            <div class="meditation-container">
                <h1>🧘‍♀️ Mindful Moment</h1>
                <div class="quote" id="quote">
                    "Peace comes from within. Do not seek it without." - Buddha
                </div>
                
                <div class="breathing-circle" id="breathingCircle">
                    <div class="inner-circle">
                        <span id="breathingGuidance">🌸</span>
                    </div>
                </div>
                
                <div class="breathing-text" id="breathingText">
                    Click "Start Breathing" to begin your meditation journey
                </div>
                
                <div class="meditation-controls">
                    <button class="med-btn" onclick="startBreathing()">Start Breathing</button>
                    <button class="med-btn" onclick="changeQuote()">New Quote</button>
                    <button class="med-btn" onclick="toggleAmbience()">Ambient Mode</button>
                </div>
            </div>
            
            <script>
                let breathingActive = false;
                let breathingCycle = 0;
                let ambienceMode = false;
                
                const quotes = [
                    "Peace comes from within. Do not seek it without. - Buddha",
                    "The present moment is the only time over which we have dominion. - Thích Nhất Hạnh",
                    "Meditation is a way for nourishing and blossoming the divinity within you. - Amit Ray",
                    "Quiet the mind, and the soul will speak. - Ma Jaya Sati Bhagavati",
                    "The thing about meditation is: You become more and more you. - David Lynch",
                    "In the midst of movement and chaos, keep stillness inside of you. - Deepak Chopra"
                ];
                
                function startBreathing() {
                    breathingActive = !breathingActive;
                    const button = event.target;
                    
                    if (breathingActive) {
                        button.textContent = 'Stop Breathing';
                        breathe();
                    } else {
                        button.textContent = 'Start Breathing';
                        document.getElementById('breathingText').textContent = 'Breathing exercise stopped. Take a moment to notice how you feel.';
                    }
                }
                
                function breathe() {
                    if (!breathingActive) return;
                    
                    const circle = document.getElementById('breathingCircle');
                    const text = document.getElementById('breathingText');
                    const guidance = document.getElementById('breathingGuidance');
                    
                    if (breathingCycle % 2 === 0) {
                        // Inhale
                        circle.classList.add('inhale');
                        text.textContent = 'Breathe in slowly... feel your chest expand';
                        guidance.textContent = '🌬️';
                        setTimeout(() => {
                            if (breathingActive) {
                                breathingCycle++;
                                breathe();
                            }
                        }, 4000);
                    } else {
                        // Exhale
                        circle.classList.remove('inhale');
                        text.textContent = 'Breathe out gently... release all tension';
                        guidance.textContent = '🕊️';
                        setTimeout(() => {
                            if (breathingActive) {
                                breathingCycle++;
                                breathe();
                            }
                        }, 4000);
                    }
                }
                
                function changeQuote() {
                    const quoteElement = document.getElementById('quote');
                    const randomQuote = quotes[Math.floor(Math.random() * quotes.length)];
                    quoteElement.style.opacity = '0';
                    setTimeout(() => {
                        quoteElement.textContent = randomQuote;
                        quoteElement.style.opacity = '1';
                    }, 300);
                }
                
                function toggleAmbience() {
                    ambienceMode = !ambienceMode;
                    const button = event.target;
                    
                    if (ambienceMode) {
                        button.textContent = 'Stop Ambience';
                        createParticles();
                        document.body.style.background = 'radial-gradient(circle, #1a237e 0%, #000051 70%)';
                    } else {
                        button.textContent = 'Ambient Mode';
                        document.getElementById('particles').innerHTML = '';
                        document.body.style.background = 'radial-gradient(circle, #2c3e50 0%, #1a252f 70%)';
                    }
                }
                
                function createParticles() {
                    if (!ambienceMode) return;
                    
                    const container = document.getElementById('particles');
                    const particle = document.createElement('div');
                    particle.className = 'particle';
                    particle.style.left = Math.random() * 100 + '%';
                    particle.style.width = Math.random() * 10 + 3 + 'px';
                    particle.style.height = particle.style.width;
                    particle.style.animationDelay = Math.random() * 5 + 's';
                    container.appendChild(particle);
                    
                    setTimeout(() => particle.remove(), 20000);
                    
                    if (ambienceMode) {
                        setTimeout(createParticles, 2000);
                    }
                }
                
                // Initialize with some particles
                for (let i = 0; i < 10; i++) {
                    setTimeout(createParticles, i * 1000);
                }
            </script>
        </body>
        </html>
      HTML
    }
  }
]

puts "\n🌱 Creating experiences..."

created_count = 0
failed_count = 0

experiences_data.each_with_index do |exp_data, index|
  puts "\n📝 Creating: '#{exp_data[:title]}'..."
  
  begin
    # Create the experience
    experience = Experience.new(
      title: exp_data[:title],
      description: exp_data[:description],
      author: exp_data[:author],
      account: admin_account,
      approved: true # Auto-approve since it's created by admin
    )
    
    # Create and attach the HTML file
    html_content = exp_data[:html_file_data][:content]
    filename = exp_data[:html_file_data][:filename]
    
    # Create a temporary file
    temp_file = Tempfile.new([filename.gsub('.html', ''), '.html'])
    temp_file.write(html_content)
    temp_file.rewind
    
    # Attach the file
    experience.html_file.attach(
      io: temp_file,
      filename: filename,
      content_type: 'text/html'
    )
    
    # Save the experience (skip validations to bypass moderation for demo data)
    if experience.save(validate: false)
      puts "   ✅ Successfully created '#{experience.title}' (ID: #{experience.id})"
      created_count += 1
    else
      puts "   ❌ Failed to create '#{exp_data[:title]}': #{experience.errors.full_messages.join(', ')}"
      failed_count += 1
    end
    
    temp_file.close
    temp_file.unlink
    
  rescue => e
    puts "   ❌ Error creating '#{exp_data[:title]}': #{e.message}"
    failed_count += 1
  end
  
  # Small delay between creations
  sleep(0.1)
end

puts "\n" + "="*60
puts "🎯 Experience Creation Summary:"
puts "   ✅ Successfully created: #{created_count} experiences"
puts "   ❌ Failed to create: #{failed_count} experiences"
puts "   📊 Total experiences in database: #{Experience.count}"
puts "   🎉 Approved experiences: #{Experience.approved.count}"
puts "   ⏳ Pending approval: #{Experience.pending_approval.count}"

if created_count > 0
  puts "\n🚀 Great! You now have example experiences to explore."
  puts "   💡 Visit the experiences page to see them in action!"
  puts "   🔗 Or use the API to interact with them programmatically."
end

puts "\n🎉 Done! Your Libreverse instance now has sample content to explore."
