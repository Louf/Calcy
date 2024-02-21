//
//  CalculatorView.swift
//  Calcy
//
//  Created by Louis Farmer on 2/16/24.
//

import SwiftUI

struct CalculatorButton: View {
    var label: String
    var color: Color = .gray
    let buttonWidth: CGFloat
    var action: () -> Void // Closure to handle tap action

    @State private var isPressed = false // Track the press state
    
    var body: some View {
        Text(label)
            .font(.title) // Adjust font size to fit
            .frame(width: label == "0" ? (buttonWidth * 2) + 10 : buttonWidth, height: buttonWidth)
            .foregroundColor(.white)
            .background(color)
            .cornerRadius(buttonWidth / 2)
            .scaleEffect(isPressed ? 0.9 : 1.0) // Apply scale effect based on press state
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in self.isPressed = true })
                    .onEnded({ _ in
                        self.isPressed = false
                        self.action() // Execute the button's action on release
                    })
            )
            .animation(.easeInOut(duration: 0.1), value: isPressed) // Animate the scale effect

    }
}

struct CalculatorView: View {
    let buttons = [
        ["AC", "+/-", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "+"],
        ["0", ".", "="]
    ]
    
    @State private var displayValue = "0"
    @State private var currentOperation: String? = nil
    @State private var previousValue: String? = nil
    @State private var pressedEquals = false
    
    @State private var lastCalculation: String = ""
    @State private var isOperationIn = false
    
    @State private var hoveringResult = false
    @State private var isPressed = false // Track the press state
    
    @Environment(\.managedObjectContext) private var context
    
    let dataManager = DataManager()
    
    let pasteboard: NSPasteboard = .general
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Text(currentOperation ?? "")
                        .font(.title)
                    Spacer()
                    Text(displayValue)
                        .font(.largeTitle) // You can adjust the font size as needed
                        .lineLimit(1) // Ensure the text stays within one line
                        .minimumScaleFactor(0.1) // Adjust this value as needed
                        .scaledToFit() // This ensures the text scales down to fit its container
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(height: 35)
                .padding()
                .background(hoveringResult ? .gray.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 12))
                .onHover { hovering in
                    if pressedEquals {
                        hoveringResult = hovering
                    }
                }
                .scaleEffect(isPressed ? 0.95 : 1.0) // Apply scale effect based on press state
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged({ _ in
                            if pressedEquals {
                                self.isPressed = true
                            }
                        })
                        .onEnded({ _ in
                            if pressedEquals {
                                self.isPressed = false
                                self.copyDisplay()
                            }
                        })
                )
                .animation(.easeInOut(duration: 0.1), value: isPressed) // Animate the scale effect
 
                
                self.generateButtons(geometry: geometry)
            }
        }
        .padding()
        .onAppear {
            // Set up the keyboard event listener
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) -> NSEvent? in
                self.handleKeyPress(event: event)
                return event
            }
        }
    }
    

    //Copy whatever is on the display to the clipboard
    private func copyDisplay(){
        if pressedEquals {
            pasteboard.clearContents()
            pasteboard.setString(displayValue, forType: .string)
        }
    }
    
    private func generateButtons(geometry: GeometryProxy) -> some View {
        let width = geometry.size.width / 4 - 8 // Adjust the division based on the number of columns
        return VStack(spacing: 10) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { button in
                        CalculatorButton(label: button, color: self.buttonColor(button: button), buttonWidth: width) {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                self.handleButtonPress(button: button)
                            }
                        }
                    }
                }
            }
        }
    }

    private func buttonColor(button: String) -> Color {
        if button == "AC" || button == "+/-" || button == "%" {
            return .gray
        } else if button == "÷" {
            return currentOperation == "÷" ? .orange.opacity(0.2) : .orange
        }
        else if button == "×" {
            return currentOperation == "×" ? .orange.opacity(0.2) : .orange
        }
        else if button == "-" {
            return currentOperation == "-" ? .orange.opacity(0.2) : .orange
        }
        else if button == "+" {
            return currentOperation == "+" ? .orange.opacity(0.2) : .orange
        }
        else if button == "=" {
            return .orange
        }else {
            return Color(.darkGray)
        }
    }
    
    private func handleButtonPress(button: String) {
        switch button {
        case "AC":
            displayValue = "0"
            previousValue = nil
            currentOperation = nil
            pressedEquals = false
            lastCalculation = ""
        case "+/-":
            if displayValue != "0", let value = Double(displayValue) {
                displayValue = integerCheck(result: value * -1)
            }
        case "%":
            if let value = Double(displayValue) {
                displayValue = String(value / 100)
            }
        case "=":
            if let operation = currentOperation, let previousValue = previousValue, let previous = Double(previousValue), let current = Double(displayValue) {
                lastCalculation += "\(displayValue)"
                
                displayValue = calculate(operation: operation, previousValue: previous, currentValue: current)
                
                //Add the calculation after the display value is updated so we get the correct value
                dataManager.addHistoryItem(operation: lastCalculation, result: displayValue, context: context)
                
                //Reset some values after calculation
                isOperationIn = false
                self.previousValue = nil
                currentOperation = nil
                pressedEquals = true
                lastCalculation = ""
            }
        case "÷", "×", "-", "+":
            if currentOperation == nil && !(displayValue == ".") {
                currentOperation = button
                lastCalculation += "\(displayValue) "
                previousValue = displayValue
                displayValue = "0"
                pressedEquals = false
                //Make sure we can't do an operation if the user just puts a decimal point with nothing else
            } else if !(displayValue == ".") {
                currentOperation = button
            }
        default:
            //This is any number button
            if currentOperation != nil {
                if !isOperationIn {
                    lastCalculation += "\(currentOperation ?? "") "
                    isOperationIn = true
                }
            }
            
            if !(displayValue.contains(".") && button == ".") {
                if displayValue == "0" || currentOperation != nil && previousValue == nil {
                    displayValue = button
                } else {
                    if pressedEquals == true {
                        displayValue = button
                        pressedEquals = false
                    } else {
                        displayValue += button
                    }
                }
            }
        }
    }
    
    private func handleKeyPress(event: NSEvent) {
        guard let characters = event.characters else { return }
        switch characters {
        case "0"..."9":
            self.handleButtonPress(button: characters)
        case "+", "-", "*", "/":
            let operationMap: [String: String] = ["+": "+", "-": "-", "*": "×", "/": "÷"]
            if let operation = operationMap[characters] {
                self.handleButtonPress(button: operation)
            }
        case "\u{8}", "\u{7f}": // Backspace
            self.backspace()
        case "=", "\r":
            self.handleButtonPress(button: "=")
        case "c", "C": // 'C' to clear
            self.handleButtonPress(button: "AC")
        case ".":
            self.handleButtonPress(button: ".")
        default:
            break
        }
    }
    
    private func backspace() {
        guard !displayValue.isEmpty else { return }
        displayValue.removeLast()
        if displayValue.isEmpty || displayValue == "-" { // Reset to "0" if empty or only a negative sign is left
            displayValue = "0"
        }
    }
    
    private func integerCheck(result: Double) -> String {
        // Check if the result is an integer
        if result.truncatingRemainder(dividingBy: 1) == 0 {
            // Check if the result fits within Int64 range
            if result >= Double(Int64.min) && result <= Double(Int64.max) {
                return String(Int64(result))
            } else {
                // For numbers outside the Int64 range, return the string representation of the result directly
                // This retains the whole number appearance without '.0'
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                numberFormatter.maximumFractionDigits = 0 // Avoid decimal places for whole numbers
                let number = NSNumber(value: result)
                return numberFormatter.string(from: number) ?? "Error"
            }
        } else {
            // For non-whole numbers, return as is with decimals
            return String(result)
        }
    }
    
    private func calculate(operation: String, previousValue: Double, currentValue: Double) -> String {
        let result: Double

        switch operation {
        case "+":
            result = previousValue + currentValue
        case "-":
            result = previousValue - currentValue
        case "×":
            result = previousValue * currentValue
        case "÷":
            if currentValue == 0 {
                return "Error" // Return error if dividing by zero
            } else {
                result = previousValue / currentValue
            }
        default:
            return "0"
        }

        return integerCheck(result: result)

    }
}
