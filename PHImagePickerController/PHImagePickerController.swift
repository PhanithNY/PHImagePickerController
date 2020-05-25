//
//  PHImagePickerController.swift
//  PHImagePickerController
//
//  Created by PhanithNY on 5/21/20.
//  Copyright © 2020 PhanithNY. All rights reserved.
//

import UIKit
import Photos

final class PHImagePickerController: UIViewController {
  
  var handler: ((UIImage) -> Swift.Void)?
  
  // MARK: - Properties
  
  public var localizedTitle: String? = "Choose Photo"
  public var itemSize: CGSize = CGSize(width: 200, height: 200)
  public var perPageItem: Int = 11
  
  private enum Section: String, CaseIterable {
    case content
  }
  
  private var diffableDataSource: UICollectionViewDiffableDataSource<Section, UIImage>!
  private var oldPage: Int = 0
  private var currentPage: Int = 0
  private let lineSpacing: CGFloat = 1.0/UIScreen.main.scale
  private var assets: [PHAsset] = []
  private var selectedImage: UIImage?
  private var isLoading: Bool = false
  
  private var images: [UIImage] = [] {
    didSet {
      var snapshot = NSDiffableDataSourceSnapshot<Section, UIImage>()
      snapshot.appendSections(Section.allCases)
      snapshot.appendItems(images, toSection: .content)
      DispatchQueue.global(qos: .background).async { [weak self] in
        self?.diffableDataSource.apply(snapshot, animatingDifferences: false)
      }
    }
  }
  
  private var selectedAsset: PHAsset? {
    didSet {
      if let asset = selectedAsset {
        fetchHighRes(for: asset, then: nil)
      }
    }
  }
  
  private lazy var targetSize: CGSize = {
    let width: CGFloat = itemSize.width * UIScreen.main.scale
    let targetSize: CGSize = CGSize(width: width, height: width)
    return targetSize
  }()
  
  private lazy var fetchOptions: PHFetchOptions = {
    let options = PHFetchOptions()
    let sortDescriptors = NSSortDescriptor(key: "creationDate", ascending: false)
    options.sortDescriptors = [sortDescriptors]
    return options
  }()
  
  private lazy var collectionView: UICollectionView = {
    let layout = createLayout()
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.backgroundColor = .systemBackground
    collectionView.alwaysBounceVertical = true
    collectionView.register(PHImageViewCell.self)
    collectionView.register(LoadingReusableView.self, ofKind: UICollectionView.elementKindSectionFooter)
    collectionView.delegate = self
    return collectionView
  }()
  
  private var previewView = PreviewView()
  
  // MARK: - ViewController's lifecycle
  
  override func loadView() {
    super.loadView()
    
    prepareLayouts()
    wireDataSource()
    loadPhotosForFirstPageIfNeeded()
  }
  
  // MARK: - Actions
  
  private func loadPhotosForFirstPageIfNeeded() {
    switch PHPhotoLibrary.authorizationStatus() {
    case .authorized:
      fetchPhotos()
    case .denied,
         .restricted,
         .notDetermined:
      PHPhotoLibrary.requestAuthorization { status in
        if status == PHAuthorizationStatus.authorized {
          self.fetchPhotos()
        }
      }
    @unknown default:
      break
    }
  }
  
  private func fetchHighRes(for asset: PHAsset, then: ((UIImage?) -> Swift.Void)?) {
    let imageManager = PHImageManager.default()
    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = true
    options.isSynchronous = true
    imageManager.requestImage(for: asset, targetSize: CGSize(width: 1024, height: 1024), contentMode: .aspectFill, options: options) { (image, info) in
      if let image = image {
        self.selectedImage = image
      }
      then?(image)
    }
  }
  
  private func fetchPhotos() {
    let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    
    let imageManager = PHImageManager.default()
    let option = PHImageRequestOptions()
    option.isSynchronous = true
    option.deliveryMode = .opportunistic
    
    let indexSet: IndexSet
    if allPhotos.count > perPageItem {
      if currentPage < allPhotos.count {
        if (currentPage + perPageItem) < allPhotos.count {
          indexSet = IndexSet(currentPage..<(currentPage + perPageItem))
          currentPage = currentPage + perPageItem
        } else {
          indexSet = IndexSet(currentPage..<allPhotos.count)
          currentPage = allPhotos.count
        }
      } else {
        indexSet = IndexSet(currentPage..<allPhotos.count)
        currentPage = allPhotos.count
      }
    } else {
      indexSet = IndexSet(0..<allPhotos.count)
      currentPage = allPhotos.count
    }
    
    isLoading = true
    oldPage = currentPage
    let enumerationOptions = NSEnumerationOptions()
    
    allPhotos.enumerateObjects(at: indexSet, options: enumerationOptions) { (asset, count, obj) in
      imageManager.requestImage(for: asset, targetSize: self.targetSize, contentMode: .aspectFill, options: option, resultHandler: { (image, info) in
        
        if let image = image {
          self.images.append(image)
          self.assets.append(asset)
          if self.selectedImage == nil {
            self.selectedAsset = self.assets[0]
          }
        }
        
        if count == self.oldPage - 1 {
          self.isLoading = false
        }
        
      })
    }
  }
  
  @objc
  private func dismissSelf() {
    dismiss(animated: true, completion: nil)
  }
  
  @objc
  private func doneHandler(_ sender: UIBarButtonItem) {
    handler?(selectedImage.unsafelyUnwrapped)
    dismissSelf()
  }
}

// MARK: - UICollectionViewDelegate

extension PHImagePickerController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let cell = collectionView.cellForItem(at: indexPath) as! PHImageViewCell
    preview(cell: cell, at: indexPath)
  }
  
  private func preview(cell: PHImageViewCell, at indexPath: IndexPath) {
    let frameInSuper = cell.convert(cell.bounds, to: nil)
    
    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
      if let window = scene.windows.first(where: { $0.isKeyWindow }) {
        previewView.preview(frameInSuper, image: cell.image, asset: assets[indexPath.item], in: window)
      }
    }
  }
}

// MARK: - UIScrollViewDelegate

extension PHImagePickerController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if !isLoading {
      DispatchQueue.global(qos: .background).async {
        self.fetchPhotos()
      }
    }
  }
}

// MARK: - Prepare layouts

extension PHImagePickerController {
  private func prepareLayouts() {
    navigationItem.title = localizedTitle
    navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .close, target: self, action: #selector(dismissSelf))
    
    view.backgroundColor = .systemBackground
    view.addSubview(collectionView)
    collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
    collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
    view.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: 0).isActive = true
    view.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 0).isActive = true
  }
}

// MARK: - Layouts

extension PHImagePickerController {
  private func createLayout() -> UICollectionViewLayout {
    let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
      let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100.0))
      let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [
        self.hStackThreeLayoutSection(bottomInset: 4.0),
        self.vStackLargeLayoutSection(),
        self.hStackThreeLayoutSection(bottomInset: 4.0),
        self.hStackFirstLargeLayoutSection(),
        self.hStackThreeLayoutSection(bottomInset: 0.0),
        self.hStackThreeLayoutSection(bottomInset: 4.0),
        self.hStackLastLargeLayoutSection(),
        self.hStackThreeLayoutSection(bottomInset: 0.0)
      ])
      let section = NSCollectionLayoutSection(group: group)
      let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50.0))
      let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
      footer.contentInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 4)
      section.boundarySupplementaryItems = [footer]
      return section
    }
    return layout
  }
  
  private func vStackLargeLayoutSection() -> NSCollectionLayoutGroup {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    item.contentInsets = .init(top: 0, leading: 4, bottom: 0, trailing: 4)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                           heightDimension: .fractionalWidth(1.0))
    let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: 2)
    group.interItemSpacing = .fixed(4.0)
    return group
  }
  
  private func hStackFirstLargeLayoutSection() -> NSCollectionLayoutGroup {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.66325),
                                           heightDimension: .fractionalHeight(1.0))
    let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: 1)
    
    let group1Size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.33675),
                                            heightDimension: .fractionalHeight(1.0))
    let group1 = NSCollectionLayoutGroup.vertical(layoutSize: group1Size, subitem: item, count: 2)
    group1.contentInsets = .init(top: 0, leading: 4, bottom: 0, trailing: 0)
    group1.interItemSpacing = .fixed(4.0)
    
    let mainGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.7))
    let mainGroup = NSCollectionLayoutGroup.horizontal(layoutSize: mainGroupSize, subitems: [group, group1])
    mainGroup.contentInsets = .init(top: 0, leading: 4.0, bottom: 0, trailing: 4.0)
    return mainGroup
  }
  
  private func hStackThreeLayoutSection(bottomInset: CGFloat) -> NSCollectionLayoutGroup {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                           heightDimension: .fractionalWidth(1.0/3.0))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
    group.contentInsets = .init(top: 4, leading: 4, bottom: bottomInset, trailing: 4)
    group.interItemSpacing = .fixed(4.0)
    return group
  }
  
  private func hStackLastLargeLayoutSection() -> NSCollectionLayoutGroup {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.66325),
                                           heightDimension: .fractionalHeight(1.0))
    let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: 1)
    
    let group1Size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.33675),
                                            heightDimension: .fractionalHeight(1.0))
    let group1 = NSCollectionLayoutGroup.vertical(layoutSize: group1Size, subitem: item, count: 2)
    group1.interItemSpacing = .fixed(4.0)
    group1.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 4.0)
    
    let mainGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.7))
    let mainGroup = NSCollectionLayoutGroup.horizontal(layoutSize: mainGroupSize, subitems: [group1, group])
    mainGroup.contentInsets = .init(top: 0, leading: 4.0, bottom: 0, trailing: 4.0)
    return mainGroup
  }
  
  private func wireDataSource() {
    diffableDataSource = .init(collectionView: collectionView, cellProvider: { [unowned self] (collectionView, indexPath, model) -> UICollectionViewCell? in
      let cell: PHImageViewCell = collectionView.dequeueReusableCell(at: indexPath)
      cell.contentView.layer.cornerRadius = 4
      cell.contentView.layer.cornerCurve = .continuous
      cell.contentView.layer.masksToBounds = true
      cell.image = self.images[indexPath.item]
      return cell
    })
    
    diffableDataSource.supplementaryViewProvider = { [unowned self] collectionView, kind, indexPath in
      if kind == UICollectionView.elementKindSectionFooter {
        let footer: LoadingReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, for: indexPath)
        (self.oldPage == self.currentPage) ? footer.stopAnimating() : footer.startAnimating()
        return footer
      }
      return nil
    }
    
    var snapshot = NSDiffableDataSourceSnapshot<Section, UIImage>()
    snapshot.appendSections(Section.allCases)
    snapshot.appendItems(images, toSection: .content)
    DispatchQueue.global(qos: .background).async { [weak self] in
      self?.diffableDataSource.apply(snapshot, animatingDifferences: false)
    }
    
  }
}
