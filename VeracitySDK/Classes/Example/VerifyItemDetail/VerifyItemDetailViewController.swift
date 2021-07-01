//
//  HistoryItemDetailViewController.swift
//  Veracity Authenticator
//
//  Created by Minh Chu on 1/28/21.
//  Copyright © 2021 ONEPROVE s.r.o. All rights reserved.
//

import UIKit


protocol VerifyItemDetailPresentableListener: AnyObject {
    
}

protocol VerifyItemDetailViewControllerDelegate: AnyObject {
    
}

final class VerifyItemDetailViewController: UIViewController, VerifyItemDetailPresentable {
    var listener: VerifyItemDetailPresentableListener?
    weak var delegate: VerifyItemDetailViewControllerDelegate?
    
    @IBOutlet weak var backToListButton: AppButton!
    @IBOutlet weak var tableView: UITableView!
    
    private let verifyItemStream : MutableVerifyItemStream
    private var item: VeracityItem
    
    init(item: VeracityItem, verifyItemStream: MutableVerifyItemStream) {
        self.item = item
        self.verifyItemStream = verifyItemStream
        
        let bundle = Bundle(for: VerifyItemDetailViewController.self)
        super.init(nibName: "VerifyItemDetailViewController", bundle: bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.selfSetup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Actiion
    @objc func moveBack() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func backToListPressed(_ sender: Any) {
        moveBack()
    }
    
    // MARK: - Setup
    private func selfSetup() {
        let interactor = VerifyItemDetailInteractor(presenter: self, item: item)
        self.listener = interactor
    }
    
    private func setupView() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.title = "Verification detail".uppercased()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow-left"), style: .plain, target: self, action: #selector(moveBack))
        navigationItem.leftBarButtonItem?.tintColor = AppColor.primary
        let textAttributes = [NSAttributedString.Key.foregroundColor: AppColor.primary]
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 100
        backToListButton.setTitle("Back".uppercased(), for: .normal)
        backToListButton.backgroundColor = AppColor.white
    }
}

// MARK: - TableView
extension VerifyItemDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = VerifyItemInfoView()
        view.setItemData(item)
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

// MARK: - Interactor
extension VerifyItemDetailViewController {
    func reloadData(item: VeracityItem) {
        self.item = item
        self.tableView.reloadData()
    }
}
