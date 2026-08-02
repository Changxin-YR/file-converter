/**
 * 保存位置服务
 * 由用户选择目标保存位置,返回可写的 uri（免授权）。
 */
import { picker } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'

export class SaveService {
  private context: common.UIAbilityContext

  constructor(context: common.UIAbilityContext) {
    this.context = context
  }

  /** 让用户选择保存位置,返回目标 uri。用户取消时抛出异常。 */
  async getSavePath(defaultFileName: string): Promise<string> {
    const options = new picker.DocumentSaveOptions()
    options.newFileNames = [defaultFileName]
    const documentPicker = new picker.DocumentViewPicker(this.context)
    const result = await documentPicker.save(options)
    if (!result || result.length === 0) {
      throw new Error('用户取消了保存')
    }
    return result[0]
  }
}
