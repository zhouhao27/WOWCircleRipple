//
//  WOWCircleRippleButton.swift
//  CircleRipple
//
//  Created by Zhou Hao on 15/08/15.
//  Copyright © 2015年 Zeus. All rights reserved.
//

import UIKit

@IBDesignable public class WOWCircleRippleButton: UIButton {
    
    // MARK: inspectable
    @IBInspectable var cornerRadius         : CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var borderWidth          : CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var borderColor          : UIColor? {
        didSet {
            layer.borderColor = borderColor?.CGColor
        }
    }
    
    // MARK: private variables
    private var actionInProgress            : Bool = false
    var backLayer                           : CALayer?
    var originalBackgroundColor = UIColor.clearColor()
    var originalBorderColor = UIColor.clearColor().CGColor
    var ripples = [CALayer]()
        
    // MARK: public methods
    public func startAction() {
        
        if !actionInProgress {
            
            actionInProgress = true
            
            // add background layer
            originalBackgroundColor = backgroundColor!
            backgroundColor = UIColor.clearColor()
            
            backLayer = createBacklayer()
            
            // animate to cicle (bounds)
            originalBorderColor = layer.borderColor!
            layer.borderColor = UIColor.clearColor().CGColor
            
            var newBounds = getNewBounds()
            //backLayer!.cornerRadius = newBounds.width / 2
            backLayer!.borderWidth = layer.borderWidth
            backLayer!.borderColor = originalBorderColor
            
            let animRadius = CABasicAnimation(keyPath: "cornerRadius")
            animRadius.toValue = newBounds.width / 2
            animRadius.fillMode = kCAFillModeForwards
            animRadius.removedOnCompletion = false
            //backLayer!.addAnimation(animRadius, forKey: "")
            
            let animation = CABasicAnimation(keyPath: "bounds")
            animation.toValue = NSValue(CGRect: newBounds)
            //animation.duration = 0.3
            animation.fillMode = kCAFillModeForwards
            animation.removedOnCompletion = false
            //backLayer!.addAnimation(animation, forKey: "")
            
            let animGroup = CAAnimationGroup()
            animGroup.animations = [animRadius,animation]
            animGroup.duration = 0.3
            backLayer!.addAnimation(animGroup, forKey: "group")
            
            GCD.delay(0.2, block: { () -> () in
                
                self.backLayer!.bounds = newBounds
                self.startAnimating()
            })
        }
    }
    
    public func stopAction(animated : Bool) {
        
        if actionInProgress {
            
            actionInProgress = false

            // remove ripples
            for subLayer in ripples {
                subLayer.removeAllAnimations()
                subLayer.removeFromSuperlayer()
            }
            
            // restore original status
            if animated {
                
            }
            
            backLayer!.removeAllAnimations()
            
            resetToOriginalStatus()
        }        
    }
    
    // MARK: private methods
    private func createBacklayer() -> CALayer {
        
        let backlayer = CALayer()
        backlayer.masksToBounds = true
        backlayer.frame = bounds
        backlayer.backgroundColor = originalBackgroundColor.CGColor
        
        layer.addSublayer(backlayer)
        return backlayer
    }
    
    private func resetToOriginalStatus() {
        
        backLayer!.removeFromSuperlayer()
        backLayer = nil
        
        layer.backgroundColor = UIColor.clearColor().CGColor
        layer.borderColor = originalBorderColor
        backgroundColor = originalBackgroundColor
    }
    
    private func getNewBounds() -> CGRect {
        
        var newBounds : CGRect
        if layer.bounds.width > layer.bounds.height {
            newBounds = CGRectMake(0, 0, layer.bounds.height, layer.bounds.height)
        } else {
            newBounds = CGRectMake(0, 0, layer.bounds.width, layer.bounds.width)
        }
        return newBounds
        
    }
    
    private func startAnimating() {
  
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.fromValue = 1
        anim.toValue = 0
        anim.duration = 0.2
        anim.removedOnCompletion = false
        anim.fillMode = kCAFillModeForwards
        
        backLayer!.addAnimation(anim, forKey: "scale")
        
        GCD.delay(0.1) { () -> () in
            self.ripple()
        }
        GCD.delay(0.3) { () -> () in
            self.ripple()
        }
        GCD.delay(0.5) { () -> () in
            self.ripple()
        }
    }
    
    private func ripple() {
        
        let circle = CAShapeLayer()
        
        // anchorPoint doesn't work
        // need to set the layer's frame
        circle.path = pathFor(backLayer!, radius: backLayer!.bounds.width/2)
        circle.frame = backLayer!.frame
        
        circle.fillColor = UIColor.clearColor().CGColor
        circle.strokeColor = originalBackgroundColor.CGColor
        circle.lineWidth = 3
        
        self.layer.addSublayer(circle)
        
        let animScale = CABasicAnimation(keyPath: "transform.scale")
        animScale.fromValue = 0
        animScale.toValue = 1
        
        circle.transform = CATransform3DMakeScale(1.0,1.0,1.0)
        circle.addAnimation(animScale, forKey: "scale")
        
        let animAlpha = CABasicAnimation(keyPath: "opacity")
        animAlpha.fromValue = 1
        animAlpha.toValue = 0
        animAlpha.removedOnCompletion = false
        animAlpha.fillMode = kCAFillModeForwards
        
        circle.addAnimation(animAlpha, forKey: "alpha")
        
        let animGroup = CAAnimationGroup()
        animGroup.animations = [animScale,animAlpha]
        animGroup.repeatCount = Float.infinity
        animGroup.duration = 0.8
        circle.addAnimation(animGroup, forKey: "")
        
        ripples.append(circle)
    }
    
    private func pathFor(layer : CALayer, radius : CGFloat) -> CGPathRef {
        
        let center = CGPointMake(layer.bounds.width / 2, layer.bounds.width / 2)
        return UIBezierPath(arcCenter: center, radius: radius, startAngle: 0.0, endAngle: CGFloat(2 * M_PI), clockwise: false).CGPath
    }
    
}
