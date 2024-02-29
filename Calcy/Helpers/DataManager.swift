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
