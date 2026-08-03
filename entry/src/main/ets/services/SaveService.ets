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
    const result = await this.getSavePaths([defaultFileName])
    return result[0]
  }

  /** 一次选择多个文件的保存位置,返回与文件名顺序一致的目标 uri。 */
  async getSavePaths(defaultFileNames: string[]): Promise<string[]> {
    const options = new picker.DocumentSaveOptions()
    options.newFileNames = defaultFileNames
    const documentPicker = new picker.DocumentViewPicker(this.context)
    let result: string[] = []
    try {
      result = await documentPicker.save(options)
    } catch (e) {
      const error = e as Error
      throw new Error(`用户取消保存或保存选择器失败:${error.message}`)
    }
    if (!result || result.length === 0) {
      throw new Error('用户取消了保存')
    }
    if (result.length !== defaultFileNames.length) {
      throw new Error('保存目标数量与待保存文件数量不一致')
    }
    return result
  }
}
