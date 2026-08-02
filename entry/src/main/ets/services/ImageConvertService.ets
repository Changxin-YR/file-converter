/**
 * 图片转换服务
 * 基于 @kit.ImageKit 实现格式互转与尺寸调整,资源统一释放。
 */
import { image } from '@kit.ImageKit'
import { fileIo as fs } from '@kit.CoreFileKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { ConvertOptions, ConvertResult } from '../common/ConvertTask'
import { BmpEncoder } from '../common/converters/BmpEncoder'

export class ImageConvertService {
  /**
   * 图片格式转换:解码 → 尺寸调整 → 编码 → 写盘
   */
  async convertFormat(
    sourceUri: string,
    targetPath: string,
    targetFormat: string,
    options?: ConvertOptions
  ): Promise<ConvertResult> {
    let sourceFile: fs.File | null = null
    let imageSource: image.ImageSource | null = null
    let pixelMap: image.PixelMap | null = null
    let imagePacker: image.ImagePacker | null = null
    try {
      // 1. 打开源文件并按 fd 解码
      sourceFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY)
      imageSource = image.createImageSource(sourceFile.fd)

      const decodingOptions: image.DecodingOptions = {
        editable: true,
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      }
      pixelMap = await imageSource.createPixelMap(decodingOptions)

      // 2. 尺寸调整（可选,支持仅指定宽或高时按原图比例补齐）
      const reqWidth = options?.width
      const reqHeight = options?.height
      if (reqWidth || reqHeight) {
        const info: image.ImageInfo = await imageSource.getImageInfo()
        const srcWidth = info.size.width
        const srcHeight = info.size.height
        if (srcWidth === 0 || srcHeight === 0) {
          return { success: false, errorMsg: '图片尺寸无效' }
        }
        let width = srcWidth
        let height = srcHeight
        if (reqWidth && reqHeight) {
          width = reqWidth
          height = reqHeight
        } else if (reqWidth) {
          width = reqWidth
          height = Math.round(reqWidth / (srcWidth / srcHeight))
        } else if (reqHeight) {
          height = reqHeight
          width = Math.round(reqHeight * (srcWidth / srcHeight))
        }
        if (options?.keepAspectRatio ?? true) {
          const ratio = srcWidth / srcHeight
          if (width / height > ratio) {
            width = Math.round(height * ratio)
          } else {
            height = Math.round(width / ratio)
          }
        }
        await pixelMap.scale(width / srcWidth, height / srcHeight)
      }

      // 3. 编码为目标格式。BMP 使用项目内编码器，不依赖设备 ImagePacker 能力。
      let packedData: ArrayBuffer
      if (targetFormat.toLowerCase() === 'bmp') {
        const pixelInfo: image.ImageInfo = await pixelMap.getImageInfo()
        const rgba = new ArrayBuffer(pixelInfo.size.width * pixelInfo.size.height * 4)
        await pixelMap.readPixelsToBuffer(rgba)
        packedData = BmpEncoder.encode(rgba, pixelInfo.size.width, pixelInfo.size.height)
      } else {
        imagePacker = image.createImagePacker()
        const packingOptions: image.PackingOption = {
          format: this.getMimeType(targetFormat),
          quality: options?.quality ?? 90
        }
        packedData = await imagePacker.packing(pixelMap, packingOptions)
      }

      // 4. 写入目标文件
      const outFile = fs.openSync(targetPath, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.WRITE_ONLY)
      try {
        fs.writeSync(outFile.fd, packedData)
      } finally {
        fs.closeSync(outFile)
      }

      return { success: true, targetPath }
    } catch (e) {
      const err = e as BusinessError
      return { success: false, errorMsg: `图片转换失败:${err.message}` }
    } finally {
      if (pixelMap) {
        pixelMap.release()
      }
      if (imageSource) {
        imageSource.release()
      }
      if (imagePacker) {
        imagePacker.release()
      }
      if (sourceFile) {
        fs.closeSync(sourceFile)
      }
    }
  }

  private getMimeType(format: string): string {
    const mimeMap: Record<string, string> = {
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      'heif': 'image/heif',
      'heic': 'image/heic'
    }
    return mimeMap[format.toLowerCase()] ?? 'image/png'
  }
}
