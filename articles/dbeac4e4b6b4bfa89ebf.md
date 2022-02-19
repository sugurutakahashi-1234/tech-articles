---
title: "[Swift] 平面座標系でのベクトルの内積の公式を用いてある3点からなるなす角を求める方法"
emoji: "🔖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift"]
published: true
---
# サンプルコード

タイトルの通りです。
環境：Xcode12.5.1

```swift
import Foundation

struct RectangularCoordinateSystemPoint {
    let x: Double
    let y: Double
    
    init(_ x:Double, _ y:Double) {
        self.x = x
        self.y = y
    }
}

extension RectangularCoordinateSystemPoint {
    func getSubtendedAngle(_ pointA: RectangularCoordinateSystemPoint, _ pointB:RectangularCoordinateSystemPoint) -> Angle {
        // 始点を自身の点Pとする
        let pointP = self

        // 点Aと点Bまでのベクトルを宣言する
        let vectorPA = RectangularCoordinateSystemVector(from: pointP, to: pointA)
        let vectorPB = RectangularCoordinateSystemVector(from: pointP, to: pointB)

        // ベクトルの大きさと内積を求める
        let magnitudePA = vectorPA.magnitude
        let magnitudePB = vectorPB.magnitude
        let innerProduct = RectangularCoordinateSystemVector.innerProduct(vectorPA, vectorPB)

        //  cosθ = 𝑎⃗・𝑏⃗ / |𝑎⃗| * |𝑏⃗| の公式より
        let cosTheta = innerProduct / (magnitudePA * magnitudePB)
        return Angle.radian(acos(cosTheta))
    }
}

struct RectangularCoordinateSystemVector {
    let elementX: Double
    let elementY: Double
    
    init(from fromPoint: RectangularCoordinateSystemPoint, to toPoint: RectangularCoordinateSystemPoint) {
        self.elementX = toPoint.x - fromPoint.x
        self.elementY = toPoint.y - fromPoint.y
    }
}

extension RectangularCoordinateSystemVector {
    var magnitude: Double {
        return sqrt(elementX * elementX + elementY * elementY)
    }
    
    static func innerProduct(_ vectorA: RectangularCoordinateSystemVector, _ vectorB: RectangularCoordinateSystemVector) -> Double {
        return vectorA.elementX * vectorB.elementX + vectorA.elementY * vectorB.elementY
    }
}

enum Angle {
    case radian(_ value: Double)
    case arcDegree(_ value: Double)
    
    var radian: Double {
        switch self {
        case let .arcDegree(value):
            return value * .pi / 180
        case let .radian(value):
            return value
        }
    }
    
    var arcDegree: Double {
        var arcDegree: Double {
            switch self {
            case let .arcDegree(value):
                return value
            case let .radian(value):
                return value * 180 / .pi
            }
        }
        let normalizedArcDegree = arcDegree.truncatingRemainder(dividingBy: 360.0)
        return 0.0 > normalizedArcDegree ? normalizedArcDegree + 360.0 : normalizedArcDegree
    }
}

// サンプル
let pointP = RectangularCoordinateSystemPoint(1,3)
let pointA = RectangularCoordinateSystemPoint(3,4)
let pointB = RectangularCoordinateSystemPoint(2,6)

let angle: Angle = pointP.getSubtendedAngle(pointA, pointB)

print("なす角 ∠APB: \(angle.arcDegree)") // なす角 ∠APB: 45.00000000000001
```
