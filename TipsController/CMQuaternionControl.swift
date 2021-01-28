//
//  CMQuaternionControl.swift
//  TipsController
//
//  Created by Prasan Dhareshwar on 1/28/21.
//

import Foundation

struct CMQauternionControl {
    
    var x : Double = 0
    var y : Double = 0
    var z : Double = 0
    var w : Double = 0
    
    init() {
        x = 0
        y = 0
        z = 0
        w = 0
    }
    
    init(value: Double) {
        
        x = value
        y = value
        z = value
        w = value
    }
    
    init(x:Double, y:Double, z:Double, w:Double) {
        
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    init(other: CMQauternionControl) {
    
        x = other.x
        y = other.y
        z = other.z
        w = other.w
    }
}

extension CMQauternionControl: CustomStringConvertible {
    
    var description: String { return "[\(x),\(y),\(z),\(w)]" }
}

extension CMQauternionControl {
    func norm() -> Double {
        return sqrt(x*x + y*y + z*z + w*w)
    }
    
    func conjugate() -> CMQauternionControl {
        return CMQauternionControl(x: x, y: -y, z: -z, w: -w)
    }
    
    func magnitudeSquared() -> Double {
        
        return x*x + y*y + z*z + w*w
    }
    
    func inverse() -> CMQauternionControl {
        let d = magnitudeSquared()
        return CMQauternionControl(x: -x/d, y: -y/d, z: -y/d, w: w/d)
    }
}

func + (left: CMQauternionControl, right : CMQauternionControl) -> CMQauternionControl {
    
    return CMQauternionControl(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z, w: left.w + right.w);
}

func * (left: CMQauternionControl, right : CMQauternionControl) -> CMQauternionControl {
    
    var a:Double, b:Double, c:Double, d:Double
    
    a =  -left.x*right.x - left.y*right.y - left.z * right.z
    b =   left.w*right.x + left.y*right.z - right.y * left.z
    c =   left.w*right.y + left.z*right.x - right.z * left.x
    d =   left.w*right.z + left.x*right.y - right.x * left.y
    
    return CMQauternionControl(x: a, y: b, z: c, w: d)
}

