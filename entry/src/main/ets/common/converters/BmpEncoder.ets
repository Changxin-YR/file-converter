/** Encodes RGBA_8888 pixels as a top-down, uncompressed 32-bit BMP. */
export class BmpEncoder {
  static encode(rgba: ArrayBuffer, width: number, height: number): ArrayBuffer {
    if (!Number.isInteger(width) || !Number.isInteger(height) || width <= 0 || height <= 0) {
      throw new Error('BMP dimensions must be positive integers')
    }

    const pixelBytes = width * height * 4
    if (!Number.isSafeInteger(pixelBytes) || rgba.byteLength !== pixelBytes) {
      throw new Error('BMP RGBA buffer length does not match dimensions')
    }

    const headerSize = 54
    const output = new ArrayBuffer(headerSize + pixelBytes)
    const bytes = new Uint8Array(output)
    const view = new DataView(output)

    bytes[0] = 0x42
    bytes[1] = 0x4D
    view.setUint32(2, output.byteLength, true)
    view.setUint32(10, headerSize, true)
    view.setUint32(14, 40, true)
    view.setInt32(18, width, true)
    view.setInt32(22, -height, true)
    view.setUint16(26, 1, true)
    view.setUint16(28, 32, true)
    view.setUint32(30, 0, true)
    view.setUint32(34, pixelBytes, true)
    view.setInt32(38, 2835, true)
    view.setInt32(42, 2835, true)

    const source = new Uint8Array(rgba)
    for (let sourceOffset = 0, targetOffset = headerSize;
      sourceOffset < source.length; sourceOffset += 4, targetOffset += 4) {
      bytes[targetOffset] = source[sourceOffset + 2]
      bytes[targetOffset + 1] = source[sourceOffset + 1]
      bytes[targetOffset + 2] = source[sourceOffset]
      bytes[targetOffset + 3] = source[sourceOffset + 3]
    }
    return output
  }
}
