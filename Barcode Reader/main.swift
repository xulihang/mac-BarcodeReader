//
//  main.swift
//  Barcode Reader
//
//  Created by xulihang on 2024/9/13.
//

import Vision
import Cocoa

func main(args: [String]) -> Int32 {
    
    if CommandLine.arguments.count == 3 {
        let (src, dst) = (args[1], args[2])


        guard let img = NSImage(byReferencingFile: src) else {
            fputs("Error: failed to load image '\(src)'\n", stderr)
            return 1
        }
        
        guard let imgRef = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fputs("Error: failed to convert NSImage to CGImage for '\(src)'\n", stderr)
            return 1
        }

        let requestHandler = VNImageRequestHandler(cgImage: imgRef, orientation: CGImagePropertyOrientation.downMirrored)
        let barcodeRequest = VNDetectBarcodesRequest()
        barcodeRequest.symbologies = [.pdf417]
        do {
            try requestHandler.perform([barcodeRequest])
        } catch {
            print("Can't make the request due to \(error)")
        }
        let results = barcodeRequest.results
        print(results?.count ?? 0)
        let outResults = NSMutableArray()
        let width = img.size.width
        let height = img.size.height
        for result in results! {
            let subDic = NSMutableDictionary()
            
            let minY = result.boundingBox.minY * height
            let minX = result.boundingBox.minX * width
            let maxY = result.boundingBox.maxY * height
            let maxX = result.boundingBox.maxX * width
            subDic.setObject(result.payloadStringValue ?? "", forKey: "barcodeText" as NSCopying)
            subDic.setObject(result.symbology, forKey: "barcodeFormat" as NSCopying)
            subDic.setObject("", forKey: "barcodeBytes" as NSCopying) //https://developer.apple.com/documentation/vision/vnbarcodeobservation/4183553-payloaddata?language=objc only available on macOS 14.0, iOS 17.0
            subDic.setObject(minX, forKey: "x1" as NSCopying)
            subDic.setObject(minY, forKey: "y1" as NSCopying)
            subDic.setObject(maxX, forKey: "x2" as NSCopying)
            subDic.setObject(minY, forKey: "y2" as NSCopying)
            subDic.setObject(maxX, forKey: "x3" as NSCopying)
            subDic.setObject(maxY, forKey: "y3" as NSCopying)
            subDic.setObject(minX, forKey: "x4" as NSCopying)
            subDic.setObject(maxY, forKey: "y4" as NSCopying)
            outResults.add(subDic)
        }
        let data = try? JSONSerialization.data(withJSONObject: outResults, options: [])
        let jsonString = String(data: data!,
                                encoding: .utf8) ?? "[]"
        try? jsonString.write(to: URL(fileURLWithPath: dst), atomically: true, encoding: String.Encoding.utf8)
        return 0
    }else{
        print("""
              usage:
                image_path output_path
              
              example:
                ./image.jpg out.json
              """)
        return 1
    }
}



exit(main(args: CommandLine.arguments))
