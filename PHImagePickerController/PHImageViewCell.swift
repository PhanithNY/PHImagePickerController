//
//  PHImageViewCell.swift
//  PHImagePickerController
//
//  Created by PhanithNY on 5/21/20.
//  Copyright © 2020 PhanithNY. All rights reserved.
//

import UIKit

final class PHImageViewCell: UICollectionViewCell {
  
  var image: UIImage? {
    didSet {
      self.imageView.image = image
    }
  }
  
  private(set) var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
  }()
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    return label
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    contentView.addSubview(imageView)
    contentView.addSubview(titleLabel)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    imageView.frame = contentView.bounds
    titleLabel.frame = contentView.bounds
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    imageView.image = nil
  }
 
  final func set(title: String?) {
    titleLabel.text = title
  }
}
