//
//  File.swift
//  
//
//  Created by Ben Spratling on 5/23/20.
//

import Foundation


//https://developer.apple.com/fonts/TrueType-Reference-Manual/RM05/Chap5.html#FDEF

enum InvalidCommand : Error {
	case stackoverflow
	case unknownFunction
	case invalidStackIndex
	case invalidZoneIndex
}

///Interprets a stream of instruction commands
///WIP, not rounding or point moving functions are done
///if/else is not done
class Interpretter {
	
	init(commandBytes:[UInt8]) {
		allCommands = commandBytes
	}
	
	private var instructionPointer:Int = 0
	private var returnPointer:Int = 0
	
	///some are commands, some are just data bytes that get pushed on the stack
	private let allCommands:[UInt8]
	
	//key is function index, value is instuction pointer of first command in function after
	private var functions:[Int32:Int] = [:]
	
	var graphicsState:GraphicsState = GraphicsState()
	
	//TODO: replace with EF2Dot14
//	var freedomVector:FixedPoint = FixedPoint(x: F26Dot6(clamping: 0), y: F26Dot6(clamping: 0))
	
	///using signed integer so we can get easy arithmetic shifting
	private var stack:[Int32] = []
	
	
	func execute() throws {
		while instructionPointer < allCommands.count {
			try executeCommand(allCommands[instructionPointer])
		}
	}
	
	func executeCommand(_ commandByte:UInt8)throws {
		instructionPointer += 1
		guard let command:Command = Command(rawValue: commandByte) else {
			return	//throw an exception?
		}
		switch command {
		case .adjustAngle:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			_ = stack.removeLast()
			
		case .absoluteValue:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			stack.append(abs(F26Dot6(bitPattern:stack.removeLast())).bitPattern)
			
		case .add:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let n1:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			let n2:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			let sum:F26Dot6 = n1 + n2
			stack.append(sum.bitPattern)
			
//		case .alignPoints:
//		case .alignToReferencePoint:
		case .and:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let n1:Bool = stack.removeLast() != 0
			let n2:Bool = stack.removeLast() != 0
			stack.append(n1 && n2 ? 1 : 0)
			
		case .call:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let functionIndex:Int32 = stack.removeLast()
			guard let instructionIndex:Int = functions[functionIndex] else { throw InvalidCommand.unknownFunction }
			returnPointer = instructionPointer	//has already been +=1'd
			instructionPointer = instructionIndex
			
		case .ceiling:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let n1:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			stack.append(ceil(n1).bitPattern)
			
		case .copyIndexedElementToTopOfStack:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let functionIndex:Int = Int(stack.removeLast())
			if functionIndex <= 0 {
				throw InvalidCommand.invalidStackIndex
			}
			if stack.count < functionIndex {
				throw InvalidCommand.invalidStackIndex
			}
			let value = stack[stack.count - functionIndex]
			stack.append(value)
			
		case .clear:
			stack = []
			
		case .debug:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			_ = stack.removeLast()
		
		case .functionDefinition:
			guard stack.count > 0 else { throw InvalidCommand.invalidStackIndex }
			let functionIndex:Int32 = stack.removeLast()
			functions[functionIndex] = instructionPointer
			while instructionPointer < allCommands.count {
				instructionPointer += 1
				if allCommands[instructionPointer] == Command.endFunctionDefinition.rawValue {
					break
				}
			}
			
		case .depth:
			stack.append(Int32(stack.count))
			
		case .divide:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let divisor:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			let dividend:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			
			let quotient:F26Dot6 = dividend / divisor
			stack.append(quotient.bitPattern)
			
		case .duplicateTopStackElement:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			stack.append(stack.last!)
			
		case .isEqual:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let e2:Int32 = stack.removeLast()
			let e1:Int32 = stack.removeLast()
			stack.append(e2 == e1 ? 1 : 0)
			
		case .autoFlipOff:
			graphicsState.autoFlip = false
			
		case .autoFlipOn:
			graphicsState.autoFlip = true
			
//		case .getFreedomVector:
			
		case .greaterThan:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let e2:Int32 = stack.removeLast()
			let e1:Int32 = stack.removeLast()
			stack.append(e1 > e2 ? 1 : 0)
			
		case .greaterThanOrEqualTo:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let e2:Int32 = stack.removeLast()
			let e1:Int32 = stack.removeLast()
			stack.append(e1 >= e2 ? 1 : 0)
			instructionPointer += 1
			
		
		
		
		
		
		
		
		case .endFunctionDefinition:
			instructionPointer = returnPointer
		
		
		
		case .jumpRelative:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let offset:Int32 = stack.removeLast()
			instructionPointer = instructionPointer - 1 + Int(offset)
			
		case .jumpRelativeOnFalse:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let e:Int32 = stack.removeLast()
			let offset:Int32 = stack.removeLast()
			if e == 0 {
				instructionPointer = instructionPointer - 1 + Int(offset)
			}
			
		case .jumpRelativeOnTrue:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let e:Int32 = stack.removeLast()
			let offset:Int32 = stack.removeLast()
			if e != 0 {
				instructionPointer = instructionPointer - 1 + Int(offset)
			}
			
		case .loopCall:
			break
			//How in the heck do I make this work?  The end function always goes to the return pointer, but this wants to know the
	/*		if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let functionNumber:Int32 = stack.removeLast()
			let count:Int32 = stack.removeLast()
			guard let instructionIndex:Int = functions[functionIndex] else { throw InvalidCommand.unknownFunction }
			returnPointer = instructionPointer	//has already been +=1'd
			for i in 0..<count {
				instructionPointer = instructionIndex
				while instructionPointer < allCommands.count {
					try executeCommand(allCommands[instructionPointer])
				}
			}	*/
			
			
		case .max:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let n1:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			let n2:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			let maximum:F26Dot6 = max(n1, n2)
			stack.append(maximum.bitPattern)
			
			
		case .min:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let n1:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			let n2:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			let minimum:F26Dot6 = min(n1, n2)
			stack.append(minimum.bitPattern)
			
		case .moveIndexedElementToTopOfStack:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let k:Int32 = stack.removeLast()
			let indexToRemove:Int = stack.count - Int(k)
			let element = stack.remove(at: indexToRemove)
			stack.append(element)
			
		case .multiply:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let n1:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			let n2:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			let sum:F26Dot6 = n1 * n2
			stack.append(sum.bitPattern)
		
		case .negate:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let n1:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			let negated:F26Dot6 = -n1
			stack.append(negated.bitPattern)
		
		case .notEqual:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let e2:Int32 = stack.removeLast()
			let e1:Int32 = stack.removeLast()
			stack.append(e2 != e1 ? 1 : 0)
		
		case .not:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let e1:Int32 = stack.removeLast()
			stack.append(e1 != 0 ? 1 : 0)
		
		case .pushNBytes:
			guard allCommands.count > instructionPointer else { throw InvalidCommand.stackoverflow }
			let n:Int = Int(allCommands[instructionPointer])
			instructionPointer += 1
			guard instructionPointer + n < allCommands.count else { throw InvalidCommand.stackoverflow }
			for i in 0..<n {
				stack.append(Int32(allCommands[instructionPointer + i]))
			}
			instructionPointer += n
		
		case .pushNWords:
			guard allCommands.count > instructionPointer else { throw InvalidCommand.stackoverflow }
			let n:Int = Int(allCommands[instructionPointer])
			instructionPointer += 1
			if instructionPointer + 2*n < allCommands.count { throw InvalidCommand.unknownFunction }
			
			for i in 0..<n {
				let highByte:UInt8 = allCommands[instructionPointer + 2*i]
				let lowByte:UInt8 = allCommands[instructionPointer + 2*i + 1]
				var word:UInt16 = UInt16(highByte) << 8
				word |= UInt16(lowByte)
				let signedWord:Int16 = Int16(bitPattern: word)
				let valueToPush:Int32 = Int32(signedWord)
				stack.append(valueToPush)
			}
			
		case .or:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let n1:Bool = stack.removeLast() != 0
			let n2:Bool = stack.removeLast() != 0
			stack.append(n1 || n2 ? 1 : 0)
			
		case .pop:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			_ = stack.removeLast()
			
			
			
			
		case .roundOff:
			graphicsState.roundState = .off
			
			
		case .roll:
			if stack.count < 3 {
				throw InvalidCommand.stackoverflow
			}
			let a:Int32 = stack.removeLast()
			let b:Int32 = stack.removeLast()
			let c:Int32 = stack.removeLast()
			stack.append(b)
			stack.append(a)
			stack.append(c)
			
		case .roundToGrid:
			graphicsState.roundState = .toGrid
			
		case .roundToDoubleGrid:
			graphicsState.roundState = .toDoubleGrid
			
		case .roundToHalfGrid:
			graphicsState.roundState = .toHalfGrid
		
		case .roundUpToGrid:
			graphicsState.roundState = .upToGrid
			
		case .roundDownToGrid:
			graphicsState.roundState = .downToGrid
			
			
		case .setAngleWeight:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			_ = stack.removeLast()
			
		case .scanConversionControl:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let n:Int32 = stack.removeLast()
			graphicsState.scanControl = GraphicsState.ScanControl(value: n)
			
		case .setControlValueTableCutIn:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let a:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			graphicsState.controlValueCutIn = a
			
		case .setDeltaBase:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let a:UInt32 = UInt32(bitPattern:stack.removeLast())
			graphicsState.deltaBase = a
			
		case .setDeltaShift:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let a:UInt32 = UInt32(bitPattern:stack.removeLast())
			graphicsState.deltaShift = a
			
		case .setFreedomVectorFromStack:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let y16:Int16 = Int16(bitPattern:UInt16(UInt32(bitPattern:stack.removeLast()) & 0x0000FFFF))
			let x16:Int16 = Int16(bitPattern:UInt16(UInt32(bitPattern:stack.removeLast()) & 0x0000FFFF))
			let y:F2Dot14 = F2Dot14(bitPattern: y16)
			let x:F2Dot14 = F2Dot14(bitPattern: x16)
			graphicsState.freedomVector = Point2Dot14(x: x, y: y)
			
		case .setFreedomVectorToYAxis:
			graphicsState.freedomVector = Point2Dot14(x: .zero, y: .one)
			
		case .setFreedomVectorToXAxis:
			graphicsState.freedomVector = Point2Dot14(x: .one, y: .zero)
			
			
			
			
			
		case .setLoop:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let a:Int32 = stack.removeLast()
			graphicsState.loop = Int(a)
			
		case .setMinimumDistance:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let value:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			graphicsState.minimumDistance = value
			
		case .setSingleWidth:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let n:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			graphicsState.singleWidth = n
			
		case .subtract:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let n2:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			let n1:F26Dot6 = F26Dot6(bitPattern:stack.removeLast())
			
			let difference:F26Dot6 = n1 - n2
			stack.append(difference.bitPattern)
			
		case .swap:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let e2:Int32 = stack.removeLast()
			let e1:Int32 = stack.removeLast()
			stack.append(e2)
			stack.append(e1)
			
		case .setZonePointer0:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			guard let zone:GraphicsState.PointerZone = GraphicsState.PointerZone(rawValue:stack.removeLast()) else { throw InvalidCommand.invalidZoneIndex }
			graphicsState.pointerZone0 = zone
			
		case .setZonePointer1:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			guard let zone:GraphicsState.PointerZone = GraphicsState.PointerZone(rawValue:stack.removeLast()) else { throw InvalidCommand.invalidZoneIndex }
			graphicsState.pointerZone1 = zone
			
		case .setZonePointer2:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			guard let zone:GraphicsState.PointerZone = GraphicsState.PointerZone(rawValue:stack.removeLast()) else { throw InvalidCommand.invalidZoneIndex }
			graphicsState.pointerZone2 = zone
			
		case .setAllZonePointers:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			guard let zone:GraphicsState.PointerZone = GraphicsState.PointerZone(rawValue:stack.removeLast()) else { throw InvalidCommand.invalidZoneIndex }
			graphicsState.pointerZone0 = zone
			graphicsState.pointerZone1 = zone
			graphicsState.pointerZone2 = zone
			
		case .setReferencePoint0:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let index:Int = Int(stack.removeLast())
			graphicsState.referencePoint0 = index
			
		case .setReferencePoint1:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let index:Int = Int(stack.removeLast())
			graphicsState.referencePoint1 = index
			
		case .setReferencePoint2:
			if stack.count < 1 {
				throw InvalidCommand.stackoverflow
			}
			let index:Int = Int(stack.removeLast())
			graphicsState.referencePoint2 = index
			
			
		case .setProjectionVectorFromStack:
			if stack.count < 2 {
				throw InvalidCommand.stackoverflow
			}
			let y16:Int16 = Int16(bitPattern:UInt16(UInt32(bitPattern:stack.removeLast()) & 0x0000FFFF))
			let x16:Int16 = Int16(bitPattern:UInt16(UInt32(bitPattern:stack.removeLast()) & 0x0000FFFF))
			let y:F2Dot14 = F2Dot14(bitPattern: y16)
			let x:F2Dot14 = F2Dot14(bitPattern: x16)
			graphicsState.projectionVector = Point2Dot14(x: x, y: y)
			
		case .setProjectionVectorToYAxis:
			graphicsState.projectionVector = Point2Dot14(x: .zero, y: .one)
				
		case .setProjectionVectorToXAxis:
			graphicsState.projectionVector = Point2Dot14(x: .one, y: .zero)
			
		case .setProjectionAndFreedomVectorsToYAxis:
			graphicsState.freedomVector = Point2Dot14(x: .zero, y: .one)
			graphicsState.projectionVector = Point2Dot14(x: .zero, y: .one)
			
		case .setProjectionAndFreedomVectorsToXAxis:
			graphicsState.freedomVector = Point2Dot14(x: .one, y: .zero)
			graphicsState.projectionVector = Point2Dot14(x: .one, y: .zero)
			
			
			
		}
	}
	
	
}


enum Command : UInt8 {
	///AA
	case adjustAngle = 0x7F
	
	///ABS
	case absoluteValue = 0x64
	
	///ADD
	case add = 0x60
	
	///ALIGNPTS
//	case alignPoints = 0x27
	
	///ALIGNRP
//	case alignToReferencePoint = 0x3C
	
	///AND
	case and = 0x5A
	
	///CALL
	case call = 0x2B
	
	///CEILING
	case ceiling = 0x67
	
	///CINDEX
	case copyIndexedElementToTopOfStack = 0x25
	
	///CLEAR
	case clear = 0x22
	
	///DEBUG
	case debug = 0x4F
	
	///DELTAC1
//	case deltaExceptionC1 = 0x73	//TODO: write me
	
	
	//TODO: DELTAC1, DELTAC2, DELTAC3, DELTAP1, DELTAP2, DELTAP3
	
	///DEPTH
	case depth = 0x24
	
	///DIV
	case divide = 0x62
	
	///DUP
	case duplicateTopStackElement = 0x20
	
	///EIF
//	case endIf = 0x59
	
	///ELSE
//	case `else` = 0x1B
	
	///????
//	case endIf = 0x2D
	
	///ENDF
	case endFunctionDefinition = 0x2D
	
	
	
	///EQ
	case isEqual = 0x54
	
	///EVEN
//	case even = 0x57
	
	///FDEF
	case functionDefinition = 0x2C
	
	///FLIPOFF
	case autoFlipOff = 0x4E
	
	///FLIPON
	case autoFlipOn = 0x4D
	
	///GFV
//	case getFreedomVector = 0x0D
	
	
	///GT
	case greaterThan = 0x52
	
	///GTEQ
	case greaterThanOrEqualTo = 0x53
	
	///IDEF
	//TODO: instruction definition
	
	
	///JMPR
	case jumpRelative = 0x1C
	
	///JROF
	case jumpRelativeOnFalse = 0x79
	
	///JROT
	case jumpRelativeOnTrue = 0x78
	
	
	///LOOPCALL
	case loopCall = 0x2A
	
	
	
	
	
	///MAX
	case max = 0x8B
	
	///MIN
	case min = 0x8C
	
	///MINDEX
	case moveIndexedElementToTopOfStack = 0x26
	
	
	///MUL
	case multiply = 0x63
	
	///NEG
	case negate = 0x65
	
	///NEQ
	case notEqual = 0x55
	
	///NOT
	case not = 0x5C
	
	///NPUSHB
	case pushNBytes = 0x40
	
	///NPUSHW
	case pushNWords = 0x41
	
	
	///OR
	case or = 0x5B
	
	///POP
	case pop = 0x21
	
	
	//TODO: missing commands
	
	///ROFF
	case roundOff = 0x7A
	
	///ROLL
	case roll = 0x8A
	
	///RDTG
	case roundDownToGrid = 0x7D
	
	///RTG
	case roundToGrid = 0x18
	
	///RTDG
	case roundToDoubleGrid = 0x3D
	
	///RTHG
	case roundToHalfGrid = 0x19
	
	///RUTG
	case roundUpToGrid = 0x7C
	
	
	///SANGW
	case setAngleWeight = 0x7E
	
	///SCANCTRL
	case scanConversionControl = 0x85
	
	///SCVTCI
	case setControlValueTableCutIn = 0x1D
	
	///SDB
	case setDeltaBase = 0x5E
	
	///SDS
	case setDeltaShift = 0x5F
	
	///SFVFS
	case setFreedomVectorFromStack = 0x0B
	
	
	///SFVTCA
	case setFreedomVectorToYAxis = 0x04
	case setFreedomVectorToXAxis = 0x05
	
	
	///SLOOP
	case setLoop = 0x17
	
	///SMD
	case setMinimumDistance = 0x1A
	
	
	///SPVFS
	case setProjectionVectorFromStack = 0x0A
	
	///SPVTCA
	case setProjectionVectorToYAxis = 0x02
	case setProjectionVectorToXAxis = 0x03
	
	
	///SVTCA
	case setProjectionAndFreedomVectorsToYAxis = 0x00
	case setProjectionAndFreedomVectorsToXAxis = 0x01
	
	///SRP0
	case setReferencePoint0 = 0x10
	
	///SRP1
	case setReferencePoint1 = 0x11
	
	///SRP2
	case setReferencePoint2 = 0x12
	
	
	///SROUND	//TODO: super round
	///S45ROUND	//TODO: Super ROUND 45 degrees
	
	///SSW
	case setSingleWidth = 0x1F
	
	///SUB
	case subtract = 0x61
	
	///SWAP
	case swap = 0x23
	
	
	///SZP0
	case setZonePointer0 = 0x13
	
	///SZP1
	case setZonePointer1 = 0x14
	
	///SZP2
	case setZonePointer2 = 0x15
	
	///SZPS
	case setAllZonePointers = 0x16
	
	
}

