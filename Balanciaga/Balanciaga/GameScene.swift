import SpriteKit
import SwiftUICore
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Game objects
    var seesaw: SKSpriteNode!
    var ball: SKSpriteNode!
    var hinge: SKSpriteNode!
    var leftBarrier: SKSpriteNode!
    var rightBarrier: SKSpriteNode!
    
    // Game state
    var isGameOver = false
    var score = 0
    var scoreLabel: SKLabelNode!
    var gameOverLabel: SKLabelNode!
    var restartLabel: SKLabelNode!
    
    // Touch tracking
    var isTouchingLeft = false
    var isTouchingRight = false
    var touchStartTime: TimeInterval = 0
    var isRotating = false
    
    // Seesaw rotation
    var seesawRotation: CGFloat = 0
    let rotationSpeed: CGFloat = 0.006
    let maxRotation: CGFloat = .pi/9 // 60 degrees
    
    // Obstacle management
    var activeObstacles: [SKSpriteNode] = []
    var nextObstacleSpawnScore = 1
    
    // Predefined obstacle patterns
    let obstaclePatterns: [[CGPoint]] = [
        // Pattern 1: Line across top
        [CGPoint(x: 0.2, y: 0), CGPoint(x: 0.4, y: 0), CGPoint(x: 0.6, y: 0), CGPoint(x: 0.8, y: 0)],
        
        // Pattern 2: V shape
        [CGPoint(x: 0.3, y: 0), CGPoint(x: 0.4, y: 50), CGPoint(x: 0.6, y: 50), CGPoint(x: 0.7, y: 0)],
        
        // Pattern 3: Diagonal line
        [CGPoint(x: 0.2, y: 0), CGPoint(x: 0.4, y: 30), CGPoint(x: 0.6, y: 60), CGPoint(x: 0.8, y: 90)],
        
        // Pattern 4: Sides only
        [CGPoint(x: 0.15, y: 0), CGPoint(x: 0.25, y: 20), CGPoint(x: 0.75, y: 20), CGPoint(x: 0.85, y: 0)],
        
        // Pattern 5: Center cluster
        [CGPoint(x: 0.45, y: 0), CGPoint(x: 0.55, y: 0), CGPoint(x: 0.5, y: 30)],
        
        // Pattern 6: Scattered
        [CGPoint(x: 0.2, y: 10), CGPoint(x: 0.5, y: 50), CGPoint(x: 0.8, y: 20)],
        
        // Pattern 7: Wave pattern
        [CGPoint(x: 0.25, y: 0), CGPoint(x: 0.4, y: 40), CGPoint(x: 0.6, y: 40), CGPoint(x: 0.75, y: 0)],
        
        // Pattern 8: Triple threat
        [CGPoint(x: 0.3, y: 0), CGPoint(x: 0.5, y: 30), CGPoint(x: 0.7, y: 0)]
    ]
    // Physics categories
    let ballCategory: UInt32 = 1
    let obstacleCategory: UInt32 = 2
    let seesawCategory: UInt32 = 4
    let groundCategory: UInt32 = 8
    let barrierCategory: UInt32 = 16
    
    override func didMove(to view: SKView) {
        setupGame()
    }
    
    // Helper function to create a circular texture
    func createCircleTexture(radius: CGFloat, color: UIColor) -> SKTexture {
        let size = CGSize(width: radius * 2, height: radius * 2)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image)
    }
    
    func setupGame() {
        // Reset game state
        isGameOver = false
        score = 0
        seesawRotation = 0
        isRotating = false
        activeObstacles.removeAll()
        nextObstacleSpawnScore = 1
        removeAllChildren()
        
        // Setup physics
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -1)
        
        // Create background
        backgroundColor = SKColor.systemGreen
        let sawColor = UIColor.orange
        
        // Create hinge (pivot point)
        hinge = SKSpriteNode(color: sawColor, size: CGSize(width: 20, height: 200))
        hinge.position = CGPoint(x: size.width/2, y: 0)
        hinge.physicsBody = SKPhysicsBody(rectangleOf: hinge.size)
        hinge.physicsBody?.isDynamic = false
        addChild(hinge)
        
        // Create seesaw
        seesaw = SKSpriteNode(color: sawColor, size: CGSize(width: 300, height: 15))
        seesaw.position = CGPoint(
            x: size.width/2,
            y: hinge.position.y + hinge.size.height/2 + seesaw.size.height/2
        )
        seesaw.physicsBody = SKPhysicsBody(rectangleOf: seesaw.size)
        seesaw.physicsBody?.isDynamic = false
        seesaw.physicsBody?.categoryBitMask = seesawCategory
        addChild(seesaw)
        
        // Create left barrier
        leftBarrier = SKSpriteNode(color: sawColor, size: CGSize(width: 16, height: 45))
        leftBarrier.physicsBody = SKPhysicsBody(rectangleOf: leftBarrier.size)
        leftBarrier.physicsBody?.isDynamic = false
        leftBarrier.physicsBody?.categoryBitMask = barrierCategory
        addChild(leftBarrier)
        
        // Create right barrier
        rightBarrier = SKSpriteNode(color: sawColor, size: CGSize(width: 16, height: 45))
        rightBarrier.physicsBody = SKPhysicsBody(rectangleOf: rightBarrier.size)
        rightBarrier.physicsBody?.isDynamic = false
        rightBarrier.physicsBody?.categoryBitMask = barrierCategory
        addChild(rightBarrier)
        
        // Create ball
        ball = SKSpriteNode(color: .red, size: CGSize(width: 30, height: 30))
        ball.position = CGPoint(x: size.width/2, y: seesaw.position.y + 50)
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 15)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.categoryBitMask = ballCategory
        ball.physicsBody?.contactTestBitMask = obstacleCategory
        ball.physicsBody?.restitution = 0.3
        ball.physicsBody?.friction = 5
        ball.physicsBody?.mass = 100
        
        // Make ball actually round
        ball.texture = createCircleTexture(radius: 15, color: .red)
        
        addChild(ball)
        
        // Create score label
        scoreLabel = SKLabelNode(fontNamed: "Arial-Bold")
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height - 200)
        scoreLabel.text = "0"
        addChild(scoreLabel)
        
        // Spawn first obstacle
        spawnObstacle()
    }
    
    func updateSeesawAndBarriers() {
        // Update seesaw rotation
        seesaw.zRotation = seesawRotation
        
        // Update barrier positions to follow seesaw rotation
        let seesawCenter = seesaw.position
        let halfWidth = seesaw.size.width / 2
        let seesawHalfHeight = seesaw.size.height / 2
        let barrierOffset = seesawHalfHeight + leftBarrier.size.height / 2
        
        // Calculate positions for barriers at the ends of the seesaw
        // Left barrier position
        let leftX = seesawCenter.x - halfWidth * cos(seesawRotation) - barrierOffset * sin(seesawRotation)
        let leftY = (
            seesawCenter.y - halfWidth * sin(seesawRotation) + barrierOffset * cos(
                seesawRotation
            )
        ) - seesaw.size.height
        
        // Right barrier position
        let rightX = seesawCenter.x + halfWidth * cos(seesawRotation) - barrierOffset * sin(seesawRotation)
        let rightY = (
            seesawCenter.y + halfWidth * sin(seesawRotation) + barrierOffset * cos(
                seesawRotation
            )
        ) - seesaw.size.height
        
        leftBarrier.position = CGPoint(x: leftX, y: leftY)
        leftBarrier.zRotation = seesawRotation
        
        rightBarrier.position = CGPoint(x: rightX, y: rightY)
        rightBarrier.zRotation = seesawRotation
    }
    
    func spawnObstacle() {
        
        // Pick a random pattern
        let randomPattern = obstaclePatterns.randomElement()!
        
        for relativePosition in randomPattern {
            let obstacle = SKSpriteNode(color: .black, size: CGSize(width: 20, height: 20))
            
            // Convert relative position to actual screen coordinates
            let actualX = relativePosition.x * size.width
            let actualY = size.height + 25 + relativePosition.y
            
            obstacle.position = CGPoint(x: actualX, y: actualY)
            
            // Physics - start with no gravity effect (static)
            obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
            obstacle.physicsBody?.isDynamic = false // Start as static
            obstacle.physicsBody?.categoryBitMask = obstacleCategory
            obstacle.physicsBody?.contactTestBitMask = ballCategory
            
            addChild(obstacle)
            activeObstacles.append(obstacle)
        }
    }
    
    func moveObstacles(fallSpeed: CGFloat) {
        for obstacle in activeObstacles {
            let currentPosition = obstacle.position
            let newY = currentPosition.y - fallSpeed
            obstacle.position = CGPoint(x: currentPosition.x, y: newY)
            
            // Check if obstacle passed the ball (scored)
            if obstacle.position.y < ball.position.y && obstacle.position.y > ball.position.y - 30 {
                // Check if this obstacle hasn't been scored yet
                if ((obstacle.userData?["scored"]) == nil) as? Bool ?? false {
                    score += 1
                    scoreLabel.text = "\(score)"
                    obstacle.userData = ["scored": true]
                    
                    // Spawn new obstacle when current one is passed
                    if score >= nextObstacleSpawnScore {
                        spawnObstacle()
                        nextObstacleSpawnScore = score + Int.random(in: 3...6) // Next obstacle wave in 3-6 points
                    }
                }
            }
            
            // Remove obstacles that are off screen
            if obstacle.position.y < -50 {
                obstacle.removeFromParent()
                if let index = activeObstacles.firstIndex(of: obstacle) {
                    activeObstacles.remove(at: index)
                }
            }
        }
    }
    
    func checkObstacleCollisions() {
        for obstacle in activeObstacles {
            let ballFrame = CGRect(
                x: ball.position.x - 15,
                y: ball.position.y - 15,
                width: ball.size.width,
                height: ball.size.height
            )
            let obstacleFrame = CGRect(
                x: obstacle.position.x,
                y: obstacle.position.y,
                width: obstacle.size.width,
                height: obstacle.size.height
            )
            
            if ballFrame.intersects(obstacleFrame) {
                gameOver()
                break
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else {
            // Check if restart was tapped
            if let touch = touches.first {
                let location = touch.location(in: self)
                if restartLabel?.contains(location) == true {
                    setupGame()
                }
            }
            return
        }
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        touchStartTime = CACurrentMediaTime()
        
        if location.x < size.width/2 {
            isTouchingLeft = true
        } else {
            isTouchingRight = true
        }
        
        isRotating = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouchingLeft = false
        isTouchingRight = false
        isRotating = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        
        var rotationOccurred = false
        
        // Manual seesaw rotation based on touch
        if isTouchingLeft {
            seesawRotation = min(seesawRotation + rotationSpeed, maxRotation)
            rotationOccurred = true
        } else if isTouchingRight {
            seesawRotation = max(seesawRotation - rotationSpeed, -maxRotation)
            rotationOccurred = true
        }
        
        // Update seesaw and barrier positions
        updateSeesawAndBarriers()
        
        // Move obstacles only when rotating
        if isRotating && rotationOccurred {
            // Static fall speed - no more acceleration based on hold time
            let fallSpeed: CGFloat = 2.5
            moveObstacles(fallSpeed: fallSpeed)
        }
        
        // Check for collisions
        checkObstacleCollisions()
        
        // Check if ball fell off screen
        if ball.position.y < -50 {
            gameOver()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Collision detection is now handled in checkObstacleCollisions()
        // This method is kept for potential future physics-based collisions
    }
    
    func gameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        
        // Show game over screen
        gameOverLabel = SKLabelNode(fontNamed: "Arial-Bold")
        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: size.width/2, y: size.height/2 + 50)
        gameOverLabel.text = "Game Over!"
        addChild(gameOverLabel)
        
        let finalScoreLabel = SKLabelNode(fontNamed: "Arial")
        finalScoreLabel.fontSize = 24
        finalScoreLabel.fontColor = .white
        finalScoreLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        finalScoreLabel.text = "Final Score: \(score)"
        addChild(finalScoreLabel)
        
        restartLabel = SKLabelNode(fontNamed: "Arial")
        restartLabel.fontSize = 20
        restartLabel.fontColor = .yellow
        restartLabel.position = CGPoint(x: size.width/2, y: size.height/2 - 50)
        restartLabel.text = "Tap to restart"
        addChild(restartLabel)
        
        // Add pulsing animation to restart label
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        restartLabel.run(SKAction.repeatForever(pulse))
    }
}
