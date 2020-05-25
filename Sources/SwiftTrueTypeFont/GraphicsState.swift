//
//  File.swift
//  
//
//  Created by Ben Spratling on 5/24/20.
//

import Foundation



struct GraphicsState {
	
	var autoFlip:Bool = false
	var controlValueCutIn:F26Dot6 = F26Dot6(approximate: 1.0625)	//	17/16
	var deltaBase:UInt32 = 9
	var deltaShift:UInt32 = 3
	var loop:Int = 1
	var minimumDistance:F26Dot6 = F26Dot6(clamping:0)
	var singleWidth:F26Dot6 = F26Dot6(clamping:0)
//	var dualProjectionVector	//no idea
	
	var freedomVector:Point2Dot14 = Point2Dot14(x: .one, y: .zero)	//x-axis
	var projectionVector:Point2Dot14 = Point2Dot14(x: .one, y: .zero)	//x-axis
	
	var roundState:RoundState = .toGrid
	
	var pointerZone0:PointerZone = .glyph
	var pointerZone1:PointerZone = .glyph
	var pointerZone2:PointerZone = .glyph
	
	var referencePoint0:Int = 0
	var referencePoint1:Int = 0
	var referencePoint2:Int = 0
	
	var scanControl:ScanControl = ScanControl(value: 0)
	
	
	enum RoundState {
		///distances are first subjected to compensation for the engine characteristics and then truncated to an integer. If the result of the compensation and rounding would be to change the sign of the distance, the distance is set to 0.
		case downToGrid
		
		///distances are compensated for engine characteristics and rounded to the nearest integer.
		case toGrid
		
		///distances are compensated for engine characteristics and then rounded to an integer or half-integer, whichever is closest
		case toDoubleGrid
		
		///distances are compensated for engine characteristics and rounded to the nearest half integer. If these operations change the sign of the distance, the distance is set to +1/2 or -1/2 according to the original sign of the distance.
		case toHalfGrid
		
		///after compensation for the engine characteristics, distances are rounded up to the closest integer. If the compensation and rounding would change the sign of the distance, the distance will be set to 0.
		case upToGrid
		
		///engine compensation occurs but no rounding takes place. If engine compensation would change the sign of a distance, the distance is set to 0
		case off
		
		
		
		//TODO: SROUND
		//TODO: S45ROUND
		
	}
	
	
	enum PointerZone : Int32 {
		case twilight = 0
		case glyph = 1
	}
	
	
	
	struct ScanControl {
		var ppemThreshold:UInt8	//255 means all sizes
		
		var setTrueIfLTEThreshold:Bool
		var setTrueIfRotated:Bool
		var setTrueIfStretched:Bool
		var setFalseUnlessLTEThenThreshold:Bool
		var setFalseUnlessRotated:Bool
		var setFalseUnlessStretched:Bool
		
		init(value:Int32) {
			ppemThreshold = UInt8(UInt32(bitPattern: value & 0xFF))
			setTrueIfLTEThreshold = (value >> 8) & 0x01 != 0
			setTrueIfRotated = (value >> 9) & 0x01 != 0
			setTrueIfStretched = (value >> 10) & 0x01 != 0
			setFalseUnlessLTEThenThreshold = (value >> 11) & 0x01 != 0
			setFalseUnlessRotated = (value >> 12) & 0x01 != 0
			setFalseUnlessStretched = (value >> 13) & 0x01 != 0
		}
		
		func evaluate(ppem:UInt32, isRotated:Bool, isStretched:Bool)->Bool {
			let ppemIsLTEToThreshold:Bool = ppemThreshold == 255 ? true : ppem <=  UInt32(ppemThreshold)
			if setFalseUnlessRotated, !isRotated {
				return false
			}
			if setFalseUnlessStretched, !isStretched {
				return false
			}
			if setFalseUnlessLTEThenThreshold, !ppemIsLTEToThreshold {
				return false
			}
			if setTrueIfStretched, isStretched {
				return true
			}
			if setTrueIfRotated, isRotated {
				return true
			}
			if setTrueIfLTEThreshold, ppemIsLTEToThreshold {
				return true
			}
			return false
		}
		
	}
	
	
}

