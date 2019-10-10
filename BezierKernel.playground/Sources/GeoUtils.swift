//
//	GeoUtils.swift
//	Silvershadow
//
//	Created by Kaz Yoshikawa on 1/4/16.
//	Copyright © 2016 Electricwoods LLC. All rights reserved.
//

import Foundation
import CoreGraphics
import QuartzCore
import GLKit

infix operator •
infix operator ×

// MARK: -

public protocol FloatCovertible {
	var floatValue: Float { get }
}

extension CGFloat: FloatCovertible {
	public var floatValue: Float { return Float(self) }
}

extension Int: FloatCovertible {
	public var floatValue: Float { return Float(self) }
}

extension Float: FloatCovertible {
	public var floatValue: Float { return self }
}

// MARK: -

public protocol CGFloatCovertible {
	var cgFloatValue: CGFloat { get }
}

extension CGFloat: CGFloatCovertible {
	public var cgFloatValue: CGFloat { return self }
}

extension Int: CGFloatCovertible {
	public var cgFloatValue: CGFloat { return CGFloat(self) }
}

extension Float: CGFloatCovertible {
	public var cgFloatValue: CGFloat { return CGFloat(self) }
}



// MARK: -

public struct Point: Hashable {

	public var x: Float
	public var y: Float

	public static func - (lhs: Point, rhs: Point) -> Point {
		return Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
	}

	public static func + (lhs: Point, rhs: Point) -> Point {
		return Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
	}

	public static func * (lhs: Point, rhs: Float) -> Point {
		return Point(x: lhs.x * rhs, y: lhs.y * rhs)
	}

	public static func / (lhs: Point, rhs: Float) -> Point {
		return Point(x: lhs.x / rhs, y: lhs.y / rhs)
	}
	
	public static func • (lhs: Point, rhs: Point) -> Float { // dot product
		return lhs.x * rhs.x + lhs.y * rhs.y
	}

	public static func × (lhs: Point, rhs: Point) -> Float { // cross product
		return lhs.x * rhs.y - lhs.y * rhs.x
	}
	
	public var length²: Float {
		return (x * x) + (y * y)
	}

	public var length: Float {
		return sqrt(self.length²)
	}

	public var normalized: Point {
		let length = self.length
		return Point(x: x/length, y: y/length)
	}

	public func angle(to: Point) -> Float {
		return atan2(to.y - self.y, to.x - self.x)
	}

	public func angle(from: Point) -> Float {
		return atan2(self.y - from.y, self.x - from.x)
	}

	public var hashValue: Int { return self.x.hashValue &- self.y.hashValue }

	public static func == (lhs: Point, rhs: Point) -> Bool {
		return lhs.x == rhs.y && lhs.y == rhs.y
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(x)
		hasher.combine(y)
	}
}

public extension Point {

	init<X: FloatCovertible, Y: FloatCovertible>(_ x: X, _ y: Y) {
		self.x = x.floatValue
		self.y = y.floatValue
	}
	init<X: FloatCovertible, Y: FloatCovertible>(x: X, y: Y) {
		self.x = x.floatValue
		self.y = y.floatValue
	}
	init(_ point: CGPoint) {
		self.x = Float(point.x)
		self.y = Float(point.y)
	}
	
}


public struct Size {
	public var width: Float
	public var height: Float

	public init<W: FloatCovertible, H: FloatCovertible>(_ width: W, _ height: H) {
		self.width = width.floatValue
		self.height = height.floatValue
	}

	public init<W: FloatCovertible, H: FloatCovertible>(width: W, height: H) {
		self.width = width.floatValue
		self.height = height.floatValue
	}
	public init(_ size: CGSize) {
		self.width = Float(size.width)
		self.height = Float(size.height)
	}
}


public struct Rect: CustomStringConvertible {
	public var origin: Point
	public var size: Size

	public init(origin: Point, size: Size) {
		self.origin = origin; self.size = size
	}
	public init(_ origin: Point, _ size: Size) {
		self.origin = origin; self.size = size
	}
	public init<X: FloatCovertible, Y: FloatCovertible, W: FloatCovertible, H: FloatCovertible>(_ x: X, _ y: Y, _ width: W, _ height: H) {
		self.origin = Point(x: x, y: y)
		self.size = Size(width: width, height: height)
	}
	public init<X: FloatCovertible, Y: FloatCovertible, W: FloatCovertible, H: FloatCovertible>(x: X, y: Y, width: W, height: H) {
		self.origin = Point(x: x, y: y)
		self.size = Size(width: width, height: height)
	}
	public init(_ rect: CGRect) {
		self.origin = Point(rect.origin)
		self.size = Size(rect.size)
	}

	public var minX: Float { return min(origin.x, origin.x + size.width) }
	public var maxX: Float { return max(origin.x, origin.x + size.width) }
	public var midX: Float { return (origin.x + origin.x + size.width) / 2.0 }
	public var minY: Float { return min(origin.y, origin.y + size.height) }
	public var maxY: Float { return max(origin.y, origin.y + size.height) }
	public var midY: Float { return (origin.y + origin.y + size.height) / 2.0 }

	public var cgRectValue: CGRect { return CGRect(x: CGFloat(origin.x), y: CGFloat(origin.y), width: CGFloat(size.width), height: CGFloat(size.height)) }
	public var description: String { return "{Rect: (\(origin.x),\(origin.y))-(\(size.width), \(size.height))}" }
}

// MARK: -

public protocol PointConvertible {
	var pointValue: Point { get }
}

extension Point: PointConvertible {
	public var pointValue: Point { return self }
}

extension CGPoint: PointConvertible {
	public var pointValue: Point { return Point(self) }
}


// MARK: -

public extension CGPoint {

	init(_ point: Point) {
		self.init(x: CGFloat(point.x), y: CGFloat(point.y))
	}

	static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
	}

	static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
	}

	static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
		return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
	}

	static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
		return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
	}
	
	static func • (lhs: CGPoint, rhs: CGPoint) -> CGFloat { // dot product
		return lhs.x * rhs.x + lhs.y * rhs.y
	}

	static func × (lhs: CGPoint, rhs: CGPoint) -> CGFloat { // cross product
		return lhs.x * rhs.y - lhs.y * rhs.x
	}
	
	var length²: CGFloat {
		return (x * x) + (y * y)
	}

	var length: CGFloat {
		return sqrt(self.length²)
	}

	var normalized: CGPoint {
		let length = self.length
		return CGPoint(x: x/length, y: y/length)
	}

}

extension CGPoint {

	public init<X: CGFloatCovertible, Y: CGFloatCovertible>(_ x: X, _ y: Y) {
		self = CGPoint(x: x.cgFloatValue, y: y.cgFloatValue)
	}

}


extension CGSize {

	public init(_ size: Size) {
		self.init(width: CGFloat(size.width), height: CGFloat(size.height))
	}

	public init<W: CGFloatCovertible, H: CGFloatCovertible>(_ width: W, _ height: H) {
		self = CGSize(width: width.cgFloatValue, height: height.cgFloatValue)
	}
}


extension CGRect {

	public init(_ rect: Rect) {
		self.init(origin: CGPoint(rect.origin), size: CGSize(rect.size))
	}

	public init<X: CGFloatCovertible, Y: CGFloatCovertible, W: CGFloatCovertible, H: CGFloatCovertible>(_ x: X, _ y: Y, _ width: W, _ height: H) {
		self = CGRect(origin: CGPoint(x, y), size: CGSize(width, height))
	}

}


extension GLKMatrix4 {
	public init(_ transform: CGAffineTransform) {
		let t = CATransform3DMakeAffineTransform(transform)
		self.init(m: (
				Float(t.m11), Float(t.m12), Float(t.m13), Float(t.m14),
				Float(t.m21), Float(t.m22), Float(t.m23), Float(t.m24),
				Float(t.m31), Float(t.m32), Float(t.m33), Float(t.m34),
				Float(t.m41), Float(t.m42), Float(t.m43), Float(t.m44)))
	}
	public var scaleFactor : Float {
		return sqrt(m00 * m00 + m01 * m01 + m02 * m02)
	}
	public var invert: GLKMatrix4 {
		var invertible: Bool = true
		let t = GLKMatrix4Invert(self, &invertible)
		if !invertible { print("not invertible") }
		return t
	}
	public var description: String {
		return	"[ \(self.m00), \(self.m01), \(self.m02), \(self.m03) ;" +
				" \(self.m10), \(self.m11), \(self.m12), \(self.m13) ;" +
				" \(self.m20), \(self.m21), \(self.m22), \(self.m23) ;" +
				" \(self.m30), \(self.m31), \(self.m32), \(self.m33) ]"
	}
}


extension GLKVector2 {
	public init(_ point: CGPoint) {
		self.init(v: (Float(point.x), Float(point.y)))
	}
	public var description: String {
		return	"[ \(self.x), \(self.y) ]"
	}
}


extension GLKVector4 {
	public var description: String {
		return	"[ \(self.x), \(self.y), \(self.z), \(self.w) ]"
	}
}


public func * (l: GLKMatrix4, r: GLKMatrix4) -> GLKMatrix4 {
	return GLKMatrix4Multiply(l, r)
}

public func + (l: GLKVector2, r: GLKVector2) -> GLKVector2 {
	return GLKVector2Add(l, r)
}

public func * (l: GLKMatrix4, r: GLKVector2) -> GLKVector2 {
	let vector4 = GLKMatrix4MultiplyVector4(l, GLKVector4Make(r.x, r.y, 0.0, 1.0))
	return GLKVector2Make(vector4.x, vector4.y)
}

