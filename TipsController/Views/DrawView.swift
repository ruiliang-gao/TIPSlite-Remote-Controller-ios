//
//  Canvas.swift
//  TipsController
//
//  Created by Prasan Dhareshwar on 1/15/21.
//

import UIKit


class DrawView: UIView {

    private var lineArray: [[CGPoint]] = [[CGPoint]]()
    var isOnTouch: Bool = false
    var motionX: Float = 0
    var motionY: Float = 0
    
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        var path = UIBezierPath()
        path = UIBezierPath(ovalIn: CGRect(x: self.windowWidth() * 0.4, y: self.windowHeight() * 0.46, width: self.windowWidth() * 0.2, height: self.windowHeight() * 0.1))
        UIColor.yellow.setStroke()
        UIColor.yellow.setFill()
        path.lineWidth = 5
        path.stroke()
        path.fill()
        draw(inContext: context)
        
    }
    
    func windowHeight() -> CGFloat {
        return UIScreen.main.bounds.size.height
    }

    func windowWidth() -> CGFloat {
        return UIScreen.main.bounds.size.width
    }

    func draw(inContext context: CGContext) {
//        self.isOnTouch = true
        
        context.setLineWidth(2)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineCap(.round)

        for line in lineArray {
            
            guard let firstPoint = line.first else { continue }
            context.beginPath()
            context.move(to: firstPoint)
            
            for point in line.dropFirst() {
                context.addLine(to: point)
            }
            context.strokePath()
        }
    }
    
    func resetDrawing() {
//        self.isOnTouch = false
        lineArray = []
        setNeedsDisplay()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isOnTouch = true
        guard let touch = touches.first else { return }
        let firstPoint = touch.location(in: self)
        
        motionX = Float(firstPoint.x/windowWidth())
        motionY = Float(firstPoint.y/windowHeight())
        
        lineArray.append([CGPoint]())
        lineArray[lineArray.count - 1].append(firstPoint)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        let currentPoint = touch.location(in: self)
        
        motionX = Float(currentPoint.x/windowWidth())
        motionY = Float(currentPoint.y/windowHeight())
        
        lineArray[lineArray.count - 1].append(currentPoint)
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isOnTouch = false
        resetDrawing()
    }

}
