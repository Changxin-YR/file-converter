/**
 * 文件选取服务
 * 通过系统文件选择器获取临时授权 uri,无需常驻全局权限。
 */
import { picker } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'

export class FilePickerService {
  private context: common.UIAbilityContext

  constructor(context: common.UIAbilityContext) {
    this.context = context
  }

  /** 从系统文件选择器选择图片（返回 uri 列表,免授权且不依赖相册索引） */
  async pickImages(maxCount: number = 9): Promise<string[]> {
    const options = new picker.DocumentSelectOptions()
    options.maxSelectNumber = maxCount
    options.fileSuffixFilters = ['.png', '.jpg', '.jpeg', '.webp', '.bmp', '.heif', '.heic']
    const documentPicker = new picker.DocumentViewPicker(this.context)
    return await documentPicker.select(options)
  }

  /** 选择任意文件（按后缀过滤,免授权） */
  async pickFiles(fileSuffixFilters: string[], maxCount: number = 9): Promise<string[]> {
    const options = new picker.DocumentSelectOptions()
    options.maxSelectNumber = maxCount
    options.fileSuffixFilters = fileSuffixFilters
    const documentPicker = new picker.DocumentViewPicker(this.context)
    return await documentPicker.select(options)
  }
}
