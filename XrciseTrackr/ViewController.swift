//
//  ViewController.swift
//  XrciseTrackr
//
//  Created by Cris Rene Denopol on 7/31/18.
//  Copyright © 2018 Cris Rene Denopol. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    @IBOutlet weak var lbl_header: UILabel!
    @IBOutlet weak var HRTableView: UITableView!
    let healthKitManager = HealthKitManager.sharedInstance
    var datasource: [HKQuantitySample] = []
    var heartRateQuery: HKQuery?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        healthKitManager.authorizeHealthKit { (success, error) in
            print("*** iOS healthkit authorization success: \(success)")
            self.retrieveHeartRateData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func retrieveHeartRateData(){
        if let query = healthKitManager.createHeartRateStreamingQuery(Date()){
            heartRateQuery = query
            healthKitManager.heartRateDelegate = self
            healthKitManager.healthStore.execute(query)
        }
    }

}

extension ViewController: UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HRTableView", for: indexPath)
        cell.textLabel?.text = "\(datasource[indexPath.row].quantity)"
        return cell
    }
}

extension ViewController: HeartRateDelegate{
    func heartRateUpdated(heartRateSamples: [HKSample]) {
        guard let heartRateSamples = heartRateSamples as? [HKQuantitySample] else{
            return
        }
        
        DispatchQueue.main.async {
            self.datasource.append(contentsOf: heartRateSamples)
            self.HRTableView.reloadData()
        }
    }
    
    
}

