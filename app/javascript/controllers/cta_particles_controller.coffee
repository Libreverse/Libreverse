import ApplicationController from './application_controller'

# Generates randomized floating particles for the CTA xAI effect
export default class extends ApplicationController
  connect: ->
    @particles = []
    num_particles = 18
    colors = [
      'rgba(255,255,255,0.8)'
      'rgba(255,230,160,0.7)'
      'rgba(255,200,100,0.6)'
      'rgba(255,150,50,0.5)'
      'rgba(255,255,255,0.5)'
    ]
    for i in [0...num_particles]
      particle = document.createElement('div')
      particle.className = 'particle'
      size = Math.random() * 10 + 6 # 6px to 16px
      left = Math.random() * 90 + 5 # 5% to 95%
      color = colors[Math.floor(Math.random() * colors.length)]
      duration = (Math.random() * 2.5 + 3.5).toFixed(2) # 3.5s to 6s
      delay = (Math.random() * 5).toFixed(2) # 0s to 5s
      bezier = "cubic-bezier(#{Math.random().toFixed(2)},#{Math.random().toFixed(2)},#{Math.random().toFixed(2)},#{Math.random().toFixed(2)})"
      particle.style.cssText = "left: #{left}%; width: #{size}px; height: #{size}px; background: #{color}; animation-delay: #{delay}s; animation-duration: #{duration}s; animation-timing-function: #{bezier};"
      @element.appendChild(particle)
      @particles.push(particle)

  disconnect: ->
    for particle in @particles
      particle.remove()
    @particles = []
