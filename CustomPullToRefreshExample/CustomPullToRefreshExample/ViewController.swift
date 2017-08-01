//
//  ViewController.swift
//  CustomPullToRefreshExample
//
//  Created by Rawlings on 01/08/2017.
//  Copyright © 2017 Rawlings. All rights reserved.
//

import UIKit
import CustomPullToRefresh


class ViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.addPullToRefreshWithBlock {
            Delay(time: 3, task: { 
                self.tableView.endRefreshing()
            })
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.textLabel?.text = "Label"
        return cell
    }

}


extension UIScrollView {
    
    var isRefreshing: Bool {
        return pullToRefreshView != nil && pullToRefreshView.state != .stopped
    }
    
    func addPullToRefreshWithBlock(_ block: @escaping () -> Void) {
        addPullToRefresh(withCustomView: CreamsRefreshView(frame: .zero)) {
            block()
        }
    }
    
    func beginRefreshing() {
        triggerPullToRefresh()
    }
    
    func endRefreshing() {
        if isRefreshing {
            pullToRefreshView.stopAnimating()
        }
    }
}
