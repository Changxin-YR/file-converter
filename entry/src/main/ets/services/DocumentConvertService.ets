/**
 * 文档转换服务
 * 通过引擎注册表分发转换任务,预留三方离线引擎扩展点。
 */
import { IConvertEngine } from '../engines/IConvertEngine'
import { EngineRegistry } from '../engines/EngineRegistry'
import { NativeTextEngine } from '../engines/NativeTextEngine'
import { ConvertTask, ConvertResult } from '../common/ConvertTask'

export class DocumentConvertService {
  private registry: EngineRegistry = new EngineRegistry()

  constructor() {
    // 注册原生文本引擎;PDF/Office 等三方引擎后续按需注册
    this.registry.register(new NativeTextEngine())
  }

  get engineCount(): number {
    return this.registry.size
  }

  /**
   * 转换一个文档任务
   * 通过注册表解析可处理引擎;无引擎时返回明确错误,不静默失败。
   */
  async convert(task: ConvertTask, onProgress: (percent: number) => void): Promise<ConvertResult> {
    const engine: IConvertEngine | undefined =
      this.registry.resolve(task.type, task.sourceFormat, task.targetFormat)
    if (!engine) {
      return { success: false, errorMsg: `暂不支持 ${task.sourceFormat} → ${task.targetFormat}` }
    }
    return await engine.convert(task, onProgress)
  }
}
