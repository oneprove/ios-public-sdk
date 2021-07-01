//
//  OPHUD.swift
//  ONEPROVE
//
//  Created by Andrew on 05/11/2018.
//  Copyright © 2018 ONEPROVE s.r.o. All rights reserved.
//

import UIKit

class Indicator {
    static let shared = Indicator()
    
    func showActivityIndicator() {
        guard let view = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        let spinner = UIActivityIndicatorView()
        spinner.style = .gray
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)

        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    func hideActivityIndicator() {
        guard let view = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              let spinner = view.subviews.first(where: { $0 is UIActivityIndicatorView}) as? UIActivityIndicatorView
              else {
            return
        }
        
        spinner.stopAnimating()
        spinner.removeFromSuperview()
    }
}
