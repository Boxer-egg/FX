import SpriteKit
import SwiftUI

class MainParticleScene: SKScene {
    private var snowEmitter: SKEmitterNode?
    private var sakuraEmitter: SKEmitterNode?
    private var leavesEmitter: SKEmitterNode?
    private var firefliesEmitter: SKEmitterNode?
    private var lastType: ParticleType?
    private var cachedSettings: (type: ParticleType, birthRate: CGFloat, speed: CGFloat, scale: CGFloat, scaleRange: CGFloat, windX: CGFloat, opacity: CGFloat, color: Color)?
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        self.anchorPoint = .zero
        setupEmitters()
    }
    
    private func setupEmitters() {
        // 1. Snow (❄️) - 六角雪花形状，银白色
        snowEmitter = createEmitter(texture: createSnowflakeTexture())
        snowEmitter?.emissionAngle = -CGFloat.pi / 2
        snowEmitter?.emissionAngleRange = 0.2
        snowEmitter?.particleRotationRange = .pi * 2
        snowEmitter?.particleRotationSpeed = 0.3
        self.addChild(snowEmitter!)
        
        // 2. Sakura (🌸)
        sakuraEmitter = createEmitter(texture: createPetalTexture(color: NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.8, alpha: 1.0)))
        sakuraEmitter?.emissionAngle = -CGFloat.pi / 2
        sakuraEmitter?.emissionAngleRange = 0.5
        sakuraEmitter?.xAcceleration = 5
        sakuraEmitter?.particleRotationRange = CGFloat.pi * 2
        sakuraEmitter?.particleRotationSpeed = 0.5
        self.addChild(sakuraEmitter!)
        
        // 3. Leaves (🍂) - 修复重点
        leavesEmitter = createEmitter(texture: createPetalTexture(color: .white)) // 使用白色纹理配合颜色混合
        leavesEmitter?.particleColor = .orange
        leavesEmitter?.particleColorBlendFactor = 1.0
        leavesEmitter?.particleColorRedRange = 0.4 // 产生红-橙-黄的过渡
        leavesEmitter?.particleColorGreenRange = 0.4
        
        leavesEmitter?.emissionAngle = -CGFloat.pi / 2
        leavesEmitter?.emissionAngleRange = 1.0
        leavesEmitter?.particleRotationRange = CGFloat.pi * 2
        leavesEmitter?.particleRotationSpeed = 2.0 // 旋转更快
        leavesEmitter?.particleSpeed = 120
        leavesEmitter?.particleSpeedRange = 60
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
    
    override func didChangeSize(_ oldSize: CGSize) {
        syncEmitterPositions()
    }

    override func update(_ currentTime: TimeInterval) {
        syncCurrentSettings()
    }
    
    private func syncEmitterPositions() {
        let w = self.size.width
        let h = self.size.height
        guard w > 0 && h > 0 else { return }
        
        [snowEmitter, sakuraEmitter, leavesEmitter].forEach {
            $0?.position = CGPoint(x: w / 2, y: h + 20)
            $0?.particlePositionRange = CGVector(dx: w, dy: 0)
        }
        
        firefliesEmitter?.position = CGPoint(x: w / 2, y: h / 2)
        firefliesEmitter?.particlePositionRange = CGVector(dx: w, dy: h)
    }
    
    private func syncCurrentSettings() {
        let settings = AppSettings.shared
        let type = settings.currentType
        let br = settings.birthRate

        let changed = cachedSettings == nil ||
            cachedSettings!.type != type ||
            cachedSettings!.birthRate != br ||
            cachedSettings!.speed != settings.speed ||
            cachedSettings!.scale != settings.scale ||
            cachedSettings!.scaleRange != settings.scaleRange ||
            cachedSettings!.windX != settings.windX ||
            cachedSettings!.opacity != settings.opacity ||
            cachedSettings!.color != settings.particleColor
        guard changed else { return }
        cachedSettings = (type, br, settings.speed, settings.scale, settings.scaleRange,
                          settings.windX, settings.opacity, settings.particleColor)

        snowEmitter?.particleBirthRate = (type == .snow) ? br : 0
        sakuraEmitter?.particleBirthRate = (type == .sakura) ? br / 2.0 : 0
        leavesEmitter?.particleBirthRate = (type == .leaves) ? br / 1.5 : 0
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
            emitter.particleScaleRange = settings.scaleRange * 2.0
            emitter.xAcceleration = settings.windX * 100.0

            if type != .fireflies {
                emitter.particleAlpha = settings.opacity
            }

            if type == .fireflies {
                emitter.particleColor = NSColor(settings.particleColor)
                emitter.particleColorBlendFactor = 1.0
            } else if type == .snow {
                emitter.particleColor = NSColor(calibratedWhite: 0.95, alpha: 1.0)
                emitter.particleColorBlendFactor = 0.3
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

    private func createSnowflakeTexture() -> SKTexture {
        let size: CGFloat = 40
        let image = NSImage(size: CGSize(width: size, height: size), flipped: false) { r in
            let center = CGPoint(x: r.midX, y: r.midY)
            let radius = size / 2 - 4

            // 银白色
            NSColor(calibratedWhite: 0.95, alpha: 1.0).setStroke()

            let path = NSBezierPath()
            path.lineWidth = 2.0
            path.lineCapStyle = .round

            // 绘制六角雪花：6条主分支
            for i in 0..<6 {
                let angle = CGFloat(i) * .pi / 3
                let endX = center.x + cos(angle) * radius
                let endY = center.y + sin(angle) * radius

                // 主分支
                path.move(to: center)
                path.line(to: CGPoint(x: endX, y: endY))

                // 末端小分叉
                let branchStart = CGPoint(
                    x: center.x + cos(angle) * (radius * 0.6),
                    y: center.y + sin(angle) * (radius * 0.6)
                )
                let sideOffset: CGFloat = .pi / 4
                let sideLength = radius * 0.25

                // 左侧小叉
                path.move(to: branchStart)
                path.line(to: CGPoint(
                    x: branchStart.x + cos(angle - sideOffset) * sideLength,
                    y: branchStart.y + sin(angle - sideOffset) * sideLength
                ))

                // 右侧小叉
                path.move(to: branchStart)
                path.line(to: CGPoint(
                    x: branchStart.x + cos(angle + sideOffset) * sideLength,
                    y: branchStart.y + sin(angle + sideOffset) * sideLength
                ))
            }

            path.stroke()
            return true
        }
        return SKTexture(image: image)
    }
}
