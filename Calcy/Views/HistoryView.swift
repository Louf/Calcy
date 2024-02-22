//
//  HistoryView.swift
//  Calcy
//
//  Created by Louis Farmer on 2/16/24.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [SortDescriptor(\.date, order: .reverse)]) var allCalculations: FetchedResults<Calculation>
    
    let pasteboard: NSPasteboard = .general
    
    @State private var hoveringResult: UUID? // Changed to track ID of the hovering result
    @State private var pressedResult: UUID? // Added to track the ID of the pressed result
    @State private var hoveringTitle = false
    @State private var hoveringTrash = false
    @State private var pressedTrash = false

    var body: some View {
        VStack {
            VStack {
                HStack {
                    if hoveringTitle {
                        Image(systemName: "trash")
                            .opacity(hoveringTrash ? 1 : 0.5)
                            .foregroundColor(hoveringTrash ? .red : .white)
                            .font(.system(size: 20, weight: hoveringTrash ? .bold : .regular))
                            .onHover { hovering in
                                hoveringTrash = hovering
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged({ _ in
                                        self.pressedTrash = true
                                    })
                                    .onEnded({ _ in
                                        self.pressedTrash = false
                                        self.clearHistory(context: context)
                                    })
                            )
                    }
                    Spacer()
                    Text("History")
                        .font(.title.bold())
                }
                .onHover { hovering in
                    hoveringTitle = hovering
                }
                
                //A clear history button mainly for debugging
//                Button("Clear History") {
//                    clearHistory(context: context)
//                }
//                .foregroundColor(.white)
//                .cornerRadius(8)
            }
            
            if !allCalculations.isEmpty {
                //List of calculations if there are some
                ScrollView {
                    ForEach(allCalculations) { calc in
                        VStack(alignment: .trailing) {
                            //Force unwrapping them because the operation and result have to be there
                            Text(calc.operation!)
                                .font(.system(size: 14))
                                .opacity(0.5)
                                
                            Text(calc.result!)
                                .font(.system(size: 18))
                             // Apply scale effect based on press state
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .lineLimit(1)
                        .onHover { hovering in
                            hoveringResult = hovering ? calc.id : nil
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged({ _ in
                                    self.pressedResult = calc.id
                                })
                                .onEnded({ _ in
                                    self.pressedResult = nil
                                    //Just copy the result, I don't think we need to copy the operation
                                    self.copyValue(value: "\(calc.result!)")
                                })
                        )
                        //Only animate the pressedResult
                        .animation(.easeInOut(duration: 0.1), value: pressedResult)
                        .background(hoveringResult == calc.id ? Color.gray.opacity(0.2) : Color.clear, in: 
                                        RoundedRectangle(cornerRadius: 12)
                        ) // Change the color as needed
                        .scaleEffect(pressedResult == calc.id ? 0.95 : 1.0)
                    }
                }
                .padding(.top, 2)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .overlay {
            if allCalculations.isEmpty {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView("No history", systemImage: "tray.fill")
                } else {
                    // Fallback on earlier versions
                    Text("No items")
                        .font(.title)
                }
            }
        }
    }
    
    private func copyValue(value: String) {
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }
    
    private func clearHistory(context: NSManagedObjectContext) {
        for calc in allCalculations {
            context.delete(calc)
        }

        do {
            try context.save()
        } catch {
            // Handle the error, perhaps with an alert to the user
            print("Error clearing history: \(error)")
        }
    }
}

#Preview {
    HistoryView()
}
