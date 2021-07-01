//
//  ItemDetailViewController.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 1/24/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit


protocol ProtectItemDetailPresentableListener: AnyObject {
    func onVerifyItem(photos: [(blurScore: Float, image: UIImage)])
}

protocol ProtectItemDetailViewControllerDelegate: AnyObject {
    func startProtectNewItem()
}

final class ProtectItemDetailViewController: UIViewController, ProtectItemDetailPresentable {
    var listener: ProtectItemDetailPresentableListener?
    weak var delegate: ProtectItemDetailViewControllerDelegate?
    

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var protectItemButton: UIButton!
    @IBOutlet weak var verifyItemButton: UIButton!
    private let verifyItemStream: MutableVerifyItemStream
    private let createItemStream = ProtectItemStreamImpl()
    
    private var itemData: VeracityItem
    init(item: VeracityItem, verifyItemStream: MutableVerifyItemStream) {
        self.itemData = item
        self.verifyItemStream = verifyItemStream
        
        let bundle = Bundle(for: ProtectItemDetailViewController.self)
        super.init(nibName: "ProtectItemDetailViewController", bundle: bundle)
        
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
        
        self.setupView()
        self.selfSetup()
        self.updateLayout(by: itemData.state)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func startProtectItemPressed(_ sender: Any) {
        self.delegate?.startProtectNewItem()
    }
    
    @IBAction func startVerifyItemPressed(_ sender: Any) {
        onVerifyItemProcess()
    }
    
    func updateLayout(by state: ItemState?) {
        switch state {
        case .protected:
            verifyItemButton.isHidden = false
            protectItemButton.isHidden = false
        default:
            verifyItemButton.isHidden = true
            protectItemButton.isHidden = true
        }
    }
    
    private func onVerifyItemProcess() {
        guard let item = itemData as? ProtectItem else {
            return
        }
        
        verifyItemStream.updateItemToVerify(item)
        goToVerificationItem()
    }
    
    private func goToVerificationItem() {
        let fingerVC = TakeFingerprintViewController(verifyItemStream: verifyItemStream)
        fingerVC.delegate = self
        let nav = UINavigationController(rootViewController: fingerVC)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
    
    private func gotoVerifyItemDetail() {
        guard let item = verifyItemStream.localJob else {
            print("Dont have any item verify!!")
            return
        }
        
        print("Local Job: \(item)")
        let vc = VerifyItemDetailViewController(item: item, verifyItemStream: verifyItemStream)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
    
    // MARK: - Actiion
    @objc func moveBack() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func backToItemsPressed(_ sender: Any) {
        self.moveBack()
    }
    
    // MARK: - Setup
    private func selfSetup() {
        let interactor = ProtectItemDetailInteractor(presenter: self,
                                                     item: itemData,
                                                     createItemStream: createItemStream,
                                                     verifyItemStream: verifyItemStream)
        self.listener = interactor
        
        if itemData is ProtectItem {
            print("[Item] is ProtectItem")
        } else {
            print("[Item] is LocalProtectItem")
        }
    }
    
    private func setupView() {
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.title = "Item detail".uppercased()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow-left"), style: .plain, target: self, action: #selector(moveBack))
        navigationItem.leftBarButtonItem?.tintColor = AppColor.primary
        let textAttributes = [NSAttributedString.Key.foregroundColor: AppColor.primary]
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 100
    }
}


// MARK: - TableView
extension ProtectItemDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = ProtectItemInfoView()
        view.setItemData(itemData)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
}

// MARK: - Interactor
extension ProtectItemDetailViewController {
    func reloadData(itemDetail: VeracityItem) {
        self.itemData = itemDetail
        self.tableView.reloadData()
        self.updateLayout(by: itemData.state)
    }
}

// MARK: - Verify Flow
extension ProtectItemDetailViewController: TakeFingerprintViewControllerDelegate {
    func onTakenFingerprint(_ photos: [(blurScore: Float, image: UIImage)]) {
        self.listener?.onVerifyItem(photos: photos)
        self.dismiss(animated: true) { [weak self] in
            self?.gotoVerifyItemDetail()
        }
    }
}
