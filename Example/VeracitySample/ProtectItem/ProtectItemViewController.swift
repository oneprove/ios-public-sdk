//
//  CreateItemViewController.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 1/25/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit
import VeracitySDK

protocol ProtectItemViewControllerDelegate: class {
    func completedPrepareItemData(item: VeracityItem)
}

final class ProtectItemViewController: UIViewController {
    var delegate: ProtectItemViewControllerDelegate?
    
    private var pageController: UIPageViewController?
    private let titleView = CreateItemHeaderView()
    private let createSteps = ProtectItemStep.steps
    private let viewControllers: [UIViewController]
    private let createItemStream = ProtectItemStreamImpl()
    private var currentIndex: Int = 0
    
    init(delegate: ProtectItemViewControllerDelegate) {
        let overviewVC = TakeOverviewPhotoViewController(createItemStream: createItemStream)
        let cropVC = CropBackgroundViewController(createItemStream: createItemStream)
        let dimensionVC = SetDimensionViewController(createItemStream: createItemStream)
        let fingerVC = TakeFingerprintViewController(createItemStream: createItemStream)
        viewControllers = [overviewVC, cropVC, dimensionVC, fingerVC]
        
        super.init(nibName: nil, bundle: nil)
        
        self.delegate = delegate
        createItemStream.observerStepChange({ [weak self] (step) in
            self?.change(to: step)
        })
        
        if UserManager.shared.user?.metricalUnits ?? true {
            createItemStream.update(unitType: .cm)
        } else {
            createItemStream.update(unitType: .inch)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupView()
    }
    
    // MARK: - Actiion
    @objc func moveBack() {
        guard currentIndex > 0 else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        self.moveToPrevStep()
    }
    
    @objc func closePress() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func change(to step: ProtectItemStep) {
        guard step != .completed else {
            self.delegate?.completedPrepareItemData(item: createItemStream.protectItem!)
            return
        }
        
        if currentIndex < step.rawValue {
            self.moveToNextStep()
        } else {
            self.moveToPrevStep()
        }
    }
    
    private func moveToNextStep() {
        currentIndex = min(currentIndex + 1, viewControllers.count - 1)
        updateView(at: currentIndex)
        self.pageController?.setViewControllers([viewControllers[currentIndex]], direction: .forward, animated: true, completion: nil)
    }
    
    private func moveToPrevStep() {
        currentIndex = max(currentIndex - 1, 0)
        updateView(at: currentIndex)
        self.pageController?.setViewControllers([viewControllers[currentIndex]], direction: .reverse, animated: true, completion: nil)
    }
    
    // MARK: - Setup
    
    private func setupView() {
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        view.backgroundColor = AppColor.white
        titleView.backButton.addTarget(self, action: #selector(moveBack), for: .touchUpInside)
        titleView.closeButton.addTarget(self, action: #selector(closePress), for: .touchUpInside)
        view.addSubview(titleView)
        titleView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.trailing.leading.equalToSuperview()
            $0.height.greaterThanOrEqualTo(AppSize.s4)
        }
        
        let pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.pageController = pageController
        pageController.view.backgroundColor = .clear
        let topPadding = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.top ?? 0
        let top = AppSize.s40 + topPadding
        let height = view.frame.height - top
        let width = view.frame.width
        pageController.view.frame = CGRect(x: 0, y: top, width: width, height: height)
        addChild(pageController)
        view.addSubview(pageController.view)
        pageController.setViewControllers([viewControllers[0]], direction: .forward, animated: false, completion: nil)
        pageController.didMove(toParent: self)
        
        /// disable scroll
        for view in self.pageController!.view.subviews {
            if let subView = view as? UIScrollView {
                subView.isScrollEnabled = false
            }
        }
        
        self.updateView(at: ProtectItemStep.takeOverviewPhoto.rawValue)
    }
    
    private func updateView(at index: Int) {
        self.currentIndex = index
        let currentStep = createSteps[index]
        titleView.setHeaderFor(step: currentStep)
    }
}
