import SpriteKit
import SwiftUI

class MainParticleScene: SKScene {
    private var snowEmitter: SKEmitterNode?
    private var sakuraEmitter: SKEmitterNode?
    private var leavesEmitter: SKEmitterNode?
    private var firefliesEmitter: SKEmitterNode?
    private var lastType: ParticleType?
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        self.anchorPoint = .zero // 坐标原点在左下角
        setupEmitters()
    }
    
    private func setupEmitters() {
        // 1. Snow (❄️)
        snowEmitter = createEmitter(texture: createCircleTexture(size: 32, color: .white))
        snowEmitter?.emissionAngle = -CGFloat.pi / 2
        snowEmitter?.emissionAngleRange = 0.2
        self.addChild(snowEmitter!)
        
        // 2. Sakura (🌸)
        sakuraEmitter = createEmitter(texture: createPetalTexture(color: NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.8, alpha: 1.0)))
        sakuraEmitter?.emissionAngle = -CGFloat.pi / 2
        sakuraEmitter?.emissionAngleRange = 0.5
        sakuraEmitter?.xAcceleration = 5
        sakuraEmitter?.particleRotationRange = CGFloat.pi * 2
        sakuraEmitter?.particleRotationSpeed = 0.5
        self.addChild(sakuraEmitter!)
        
        // 3. Leaves (🍂)
        leavesEmitter = createEmitter(texture: createPetalTexture(color: .orange))
        leavesEmitter?.emissionAngle = -CGFloat.pi / 2
        leavesEmitter?.emissionAngleRange = 0.8
        leavesEmitter?.particleRotationRange = CGFloat.pi * 2
        leavesEmitter?.particleRotationSpeed = 1.0
        leavesEmitter?.particleColorBlendFactor = 1.0
        leavesEmitter?.particleColorRedRange = 0.3
        leavesEmitter?.particleColorGreenRange = 0.3
        self.addChild(leavesEmitter!)
        
        // 4. Fireflies (🪲)
        firefliesEmitter = createEmitter(texture: createCircleTexture(size: 24, color: .yellow))
        firefliesEmitter?.particleSpeed = 20
        firefliesEmitter?.emissionAngleRange = CGFloat.pi * 2
        let fadeIn = SKKeyframeSequence(keyframeValues: [0, 1.0, 0], times: [0, 0.4, 1.0])
        firefliesEmitter?.particleAlphaSequence = fadeIn
        self.addChild(firefliesEmitter!)
        
        syncEmitterPositions()
    }
    
    private func createEmitter(texture: SKTexture) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = texture
        emitter.particleBirthRate = 0
        emitter.particleLifetime = 15
        emitter.particleSpeed = 100
        emitter.particleSpeedRange = 50
        emitter.particleScale = 0.2
        emitter.particleAlpha = 0.8
        emitter.zPosition = 10
        return emitter
    }
    
    override func update(_ currentTime: TimeInterval) {
        let settings = AppSettings.shared
        
        // 每一帧都确保位置和范围是正确的
        syncEmitterPositions()
        
        if lastType != settings.currentType {
            lastType = settings.currentType
        }
        
        syncCurrentSettings()
    }
    
    private func syncEmitterPositions() {
        let w = self.size.width
        let h = self.size.height
        guard w > 0 && h > 0 else { return }
        
        // 顶部飘落型
        [snowEmitter, sakuraEmitter, leavesEmitter].forEach {
            $0?.position = CGPoint(x: w / 2, y: h + 10)
            $0?.particlePositionRange = CGVector(dx: w, dy: 0)
        }
        
        // 全屏漂浮型
        firefliesEmitter?.position = CGPoint(x: w / 2, y: h / 2)
        firefliesEmitter?.particlePositionRange = CGVector(dx: w, dy: h)
    }
    
    private func syncCurrentSettings() {
        let settings = AppSettings.shared
        let type = settings.currentType
        let br = settings.birthRate
        
        // 实时更新 BirthRate
        snowEmitter?.particleBirthRate = (type == .snow) ? br : 0
        sakuraEmitter?.particleBirthRate = (type == .sakura) ? br / 2.0 : 0
        leavesEmitter?.particleBirthRate = (type == .leaves) ? br / 3.0 : 0
        firefliesEmitter?.particleBirthRate = (type == .fireflies) ? br / 2.0 : 0
        
        let currentEmitter: SKEmitterNode?
        switch type {
        case .snow: currentEmitter = snowEmitter
        case .sakura: currentEmitter = sakuraEmitter
        case .leaves: currentEmitter = leavesEmitter
        case .fireflies: currentEmitter = firefliesEmitter
        }
        
        if let emitter = currentEmitter {
            emitter.particleSpeed = settings.speed * (type == .fireflies ? 0.3 : 1.0)
            emitter.particleScale = settings.scale * 2.0 
            if type != .fireflies {
                emitter.particleAlpha = settings.opacity
            }
        }
    }
    
    private func createCircleTexture(size: CGFloat, color: NSColor) -> SKTexture {
        let image = NSImage(size: CGSize(width: size, height: size), flipped: false) { r in
            color.set(); NSBezierPath(ovalIn: r.insetBy(dx: 2, dy: 2)).fill()
            return true
        }
        return SKTexture(image: image)
    }
    
    private func createPetalTexture(color: NSColor) -> SKTexture {
        let image = NSImage(size: CGSize(width: 64, height: 32), flipped: false) { r in
            color.set(); NSBezierPath(ovalIn: r.insetBy(dx: 2, dy: 2)).fill()
            return true
        }
        return SKTexture(image: image)
    }
}
