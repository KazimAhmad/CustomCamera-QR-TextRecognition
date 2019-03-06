//
//  CustomCamera.swift
//  RiskivectorReadings
//
//  Created by KazimAhmad on 04/01/2019.
//  Copyright © 2019 Riskivector. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox.AudioServices

class CustomCamera: UIViewController {

    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var capturePreviewView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var galleryButton: UIButton!
    
    @IBOutlet weak var typesCollection: UICollectionView!
    var namesOfTypes = [ReadingTypes]()
    var nameForFirstIndex = String()
    var flatNickName = String()
    
    //taking reading for which type
    var selectedCellForReading : IndexPath = [0,0]
    var takingReadingFor = String()
    //
    
    let imagePicker = UIImagePickerController()
    var imageFromGallery = UIImage()
    
    var isQRDetected : Bool = false
    var isQRForElectricity: Bool = false
    
    let cameraController = CameraController()
    //data fetched from QR Code
    var flatAndBuilding = [Int]()
    var qrDataObj : DataFromQRScan?
    //
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        typesCollection.isPagingEnabled = true
        typesCollection.contentInset = UIEdgeInsets(top: 0, left: typesCollection.frame.width/3, bottom: 0, right: typesCollection.frame.width/3)
        setupNames()
        imagePicker.delegate = self
        shutterButton.isEnabled = false
        galleryButton.isEnabled = false
        flashButton.isEnabled = false
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishScanningQR), name: .qrResult, object: nil)
        shutterButton.layer.cornerRadius = shutterButton.frame.width/2
        shutterButton.layer.borderWidth = 8.0
        shutterButton.layer.borderColor = UIColor.init(red: 154/255, green: 154/255, blue: 154/255, alpha: 0.5).cgColor
        cameraController.captureSession?.startRunning()
        configureCameraController()
    }
    func setupNames() {
        typesCollection.delegate = self
        typesCollection.dataSource = self
        takingReadingFor = nameForFirstIndex
        typesCollection.register(UINib.init(nibName: "CellOnCamera", bundle: nil), forCellWithReuseIdentifier: "CellOnCamera")
        namesOfTypes = ReadingTypesArray.shared.AllData
        let index = namesOfTypes.firstIndex(where: { $0.labelName == nameForFirstIndex })
        if index != nil {
            isQRForElectricity = namesOfTypes[index!].counterTypeID == 3 || namesOfTypes[index!].counterTypeID == 4 || namesOfTypes[index!].counterTypeID == 5 ? true : false
            let element = namesOfTypes.remove(at: index ?? 0)
            namesOfTypes.insert(element, at: 0)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    override func viewWillAppear(_ animated: Bool) {
        disableCameraAndEnableQR()
    }
    @objc func didFinishScanningQR(notification: Notification) {
        let qrResultValue = notification.object as? String
        print(qrResultValue ?? "")
        if isQRDetected == false && qrResultValue != "" {
            isQRDetected = true
            AudioServicesPlayAlertSound(1111)

            AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate) {
                DispatchQueue.main.async {
                    self.shutterButton.isEnabled = true
                    self.flashButton.isEnabled = true
                    self.galleryButton.isEnabled = true
                    self.messageLabel.text = "Take Reading"
                }
            }
            getQRData(qrValue: qrResultValue ?? "")
        } else {
            print("no qr code detected")
        }
        
    }//end of didFinishScanningQR
    
    //QR code values and comparison
    func getQRData(qrValue: String) {
        Requests.shared.FetchQRObject(accessToken: AppConstants.shared.UserToken, qrCode: qrValue) { (dict) in
            self.qrDataObj = DataFromQRScan(dict)
            print(self.qrDataObj?.lastReading)
        }
    }
    
    func isQRFromSameFlat() -> Bool {
        print(flatAndBuilding[0], flatAndBuilding[1])
        print(qrDataObj?.flatID)
        print(qrDataObj?.buildingID)

        if qrDataObj?.flatID == flatAndBuilding[0] && qrDataObj?.buildingID == flatAndBuilding[1] {
            return true
        }else{
            return false
        }
    }
    
    func isWorkerScannigQRofSameReadingType() -> Bool {
        let index = namesOfTypes.firstIndex(where: { $0.labelName == takingReadingFor })
        if index != nil {
            let thisCounterTypeID = namesOfTypes[index!].counterTypeID
            if thisCounterTypeID == qrDataObj?.counterTypeId {
                return true
            }else{
                return false
            }
        }else{
            return false
        }
    }
    
    func disableCameraAndEnableQR() {
        self.shutterButton.isEnabled = false
        self.flashButton.isEnabled = false
        self.galleryButton.isEnabled = false
        self.messageLabel.text = "Scan QR Code"
        isQRDetected = false
        qrDataObj = nil
    }
    
    //end of QR code values and comparison

    func configureCameraController() {
        cameraController.prepare {(error) in
            if let error = error {
                print(error)
            }
            try? self.cameraController.displayPreview(on: self.capturePreviewView)
        }
    }
    
    @IBAction func galleryAct(_ sender: UIButton) {
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func toggleFlash(_ sender: UIButton) {
        if cameraController.flashMode == .on {
            cameraController.flashMode = .off
            flashButton.setImage(#imageLiteral(resourceName: "flash-off"), for: .normal)
        }
            
        else {
            cameraController.flashMode = .on
            flashButton.setImage(#imageLiteral(resourceName: "flash-on"), for: .normal)
        }
    }
    
    @IBAction func closeCamera(_ sender: UIButton) {
        dismiss(animated: false, completion: nil)
    }
    @IBAction func shutterAction(_ sender: UIButton) {
        if isQRFromSameFlat() == false {
            AppConstants.shared.showAlert("The QR code you scanned is not from the flat you are taking readings for", "", view: self)
            disableCameraAndEnableQR()
            return
        }
        if isWorkerScannigQRofSameReadingType() == false {
            AppConstants.shared.showAlert("The QR code you scanned is not for \(takingReadingFor)", "", view: self)
            disableCameraAndEnableQR()
            return
        }
        cameraController.captureImage {(image, error) in
            guard let image = image else {
                print(error ?? "Image capture error")
                return
            }
            let editImage = self.storyboard?.instantiateViewController(withIdentifier: "edit") as! EditImage
            editImage.imageCaptured = image
            editImage.readingFor = self.takingReadingFor
            editImage.delegate = self
            editImage.ReadingFlatNickName = self.flatNickName
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MM-yyyy hh:mm:ss"
            let time = (formatter.string(from: Date()) as NSString) as String
            editImage.time = time
            print(self.qrDataObj?.lastReading)
            editImage.previousReadingTaken = self.qrDataObj?.lastReading ?? 0
//            let nav = UINavigationController.init(rootViewController: editImage)
            self.present(editImage, animated: true, completion: nil)
            //            try? PHPhotoLibrary.shared().performChangesAndWait {
//                PHAssetChangeRequest.creationRequestForAsset(from: image)
//            }
        }
    }
    
}

extension CustomCamera: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imagePicked = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.imageFromGallery = imagePicked
        }
        dismiss(animated: false) {
            print("completion of dismiss")
            if self.isQRFromSameFlat() == false {
                AppConstants.shared.showAlert("The QR code you scanned is not from the flat you are taking readings for", "", view: self)
                self.disableCameraAndEnableQR()
                return
            }
            if self.isWorkerScannigQRofSameReadingType() == false {
                AppConstants.shared.showAlert("The QR code you scanned is not for \(self.takingReadingFor)", "", view: self)
                self.disableCameraAndEnableQR()
                return
            }
            let editImage = self.storyboard?.instantiateViewController(withIdentifier: "edit") as! EditImage
            editImage.imageCaptured = self.imageFromGallery
            editImage.readingFor = self.takingReadingFor
            editImage.delegate = self
            editImage.ReadingFlatNickName = self.flatNickName
            editImage.previousReadingTaken = self.qrDataObj?.lastReading ?? 0
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MM-yyyy hh:mm:ss"
            let time = (formatter.string(from: Date()) as NSString) as String
            editImage.time = time
            self.present(editImage, animated: true, completion: nil)
        }
    }
}

extension CustomCamera: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        targetContentOffset.pointee = scrollView.contentOffset
//        let cellSize = CGSize(width:120, height:typesCollection.frame.height);
//
//        //get current content Offset of the Collection view
//        let contentOffset = typesCollection.contentOffset;
//
//        if typesCollection.contentSize.width <= typesCollection.contentOffset.x + cellSize.width
//        {
//            typesCollection.scrollRectToVisible(CGRect(x:0, y:contentOffset.y, width:cellSize.width, height:cellSize.height), animated: true);
//
//        } else {
//            typesCollection.scrollRectToVisible(CGRect(x:contentOffset.x + cellSize.width, y:contentOffset.y, width:cellSize.width, height:cellSize.height), animated: true);
//
//        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let width = typesCollection.bounds.width
        let widthForAllCells = CGFloat(3 * 120) // cell width is 120 in Storyboard
        let widthForAllCellSpacings = CGFloat(2 * 10)
        
        let leftInset = CGFloat(width - (widthForAllCells + widthForAllCellSpacings)) / 2
        let rightInset = leftInset
        
        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: 120, height: typesCollection.frame.height)
    }
}

extension CustomCamera: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return namesOfTypes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = typesCollection.dequeueReusableCell(withReuseIdentifier: "CellOnCamera", for: indexPath) as! CellOnCamera
        cell.typeName.text = namesOfTypes[indexPath.item].labelName
        if indexPath == selectedCellForReading {
            cell.typeName.textColor = UIColor.yellow
        }else{
            cell.typeName.textColor = UIColor.white
        }
        cell.typeNum.text = "\(namesOfTypes[indexPath.item].counterTypeID)"
        cell.tapCellSelect = {(select) in
            self.disableCameraAndEnableQR()
            self.selectedCellForReading = indexPath
            self.takingReadingFor = self.namesOfTypes[indexPath.item].labelName
            self.typesCollection.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            self.typesCollection.reloadData()
        }
        return cell
    }
    
    
}

extension CustomCamera: EditImageDelegate {
    func didFinishEditingImage(forReadingTypeName: String) {
        print(forReadingTypeName)
        let index = namesOfTypes.firstIndex(where: { $0.labelName == forReadingTypeName })
        if index != nil {
            namesOfTypes.remove(at: index ?? 0)
            if namesOfTypes.count != 0 {
                takingReadingFor = namesOfTypes[0].labelName
            }
            typesCollection.reloadData()
        }
    }
    
}
