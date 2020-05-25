//
//  LoadingReusableView.swift
//  PHImagePickerController
//
//  Created by PhanithNY on 5/25/20.
//  Copyright © 2020 PhanithNY. All rights reserved.
//

import UIKit

final class LoadingReusableView: UICollectionReusableView {
  
  // MARK: - Properties
  
  private lazy var indicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.translatesAutoresizingMaskIntoConstraints = false
    return indicator
  }()
  
  // MARK: - Init / Deinit
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    prepareLayouts()
  }
  
  required init?(coder: NSCoder) {
    fatalError()
  }
  
}

// MARK: - Actions

extension LoadingReusableView {
  final func startAnimating() {
    indicator.startAnimating()
  }
  
  final func stopAnimating() {
    indicator.stopAnimating()
  }
}

// MARK: - Layouts

extension LoadingReusableView {
  
  private func prepareLayouts() {
    addSubview(indicator)
    indicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    indicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
  }
  
}
