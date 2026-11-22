import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct PNGFile: Transferable {
    let name: String
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .png) { file in
            let url = URL.temporaryDirectory.appending(path: file.name + ".png")
            try file.data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}
