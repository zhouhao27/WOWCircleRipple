//
//  WOWCircleRippleButton.swift
//  CircleRipple
//
//  Created by Zhou Hao on 15/08/15.
//  Copyright © 2015年 Zeus. All rights reserved.
//

import UIKit

@IBDesignable open class WOWCircleRippleButton: UIButton {
    
    // MARK: inspectable
    @IBInspectable var cornerRadius : CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var borderWidth : CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var borderColor : UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    @IBInspectable var rippleLineWidth : CGFloat = 2
    
    // MARK: private variables
    fileprivate var actionInProgress : Bool = false
    var backLayer : CALayer?
    
    var originalBackgroundColor = UIColor.clear
    var originalBorderColor = UIColor.clear.cgColor
    var originalTitleColor = UIColor.white
    
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
    open func startAction() {
        
        if !actionInProgress {
            
            actionInProgress = true
            
            // add background layer
            originalBackgroundColor = backgroundColor!
            backgroundColor = UIColor.clear
            originalTitleColor = self.titleColor(for: .normal)!
            setTitleColor(UIColor.clear, for: .normal)
            
            backLayer = createBacklayer()
            
            // animate to cicle (bounds)
            originalBorderColor = layer.borderColor!
            layer.borderColor = UIColor.clear.cgColor
            
            let newBounds = getNewBounds()
            backLayer!.borderWidth = layer.borderWidth
            backLayer!.borderColor = originalBorderColor
            
            let animRadius = CABasicAnimation(keyPath: "cornerRadius")
            animRadius.toValue = newBounds.width / 2
            animRadius.fillMode = kCAFillModeForwards
            animRadius.isRemovedOnCompletion = false
            
            let animation = CABasicAnimation(keyPath: "bounds")
            animation.toValue = NSValue(cgRect: newBounds)
            animation.fillMode = kCAFillModeForwards
            animation.isRemovedOnCompletion = false
            
            let animGroup = CAAnimationGroup()
            animGroup.animations = [animRadius,animation]
            animGroup.duration = 0.3
            backLayer!.add(animGroup, forKey: "group")
            
            GCD.delay(0.2, block: { () -> () in
                
                self.backLayer!.bounds = newBounds
                self.startAnimating()
            })
        }
    }
    
    open func stopAction(_ toView : UIView, animated : Bool) {
        
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
            animGroup.isRemovedOnCompletion = false
            animGroup.completion = {
                finished in
                
                if self.backLayer != nil {
                    self.backLayer!.removeAllAnimations()
                    self.backLayer!.removeFromSuperlayer()
                    self.backLayer = nil
                }
            }
            
            backLayer!.add(animGroup, forKey: "group")
            
        }
    }
    
    open func stopAction(_ animated : Bool) {
        
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
                animation.toValue = NSValue(cgRect: layer.bounds)
                
                let animScale = CABasicAnimation(keyPath: "transform.scale")
                animScale.fromValue = 0
                animScale.toValue = 1
                
                let animGroup = CAAnimationGroup()
                animGroup.animations = [animRadius,animation,animScale]
                animGroup.duration = 0.3
                animGroup.fillMode = kCAFillModeForwards
                animGroup.isRemovedOnCompletion = false
                animGroup.completion = {
                    finished in
                    self.backLayer!.removeAllAnimations()
                    self.resetToOriginalStatus()
                }
                
                backLayer!.add(animGroup, forKey: "group")
                
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
        addTarget(self, action: #selector(WOWCircleRippleButton.onClicked), for: UIControlEvents.touchUpInside)
    }
    
    func onClicked() {
        self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        
        UIView.animate(withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 100.0,
            options: UIViewAnimationOptions.curveEaseInOut,
            animations: {
                self.transform = CGAffineTransform.identity
            }, completion: {
                (finished) -> Void in
        })
    }
    
    fileprivate func createBacklayer() -> CALayer {
        
        let backlayer = CALayer()
        backlayer.masksToBounds = true
        backlayer.frame = bounds
        backlayer.backgroundColor = originalBackgroundColor.cgColor
        
        layer.addSublayer(backlayer)
        return backlayer
    }
    
    fileprivate func resetToOriginalStatus() {
        
        if backLayer != nil {
            backLayer!.removeFromSuperlayer()
            backLayer = nil
        }
        
        layer.backgroundColor = UIColor.clear.cgColor
        layer.borderColor = originalBorderColor
        backgroundColor = originalBackgroundColor
        setTitleColor(originalTitleColor, for: .normal)
    }
    
    fileprivate func getNewBounds() -> CGRect {
        
        var newBounds : CGRect
        if layer.bounds.width > layer.bounds.height {
            newBounds = CGRect(x: 0, y: 0, width: layer.bounds.height, height: layer.bounds.height)
        } else {
            newBounds = CGRect(x: 0, y: 0, width: layer.bounds.width, height: layer.bounds.width)
        }
        return newBounds
        
    }
    
    fileprivate func startAnimating() {
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.fromValue = 1
        anim.toValue = 0
        anim.duration = 0.2
        anim.isRemovedOnCompletion = false
        anim.fillMode = kCAFillModeForwards
        
        backLayer!.add(anim, forKey: "scale")
        
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
    
    fileprivate func ripple() {
        
        let circle = CAShapeLayer()
        
        // anchorPoint doesn't work
        // need to set the layer's frame
        circle.path = pathFor(backLayer!, radius: backLayer!.bounds.width/2)
        circle.frame = backLayer!.frame
        
        circle.fillColor = UIColor.clear.cgColor
        circle.strokeColor = originalBackgroundColor.cgColor
//        circle.lineWidth = 3
        circle.lineWidth = rippleLineWidth
        
        self.layer.addSublayer(circle)
        
        let animScale = CABasicAnimation(keyPath: "transform.scale")
        animScale.fromValue = 0
        animScale.toValue = 1
        
        circle.transform = CATransform3DMakeScale(1.0,1.0,1.0)
        circle.add(animScale, forKey: "scale")
        
        let animAlpha = CABasicAnimation(keyPath: "opacity")
        animAlpha.fromValue = 1
        animAlpha.toValue = 0
        animAlpha.isRemovedOnCompletion = false
        animAlpha.fillMode = kCAFillModeForwards
        
        circle.add(animAlpha, forKey: "alpha")
        
        let animGroup = CAAnimationGroup()
        animGroup.animations = [animScale,animAlpha]
        animGroup.repeatCount = Float.infinity
        animGroup.duration = 0.8
        circle.add(animGroup, forKey: "")
        
        ripples.append(circle)
    }
    
    fileprivate func pathFor(_ layer : CALayer, radius : CGFloat) -> CGPath {
        
        let center = CGPoint(x: layer.bounds.width / 2, y: layer.bounds.width / 2)
        return UIBezierPath(arcCenter: center, radius: radius, startAngle: 0.0, endAngle: CGFloat(2 * M_PI), clockwise: false).cgPath
    }
    
}
