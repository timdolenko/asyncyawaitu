import UIKit

extension UIImage {
    func mergedSideBySide(with otherImage: UIImage) -> UIImage? {
        let mergedWidth = self.size.width + otherImage.size.width
        let mergedHeight = max(self.size.height, otherImage.size.height)
        let mergedSize = CGSize(width: mergedWidth, height: mergedHeight)
        UIGraphicsBeginImageContext(mergedSize)
        self.draw(in: CGRect(x: 0, y: 0, width: mergedWidth, height: mergedHeight))
        otherImage.draw(in: CGRect(x: self.size.width, y: 0, width: mergedWidth, height: mergedHeight))
        let mergedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return mergedImage
    }
}
