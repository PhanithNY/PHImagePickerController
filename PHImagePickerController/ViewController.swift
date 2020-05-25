//
//  ViewController.swift
//  PHImagePickerController
//
//  Created by PhanithNY on 5/21/20.
//  Copyright © 2020 PhanithNY. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let showButton = UIButton()
    showButton.setTitle("Show Picker", for: .normal)
    showButton.setTitleColor(.systemRed, for: .normal)
    showButton.translatesAutoresizingMaskIntoConstraints = false
    showButton.addTarget(self, action: #selector(didTapShowPicker(_:)), for: .touchUpInside)
    view.addSubview(showButton)
    showButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    showButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    showButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
    showButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
  }

  @objc
  private func didTapShowPicker(_ sender: UIButton) {
    let picker = PHImagePickerController()
    let navigationController = UINavigationController(rootViewController: picker)
    navigationController.modalPresentationStyle = .fullScreen
    present(navigationController, animated: true, completion: nil)
  }
}

