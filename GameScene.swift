//
//  GameScene.swift
//  Project26
//
//  Created by Eren Erinanc on 12.04.2021.
//

import SpriteKit
import CoreMotion

enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case donut = 4
    case vortex = 8
    case portal = 16
    case finish = 32
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var lastTouchPosition: CGPoint?
    var motionManager: CMMotionManager!
    
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var level = 1
    var portalTogged = false
    var isGameOver = false
    

    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        loadLevel()
        createPlayer()
        
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
    }
    
    func loadLevel() {
        setTheScene()
        guard let levelURL = Bundle.main.url(forResource: "level\(level)", withExtension: "txt") else {
            fatalError("Could not find level1.txt in the app bundle.")
        }
        
        guard let levelString = try? String(contentsOf: levelURL) else {
            fatalError("Could not find level1.txt in the app bundle.")
        }
        
        let lines = levelString.components(separatedBy: "\n")
        
        for (row,line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = CGPoint(x: (64*column) + 32, y: (64*row) + 32)
                
                if letter == "x" {
                    wallCreation(at: position)
                    
                } else if letter == "v" {
                    vortexCreation(at: position)

                } else if letter == "s" {
                    donutCreation(at: position)

                } else if letter == "f" {
                    finishFlagCreation(at: position)

                } else if letter == "p" {
                    portalCreation(at: position, with: "p")
                } else if letter == "t" {
                    portalCreation(at: position, with: "t")
                } else if letter == " " {

                } else {
                    fatalError("Unknown level letter: \(letter)")
                }
            }
        }
    }
    
    func setTheScene(){
        let background = SKSpriteNode(imageNamed: "background")
        background.zPosition = -1
        background.blendMode = .replace
        background.position = CGPoint(x: 512, y: 384)
        addChild(background)
        
        scoreLabel = SKLabelNode()
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.fontName = "Chalkduster"
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
        
        if level == 3 {
            level = 1
        }
    }
    
    func wallCreation(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "block")
        node.position = position

        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
        node.physicsBody?.isDynamic = false
        addChild(node)
    }
    
    func vortexCreation(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "vortex")
        node.name = "vortex"
        node.position = position
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width/2)
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
        node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        node.physicsBody?.isDynamic = false
        
        addChild(node)

    }
    
    func donutCreation(at position: CGPoint) {
        let number = Int.random(in: 1...7)
        var imageName: String!
        if number == 1{
            imageName = "bluedonut"
        } else if number == 2 {
            imageName = "greendonut"
        } else if number == 3 {
            imageName = "orangedonut"
        } else if number == 4 {
            imageName = "pinkdonut"
        } else if number == 5 {
            imageName = "reddonut"
        } else if number == 6 {
            imageName = "yellowdonut"
        } else if number == 7 {
            imageName = "whitedonut"
        }
        
        let node = SKSpriteNode(imageNamed: imageName)
        
        node.name = "donut"
        node.setScale(0.1)
        node.position = position
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width/2)
        node.physicsBody?.isDynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionTypes.donut.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        
        
        addChild(node)

    }
    
    func finishFlagCreation(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "finish")
        node.name = "finish"
        node.position = position
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width/2)
        node.physicsBody?.isDynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        
        addChild(node)

    }
    
    func portalCreation(at position: CGPoint, with letter: String) {
        let node = SKSpriteNode(imageNamed: "portalblue")
        if letter == "p" {
            node.name = "portal1"
        } else if letter == "t" {
            node.name = "portal2"
        }
        
        node.setScale(0.03)
        node.position = position
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width/2)
        node.physicsBody?.isDynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionTypes.portal.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        
        addChild(node)
    }
    func createPlayer() {
        player = SKSpriteNode(imageNamed: "player")
        player.zPosition = 1
        
        if portalTogged {
            player.position = childNode(withName: "portal2")!.position
            player.removeAllActions()
        } else {
            if level == 1 {
                player.position = CGPoint(x: 96, y: 672)
            } else if level == 2 {
                player.position = CGPoint(x: 224, y: 672)
            }
        }
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width/2)
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.donut.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.portal.rawValue | CollisionTypes.finish.rawValue
        
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.75
        addChild(player)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA == player {
            playerCollided(with: nodeB)
        } else if nodeB == player {
            playerCollided(with: nodeA)
        }
    }
    
    func playerCollided(with node: SKNode) {
        if node.name == "vortex" {
            player.physicsBody?.isDynamic = false
            isGameOver = true
            score -= 1
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(by: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            
            let sequence = SKAction.sequence([move,scale,remove])
            
            player.run(sequence) { [weak self] in
                self?.createPlayer()
                self?.isGameOver = false
            }
        } else if node.name == "donut" {
            node.removeFromParent()
            score += 1
        } else if node.name == "portal1" || node.name == "portal2" {
            guard portalTogged == false else { return }
            player.physicsBody?.isDynamic = false
            portalTogged = true
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            
            let sequence = SKAction.sequence([move,scale,remove])
            
            player.run(sequence) { [weak self] in
                self?.createPlayer()
                self?.player.removeAllActions()
            }
        } else if node.name == "finish" {
            score = 0
            level += 1
            removeAllChildren()
            loadLevel()
            createPlayer()

        }
        
    }

    override func update(_ currentTime: TimeInterval) {
        guard isGameOver == false else { return }
        
        #if targetEnvironment(simulator)
        if let currentTouch = lastTouchPosition {
            let diff = CGPoint(x: currentTouch.x - player.position.x, y: currentTouch.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x/100, dy: diff.y/100)
        }
        #else
        if let accelerometerData = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y*-50, dy: accelerometerData.acceleration.x*50)
        }
        #endif
    }
}
