//
//  PieGraphView.swift
//  VendingMachineApp
//
//  Created by Eunjin Kim on 2018. 3. 29..
//  Copyright © 2018년 Eunjin Kim. All rights reserved.
//

import UIKit

class PieGraphView: UIView {
    private var graphColor = [UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.blue, UIColor.purple, UIColor.gray, UIColor.brown, UIColor.darkGray, UIColor.black]
    private var beverage = [String: Int]()
    private var isTouched = false
    private var isInitialized = false
    private var originLength: CGFloat = 0
    struct DataOfPieGraph {
        var path: UIBezierPath
        var startAngle: CGFloat
        var endAngle: CGFloat
        var index: Int
        var product: (key: String, value: Int)
        init(path: UIBezierPath, startAngle: CGFloat, endAngle: CGFloat, index: Int, product: (key: String, value: Int)) {
            self.path = path
            self.startAngle = startAngle
            self.endAngle = endAngle
            self.index = index
            self.product = product
        }
        init(path: UIBezierPath, product: (key: String, value: Int)) {
            self.path = path
            self.startAngle = 0
            self.endAngle = 2 * .pi
            self.index = 9
            self.product = product
        }
    }
    private var numberOfBeverage: Float {
        var number: Float = 0
        for data in beverage {
            number += Float(data.value)
        }
        return number
    }
    var pieDrawable: PieDrawable? {
        didSet {
            guard let data = pieDrawable?.receiveData() else {
                return
            }
            self.beverage = data
        }
    }
    private lazy var textAttributes: [NSAttributedStringKey: Any] = {
        let myShadow = NSShadow()
        myShadow.shadowBlurRadius = 3
        myShadow.shadowOffset = CGSize(width: 3, height: 3)
        myShadow.shadowColor = UIColor.gray
        return [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.shadow: myShadow, NSAttributedStringKey.font: UIFont(name: "Helvetica-Bold", size: radiusOfGraph - Constants.fontSize)!]
    }()
    
    private var centerOfGraph: CGPoint {
        return CGPoint(x: bounds.width / 2, y: self.bounds.height / 2)
    }
    private var sizeOfView: CGFloat {
        return max(bounds.width, bounds.height)
    }
    private var radius: CGFloat = 0
    private var radiusOfGraph: CGFloat {
        get {
            return radius
        }
        set(newRadius) {
            radius = newRadius
        }
    }
    private struct Constants {
        static let arcWidth: CGFloat = 10
        static let minRadius: CGFloat = 20
        static let fontSize: CGFloat = 300
    }
    
    private func calculateAngle(endAngle: CGFloat, number: Float) -> CGFloat {
        let angle = 2 * .pi * CGFloat(number / numberOfBeverage)
        let result = endAngle + angle
        return result
    }
    
    private func calculatePoint(center: CGPoint, angle: CGFloat, radius: CGFloat) -> CGPoint {
        let x1 = Int(center.x + (cos(angle) * radius))
        let y1 = Int(center.y + (sin(angle) * radius))
        return CGPoint(x: x1, y: y1)
    }
    
    private func calculateTextPoint(center: CGPoint, startAngle: CGFloat, endAngle: CGFloat, radius: CGFloat) -> CGPoint {
        let halfAngle = (endAngle + startAngle) / 2
        return calculatePoint(center: center, angle: halfAngle, radius: radius/2)
    }
    
    // 파이그래프 세팅
    private func setPieGraphdrawing(pieData: DataOfPieGraph) -> CGFloat {
        pieData.path.move(to: centerOfGraph)
        graphColor[pieData.index].setFill()
        return calculateAngle(endAngle: pieData.endAngle, number: Float(pieData.product.value))
    }
    
    // 파이그래프 그리기
    private func drawPieGraph(pieData: DataOfPieGraph) {
        let point = calculatePoint(center: centerOfGraph, angle: pieData.startAngle, radius: radiusOfGraph)
        pieData.path.addLine(to: point)
        pieData.path.addArc(withCenter: centerOfGraph, radius: radiusOfGraph, startAngle: pieData.startAngle, endAngle: pieData.endAngle, clockwise: true)
        pieData.path.addLine(to: centerOfGraph)
        pieData.path.fill()
        pieData.path.close()
    }
    
    // 파이그래프에 글자 넣기
    private func drawTextOnPieGraph(pieData: DataOfPieGraph) {
        let textPoint = calculateTextPoint(center: centerOfGraph, startAngle: pieData.startAngle, endAngle: pieData.endAngle, radius: radiusOfGraph)
        let textToRender: NSString = pieData.product.key as NSString
        var renderRect = CGRect(origin: .zero, size: textToRender.size(withAttributes: textAttributes))
        renderRect.origin = textPoint
        textToRender.draw(in: renderRect, withAttributes: textAttributes)
    }
    
    // 검은색 원 그리기
    private func drawBlackCircle() {
        let path = UIBezierPath()
        var dataOfPieGraph = DataOfPieGraph(path: path, product: (key: "circle", value: Int(numberOfBeverage)))
        dataOfPieGraph.endAngle = setPieGraphdrawing(pieData: dataOfPieGraph)
        drawPieGraph(pieData: dataOfPieGraph)
    }
    
    // 음료수 별 비율을 계산하여 그래프로 출력
    private func drawPieGraphByCalculation() {
        var startAngle: CGFloat = 0
        var endAngle: CGFloat = 0
        var dataOfPieGraph: DataOfPieGraph
        for (index, product) in beverage.enumerated() {
            let path = UIBezierPath()
            dataOfPieGraph = DataOfPieGraph(path: path, startAngle: startAngle, endAngle: endAngle, index: index, product: product)
            endAngle = setPieGraphdrawing(pieData: dataOfPieGraph)
            dataOfPieGraph.endAngle = endAngle
            drawPieGraph(pieData: dataOfPieGraph)
            drawTextOnPieGraph(pieData: dataOfPieGraph)
            startAngle = endAngle
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        if !isInitialized {
            radius = sizeOfView/2 - Constants.arcWidth/2
            isInitialized = true
        }
        if isTouched {
            drawBlackCircle()
        } else {
            drawPieGraphByCalculation()
        }
    }
    
    func drawByShake() {
        isInitialized = false
        setNeedsDisplay()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let location = touch.location(in: self)
        if pow((centerOfGraph.x - location.x), 2) + pow((centerOfGraph.y - location.y), 2) < pow(radiusOfGraph, 2) {
            isTouched = true
            setNeedsDisplay()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let location = touch.location(in: self)
        if isTouched {
            var currentLength = sqrt(pow((centerOfGraph.x - location.x), 2) + pow((centerOfGraph.y - location.y), 2))
            if currentLength > sizeOfView/2 {
                currentLength = sizeOfView/2
            } else if currentLength < Constants.minRadius {
                currentLength = Constants.minRadius
            }
            radiusOfGraph = currentLength
            setNeedsDisplay()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let number = graphColor.count - 2
        graphColor = graphColor.shuffle(number)
        isTouched = false
        setNeedsDisplay()
    }
    
}

extension Array where Element == UIColor {
    mutating func shuffle(_ number: Int) -> [UIColor] {
        var list = self
        for index in list.indices {
            if index > number { break }
            let random = Int(arc4random_uniform(UInt32(number)))
            list.swapAt(index, random)
        }
        return list
    }
}
