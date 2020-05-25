//
//  UICollectionView+Extensions.swift
//  PHImagePickerController
//
//  Created by PhanithNY on 5/25/20.
//  Copyright © 2020 PhanithNY. All rights reserved.
//

import UIKit

extension UICollectionViewCell {
  static var identifier: String { String(describing: self) }
}

extension UICollectionReusableView {
  static var reuseIdentifier: String { String(describing: self) }
}

extension UICollectionView {
  final func register<T: UICollectionViewCell>(_: T.Type) {
    register(T.self, forCellWithReuseIdentifier: T.identifier)
  }
  
  final func register<T: UICollectionReusableView>(_: T.Type, ofKind kind: String) {
    register(T.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: T.reuseIdentifier)
  }
  
  final func dequeueReusableCell<T: UICollectionViewCell>(at indexPath: IndexPath) -> T {
    unsafeDowncast(dequeueReusableCell(withReuseIdentifier: T.identifier, for: indexPath), to: T.self)
  }
  
  final func dequeueReusableSupplementaryView<T: UICollectionReusableView>(ofKind kind: String, for indexPath: IndexPath) -> T {
    unsafeDowncast(dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: T.reuseIdentifier, for: indexPath), to: T.self)
  }
}
