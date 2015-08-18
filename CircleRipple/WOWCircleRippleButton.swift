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
    @IBInspectable var rippleLineWidth            : CGFloat = 2
    
    // MARK: private variables
    private var actionInProgress            : Bool = false
    var backLayer                           : CALayer?
    var originalBackgroundColor = UIColor.clearColor()
    var originalBorderColor = UIColor.clearColor().CGColor
    var originalTitleColor = UIColor.whiteColor()
    var ripples = [CALayer]()
    
    // MARK: override
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    // MARK: public methods
    public func startAction() {
        
        if !actionInProgress {
            
            actionInProgress = true
            
            // add background layer
            originalBackgroundColor = backgroundColor!
            backgroundColor = UIColor.clearColor()
            originalTitleColor = self.titleColorForState(.Normal)!
            setTitleColor(UIColor.clearColor(), forState: .Normal)
            
            backLayer = createBacklayer()
            
            // animate to cicle (bounds)
            originalBorderColor = layer.borderColor!
            layer.borderColor = UIColor.clearColor().CGColor
            
            var newBounds = getNewBounds()
            backLayer!.borderWidth = layer.borderWidth
            backLayer!.borderColor = originalBorderColor
            
            let animRadius = CABasicAnimation(keyPath: "cornerRadius")
            animRadius.toValue = newBounds.width / 2
            animRadius.fillMode = kCAFillModeForwards
            animRadius.removedOnCompletion = false
            
            let animation = CABasicAnimation(keyPath: "bounds")
            animation.toValue = NSValue(CGRect: newBounds)
            animation.fillMode = kCAFillModeForwards
            animation.removedOnCompletion = false
            
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
    
    public func stopAction(toView : UIView, animated : Bool) {
        
        if actionInProgress {
            
            actionInProgress = false
            
            // remove ripples
            for subLayer in ripples {
                subLayer.removeAllAnimations()
                subLayer.removeFromSuperlayer()
            }
            
            self.backLayer!.removeAllAnimations()
            
            // expand
            toView.clipsToBounds = true // don't allow the subview out of the boundary
            
            let animScale = CABasicAnimation(keyPath: "transform.scale")
            let offset = max(toView.bounds.width - backLayer!.bounds.origin.x/2, toView.bounds.height - backLayer!.bounds.origin.y/2)
            let scale = offset / (backLayer!.bounds.width/2)
            animScale.toValue = scale
            
            let animAlpha = CABasicAnimation(keyPath: "opacity")
            animAlpha.fromValue = 1
            animAlpha.toValue = 0
            
            let animGroup = CAAnimationGroup()
            animGroup.animations = [animScale,animAlpha]
            animGroup.duration = 0.3
            animGroup.fillMode = kCAFillModeForwards
            animGroup.removedOnCompletion = false
            animGroup.completion = {
                finished in
                self.backLayer!.removeAllAnimations()
                self.backLayer!.removeFromSuperlayer()
                self.backLayer = nil
            }
            
            backLayer!.addAnimation(animGroup, forKey: "group")
            
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
                
                let animRadius = CABasicAnimation(keyPath: "cornerRadius")
                animRadius.toValue = layer.cornerRadius
                
                let animation = CABasicAnimation(keyPath: "bounds")
                animation.toValue = NSValue(CGRect: layer.bounds)
                
                let animScale = CABasicAnimation(keyPath: "transform.scale")
                animScale.fromValue = 0
                animScale.toValue = 1
                
                let animGroup = CAAnimationGroup()
                animGroup.animations = [animRadius,animation,animScale]
                animGroup.duration = 0.3
                animGroup.fillMode = kCAFillModeForwards
                animGroup.removedOnCompletion = false
                animGroup.completion = {
                    finished in
                    self.backLayer!.removeAllAnimations()
                    self.resetToOriginalStatus()
                }
                
                backLayer!.addAnimation(animGroup, forKey: "group")
                
            } else {
                self.backLayer!.removeAllAnimations()
                self.resetToOriginalStatus()
            }
            
        }
    }
    
    public func reset() {
        resetToOriginalStatus()
    }
    
    // MARK: private methods
    func setup() {
        
        addTarget(self, action: "onClicked", forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    func onClicked() {
        self.transform = CGAffineTransformMakeScale(1.2, 1.2)
        
        UIView.animateWithDuration(0.4,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 100.0,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: {
                self.transform = CGAffineTransformIdentity
            }, completion: {
                (finished) -> Void in
        })
    }
    
    private func createBacklayer() -> CALayer {
        
        let backlayer = CALayer()
        backlayer.masksToBounds = true
        backlayer.frame = bounds
        backlayer.backgroundColor = originalBackgroundColor.CGColor
        
        layer.addSublayer(backlayer)
        return backlayer
    }
    
    private func resetToOriginalStatus() {
        
        if backLayer != nil {
            backLayer!.removeFromSuperlayer()
            backLayer = nil
        }
        
        layer.backgroundColor = UIColor.clearColor().CGColor
        layer.borderColor = originalBorderColor
        backgroundColor = originalBackgroundColor
        setTitleColor(originalTitleColor, forState: .Normal)
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
        circle.lineWidth = rippleLineWidth
        
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
