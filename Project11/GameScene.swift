//
//  GameScene.swift
//  Project11
//
//  Created by Furkan Eruçar on 18.04.2022.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    // To make a score show on the screen we need to do two things: create a score integer that tracks the value itself, then create a new node type, SKLabelNode, that displays the value to players.
    var scoreLabel: SKLabelNode! // The SKLabelNode class is somewhat similar to UILabel in that it has a text property, a font, a position, an alignment, and so on. Plus we can use Swift's string interpolation to set the text of the label easily, and we're even going to use the property observers you learned about in project 8 to make the label update itself when the score value changes.
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }

    let cameraNode = SKCameraNode()
    
    
    var editLabel: SKLabelNode! // We're going to let you place obstacles between the top of the scene and the slots at the bottom, so that players have to position their balls exactly correctly to bounce off things in the right ways.
    
    var editingMode: Bool = false { // To make this work, we're going to add two more properties. The first one will hold a label that says either "Edit" or "Done", and one to hold a boolean that tracks whether we're in editing mode or not. 
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
        let background = SKSpriteNode(imageNamed: "background") // Let's kick off this project by ditching the plain background and replacing it with a picture. If you want to place an image in your game, the class to use is called SKSpriteNode, and it can load any picture from your app bundle just like UIImage.
        background.position = CGPoint(x: 512, y: 256) // Remember, unlike UIKit SpriteKit positions things based on their center – i.e., the point 0,0 refers to the horizontal and vertical center of a node. And also unlike UIKit, SpriteKit's Y axis starts at the bottom edge, so a higher Y number places a node higher on the screen. So, to place the background image in the center of a landscape iPad, we need to place it at the position X:512, Y:384.
        background.blendMode = .replace // We're going to do two more things, both of which are only needed for this background. First, we're going to give it the blend mode .replace. Blend modes determine how a node is drawn, and SpriteKit gives you many options. The .replace option means "just draw it, ignoring any alpha values," which makes it fast for things without gaps such as our background.
        background.zPosition = -1 // We're also going to give the background a zPosition of -1, which in our game means "draw this behind everything else."
        addChild(background) // To add any node to the current screen, you use the addChild() method. As you might expect, SpriteKit doesn't use UIViewController like our UIKit apps have done. Yes, there is a view controller in your project, but it's there to host your SpriteKit game. The equivalent of screens in SpriteKit are called scenes. When you add a node to your scene, it becomes part of the node tree. Using addChild() you can add nodes to other nodes to make a more complicated tree, but in this game we're going to keep it simple.
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster") // We're going to use the Chalkduster font, then align the label to the right and position it on the top-right edge of the scene.
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: 980, y: 700)
        addChild(scoreLabel) // That places the label into the scene, and the property observer automatically updates the label as the score value changes. But it's not complete yet because we don't ever modify the player's score. Fortunately, we already have places in the collisionBetween() method where we can do exactly that
        
        editLabel = SKLabelNode(fontNamed: "Chalkduster")
        editLabel.text = "Edit"
        editLabel.position = CGPoint(x: 80, y: 700)
        addChild(editLabel)
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame) // This line of code adds a physics body to the whole scene that is a line on each edge, effectively acting like a container for the scene.
        physicsWorld.contactDelegate = self // Now comes the tricky part, which is setting up our scene to be the contact delegate of the physics world. The initial change is easy: we just need to conform to the SKPhysicsContactDelegate protocol then assign the physics world's contactDelegate property to be our scene. But by default, you still won't get notified when things collide.
        
        makeSlot(at: CGPoint(x: 128, y: 0), isGood: true) // The X positions are exactly between the bouncers, so if you run the game now you'll see bouncer / slot / bouncer / slot and so on.
        makeSlot(at: CGPoint(x: 384, y: 0), isGood: false)
        makeSlot(at: CGPoint(x: 640, y: 0), isGood: true)
        makeSlot(at: CGPoint(x: 896, y: 0), isGood: false)
        
        makeBouncer(at: CGPoint(x: 0, y: 0))
        makeBouncer(at: CGPoint(x: 256, y: 0))
        makeBouncer(at: CGPoint(x: 512, y: 0))
        makeBouncer(at: CGPoint(x: 768, y: 0))
        makeBouncer(at: CGPoint(x: 1024, y: 0))
        
        self.camera = cameraNode
        self.addChild(cameraNode)
        
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { // We haven't used touchesBegan() before, so the first two lines needs to be explained. This method gets called (in UIKit and SpriteKit) whenever someone starts touching their device. It's possible they started touching with multiple fingers at the same time, so we get passed a new data type called Set. This is just like an array, except each object can appear only once.
        guard let touch = touches.first else { return } // We want to know where the screen was touched, so we use a conditional typecast plus if let to pull out any of the screen touches from the touches set,
        let location = touch.location(in: self) // then use its location(in:) method to find out where the screen was touched in relation to self - i.e., the game scene. UITouch is a UIKit class that is also used in SpriteKit, and provides information about a touch such as its position and when it happened.
        // But what is new is detecting whether the user tapped the edit/done button or is trying to create a ball. To make this work, we're going to ask SpriteKit to give us a list of all the nodes at the point that was tapped, and check whether it contains our edit label. If it does, we'll flip the value of our editingMode boolean; if it doesn't, we want to execute the previous ball-creation code.
        let objects = nodes(at: location)
        
        if objects.contains(editLabel) {
            editingMode.toggle() // I slipped in a small but important new method there? editingMode.toggle() changes editingMode to true if it’s currently false, and to false if it was true. We could have written editingMode = !editingMode there and it would do the same thing, but toggle() is both shorter and clearer. That change will be picked up by the property observer, and the label will be updated to reflect the change. Now that we have a boolean telling us whether we're in editing mode or not, we're going to extend touchesBegan() even further so that if we're in editing mode we add blocks to the screen of random sizes, and if we're not it drops a ball.
        } else {
            
            if editingMode {
                // create a box
                let size = CGSize(width: Int.random(in: 16...128), height: 16) // To create randomness we’re going to be using both Int.random(in:) for integer values and CGFloat.random(in:) for CGFloat values, with the latter being used to create random red, green, and blue values for a UIColor. So, we create a size with a height of 16 and a width between 16 and 128
                let box = SKSpriteNode(color: UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1), size: size) // then create an SKSpriteNode with the random size we made along with a random color
                box.zRotation = CGFloat.random(in: 0...3) // First, we're going to use a new property on nodes called zRotation. When creating the background image, we gave it a Z position, which adjusts its depth on the screen, front to back. If you imagine sticking a skewer through the Z position – i.e., going directly into your screen – and through a node, then you can imagine Z rotation: it rotates a node on the screen as if it had been skewered straight through the screen. give the new box a random rotation and place it at the location that was tapped on the screen.
                box.position = location
                
                box.physicsBody = SKPhysicsBody(rectangleOf: box.size) // For a physics body, it's just a rectangle.
                box.physicsBody?.isDynamic = false // but we need to make it non-dynamic so the boxes don't move when hit.
                
                addChild(box)
                
            } else {
                let ball = SKSpriteNode(imageNamed: "building")
                ball.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: ball.size.width / 1.15, height: ball.size.height / 1.15)) // First, we're using the circleOfRadius initializer for SKPhysicsBody to add circular physics to this ball, because using rectangles would look strange.
                ball.physicsBody?.restitution = 0.1 // Second, we're giving the ball's physics body a restitution (bounciness) level of 0.4, where values are from 0 to 1.
                ball.physicsBody?.contactTestBitMask = ball.physicsBody?.collisionBitMask ?? 0 // What we need to do is change the "contactTestBitMask" property of our physics objects, which sets the contact notifications we want to receive. This needs to introduce a whole new concept – bitmasks – and really it doesn't matter at this point, so we're going to take a shortcut for now, then return to it in a later project. Now for our shortcut: we're going to tell all the ball nodes to set their "contactTestBitMask" property to be equal to their "collisionBitMask". Two bitmasks, with confusingly similar names but quite different jobs. The "collisionBitMask" bitmask means "which nodes should I bump into?" By default, it's set to everything, which is why our ball are already hitting each other and the bouncers. The "contactTestBitMask" bitmask means "which collisions do you want to know about?" and by default it's set to nothing. So by setting "contactTestBitMask" to the value of "collisionBitMask" we're saying, "tell me about every collision."
                ball.position = location
                ball.name = "ball" // Then add this to the code where you create the balls:
                addChild(ball)
            }
            
        }
        
        func update(_ currentTime: TimeInterval) {
            // Kamera ekranın yukarı doğru kaymasını takip ediyor
            cameraNode.position.y += 1.0
        }
        
        
        
        
        /*
        let box = SKSpriteNode(color: .red, size: CGSize(width: 32, height: 32)) // The third line is also new, but it's still SKSpriteNode. We're just writing some example code for now, so this line generates a node filled with a color (red) at a size (64x64). The CGSize struct is new, but also simple: it just holds a width and a height in a single structure. // Burası eklediğimiz şekillerin boyutlarını ayarlıyor.
        box.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 128, height: 128)) // This line of code adds a physics body to the box that is a rectangle of the same size as the box. // Burası da aralarındaki boşluğu ayarlıyor. yani SKSSpriteNode'daki boyutlu bir cisim SKPhysicsBody'deki kadar yer kaplıyor. Mesela üstteki 32x32 olursa kapladığı alan 64x64 olacak. Yani sıkışamayacaklar.
        box.position = location
        addChild(box)
        */
        // Projeyi ilk oluştururken kendimiz bir geometrik şekil oluşturmuştuk fakat assetlere eklediğimiz küreleri kullanacağımız için üsttekileri kullanmamıza gerek kalmadı
        
       
    }
    
    func makeBouncer(at position: CGPoint) { // With that method in place, you can place a bouncer in one line of code: just call makeBouncer(at:) with a position, and it will be placed and given a non-dynamic physics body automatically. You might have noticed that the parameter to makeBouncer(at:) has two names: at and position. This isn’t required, but it makes your code more readable: the first name is the one you use when calling the method, and the second name is the one you use inside the method. That is, you write makeBouncer(at:) to call it, but inside the method the parameter is named position rather than at. This is identical to cellForRowAt indexPath in table views.
        
        
        
    }
    
    // The purpose of the game will be to drop your balls in such a way that they land in good slots and not bad ones. We have bouncers in place, but we need to fill the gaps between them with something so the player knows where to aim.
    // We'll be filling the gaps with two types of target slots: good ones (colored green) and bad ones (colored red). As with bouncers, we'll need to place a few of these, which means we need to make a method. This needs to load the slot base graphic, position it where we said, then add it to the scene, like this:
    func makeSlot(at position: CGPoint, isGood: Bool) { // Unlike makeBouncer(at:), this method has a second parameter – whether the slot is good or not – and that affects which image gets loaded.
        var slotBase: SKSpriteNode
        var slotGlow: SKSpriteNode // One of the obvious-but-nice things about using methods to create the bouncers and slots is that if we want to change the way slots look we only need to change it in one place. For example, we can make the slot colors look more obvious by adding a glow image behind them:
        
        //The second step is also easy, but bears some explanation. As with UIKit, it's easy enough to store a variable pointing at specific nodes in your scene for when you want to make something happen, and there are lots of times when that's the right solution.
        // But for general use, Apple recommends assigning names to your nodes, then checking the name to see what node it is. We need to have three names in our code: good slots, bad slots and balls. This is really easy to do – just modify your makeSlot(at:) method so the SKSpriteNode creation looks like this:
        
        
    
        
        /*
         In this game, we want the player to win or lose depending on how many green or red slots they hit, so we need to make a few changes:

         1. Add rectangle physics to our slots.
         2. Name the slots so we know which is which, then name the balls too.
         3. Make our scene the contact delegate of the physics world – this means, "tell us when contact occurs between two bodies."
         4. Create a method that handles contacts and does something appropriate.
         The first step is easy enough: add these two lines just before you call addChild() for slotBase:
         */
        
        
        /*
         Angles are specified in radians, not degrees. This is true in UIKit too. 360 degrees is equal to the value of 2 x Pi – that is, the mathematical value π. Therefore π radians is equal to 180 degrees.
         Rather than have you try to memorize it, there is a built-in value of π called CGFloat.pi.
         Yes CGFloat is yet another way of representing decimal numbers, just like Double and Float. Behind the scenes, CGFloat can be either a Double or a Float depending on the device your code runs on. Swift also has Double.pi and Float.pi for when you need it at different precisions.
         When you create an action it will execute once. If you want it to run forever, you create another action to wrap the first using the repeatForever() method, then run that.
         */
        
        
        
    }
    

    
    func destroy(ball: SKNode) { // Our current destroy() method does nothing much, it just removes the ball from the game. But I made it a method for a reason, and that's so that we can add some special effects now, in one place, so that however a ball gets destroyed the same special effects are used. Perhaps unsurprisingly, it's remarkably easy to create special effects with SpriteKit. In fact, it has a built-in particle editor to help you create effects like fire, snow, rain and smoke almost entirely through a graphical editor. I already created an example particle effect for you (which you can customize soon, don't worry!) so let's take a look at the code first.
        if let fireParticles = SKEmitterNode(fileNamed: "FireParticles") { // The SKEmitterNode class is new and powerful: it's designed to create high-performance particle effects in SpriteKit games, and all you need to do is provide it with the filename of the particles you designed and it will do the rest. Once we have an SKEmitterNode object to work with, we position it where the ball was then use addChild() to add it to the scene.
            fireParticles.position = ball.position
            addChild(fireParticles)
        }
        
        ball.removeFromParent()
    }
    
    func didBegin(_ contact: SKPhysicsContact) { // With those two in place, our contact checking method almost writes itself. We'll get told which two bodies collided, and the contact method needs to determine which one is the ball so that it can call collisionBetween() with the correct parameters. This is as simple as checking the names of both properties to see which is the ball.
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        // we’ll use guard to ensure both bodyA and bodyB have nodes attached. If either of them don’t then this is a ghost collision and we can bail out immediately.
        
    }
}
