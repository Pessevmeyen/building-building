//
//  GameScene.swift
//  Project11
//
//  Created by Furkan Eruçar on 18.04.2022.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var scoreLabel: SKLabelNode!
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }

    let cameraNode = SKCameraNode()
    
    var cameraYOffset: CGFloat = 0

    var editLabel: SKLabelNode!

    var editingMode: Bool = false {
        didSet {
            if editingMode {
                editLabel.text = "Done"
            } else {
                editLabel.text = "Edit"
            }
        }
    }
    
    let balls = ["ballBlue", "ballCyan", "ballGreen", "ballGrey", "ballPurple", "ballRed", "ballYellow"]
   
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 256)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)

        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: 980, y: 700)
        addChild(scoreLabel)

        editLabel = SKLabelNode(fontNamed: "Chalkduster")
        editLabel.text = "Edit"
        editLabel.position = CGPoint(x: 80, y: 700)
        addChild(editLabel)

        self.camera = cameraNode
        self.addChild(cameraNode)

        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.contactDelegate = self

        makeSlot(at: CGPoint(x: 128, y: 0), isGood: true)
        makeSlot(at: CGPoint(x: 384, y: 0), isGood: false)
        makeSlot(at: CGPoint(x: 640, y: 0), isGood: true)
        makeSlot(at: CGPoint(x: 896, y: 0), isGood: false)

        makeBouncer(at: CGPoint(x: 0, y: 0))
        makeBouncer(at: CGPoint(x: 256, y: 0))
        makeBouncer(at: CGPoint(x: 512, y: 0))
        makeBouncer(at: CGPoint(x: 768, y: 0))
        makeBouncer(at: CGPoint(x: 1024, y: 0))

        dropObjects()
    }

    func dropObjects() {
        // Cisimleri oluşturun ve ekranın üstünden bırakın
        let object = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        object.physicsBody = SKPhysicsBody(rectangleOf: object.size)
        object.position = CGPoint(x: size.width / 2, y: size.height + object.size.height)
        addChild(object)

        // Cisimlere yerçekimi uygulayın
        object.physicsBody?.affectedByGravity = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let objects = nodes(at: location)

        if objects.contains(editLabel) {
            editingMode.toggle()
        } else {

            if editingMode {
                // create a box
                let size = CGSize(width: Int.random(in: 16...128), height: 16)
                let box = SKSpriteNode(color: UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1), size: size)
                box.zRotation = CGFloat.random(in: 0...3)
                box.position = location

                box.physicsBody = SKPhysicsBody(rectangleOf: box.size)
                box.physicsBody?.isDynamic = false

                addChild(box)

            } else {
                let ball = SKSpriteNode(imageNamed: "building")
                ball.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: ball.size.width / 1.15, height: ball.size.height / 1.15))
                ball.physicsBody?.restitution = 0.1
                ball.physicsBody?.contactTestBitMask = ball.physicsBody?.collisionBitMask ?? 0
                ball.position = location
                ball.name = "ball"
                addChild(ball)
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Kamera ekranın yukarı doğru kaymasını takip ediyor
        cameraNode.position.y += 1.0

        let editLabelPosition = CGPoint(x: editLabel.position.x, y: editLabel.position.y + 1.0)
        editLabel.position = editLabelPosition
    }

    override func didSimulatePhysics() {
        // Sahnenin boyutunu güncelliyoruz
        let newSceneSize = CGSize(width: size.width, height: size.height + cameraYOffset)
        self.size = newSceneSize

        // Arka planın yukarı doğru uzamasını sağlıyoruz
        if let background = self.childNode(withName: "background") as? SKSpriteNode {
            background.position = CGPoint(x: 512, y: 256 + cameraYOffset)
        }
    }

    func updateBackgroundPosition(yOffset: CGFloat) {
        cameraYOffset = yOffset
    }
    
    func makeBouncer(at position: CGPoint) {
    }

    func makeSlot(at position: CGPoint, isGood: Bool) {
        var slotBase: SKSpriteNode
        var slotGlow: SKSpriteNode
    }

    func destroy(ball: SKNode) {
        if let fireParticles = SKEmitterNode(fileNamed: "FireParticles") {
            fireParticles.position = ball.position
            addChild(fireParticles)
        }

        ball.removeFromParent()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
    }
}
