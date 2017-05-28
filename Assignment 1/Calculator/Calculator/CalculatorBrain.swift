//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Kanstantsin Linou on 7/15/16.
//  Copyright © 2016 Kanstantsin Linou. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    fileprivate var isPartialResult: Bool {
        get {
            return pending != nil
        }
    }
    
    fileprivate var resultAccumulator = 0.0
    
    var description: String {
        get {
            if pending == nil {
                return descriptionAccumulator
            } else {
                return pending!.descriptionFunction(pending!.descriptionOperand,
                                                    pending!.descriptionOperand != descriptionAccumulator ? descriptionAccumulator : "")
            }
        }
    }
    
    fileprivate var descriptionAccumulator = "0" {
        didSet {
            if pending == nil {
                currentPrecedence = Precedence.max
            }
        }
    }
    
    fileprivate var currentPrecedence = Precedence.max
    
    func clear() {
        pending = nil
        resultAccumulator = 0.0
        descriptionAccumulator = "0"
    }
    
    func setOperand(_ operand: Double) {
        resultAccumulator = operand
        descriptionAccumulator = String(format:"%g", operand)
    }
    
    fileprivate enum Precedence: Int {
        case min = 0, max
    }

    fileprivate var operations: Dictionary<String,Operation> = [
        "π" : Operation.constant(Double.pi),
        "e" : Operation.constant(M_E),
        "±" : Operation.unaryOperation({ -$0 }, { "-(\($0))"}),
        "√" : Operation.unaryOperation(sqrt, { "√(\($0))"}),
        "cos" : Operation.unaryOperation(cos, { "cos(\($0))"}),
        "x⁻¹" : Operation.unaryOperation({ 1 / $0 }, { "(\($0))⁻1"}),
        "x²" : Operation.unaryOperation({ $0 * $0 }, { "(\($0))²"}),
        "×" : Operation.binaryOperation({ $0 * $1 }, { "\($0) × \($1)"}, Precedence.max),
        "÷" : Operation.binaryOperation({ $0 / $1 }, { "\($0) ÷ \($1)"}, Precedence.max),
        "+" : Operation.binaryOperation({ $0 + $1 }, { "\($0) + \($1)"}, Precedence.min),
        "−" : Operation.binaryOperation({ $0 - $1 }, { "\($0) - \($1)"}, Precedence.min),
        "rand" : Operation.nullaryOperation( { Double(arc4random()) }, "arc4random()"),
        "=" : Operation.equals
    ]
    
    fileprivate enum Operation {
        case constant(Double)
        case unaryOperation((Double) -> Double, (String) -> String)
        case binaryOperation((Double, Double) -> Double, (String, String) -> String, Precedence)
        case nullaryOperation(() -> Double, String)
        case equals
    }
    
    func performOperation(_ symbol: String) {
        if let operation = operations[symbol] {
            switch operation {
            case .constant(let value):
                resultAccumulator = value
                descriptionAccumulator = symbol
            case .nullaryOperation(let function, let descriptionValue):
                resultAccumulator = function()
                descriptionAccumulator = descriptionValue
            case .unaryOperation(let resultFunction, let descriptionFunction):
                resultAccumulator = resultFunction(resultAccumulator)
                descriptionAccumulator = descriptionFunction(descriptionAccumulator)
            case .binaryOperation(let resultFunction, let descriptionFunction, let precedence):
                executePendingBinaryOperation()
                if currentPrecedence.rawValue < precedence.rawValue {
                    descriptionAccumulator = "(\(descriptionAccumulator))"
                }
                currentPrecedence = precedence
                pending = PendingBinaryOperationInfo(binaryFunction: resultFunction, firstOperand: resultAccumulator,
                                                     descriptionFunction: descriptionFunction, descriptionOperand: descriptionAccumulator)
            case .equals:
                executePendingBinaryOperation()
            }
        }
    }
    
    fileprivate func executePendingBinaryOperation() {
        if pending != nil {
            resultAccumulator = pending!.binaryFunction(pending!.firstOperand, resultAccumulator)
            descriptionAccumulator = pending!.descriptionFunction(pending!.descriptionOperand, descriptionAccumulator)
            pending = nil
        }
    }
    
    fileprivate var pending: PendingBinaryOperationInfo?
    
    fileprivate struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
        var descriptionFunction: (String, String) -> String
        var descriptionOperand: String
    }
    
    var result: Double {
        get {
            return resultAccumulator
        }
    }
    
    func getDescription() -> String {
        let whitespace = (description.hasSuffix(" ") ? "" : " ")
        return isPartialResult ? (description + whitespace  + "...") : (description + whitespace  + "=")
    }
}
