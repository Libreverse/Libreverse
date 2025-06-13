# frozen_string_literal: true

# Service for managing example experiences
class ExampleExperiencesService
  EXAMPLE_TITLES = [
    "Virtual Art Gallery Experience",
    "Interactive Fantasy Adventure",
    "Space Mission Control Dashboard",
    "Dynamic Audio Visualizer",
    "Interactive Digital Garden",
    "Retro Arcade Experience"
  ].freeze

  class << self
    def add_examples
      admin_account = find_or_create_admin_account
      created_count = 0

      experience_data.each do |exp_data|
        next if Experience.exists?(title: exp_data[:title], author: exp_data[:author])

        experience = create_experience(exp_data, admin_account)
        created_count += 1 if experience.persisted?
      end

      { created: created_count }
    end

    def restore_examples
      restored_count = 0

      experience_data.each do |exp_data|
        experience = Experience.find_by(title: exp_data[:title], author: exp_data[:author])
        next unless experience

        restored_count += 1 if update_experience_content(experience, exp_data)
      end

      { restored: restored_count }
    end

    def delete_examples
      deleted_count = Experience.where(title: EXAMPLE_TITLES).destroy_all.count
      { deleted: deleted_count }
    end

    def experience_data
      [
        {
          title: "Virtual Art Gallery Experience",
          description: "Step into a beautiful virtual art gallery featuring digital artworks and interactive displays. Explore different artistic styles and immerse yourself in a curated collection of digital masterpieces.",
          author: "Gallery Curator",
          html_file_data: {
            filename: "virtual_gallery.html",
            content: virtual_gallery_html
          }
        },
        {
          title: "Interactive Fantasy Adventure",
          description: "Embark on a choose-your-own-adventure story set in a mysterious enchanted forest. Make decisions that shape your journey and discover the secrets hidden within the mystical woodland.",
          author: "Story Weaver",
          html_file_data: {
            filename: "fantasy_adventure.html",
            content: fantasy_adventure_html
          }
        },
        {
          title: "Space Mission Control Dashboard",
          description: "Experience life as a space mission controller with this interactive dashboard. Monitor multiple planets, track space missions, and stay connected with deep space communications.",
          author: "Astronaut Alpha",
          html_file_data: {
            filename: "space_dashboard.html",
            content: space_dashboard_html
          }
        },
        {
          title: "Dynamic Audio Visualizer",
          description: "A mesmerizing audio visualization experience with multiple modes and interactive controls. Watch as sound comes to life through beautiful animated graphics and responsive visual effects.",
          author: "Sound Engineer",
          html_file_data: {
            filename: "music_visualizer.html",
            content: music_visualizer_html
          }
        },
        {
          title: "Interactive Digital Garden",
          description: "Create and tend your own digital garden! Plant flowers, add clouds, make it rain, and watch your virtual garden grow. A peaceful and interactive nature experience.",
          author: "Digital Gardener",
          html_file_data: {
            filename: "digital_garden.html",
            content: digital_garden_html
          }
        },
        {
          title: "Retro Arcade Experience",
          description: "A nostalgic journey back to the golden age of arcade games. Features classic game aesthetics, pixel art styling, and interactive elements that capture the spirit of retro gaming.",
          author: "Pixel Artist",
          html_file_data: {
            filename: "retro_arcade.html",
            content: retro_arcade_html
          }
        }
      ]
    end

    private

    def find_or_create_admin_account
      admin_account = Account.find_by(admin: true)

      if admin_account.nil?
        admin_account = Account.new(
          username: "admin_demo",
          status: 2, # verified
          admin: true,
          guest: false
        )
        admin_account.save!(validate: false)
      end

      admin_account
    end

    def create_experience(exp_data, admin_account)
      experience = Experience.new(
        title: exp_data[:title],
        description: exp_data[:description],
        author: exp_data[:author],
        account: admin_account,
        approved: true
      )

      attach_html_file(experience, exp_data[:html_file_data])
      experience.save(validate: false)
      experience
    end

    def update_experience_content(experience, exp_data)
      experience.description = exp_data[:description]

      # Remove old file attachment
      experience.html_file.purge if experience.html_file.attached?

      # Attach new file
      attach_html_file(experience, exp_data[:html_file_data])
      experience.save(validate: false)
    end

    def attach_html_file(experience, html_file_data)
      temp_file = Tempfile.new([ html_file_data[:filename].gsub(".html", ""), ".html" ])
      temp_file.write(html_file_data[:content])
      temp_file.rewind

      experience.html_file.attach(
        io: temp_file,
        filename: html_file_data[:filename],
        content_type: "text/html"
      )

      temp_file.close
      temp_file.unlink
    end

    def virtual_gallery_html
      <<~HTML
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
                    <div class="artwork-image">🖼️ Abstract Colors</div>
                    <h3>Digital Dreams</h3>
                    <p>A vibrant exploration of color and emotion in the digital realm.</p>
                </div>
                <div class="artwork">
                    <div class="artwork-image">🌟 Geometric Patterns</div>
                    <h3>Sacred Geometry</h3>
                    <p>Mathematical beauty expressed through repeating patterns and shapes.</p>
                </div>
                <div class="artwork">
                    <div class="artwork-image">🌊 Fluid Motion</div>
                    <h3>Ocean Waves</h3>
                    <p>The eternal dance of water captured in digital brushstrokes.</p>
                </div>
                <div class="artwork">
                    <div class="artwork-image">🔥 Dynamic Energy</div>
                    <h3>Fire & Light</h3>
                    <p>Raw energy and illumination converging in digital space.</p>
                </div>
            </div>
        </body>
        </html>
      HTML
    end

    def fantasy_adventure_html
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Fantasy Adventure</title>
            <style>
                body { margin: 0; padding: 20px; background: linear-gradient(45deg, #2d1b69 0%, #11998e 100%); color: white; font-family: Georgia, serif; min-height: 100vh; }
                .story-container { max-width: 800px; margin: 0 auto; background: rgba(0,0,0,0.3); padding: 30px; border-radius: 15px; }
                .choice { background: rgba(255,255,255,0.1); margin: 10px 0; padding: 15px; border-radius: 8px; cursor: pointer; transition: background 0.3s; }
                .choice:hover { background: rgba(255,255,255,0.2); }
                h1 { text-align: center; color: #ffd700; }
            </style>
        </head>
        <body>
            <div class="story-container">
                <h1>🧙‍♂️ The Enchanted Forest</h1>
                <div id="story">
                    <p>You find yourself at the edge of a mysterious forest. Ancient trees tower above you, their branches whispering secrets in the wind. Two paths diverge before you...</p>
                    <div class="choice" onclick="choosePath('left')">Take the left path through the misty grove</div>
                    <div class="choice" onclick="choosePath('right')">Take the right path along the babbling brook</div>
                </div>
            </div>
            <script>
                function choosePath(direction) {
                    const story = document.getElementById('story');
                    if (direction === 'left') {
                        story.innerHTML = '<p>🌫️ You venture into the misty grove where glowing mushrooms light your way. A wise old owl perches nearby, offering you a riddle...</p><div class="choice" onclick="restart()">Start Over</div>';
                    } else {
                        story.innerHTML = '<p>🏞️ Following the brook, you discover a clearing where magical creatures dance in the moonlight. They invite you to join their celebration...</p><div class="choice" onclick="restart()">Start Over</div>';
                    }
                }
                function restart() {
                    location.reload();
                }
            </script>
        </body>
        </html>
      HTML
    end

    def space_dashboard_html
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Space Mission Control</title>
            <style>
                body { margin: 0; padding: 0; background: #000; color: #00ff00; font-family: 'Courier New', monospace; height: 100vh; }
                .dashboard { display: grid; grid-template-columns: 1fr 1fr; grid-template-rows: 1fr 1fr; gap: 10px; padding: 10px; height: 100vh; box-sizing: border-box; }
                .panel { background: rgba(0,255,0,0.1); border: 2px solid #00ff00; padding: 20px; border-radius: 10px; }
                .status { color: #ffff00; }
                .alert { color: #ff0000; animation: blink 1s infinite; }
                @keyframes blink { 0%, 50% { opacity: 1; } 51%, 100% { opacity: 0; } }
                h2 { margin-top: 0; text-align: center; }
            </style>
        </head>
        <body>
            <div class="dashboard">
                <div class="panel">
                    <h2>🌍 Earth Status</h2>
                    <p>Orbit: <span class="status">STABLE</span></p>
                    <p>Communication: <span class="status">ONLINE</span></p>
                    <p>Weather: <span class="status">CLEAR</span></p>
                </div>
                <div class="panel">
                    <h2>🚀 Mission Control</h2>
                    <p>Active Missions: <span class="status">3</span></p>
                    <p>Crew Status: <span class="status">HEALTHY</span></p>
                    <p>Fuel Level: <span class="alert">LOW</span></p>
                </div>
                <div class="panel">
                    <h2>🪐 Deep Space</h2>
                    <p>Mars Rover: <span class="status">OPERATIONAL</span></p>
                    <p>Jupiter Probe: <span class="status">EN ROUTE</span></p>
                    <p>Voyager: <span class="status">DISTANT</span></p>
                </div>
                <div class="panel">
                    <h2>📡 Communications</h2>
                    <p>Signal Strength: <span class="status">95%</span></p>
                    <p>Data Rate: <span class="status">1.2 Mbps</span></p>
                    <p>Next Contact: <span class="status">00:45:23</span></p>
                </div>
            </div>
        </body>
        </html>
      HTML
    end

    def music_visualizer_html
      <<~HTML
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
        #{'        '}
                function createBars() {
                    const visualizer = document.getElementById('visualizer');
                    visualizer.innerHTML = '';
                    for(let i = 0; i < 64; i++) {
                        const bar = document.createElement('div');
                        bar.className = 'bar';
                        bar.style.height = Math.random() * 200 + 20 + 'px';
                        visualizer.appendChild(bar);
                    }
                }
        #{'        '}
                function animateBars() {
                    const bars = document.querySelectorAll('.bar');
                    bars.forEach(bar => {
                        bar.style.height = Math.random() * 300 + 20 + 'px';
                    });
                    if(isPlaying) {
                        animationId = requestAnimationFrame(animateBars);
                    }
                }
        #{'        '}
                function startVisualization() {
                    isPlaying = !isPlaying;
                    if(isPlaying) {
                        createBars();
                        animateBars();
                    } else {
                        cancelAnimationFrame(animationId);
                    }
                }
        #{'        '}
                function changeMode() {
                    mode = (mode + 1) % 3;
                    const bars = document.querySelectorAll('.bar');
                    bars.forEach(bar => {
                        if(mode === 0) bar.style.background = 'linear-gradient(to top, #ff6b6b, #4ecdc4, #45b7d1)';
                        if(mode === 1) bar.style.background = 'linear-gradient(to top, #ffa500, #ff4500, #ff1493)';
                        if(mode === 2) bar.style.background = 'linear-gradient(to top, #00ff00, #32cd32, #90ee90)';
                    });
                }
        #{'        '}
                function randomize() {
                    createBars();
                }
        #{'        '}
                createBars();
            </script>
        </body>
        </html>
      HTML
    end

    def digital_garden_html
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Digital Garden</title>
            <style>
                body { margin: 0; padding: 0; background: linear-gradient(to bottom, #87CEEB 0%, #98FB98 100%); height: 100vh; overflow: hidden; cursor: crosshair; }
                .garden { position: relative; width: 100%; height: 100%; }
                .flower { position: absolute; font-size: 30px; animation: grow 2s ease-out; }
                .cloud { position: absolute; font-size: 40px; animation: float 10s infinite linear; }
                .raindrop { position: absolute; color: #4169E1; animation: fall 3s linear infinite; }
                @keyframes grow { from { transform: scale(0); } to { transform: scale(1); } }
                @keyframes float { from { left: -50px; } to { left: 100vw; } }
                @keyframes fall { from { top: -20px; } to { top: 100vh; } }
                .controls { position: fixed; top: 20px; left: 20px; background: rgba(255,255,255,0.8); padding: 15px; border-radius: 10px; }
                .btn { margin: 5px; padding: 8px 15px; border: none; border-radius: 5px; cursor: pointer; }
                h1 { text-align: center; color: #2E8B57; margin: 20px 0; }
            </style>
        </head>
        <body>
            <h1>🌱 Digital Garden Experience</h1>
            <div class="controls">
                <button class="btn" onclick="plantFlower()" style="background: #FFB6C1;">🌸 Plant Flower</button>
                <button class="btn" onclick="addCloud()" style="background: #87CEEB;">☁️ Add Cloud</button>
                <button class="btn" onclick="makeRain()" style="background: #4169E1; color: white;">🌧️ Rain</button>
                <button class="btn" onclick="clearGarden()" style="background: #DDA0DD;">🧹 Clear</button>
            </div>
            <div class="garden" id="garden" onclick="plantFlowerAt(event)"></div>
            <script>
                const flowers = ['🌸', '🌺', '🌻', '🌷', '🌹', '💐', '🌼'];
                const clouds = ['☁️', '⛅', '🌤️'];
        #{'        '}
                function plantFlowerAt(event) {
                    const flower = document.createElement('div');
                    flower.className = 'flower';
                    flower.textContent = flowers[Math.floor(Math.random() * flowers.length)];
                    flower.style.left = event.clientX - 15 + 'px';
                    flower.style.top = event.clientY - 15 + 'px';
                    document.getElementById('garden').appendChild(flower);
                }
        #{'        '}
                function plantFlower() {
                    const flower = document.createElement('div');
                    flower.className = 'flower';
                    flower.textContent = flowers[Math.floor(Math.random() * flowers.length)];
                    flower.style.left = Math.random() * (window.innerWidth - 30) + 'px';
                    flower.style.top = Math.random() * (window.innerHeight - 100) + 50 + 'px';
                    document.getElementById('garden').appendChild(flower);
                }
        #{'        '}
                function addCloud() {
                    const cloud = document.createElement('div');
                    cloud.className = 'cloud';
                    cloud.textContent = clouds[Math.floor(Math.random() * clouds.length)];
                    cloud.style.top = Math.random() * 200 + 'px';
                    cloud.style.left = '-50px';
                    document.getElementById('garden').appendChild(cloud);
                    setTimeout(() => cloud.remove(), 10000);
                }
        #{'        '}
                function makeRain() {
                    for(let i = 0; i < 20; i++) {
                        setTimeout(() => {
                            const drop = document.createElement('div');
                            drop.className = 'raindrop';
                            drop.textContent = '💧';
                            drop.style.left = Math.random() * window.innerWidth + 'px';
                            drop.style.top = '-20px';
                            document.getElementById('garden').appendChild(drop);
                            setTimeout(() => drop.remove(), 3000);
                        }, i * 100);
                    }
                }
        #{'        '}
                function clearGarden() {
                    const garden = document.getElementById('garden');
                    garden.innerHTML = '';
                }
            </script>
        </body>
        </html>
      HTML
    end

    def retro_arcade_html
      <<~HTML
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
                .screen { width: 80%; height: 70%; background: #000; border: 10px solid #444; border-radius: 20px; position: relative; overflow: hidden; display: flex; flex-direction: column; align-items: center; justify-content: center; }
                .pixel { width: 20px; height: 20px; background: #00ff00; position: absolute; animation: blink 2s infinite; }
                @keyframes blink { 0%, 50% { opacity: 1; } 51%, 100% { opacity: 0.3; } }
                .score { position: absolute; top: 20px; left: 20px; font-size: 16px; }
                .title { font-size: 24px; margin-bottom: 20px; text-align: center; animation: glow 2s infinite alternate; }
                @keyframes glow { from { text-shadow: 0 0 5px #00ff00; } to { text-shadow: 0 0 20px #00ff00, 0 0 30px #00ff00; } }
                .controls { margin-top: 20px; }
                .btn { background: #444; color: #00ff00; border: 2px solid #00ff00; padding: 10px 20px; margin: 0 10px; cursor: pointer; font-family: inherit; font-size: 12px; }
                .btn:hover { background: #00ff00; color: #000; }
            </style>
        </head>
        <body>
            <div class="arcade-machine">
                <div class="screen">
                    <div class="score">SCORE: <span id="score">0000</span></div>
                    <div class="title">RETRO ARCADE</div>
                    <div id="game-area" style="position: relative; width: 100%; height: 100%;"></div>
                </div>
                <div class="controls">
                    <button class="btn" onclick="startGame()">START</button>
                    <button class="btn" onclick="addPixel()">ADD PIXEL</button>
                    <button class="btn" onclick="clearScreen()">CLEAR</button>
                </div>
            </div>
            <script>
                let score = 0;
                let gameRunning = false;
        #{'        '}
                function updateScore() {
                    document.getElementById('score').textContent = score.toString().padStart(4, '0');
                }
        #{'        '}
                function addPixel() {
                    const gameArea = document.getElementById('game-area');
                    const pixel = document.createElement('div');
                    pixel.className = 'pixel';
                    pixel.style.left = Math.random() * (gameArea.offsetWidth - 20) + 'px';
                    pixel.style.top = Math.random() * (gameArea.offsetHeight - 20) + 'px';
                    pixel.style.background = `hsl(${Math.random() * 360}, 100%, 50%)`;
                    pixel.onclick = () => {
                        pixel.remove();
                        score += 10;
                        updateScore();
                    };
                    gameArea.appendChild(pixel);
                }
        #{'        '}
                function startGame() {
                    if(gameRunning) return;
                    gameRunning = true;
                    score = 0;
                    updateScore();
        #{'            '}
                    const interval = setInterval(() => {
                        addPixel();
                        if(document.querySelectorAll('.pixel').length > 20) {
                            clearInterval(interval);
                            gameRunning = false;
                        }
                    }, 1000);
                }
        #{'        '}
                function clearScreen() {
                    document.getElementById('game-area').innerHTML = '';
                    score = 0;
                    updateScore();
                    gameRunning = false;
                }
        #{'        '}
                updateScore();
            </script>
        </body>
        </html>
      HTML
    end
  end
end
