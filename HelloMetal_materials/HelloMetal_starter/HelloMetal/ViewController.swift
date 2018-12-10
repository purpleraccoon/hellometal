/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Metal

class ViewController: UIViewController {
	var device: MTLDevice!
	var metalLayer: CAMetalLayer!
	let vertexData: [Float] = [
		 0.0,  1.0,  0.0,
		-1.0, -1.0,  0.0,
		 1.0, -1.0,  0.0
	]
	var vertexBuffer: MTLBuffer!
	var pipelineState: MTLRenderPipelineState!
	var commandQueue: MTLCommandQueue!
	var timer: CADisplayLink!
	
	var thing = 0.0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		device = MTLCreateSystemDefaultDevice()
		metalLayer = CAMetalLayer()
		metalLayer.device = device
		metalLayer.pixelFormat = .bgra8Unorm
		metalLayer.framebufferOnly = true
		let viewFrame = view.layer.frame
		metalLayer.frame = CGRect(x: 0, y: 0, width: min(viewFrame.height, viewFrame.width), height: min(viewFrame.height, viewFrame.width))
		view.layer.addSublayer(metalLayer)
		
		let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
		vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
		
		let defaultLibrary = device.makeDefaultLibrary()!
		let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
		let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
		
		let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
		pipelineStateDescriptor.vertexFunction = vertexProgram
		pipelineStateDescriptor.fragmentFunction = fragmentProgram
		pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
		
		pipelineState = try!
		device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
		
		commandQueue = device.makeCommandQueue()
		
		timer = CADisplayLink(target: self, selector: #selector(gameloop))
		timer.add(to: RunLoop.main, forMode: .default)
		
	}
	
	func render() {
		guard let drawable = metalLayer?.nextDrawable() else { return }
		let renderPassDescriptor = MTLRenderPassDescriptor()
		renderPassDescriptor.colorAttachments[0].texture = drawable.texture
		renderPassDescriptor.colorAttachments[0].loadAction = .clear
		renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: thing/255.0, green: 104.0/255.0, blue: 55.0/255.0, alpha: 1.0)
		thing += 1
		thing = thing.truncatingRemainder(dividingBy: 255.0)
		
		let commandBuffer = commandQueue.makeCommandBuffer()!
		
		let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
		renderEncoder.setRenderPipelineState(pipelineState)
		renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
		renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
		renderEncoder.endEncoding()
		commandBuffer.present(drawable)
		commandBuffer.commit()
	}
	
	@objc func gameloop() {
		autoreleasepool {
			self.render()
		}
	}
}
