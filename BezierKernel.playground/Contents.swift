//: Playground - noun: a place where people can play

import Cocoa
import Metal
import PlaygroundSupport


enum ElementType: UInt8 {
	case lineTo = 2
	case quadCurveTo = 3
	case curveTo = 4
};

struct BezierPathElement {
	var type: UInt8					// 0
	var unused1: UInt8				// 1
	var unused2: UInt8				// 2
	var unused3: UInt8				// 3

	var numberOfVertexes: UInt16	// 4
	var vertexIndex: UInt16			// 6

	var width1: UInt16				// 8
	var width2: UInt16				// 10
	var unused4: UInt16				// 12 .. somehow needed
	var unused5: UInt16				// 14 .. somehow needed

	var p0: Point					// 16
	var p1: Point					// 24
	var p2: Point					// 32
	var p3: Point					// 40
									// 48

	init(type: ElementType, numberOfVertexes: Int, vertexIndex: Int, w1: Int, w2: Int, p0: Point, p1: Point, p2: Point, p3: Point) {
		self.type = type.rawValue
		self.unused1 = 0
		self.unused2 = 0
		self.unused3 = 0
		self.numberOfVertexes = UInt16(numberOfVertexes)
		self.vertexIndex = UInt16(vertexIndex)
		self.width1 = UInt16(w1)
		self.width2 = UInt16(w2)
		self.unused4 = 0
		self.unused5 = 0
		self.p0 = p0
		self.p1 = p1
		self.p2 = p2
		self.p3 = p3
	}
}

struct Vertex {
	var x: Float16
	var y: Float16
	var width: Float16
	var unused: Float16 = Float16(0.0)

	init(x: Float, y: Float, width: Float) {
		self.x = Float16(x)
		self.y = Float16(y)
		self.width = Float16(width)
	}
	
	init(point: Point, width: Float) {
		self.x = Float16(point.x)
		self.y = Float16(point.y)
		self.width = Float16(width)
	}

}

typealias LineSegment = (type: ElementType, length: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint)

func lineSegments(cgPaths: [CGPath]) -> [LineSegment] {
	let nan2 = CGPoint(CGFloat.nan, CGFloat.nan)

	return cgPaths.map { (cgPath) -> [LineSegment] in

		var origin: CGPoint?
		var lastPoint: CGPoint?

		return cgPath.pathElements.flatMap { (pathElement) -> LineSegment? in
			switch pathElement {
			case .moveTo(let p1):
				origin = p1
				lastPoint = p1
			case .lineTo(let p1):
				guard let p0 = lastPoint else { return nil }
				let length = (p0 - p1).length
				lastPoint = p1
				return (.lineTo, length, p0, p1, nan2, nan2)
			case .quadCurveTo(let p1, let p2):
				guard let p0 = lastPoint else { return nil }
				let length = CGPath.quadraticCurveLength(p0, p1, p2)
				lastPoint = p2
				return (.quadCurveTo, length, p0, p1, p2, nan2)
			case .curveTo(let p1, let p2, let p3):
				guard let p0 = lastPoint else { return nil }
				let length = CGPath.approximateCubicCurveLength(p0, p1, p2, p3)
				lastPoint = p3
				return (.curveTo, length, p0, p1, p2, p3)
			case .closeSubpath:
				guard let p0 = lastPoint, let p1 = origin else { return nil }
				let length = (p0 - p1).length
				lastPoint = nil
				origin = nil
				return (.lineTo, length, p0, p1, nan2, nan2)
			}
			return nil
		}

	}
	.flatMap { $0 }
}

let device = MTLCreateSystemDefaultDevice()!
let commandQueue = device.makeCommandQueue()
let commandBuffer = commandQueue.makeCommandBuffer()


let shaderSource = try! String(contentsOf: #fileLiteral(resourceName: "BezierShaders.metal"))
let library = try! device.makeLibrary(source: shaderSource, options: nil)
let bezierKernel = library.makeFunction(name: "bezier_kernel")!
let computePipelineState = try! device.makeComputePipelineState(function: bezierKernel)



func computeBezierCurve(cgPaths: [CGPath]) -> [CGPoint] {

	// Note: Be aware this is very simple case to produce bezier curve points, giving this
	// more complex beizer path may require you a bit more sofisiticated memory mamegement.

	var vertexCount: Int = 0
	let (w1, w2) = (8, 8)
	let segments = lineSegments(cgPaths: cgPaths)
	var elements = [BezierPathElement]()
	for segment in segments {
		let count = Int(segment.length / 8)
		defer { vertexCount += count }
		let element = BezierPathElement(type: segment.type, numberOfVertexes: count, vertexIndex: vertexCount, w1: w1, w2: w2,
				p0: Point(segment.p0), p1: Point(segment.p1), p2: Point(segment.p2), p3: Point(segment.p3))
		elements.append(element)
	}

	let elementsBufferSize = MemoryLayout<BezierPathElement>.size * elements.count
	let elementsBuffer = device.makeBuffer(bytes: &elements, length: elementsBufferSize, options: [.storageModeShared])
	let vertexBufferSize = MemoryLayout<BezierPathElement>.size
	let vertexBuffer = device.makeBuffer(length: vertexBufferSize, options: [.storageModeShared])

	let encoder = commandBuffer.makeComputeCommandEncoder()
	encoder.setComputePipelineState(computePipelineState)
	encoder.setBuffer(elementsBuffer, offset: 0, at: 0)
	encoder.setBuffer(vertexBuffer, offset: 0, at: 1)
	let threadgroupsPerGrid = MTLSizeMake(elements.count, 1, 1)
	let threadsPerThreadgroup = MTLSizeMake(1, 1, 1)
	encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
	encoder.endEncoding()
	commandBuffer.commit()
	commandBuffer.waitUntilCompleted()

	let vertices = UnsafeMutablePointer<Vertex>(OpaquePointer(vertexBuffer.contents()))
	var points = [CGPoint]()
	for index in 0 ..< vertexCount {
		let vertex = vertices[index]
		let point = CGPoint(CGFloat(vertex.x.floatValue), CGFloat(vertex.y.floatValue))
		points.append(point)
	}
	return points
}


class MyBezierView: NSView, CALayerDelegate {

	var box: CGRect { return self.bounds.insetBy(dx: 40, dy: 40) }
	
	lazy var bezierPath: CGPath = {
		let bezierPath = CGMutablePath()
		bezierPath.addEllipse(in: self.box)
		return bezierPath
	}()

	lazy var computedPoints: [CGPoint] = {
		return computeBezierCurve(cgPaths: [self.bezierPath])
	}()

	override func layout() {
		super.layout()
		self.wantsLayer = true
		self.setNeedsDisplay(self.bounds)
	}

	override func setNeedsDisplay(_ invalidRect: NSRect) {
		super.setNeedsDisplay(invalidRect)
		self.layer?.setNeedsDisplay()
	}

	func draw(_ layer: CALayer, in context: CGContext) {

		Swift.print("draw:in:")
		context.setStrokeColor(NSColor.yellow.cgColor)
		context.setLineWidth(5)
		context.addPath(bezierPath)
		context.strokePath()

		var lastPoint: CGPoint?
		for point in self.computedPoints {
			defer { lastPoint = point }

			if let _ = lastPoint {
				context.addLine(to: point)
			}
			else {
				context.move(to: point)
			}
		}

		context.setStrokeColor(NSColor.red.cgColor)
		context.setLineWidth(1)
		context.strokePath()
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
	}
}


let bezierView = MyBezierView(frame: CGRect(0, 0, 300, 300))

PlaygroundPage.current.liveView = bezierView
