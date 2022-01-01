//
//  GameScene.swift
//  SpriteKitExperiment
//
//  Created by Zhihao Cui on 31/12/2021.
//
import CoreMotion
import SpriteKit

class Ball: SKSpriteNode { }

class GameScene: SKScene {
    
    let deviceIdiom = UIScreen.main.traitCollection.userInterfaceIdiom
    
    var balls = ["ballBlue", "ballGreen", "ballPurple", "ballRed", "ballYellow"]
    var motionManager: CMMotionManager?
    
    let labelFontSize = UIFont.systemFontSize * 2
    let highestScoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Thin")
    let scoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Thin")
    let restartLabel = SKLabelNode(fontNamed: "HelveticaNeue-Thin")
    let ballsContainerBottomMargin = UIFont.systemFontSize * 4
    var matchedBalls = Set<Ball>()
    
    var score = 0 {
        didSet {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let formattedScore = formatter.string(from: score as NSNumber) ?? "0"
            scoreLabel.text = "SCORE: \(formattedScore)"
        }
    }
    var highScore = 0 {
        didSet {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let formattedScore = formatter.string(from: highScore as NSNumber) ?? "0"
            highestScoreLabel.text = "Highest: \(formattedScore)"
        }
    }
    
    fileprivate func initializeBalls(_ ballRadius: CGFloat, _ view: SKView, _ ball: SKSpriteNode) {
        for i in stride(from: ballRadius * 3, to: view.bounds.width - ballRadius * 3, by: ball.frame.width) {
            for j in stride(from: ballsContainerBottomMargin, to: view.bounds.height - ballRadius, by: ball.frame.height) {
                let ballType = balls.randomElement()!
                let ball = Ball(imageNamed: ballType)
                ball.position = CGPoint(x: i , y: j)
                ball.name = ballType
                
                ball.physicsBody = SKPhysicsBody(circleOfRadius: ballRadius)
                ball.physicsBody?.allowsRotation = false
                ball.physicsBody?.restitution = 0
                ball.physicsBody?.friction = 0
                
                addChild(ball)
            }
        }
    }
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "checkerboard")
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        background.alpha = 0.2
        background.zPosition = -1
        addChild(background)
        
        highestScoreLabel.fontSize = labelFontSize
        highestScoreLabel.position = CGPoint(x: 20, y: 20)
        highestScoreLabel.text = "Highest: 0"
        highestScoreLabel.zPosition = 100
        highestScoreLabel.horizontalAlignmentMode = .left
        addChild(highestScoreLabel)
        
        highScore = UserDefaults.standard.integer(forKey: "high_score")
        
        scoreLabel.fontSize = labelFontSize
        scoreLabel.position = CGPoint(x: view.bounds.midX, y: 20)
        scoreLabel.text = "SCORE: 0"
        scoreLabel.zPosition = 100
        scoreLabel.horizontalAlignmentMode = .center
        addChild(scoreLabel)
        
        restartLabel.name = "RestartButton"
        restartLabel.fontSize = labelFontSize
        restartLabel.position = CGPoint(x: view.bounds.width - 20, y: 20)
        restartLabel.text = "RESTART"
        restartLabel.zPosition = 100
        restartLabel.horizontalAlignmentMode = .right
        addChild(restartLabel)
        
        let ball = SKSpriteNode(imageNamed: "ballBlue")
        let ballRadius = ball.frame.width / 2.0
        
        initializeBalls(ballRadius, view, ball)
        
        let uniforms: [SKUniform] = [
            SKUniform(name: "u_speed", float: 1),
            SKUniform(name: "u_strength", float: 3),
            SKUniform(name: "u_frequency", float: 20)
        ]
        
        let shader = SKShader(fileNamed: "Background")
        shader.uniforms = uniforms
        background.shader = shader
        
        background.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 10)))
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame.inset(by: UIEdgeInsets(top: ballsContainerBottomMargin, left: ballRadius * 2, bottom: 0, right: ballRadius * 2)))
        
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let accelerometerData = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
        }
    }
    
//    func getMatchers(from node: Ball) {
//        for body in node.physicsBody!.allContactedBodies() {
//            guard let ball = body.node as? Ball else {continue}
//            guard ball.name == node.name else {continue} // match same colored ball
//
//            if !matchedBalls.contains(ball) {
//                matchedBalls.insert(ball)
//                getMatchers(from: ball)
//            }
//        }
//    }
    
    func getMatchers(from startBall: Ball) {
        let matchWidthSquare = startBall.frame.width * startBall.frame.width * 1.1
        
        for node in children {
            guard let ball = node as? Ball else {continue}
            guard ball.name == startBall.name else {continue}
            
            let distSqr = distanceSquared(from: startBall, to: ball)
            
            guard distSqr < matchWidthSquare else {continue}
            
            if !matchedBalls.contains(ball) {
                matchedBalls.insert(ball)
                getMatchers(from: ball)
            }
        }
    }
    
    func distanceSquared(from: Ball, to: Ball) -> CGFloat {
        return (from.position.x - to.position.x) * (from.position.x - to.position.x) + (from.position.y - to.position.y) * (from.position.y - to.position.y)
    }
    
    func resetGame() {
        print("Reset game")
        for child in self.children {
           //Determine Details
            guard let childBall = child as? Ball else { continue }
            childBall.removeFromParent()
        }
        score = 0
        
        let ball = SKSpriteNode(imageNamed: "ballBlue")
        let ballRadius = ball.frame.width / 2.0
        
        initializeBalls(ballRadius, self.view!, ball)
    }
    
    func increaseScore(_ increment: Int) {
        score += increment
        
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "high_score")
            UserDefaults.standard.synchronize()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let position = touches.first?.location(in: self) else {return}
        
        let touchedNode = atPoint(position)
        if touchedNode.name == "RestartButton" {
            resetGame()
            return
        }
        
        guard let tappedBall = nodes(at: position).first(where: {$0 is Ball}) as? Ball else {return}
        
        matchedBalls.removeAll(keepingCapacity: true)
        
        getMatchers(from: tappedBall)
        
        if matchedBalls.count >= 3 {
            increaseScore(Int(pow(2, Double(min(matchedBalls.count, 16)))))
            
            for ball in matchedBalls {
                if let particles = SKEmitterNode(fileNamed: "Explosion") {
                    particles.position = ball.position
                    addChild(particles)
                    
                    let removeAfterDead = SKAction.sequence([SKAction.wait(forDuration: 3), SKAction.removeFromParent()])
                    particles.run(removeAfterDead)
                }
                
                ball.removeFromParent()
            }
        }
        
        let omgCount = deviceIdiom == .phone ? 6 : 12
        
        if matchedBalls.count >= omgCount {
            let omg = SKSpriteNode(imageNamed: "omg")
            omg.position = CGPoint(x: frame.midX, y: frame.midY)
            omg.zPosition = 100
            omg.xScale = 0.001
            omg.yScale = 0.001
            addChild(omg)
            
            let appear = SKAction.group([SKAction.scale(to: 1, duration: 0.25), SKAction.fadeIn(withDuration: 0.25)])
            let disappear = SKAction.group([SKAction.scale(to: 2, duration: 0.25), SKAction.fadeOut(withDuration: 0.25)])
            let sequence = SKAction.sequence([appear, SKAction.wait(forDuration: 0.25), disappear])
            omg.run(sequence)
        }
    }
}
