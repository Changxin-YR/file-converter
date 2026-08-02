/**
 * 引擎注册表
 * 按注册顺序持有引擎,按优先级为任务解析可处理引擎。
 */
import { IConvertEngine } from './IConvertEngine'
import { ConvertType } from '../common/ConvertTask'

export class EngineRegistry {
  private engines: IConvertEngine[] = []

  register(engine: IConvertEngine): void {
    this.engines.push(engine)
  }

  /** 取第一个能处理该任务的引擎 */
  resolve(type: ConvertType, srcExt: string, dstExt: string): IConvertEngine | undefined {
    for (const engine of this.engines) {
      if (engine.supports(type, srcExt, dstExt)) {
        return engine
      }
    }
    return undefined
  }

  get size(): number {
    return this.engines.length
  }
}
