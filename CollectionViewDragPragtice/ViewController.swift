//
//  ViewController.swift
//  CollectionViewDragPragtice
//
//  Created by Daisaku Ejiri on 2022/11/11.
//

import UIKit

class ViewController: UIViewController {
  
  var viewWidth: CGFloat {
    return view.bounds.width
  }
  
  var viewHeight: CGFloat {
    return view.bounds.height
  }
  
  var topInset: CGFloat {
    return view.safeAreaInsets.top
  }
  
  var bottomInset: CGFloat {
    return view.safeAreaInsets.bottom
  }
  
  var leftInset: CGFloat {
    return view.safeAreaInsets.left
  }
  
  var righInset: CGFloat {
    return view.safeAreaInsets.right
  }
  
  var colors_A: [UIColor] = [
    .red, .green, .blue
  ]
  
  var isDragging: Bool = false {
    didSet {
      if isDragging == true {
        UIView.animate(withDuration: 0.5, animations: {
          self.trashImageView.isHidden = !self.isDragging
          self.trashImageView.alpha = 1.0
        }) { _ in
          // do nothing
        }
      } else {
        UIView.animate(withDuration: 0.5, animations: {
          self.trashImageView.alpha = 0
        }) { _ in
          self.trashImageView.isHidden = !self.isDragging
        }
      }
    }
  }
  
  lazy var collectionView_A: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.dragDelegate = self
    collectionView.dropDelegate = self
    collectionView.backgroundColor = .systemGray6
    return collectionView
  }()
  
  lazy var trashImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage(systemName: "trash"))
    let dropInteraction = UIDropInteraction(delegate: self)
    imageView.addInteraction(dropInteraction)
    imageView.isUserInteractionEnabled = true
    imageView.alpha = 0
    imageView.isHidden = !isDragging
    return imageView
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .white
    view.addSubview(collectionView_A)
    view.addSubview(trashImageView)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    layout()
  }
  
  private func layout() {
    let bottomAreaHeight: CGFloat = 100
    let trashViewSize: CGFloat = 50
    let margin: CGFloat = 10
    
    collectionView_A.frame = CGRect(x: leftInset + margin, y: topInset, width: viewWidth - righInset - leftInset - margin*2, height: (viewHeight - topInset - bottomInset - bottomAreaHeight))
    trashImageView.frame = CGRect(x: viewWidth - bottomAreaHeight, y: viewHeight - bottomInset - bottomAreaHeight/2 - trashViewSize/2, width: trashViewSize, height: trashViewSize)
    
  }
}

extension ViewController: UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return colors_A.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    // simply adding a color to the cell background
    cell.backgroundColor = colors_A[indexPath.item]
    return cell
  }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    // can return here any size dynamically
    return CGSize(width: collectionView.frame.width/3.2, height: collectionView.frame.width/3.2)
  }
}

extension ViewController: UICollectionViewDragDelegate {
  
  // modifying the isDragging state according to the dragSession lifecycle
  func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
    isDragging = true
  }
  
  func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
    isDragging = false
  }
  
  func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    // in order for session to know the localContext. This will be used in dropSessionDidUpdate method
    session.localContext = collectionView
    let itemProvider = NSItemProvider(object: colors_A[indexPath.item])
    let dragItem = UIDragItem(itemProvider: itemProvider)
    dragItem.localObject = indexPath.item
    return [dragItem]
  }
  
}

extension ViewController: UICollectionViewDropDelegate {
  
  func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
    // checking if the localContext is equal to the collectionView
    let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
    return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
  }
  

  func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
    let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
    for item in coordinator.items {
      // if item.sourceIndexPath is not nil, then we know the drag is comming from the same collectionView
      if let sourceIndexPath = item.sourceIndexPath {
        // performBatchUpdates is necessary when making multiple changes to the model and the collectionView
        collectionView.performBatchUpdates {
          let color = colors_A.remove(at: sourceIndexPath.item)
          colors_A.insert(color, at: destinationIndexPath.item)
          collectionView_A.deleteItems(at: [sourceIndexPath])
          collectionView_A.insertItems(at: [destinationIndexPath])
        }
        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        
      }
    }
  }
}

extension ViewController: UIDropInteractionDelegate {
  
  func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
    return session.canLoadObjects(ofClass: UIColor.self)
  }
  
  func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
    return UIDropProposal(operation: .copy)
  }
  
  func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
    session.items.forEach({ item in
      if let index = item.localObject as? Int {
        // performBatchUpdates is necessary also to make the changes animate
        collectionView_A.performBatchUpdates {
          colors_A.remove(at: index)
          collectionView_A.deleteItems(at: [IndexPath(item: index, section: 0)])
        }
      }
    })
  }
}

