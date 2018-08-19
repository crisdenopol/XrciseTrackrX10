//
//  InterfaceController.swift
//  XrciseTrackr WatchKit Extension
//
//  Created by Cris Rene Denopol on 7/31/18.
//  Copyright © 2018 Cris Rene Denopol. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController {
    
    let healthKitManager = HealthKitManager.sharedInstance

    @IBOutlet var btn_startEndWorkout: WKInterfaceButton!
    @IBOutlet var lbl_heartRate: WKInterfaceLabel!
    
    var isWorkoutInProgress = false
    var workoutSession: HKWorkoutSession?
    var workoutStartDate: Date?
    var heartRateQuery: HKQuery?
    var heartRateSamples: [HKQuantitySample] = [HKQuantitySample]()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        btn_startEndWorkout.setEnabled(false) //disable before healthKit is authorized
        
        healthKitManager.authorizeHealthKit { (success, error) in
            //authorization success
            self.btn_startEndWorkout.setEnabled(true)
            self.createWorkoutSession()
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func btn_startEndWorkout_tapped() {
        if isWorkoutInProgress {
            endWorkoutSession()
        }else{
            startWorkoutSession()
        }
        
        isWorkoutInProgress = !isWorkoutInProgress
        btn_startEndWorkout.setTitle(isWorkoutInProgress ? "End Workout" : "Start Workout")
    }
    
    func createWorkoutSession(){
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .other
        workoutConfiguration.locationType = .unknown
        
        do{
            workoutSession = try HKWorkoutSession(healthStore: healthKitManager.healthStore, configuration: workoutConfiguration)
            workoutSession?.delegate = self
        }catch{
            print("Error Occured")
        }
    }
    
    func startWorkoutSession(){
        if workoutSession == nil{
            createWorkoutSession()
        }
        
        guard let session = workoutSession else{
            print("Can't start a workout without a workout session.")
            return
        }
        
        session.startActivity(with: Date())
        workoutStartDate = Date()
    }
    
    func endWorkoutSession(){
        guard let session = workoutSession else{
            print("Can't end a workout that hasn't been started.")
            return
        }
        
        session.end()
        saveWorkout()
    }
    
    func saveWorkout(){
        let workout = HKWorkout(activityType: .other, start: workoutStartDate!, end: Date())
        healthKitManager.healthStore.save(workout) { [weak self] (success, error) in
            print("Workout saved successfully: \(success)")
            guard let samples = self?.heartRateSamples else{
                return
            }
            
            self?.healthKitManager.healthStore.add(samples, to: workout, completion: { (success, error) in
                print("Successfully saved heartrate samples.")
            })
        }
    }
}

extension InterfaceController: HKWorkoutSessionDelegate{
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Error starting workout: \(error)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            print("Workout is running...")
            guard let workoutStartDate = workoutStartDate else{
                return
            }
            
            if let query = healthKitManager.createHeartRateStreamingQuery(workoutStartDate){
                self.heartRateQuery = query
                healthKitManager.heartRateDelegate = self
                healthKitManager.healthStore.execute(query)
            }
        case .ended:
            print("Workout has ended.")
            self.workoutSession = nil
            if let query = self.heartRateQuery{
                healthKitManager.healthStore.stop(query)
            }
        default:
            print("Workout session in other state")
        }
    }
}

extension InterfaceController: HeartRateDelegate{
    func heartRateUpdated(heartRateSamples: [HKSample]) {
        guard let heartRateSamples = heartRateSamples as? [HKQuantitySample] else{
            return
        }
        
        DispatchQueue.main.async {
            self.heartRateSamples = heartRateSamples
            guard let sample = heartRateSamples.first else{
                return
            }
            let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            let heartRateString = String(format: "%.00f", value)
            self.lbl_heartRate.setText(heartRateString)
        }
    }
}
