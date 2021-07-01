//
//  SetDimensionViewController.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 2/2/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import VeracitySDK

protocol SetDimensionPresentableListener: class {
    func confirmedDimension(width: String, height: String, name: String?)
}

protocol SetDimensionViewControllerDelegate: class {
    
}

final class SetDimensionViewController: UIViewController, SetDimensionPresentable, KeyboardAnimationProtocol {
    var listener: SetDimensionPresentableListener?
    private let createItemStream: MutableProtectItemStream
    var containerView: UIView?
    
    // Info
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackContentView: UIStackView!
    @IBOutlet weak var dimensionContainerView: UIView!
    @IBOutlet weak var overviewImageView: DynamicImageView!
    @IBOutlet weak var heighQuotaLabel: UILabel!
    @IBOutlet weak var widthQuotaLabel: UILabel!
    @IBOutlet weak var unitSegmentControl: UISegmentedControl!
    @IBOutlet weak var widthTextField: UITextField!
    @IBOutlet weak var heightTextField: UITextField!
    
    // Error
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
    // Bottom
    @IBOutlet weak var bottomContainerView: UIView!
    @IBOutlet weak var bottomMenuView: UIView!
    @IBOutlet weak var continueButton: AppButton!
    
    // Name
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemNameTextField: UITextField!
    
    // MARK: -
    
    init(createItemStream: MutableProtectItemStream) {
        self.createItemStream = createItemStream
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.selfSetup()
        self.setupKeyboardAnimation()
        self.setupKeyboardObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateLayoutForVertical()
        self.updateDimensionTextField()
        self.loadOverviewImage()
    }
    
    private func loadOverviewImage() {
        guard let image = createItemStream.croppedPhoto else {
            return
        }
        
        gotCropPhoto(image)
    }
    
    private func minDimensions() -> (height : Double, width : Double) {
        let isTooSmallAllow = AppManager.selectedVertical == ApplicationVertical.packaging ||
                              AppManager.selectedVertical == ApplicationVertical.apparel ||
                              AppManager.selectedVertical == ApplicationVertical.sicpa
        
        let height = isTooSmallAllow ? 1.0 : 4.0
        let width = isTooSmallAllow ? 1.0 : 4.0
        
        if getUnitType() == .cm {
            return (height, width)
        } else {
            return (Measurement(value: height, unit: UnitLength.centimeters).converted(to: UnitLength.inches).value.rounded(toPlaces: 1),
                    Measurement(value: width, unit: UnitLength.centimeters).converted(to: UnitLength.inches).value.rounded(toPlaces: 1))
        }
    }
    
    private func maxDimensions() -> (height : Double, width : Double) {
        let height = 500.0
        let width = 500.0
        
        if getUnitType() == .cm {
            return (height, width)
        } else {
            return (Measurement(value: height, unit: UnitLength.centimeters).converted(to: UnitLength.inches).value.rounded(toPlaces: 1),
            Measurement(value: width, unit: UnitLength.centimeters).converted(to: UnitLength.inches).value.rounded(toPlaces: 1))
        }
    }
    
    private func getUnitType() -> UnitType {
        guard let index = UnitType(rawValue: unitSegmentControl.selectedSegmentIndex) else {
            return .cm
        }
        
        return index
    }
    
    private func updateLayoutForVertical() {
        if isDimensionLess() {
            errorView.isHidden = true
            dimensionContainerView.isHidden = true
        }
    }
    
    private func updateDimensionTextField() {
        if getUnitType() == .cm {
            self.widthTextField.placeholder = Text.cm.localizedText
            self.heightTextField.placeholder = Text.cm.localizedText
        } else {
            self.widthTextField.placeholder = Text.in.localizedText
            self.heightTextField.placeholder = Text.in.localizedText
        }
    }
    
    private func updateDimension(width: Double, height: Double) {
        let wString = String(format: "%.1f", width)
        let hString = String(format: "%.1f", height)
        widthTextField.text = wString
        heightTextField.text = hString
        widthQuotaLabel.text = wString
        heighQuotaLabel.text = hString
        
        // auto when size change validate
        checkEnableContinueButton()
        tryToValidateOverviewRatio()
    }
    
    private func showDimensionError(message: String?) {
        errorView.isHidden = message == nil
        errorLabel.text = message
    }
    
    private func checkEnableContinueButton() {
        let enable = validateDimensions() && !(itemNameTextField.text ?? "").isEmpty
        self.continueButton.isEnabled = enable
        self.continueButton.backgroundColor = enable ? AppColor.lightBlue : AppColor.gray
    }
    
    private func setDimensionForLPM() {
        guard let name = itemNameTextField.text
        else { return }
        
        let heigh = "10"
        let width = "7.5"
        self.listener?.confirmedDimension(width: width, height: heigh, name: name)
    }
    
    private func setDimensionData() {
        guard let width = widthTextField.text,
              let heigh = heightTextField.text,
              let name = itemNameTextField.text
        else { return }
        
        self.listener?.confirmedDimension(width: width, height: heigh, name: name)
    }
    
    // MARK: - Validate
    private func validateDimensions() -> Bool {
        guard !isDimensionLess() else {
            return true
        }
        
        guard let heightText = heightTextField.text, let height = heightText.doubleValue,
              let widthText = widthTextField.text, let width = widthText.doubleValue else {
            if !(heightTextField.text?.isEmpty ?? false), !(widthTextField.text?.isEmpty ?? false) {
                showDimensionError(message: "Dimensions are not a valid numbers.")
            }
            return false
        }
        
        if height < minDimensions().height || width < minDimensions().width ||
           height > maxDimensions().height || width > maxDimensions().width {
            let message = String(format: "Fill in item's exact dimensions. Dimensions needs to be larger than %@ and smaller than %@ %@ in width and height.", "\(minDimensions().width)", "\(maxDimensions().width)", getUnitType().name)
            showDimensionError(message: message)
            return false
        } else {
            showDimensionError(message: nil)
            return true
        }
    }
    
    func tryToValidateOverviewRatio() {
        guard let heightText = heightTextField.text, let height = heightText.doubleValue,
              let widthText = widthTextField.text, let width = widthText.doubleValue
        else { return }
        
        guard height > minDimensions().height, width > minDimensions().width
        else { return }
        
        if !validateOverviewRatio(withWidth: width, height: height) {
            showDimensionError(message: "This ratio doesn’t seem right. Enter the correct dimensions or try swapping the width and height.")
        } else {
            showDimensionError(message: nil)
        }
    }
    
    func validateOverviewRatio(withWidth width : Double, height : Double) -> Bool {
        guard let overview = createItemStream.croppedPhoto else {
            return false
        }
        
        let overviewRatio = Double(overview.size.width) / Double(overview.size.height)
        let givenRatio = width / height
        
        let diff = givenRatio / 100 * 10
        let min = givenRatio - diff
        let max = givenRatio + diff
        
        return (min...max) ~= overviewRatio
    }
    
    private func isDimensionLess() -> Bool {
        return false
    }
    
    private func completedSetDimension() {
        if isDimensionLess() {
            self.setDimensionForLPM()
        } else {
            self.setDimensionData()
        }
    }
    
    // MARK: - Actions
    @objc func backgroundTap() {
        self.view.endEditing(true)
    }
    
    @IBAction func confirmPressed(_ sender: Any) {
        if !dimensionContainerView.isHidden, (widthTextField.text ?? "").isEmpty {
            widthTextField.becomeFirstResponder()
            return
        }
        
        if !dimensionContainerView.isHidden, (heightTextField.text ?? "").isEmpty {
            heightTextField.becomeFirstResponder()
            return
        }
        
        if (itemNameTextField.text ?? "").isEmpty {
            itemNameTextField.becomeFirstResponder()
            return
        }
        
        guard validateDimensions() else {
            return
        }
        
        self.completedSetDimension()
    }
    
    @IBAction func unitChanged(_ sender: UISegmentedControl) {
        self.updateDimensionTextField()
        let type = getUnitType()
        self.createItemStream.update(unitType: type)
        
        guard let wString = widthTextField.text, let width = wString.doubleValue,
              let hString = heightTextField.text, let height = hString.doubleValue
        else { return }
        
        if type == .cm {
            let w = Measurement(value: width, unit: UnitLength.inches)
                .converted(to:UnitLength.centimeters).value.rounded(toPlaces: 1)
            let h = Measurement(value: height, unit: UnitLength.inches)
               .converted(to:UnitLength.centimeters).value.rounded(toPlaces: 1)
            updateDimension(width: w, height: h)
        } else {
            let w = Measurement(value: width, unit: UnitLength.centimeters)
                .converted(to:UnitLength.inches).value.rounded(toPlaces: 1)
            let h = Measurement(value: height, unit: UnitLength.centimeters)
               .converted(to:UnitLength.inches).value.rounded(toPlaces: 1)
            updateDimension(width: w, height: h)
        }
    }
    
    @IBAction func swapUnitPressed(_ sender: Any) {
        guard let wString = widthTextField.text, let width = wString.doubleValue,
              let hString = heightTextField.text, let height = hString.doubleValue
        else { return }
        
        updateDimension(width: height, height: width)
    }
    
    @IBAction func dimensionDidChanged(_ sender: UITextField) {
        if sender == widthTextField {
            widthQuotaLabel.text = sender.text
        } else if sender == heightTextField {
            heighQuotaLabel.text = sender.text
        }
        
        checkEnableContinueButton()
        tryToValidateOverviewRatio()
    }
    
    @IBAction func itemNameDidChanged(_ sender: Any) {
        checkEnableContinueButton()
    }
    
    @IBAction func continuePressed(_ sender: Any) {
        self.completedSetDimension()
    }
    
    // MARK: - Setup
    private func selfSetup() {
        let interactor = SetDimensionInteractor(presenter: self, createItemStream: self.createItemStream)
        self.listener = interactor
    }
    
    private func setupView() {
        containerView = bottomContainerView
        bottomMenuView.isHidden = true
        errorView.isHidden = true
        continueButton.backgroundColor = AppColor.lightBlue
        continueButton.setTitle(Text.confirm.localizedText.uppercased(), for: .normal)
        checkEnableContinueButton()
        
        // unit segment
        let isCm = UserManager.shared.user?.metricalUnits ?? true
        unitSegmentControl.selectedSegmentIndex = isCm ? UnitType.cm.rawValue : UnitType.inch.rawValue
        unitSegmentControl.tintColor = AppColor.gray
        if #available(iOS 13.0, *) {
            unitSegmentControl.selectedSegmentTintColor = AppColor.primary
        } else {
            // Fallback on earlier versions
        }
        unitSegmentControl.setTitleTextAttributes( [NSAttributedString.Key.foregroundColor: AppColor.white], for: .selected)
        unitSegmentControl.setTitleTextAttributes( [NSAttributedString.Key.foregroundColor: AppColor.lightPrimary], for: .normal)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTap))
        self.scrollView.addGestureRecognizer(tap)
    }
}

// MARK: - Interactor
extension SetDimensionViewController {
    func gotCropPhoto(_ photo: UIImage) {
        overviewImageView.image = photo
        if photo.size.height >= photo.size.width {
            overviewImageView.fixedHeight = 150
        } else {
            overviewImageView.fixedWidth = UIScreen.main.bounds.width - 140
        }
    }
}

// MARK: - Keyboard
extension SetDimensionViewController {
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeShowed(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc internal func keyboardWillBeShowed(_ notification : Notification) {
        continueButton.isHidden = true
        bottomMenuView.isHidden = false
        let avaiHeight = view.bounds.height - stackContentView.frame.height
        let safeAreaBottomInset = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.bottom ?? 0
        let keyboardHeight = (KeyboardInfo(notification)?.height ?? 0) + safeAreaBottomInset + 45 // menu bar
        let transHeight = max(keyboardHeight - avaiHeight, 0)
        self.stackContentView.transform = CGAffineTransform(translationX: 0, y: -transHeight)
    }
    
    @objc internal func keyboardWillBeHidden(_ notification : Notification) {
        continueButton.isHidden = false
        bottomMenuView.isHidden = true
        self.stackContentView.transform = CGAffineTransform(translationX: 0, y: 0)
    }
}

// MARK: - Textfield delegate
extension SetDimensionViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "," {
            textField.text = textField.text! + "."
            return false
        }
        return true
    }
    
}
