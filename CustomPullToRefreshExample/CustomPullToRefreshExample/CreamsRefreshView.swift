//
//  CreamsRefreshView.swift
//  CreamsAgent
//
//  Created by Rawlings on 27/07/2017.
//  Copyright © 2017 Hangzhou Craftsman Network Technology Co.,Ltd. All rights reserved.
//

import Foundation
import SnapKit
import DGActivityIndicatorView
import CustomPullToRefresh

class CreamsRefreshView: UIView {
    
    var holder = CreamsRefreshHolderView(frame: .zero)
    var loading = DGActivityIndicatorView(type: DGActivityIndicatorAnimationType.ballPulse, tintColor: UIColor(gray: 200), size: 40)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        self.loading?.alpha = 0
        loading?.contentMode = .scaleAspectFit
        addSubview(loading!)
        loading?.snp.makeConstraints({ (make) in
            make.height.equalTo(60)
            make.width.equalTo(60)
            make.center.equalTo(self)
        })
        
        addSubview(holder)
        holder.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        holder.alpha = 0
    }
    
}

extension CreamsRefreshView: CustomRefreshViewProtocol {
    
    public func pullingAnimate(withPercent percent: CGFloat, state: SVPullToRefreshState) {
        if percent > 0 {
            loading?.alpha = percent
            holder.alpha = percent
            holder.update(percent: percent)
        }
    }
    
    public func loadingAnimate() {
        loading?.startAnimating()
        loading?.alpha = 1
        holder.alpha = 0
    }
    
    public func finishAnimate() {
        loading?.stopAnimating()
        UIView.animate(withDuration: 0.1, animations: {
            self.loading?.alpha = 0
            self.holder.alpha = 0
        }) { (finish) in
            self.loading?.alpha = 0
            self.holder.alpha = 0
        }
    }
}

class CreamsRefreshHolderView: UIView {
    
    var points = [UIView]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        for i in 0..<3 {
            let point = UIView()
            point.layer.cornerRadius = 5
            point.layer.masksToBounds = true
            point.backgroundColor = UIColor(gray: 200)
            addSubview(point)
            points.append(point)
            point.snp.makeConstraints({ (make) in
                let margin = 16
                let offset = -margin + (margin * i)
                make.centerX.equalTo(self).offset(offset)
                make.centerY.equalTo(self)
                make.width.height.equalTo(10)
            })
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(percent: CGFloat) {
        points.forEach { (ele) in
            ele.snp.updateConstraints({ (make) in
                let offset = frame.size.height/2 * (1 - percent)
                make.centerY.equalTo(self).offset(offset)
            })
        }
    }
}

extension UIColor {
    convenience init(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }
    
    convenience init(gray: CGFloat) {
        self.init(gray, gray, gray, 1)
    }
}
