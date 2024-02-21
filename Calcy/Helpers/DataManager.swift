//
//  DataManager.swift
//  Calcy
//
//  Created by Louis Farmer on 2/20/24.
//

import Foundation
import CoreData

struct DataManager {
    func addHistoryItem(operation: String, result: String, context: NSManagedObjectContext) {
        let newItem = Calculation(context: context)
        newItem.id = UUID()
        newItem.date = Date()
        newItem.operation = operation
        newItem.result = result
        
        PersistanceController.shared.save()
    }
}
