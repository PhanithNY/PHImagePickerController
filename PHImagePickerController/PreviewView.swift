//
//  PreviewView.swift
//  PHImagePickerController
//
//  Created by PhanithNY on 5/25/20.
//  Copyright © 2020 PhanithNY. All rights reserved.
//

import Photos
import UIKit

final class PreviewView: UIView {
  
  // MARK: - Properties
  
  private var frameInSuper: CGRect = .zero
  
  private lazy var previewImageView: UIImageView = {
    let redView = UIImageView(frame: .zero)
    redView.contentMode = .scaleAspectFill
    redView.layer.cornerRadius = 4
    redView.layer.cornerCurve = .continuous
    redView.layer.masksToBounds = true
    return redView
  }()
  
  private lazy var effectView: UIVisualEffectView = {
    let blur = UIBlurEffect(style: .prominent)
    let effectView = UIVisualEffectView(effect: blur)
    effectView.alpha = 0.95
    return effectView
  }()
  
  private lazy var indicatorView: UIActivityIndicatorView = {
    let indicatorView = UIActivityIndicatorView(style: .medium)
    indicatorView.translatesAutoresizingMaskIntoConstraints = false
    indicatorView.color = .systemBlue
    indicatorView.startAnimating()
    return indicatorView
  }()
  
  // MARK: - Init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    effectView.contentView.isUserInteractionEnabled = true
    effectView.contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss(_:))))
  }
  
  required init?(coder: NSCoder) {
    fatalError()
  }
  
  // MARK: - Actions
  
  final func preview(_ frameInSuper: CGRect, image: UIImage?, asset: PHAsset, in window: UIWindow) {
    self.frameInSuper = frameInSuper
    
    previewImageView.frame = frameInSuper
    previewImageView.image = image
    effectView.frame = window.bounds
    window.addSubview(effectView)
    window.addSubview(previewImageView)
    
    window.addSubview(indicatorView)
    indicatorView.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
    indicatorView.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
    
    UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
      self.previewImageView.frame = CGRect(x: 4, y: window.center.y - (window.bounds.width - 8)/2, width: window.bounds.width - 8, height: window.bounds.width - 8)
    }) { _ in
      self.indicatorView.startAnimating()
      self.fetchHighRes(for: asset) { [weak self] image in
        self?.indicatorView.stopAnimating()
        self?.previewImageView.image = image
      }
    }
  }
  
  private func fetchHighRes(for asset: PHAsset, then: ((UIImage?) -> Swift.Void)?) {
    let imageManager = PHImageManager.default()
    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = true
    options.isSynchronous = true
    imageManager.requestImage(for: asset, targetSize: CGSize(width: 1024, height: 1024), contentMode: .aspectFill, options: options) { (image, info) in
      then?(image)
    }
  }
  
  @objc
  private func dismiss(_ sender: UITapGestureRecognizer) {
    let location = sender.location(in: nil)
    if previewImageView.frame.contains(location) { return }
    
    self.effectView.removeFromSuperview()
    UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
      self.previewImageView.frame = self.frameInSuper
    }) { _ in
      self.previewImageView.removeFromSuperview()
    }
  }
}
