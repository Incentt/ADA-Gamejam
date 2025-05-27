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
    var obstacleSpawnTimer: Timer?
    
    // Seesaw rotation
    var seesawRotation: CGFloat = 0
    let rotationSpeed: CGFloat = 0.02
    let maxRotation: CGFloat = .pi/3 // 60 degrees
    
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
        removeAllChildren()
        
        // Setup physics
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
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
        leftBarrier = SKSpriteNode(color: sawColor, size: CGSize(width: 16, height: 60))
        leftBarrier.physicsBody = SKPhysicsBody(rectangleOf: leftBarrier.size)
        leftBarrier.physicsBody?.isDynamic = false
        leftBarrier.physicsBody?.categoryBitMask = barrierCategory
        addChild(leftBarrier)
        
        // Create right barrier
        rightBarrier = SKSpriteNode(color: sawColor, size: CGSize(width: 16, height: 60))
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
        ball.physicsBody?.friction = 0.8
        
        // Make ball actually round
        ball.texture = createCircleTexture(radius: 15, color: .red)
        
        addChild(ball)
        
        // Create score label
        scoreLabel = SKLabelNode(fontNamed: "Arial-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 60, y: size.height - 50)
        scoreLabel.text = "Score: 0"
        addChild(scoreLabel)
        
        // Start obstacle spawning
        startObstacleSpawning()
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
    
    func startObstacleSpawning() {
        obstacleSpawnTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if !self.isGameOver {
                self.spawnObstacle()
                self.score += 1
                self.scoreLabel.text = "Score: \(self.score)"
            }
        }
    }
    
    func spawnObstacle() {
        let obstacle = SKSpriteNode(color: .black, size: CGSize(width: 25, height: 25))
        
        // Random X position
        let randomX = CGFloat.random(in: 50...(size.width - 50))
        obstacle.position = CGPoint(x: randomX, y: size.height + 25)
        
        // Physics
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.isDynamic = true
        obstacle.physicsBody?.categoryBitMask = obstacleCategory
        obstacle.physicsBody?.contactTestBitMask = ballCategory
        
        addChild(obstacle)
        
        // Remove obstacle when it goes off screen
        let moveAction = SKAction.moveBy(x: 0, y: -size.height - 100, duration: 5.0)
        let removeAction = SKAction.removeFromParent()
        obstacle.run(SKAction.sequence([moveAction, removeAction]))
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
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouchingLeft = false
        isTouchingRight = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        
        // Manual seesaw rotation based on touch
        if isTouchingLeft {
            seesawRotation = min(seesawRotation + rotationSpeed, maxRotation)
            
            // Increase obstacle spawn rate based on hold duration
            let holdDuration = currentTime - touchStartTime
            let newInterval = max(0.5, 2.0 - holdDuration * 0.1)
            updateObstacleSpawnRate(interval: newInterval)
            
        } else if isTouchingRight {
            seesawRotation = max(seesawRotation - rotationSpeed, -maxRotation)
            
            // Increase obstacle spawn rate based on hold duration
            let holdDuration = currentTime - touchStartTime
            let newInterval = max(0.5, 2.0 - holdDuration * 0.1)
            updateObstacleSpawnRate(interval: newInterval)
        }
        
        // Update seesaw and barrier positions
        updateSeesawAndBarriers()
        
        // Check if ball fell off screen
        if ball.position.y < -50 {
            gameOver()
        }
    }
    
    func updateObstacleSpawnRate(interval: TimeInterval) {
        obstacleSpawnTimer?.invalidate()
        obstacleSpawnTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            if !self.isGameOver {
                self.spawnObstacle()
                self.score += 1
                self.scoreLabel.text = "Score: \(self.score)"
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Check if ball hit obstacle
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        if (bodyA.categoryBitMask == ballCategory && bodyB.categoryBitMask == obstacleCategory) ||
            (bodyA.categoryBitMask == obstacleCategory && bodyB.categoryBitMask == ballCategory) {
            gameOver()
        }
    }
    
    func gameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        
        // Stop obstacle spawning
        obstacleSpawnTimer?.invalidate()
        
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
