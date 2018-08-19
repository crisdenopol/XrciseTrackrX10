//
//  healthKitManager.swift
//  XrciseTrackr WatchKit Extension
//
//  Created by Cris Rene Denopol on 7/31/18.
//  Copyright © 2018 Cris Rene Denopol. All rights reserved.
//

import Foundation
import HealthKit

protocol HeartRateDelegate {
    func heartRateUpdated(heartRateSamples: [HKSample])
}

class HealthKitManager: NSObject{
    static let sharedInstance = HealthKitManager()
    
    private override init() {}
    
    let healthStore = HKHealthStore()
    var anchor: HKQueryAnchor?
    var heartRateDelegate: HeartRateDelegate?
    
    func authorizeHealthKit(_ completion: @escaping((_ success: Bool, _ error: Error?) -> Void)){
        guard let heartRateType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate) else{
            return
        }
        let typesToShare = Set([HKObjectType.workoutType(), heartRateType])
        let typesToRead = Set([HKObjectType.workoutType(), heartRateType])
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            print("Authorization successfull: \(success)")
            completion(success, error)
        }
    }
    
    func createHeartRateStreamingQuery(_ workoutStartDate: Date) -> HKQuery? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else{
            return nil
        }
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictEndDate)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate])
        let heartRateQuery = HKAnchoredObjectQuery(type: heartRateType, predicate: compoundPredicate, anchor: nil, limit: HKObjectQueryNoLimit) { (query, sampleObjects, deletedObjects, newAnchor, error) in
            guard let newAnchor = newAnchor,
                let sampleObjects = sampleObjects else{
                    return
            }
            self.anchor = newAnchor
            self.heartRateDelegate?.heartRateUpdated(heartRateSamples: sampleObjects)
        }
        heartRateQuery.updateHandler  = {(query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            guard let newAnchor = newAnchor,
                let sampleObjects = sampleObjects else{
                    return
            }
            self.anchor = newAnchor
            self.heartRateDelegate?.heartRateUpdated(heartRateSamples: sampleObjects)
        }
        return heartRateQuery
    }
}
